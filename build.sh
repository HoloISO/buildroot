#!/bin/bash

SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be ran as superuser or sudo"
	exit 1
fi

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
	--flavor)
	BUILD_FLAVOR_MANIFEST="${SCRIPTPATH}/presets/$2.sh"
	BUILD_FLAVOR_MANIFEST_ID="$2"
	POSTCOPY_DIR="$2"
	if [[ "${BUILD_FLAVOR_MANIFEST_ID}" =~ "dev" ]]; then
		BUILD_FLAVOR_MANIFEST_ID=$(echo $2 | cut -d '-' -f 1)
		BRANCH_OVERRIDES=$(echo $2 | cut -d '-' -f 2)
	fi
	shift
	shift
	;;
	--deployment_rel)
	RELEASETYPE="$2.sh"
	shift
	shift
	;;
	--snapshot_ver)
	SNAPSHOTVERSION="$2"
	shift
	shift
	;;
	--workdir)
	WORKDIR="$2/buildwork"
	shift
	shift
	;;
	--output-dir)
	if [[ -z "$2" ]]; then
		OUTPUT=${WORKDIR}
	else
		OUTPUT="$2"
		if [[ -n "${BRANCH_OVERRIDES}" ]]; then
			OUTPUT="$2/${BRANCH_OVERRIDES}"
		fi
	fi
	shift
	shift
	;;
    --add-release)
	IS_HOME_BUILD=true
	if [[ ! "${OUTPUT}" =~ "holoiso-images" ]]; then
		echo "Specific output directories should be preceeded with holoiso-images for release images."
		exit 255
	fi
	shift
	shift
	;;
    --rclone_path)
	RC_PATH="$2"
	shift
	shift
	;;
	--rclone_root)
	if [[ -n "${RC_PATH}" ]]; then
		RC_ROOT="$2"
	else
		echo "rclone root can be used only with --rclone_path"
		exit 255
	fi
	shift
	shift
	;;
	*)    # unknown option
    echo "Unknown option: $1"
    exit 1
    ;;
esac
done

# Check if everything is set.
if [[ -z "{$BUILD_FLAVOR_MANIFEST}" ]]; then
	echo "Build flavor was not set. Aborting."
	exit 0
fi
if [[ -z "${SNAPSHOTVERSION}" ]]; then
	echo "Snapshot directory was not set. Aborting."
	exit 0
fi
if [[ -z "${WORKDIR}" ]]; then
	echo "Workdir was not set. Aborting."
	exit 0
fi

source $BUILD_FLAVOR_MANIFEST
PACCFG=${SCRIPTPATH}/pacman-build-${BUILD_FLAVOR_MANIFEST_ID}.conf
PACCFG_HWSUPPORT=${SCRIPTPATH}/pacman-hwsupport-${BUILD_FLAVOR_MANIFEST_ID}.conf


ROOT_WORKDIR=${WORKDIR}/rootfs_mnt
echo "Preparing to create deployment image..."
# Pre-build cleanup
umount -l ${ROOT_WORKDIR}
rm -rf ${WORKDIR}/*.img*
rm -rf ${WORKDIR}/*.img
rm -rf ${WORKDIR}/work.img

# Start building here
mkdir -p ${WORKDIR}
mkdir -p ${OUTPUT}
mkdir -p ${ROOT_WORKDIR}
fallocate -l 10000MB ${WORKDIR}/work.img
mkfs.btrfs ${WORKDIR}/work.img
mkdir -p ${WORKDIR}/rootfs_mnt
mount -t btrfs -o loop,compress-force=zstd:1,discard,noatime,nodiratime ${WORKDIR}/work.img ${ROOT_WORKDIR}

echo "(1/7) Bootstrapping main filesystem"
# Start by bootstrapping essentials
mkdir -p ${ROOT_WORKDIR}/${OS_FS_PREFIX}_root/rootfs
mkdir -p ${ROOT_WORKDIR}/var/cache/pacman/pkg
mount --bind /var/cache/pacman/pkg/ ${ROOT_WORKDIR}/var/cache/pacman/pkg
pacstrap -C ${PACCFG} ${ROOT_WORKDIR} ${BASE_BOOTSTRAP_PKGS}
echo "(1.5/7) Bootstrapping kernel..."
pacstrap -C ${PACCFG_HWSUPPORT} ${ROOT_WORKDIR} ${KERNELCHOICE} ${KERNELCHOICE}-headers

echo "(2/7) Generating fstab..."

# fstab
echo "
LABEL=${OS_FS_PREFIX}_root /          btrfs subvol=rootfs/${FLAVOR_BUILDVER},compress-force=zstd:1,discard,noatime,nodiratime 0 0
LABEL=${OS_FS_PREFIX}_root /${OS_FS_PREFIX}_root btrfs rw,compress-force=zstd:1,discard,noatime,nodiratime,nodatacow 0 0
LABEL=${OS_FS_PREFIX}_var /var       ext4 rw,relatime 0 0
LABEL=${OS_FS_PREFIX}_home /home      ext4 rw,relatime 0 0
" > ${ROOT_WORKDIR}/etc/fstab

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' ${ROOT_WORKDIR}/etc/sudoers

echo "(3/7) Bootstrapping HoloISO core root"
pacstrap -C ${PACCFG} ${ROOT_WORKDIR} ${UI_BOOTSTRAP}
rm ${ROOT_WORKDIR}/etc/pacman.conf
cp ${PACCFG} ${ROOT_WORKDIR}/etc/pacman.conf
echo -e $OS_RELEASE > ${ROOT_WORKDIR}/etc/os-release
echo -e $HOLOISO_RELEASE > ${ROOT_WORKDIR}/etc/holoiso-release
echo -e "holoiso" > ${ROOT_WORKDIR}/etc/hostname
arch-chroot ${ROOT_WORKDIR} systemctl enable ${FLAVOR_CHROOT_SCRIPTS}
if [[ -d "${SCRIPTPATH}/postcopy_${POSTCOPY_DIR}" ]]; then
	echo "Copying production postcopy items..."
	cp -r ${SCRIPTPATH}/postcopy_${POSTCOPY_DIR}/* ${ROOT_WORKDIR}
	rm ${ROOT_WORKDIR}/upstream.sh
	mkdir ${ROOT_WORKDIR}/nix
	if [[ -n "$FLAVOR_PLYMOUTH_THEME" ]]; then
		echo "Setting $FLAVOR_PLYMOUTH_THEME theme for plymouth bootsplash..."
		arch-chroot ${ROOT_WORKDIR} plymouth-set-default-theme -R $FLAVOR_PLYMOUTH_THEME
	fi
	arch-chroot ${ROOT_WORKDIR} setuphandycon
	arch-chroot ${ROOT_WORKDIR} add_additional_pkgs
	rm -rf ${ROOT_WORKDIR}/usr/bin/setuphandycon
	rm -rf ${ROOT_WORKDIR}/usr/bin/add_additional_pkgs
	echo -e "[Unit]\nDescription=HoloISO onload - /var/lib/pacman\n\n[Mount]\nWhat=/holo_root/rootfs/${FLAVOR_FINAL_DISTRIB_IMAGE}/var/lib/pacman\nWhere=/var/lib/pacman\nType=none\nOptions=bind\n\n[Install]\nWantedBy=steamos-offload.target" > ${ROOT_WORKDIR}/usr/lib/systemd/system/var-lib-pacman.mount
	arch-chroot ${ROOT_WORKDIR} systemctl enable ${FLAVOR_CHROOT_SCRIPTS} steamos-offload.target var-lib-pacman.mount nix.mount opt.mount root.mount srv.mount usr-lib-debug.mount usr-local.mount var-cache-pacman.mount var-lib-docker.mount var-lib-flatpak.mount var-lib-systemd-coredump.mount var-log.mount var-tmp.mount powerbutton-chmod
fi

# Cleanup
umount -l ${ROOT_WORKDIR}/var/cache/pacman/pkg/

# Finish for now
echo "Packaging snapshot..."
btrfs subvolume snapshot -r ${ROOT_WORKDIR} ${ROOT_WORKDIR}/${OS_FS_PREFIX}_root/rootfs/${FLAVOR_BUILDVER}
btrfs send -f ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.img ${ROOT_WORKDIR}/${OS_FS_PREFIX}_root/rootfs/${FLAVOR_BUILDVER}
umount -l ${ROOT_WORKDIR} && umount -l ${WORKDIR}/work.img && rm -rf ${WORKDIR} && ${WORKDIR}/work.img
echo "Compressing image..."
zstd --ultra -z ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.img -o ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.img.zst
rm -rf ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.img
chown 1000:1000 ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.img.zst
chmod 777 ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.img.zst

if [[ "${IS_HOME_BUILD}" == "true" ]]; then
	echo -e ${UPDATE_METADATA} > ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.releasemeta
	echo -e ${UPDATE_METADATA} > ${OUTPUT}/latest_${BUILD_FLAVOR_MANIFEST_ID}.releasemeta
	sha256sum ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.img.zst | awk '{print $1'} > ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.sha256
	chown 1000:1000 ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.sha256 ${OUTPUT}/latest_${BUILD_FLAVOR_MANIFEST_ID}.releasemeta
	chmod 777 ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.sha256 ${OUTPUT}/latest_${BUILD_FLAVOR_MANIFEST_ID}.releasemeta
	if [[ -n "${RC_PATH}" ]]; then
		rclone mkdir ${RC_PATH}:/download/$(echo ${OUTPUT} | sed 's#.*holoiso#holoiso#g')
		rclone copy ${OUTPUT}/latest_${BUILD_FLAVOR_MANIFEST_ID}.releasemeta ${RC_PATH}:/download/$(echo ${OUTPUT} | sed 's#.*holoiso#holoiso#g') -L --progress
		rclone copy ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.sha256 ${RC_PATH}:/${RC_ROOT}/$(echo ${OUTPUT} | sed 's#.*holoiso#holoiso#g') -L --progress
		rclone copy ${OUTPUT}/${FLAVOR_FINAL_DISTRIB_IMAGE}.img.zst ${RC_PATH}:/${RC_ROOT}/$(echo ${OUTPUT} | sed 's#.*holoiso#holoiso#g') -L --progress
	fi
fi
