#!/bin/bash
rm -rf /tmp/builder-releasetag
rm -rf /tmp/build_temp_ver
export DISTRO_NAME="HoloISO"
export OS_CODENAME="Rel"
export OS_FS_PREFIX="holo"
export RELEASETAG=snapshot$(date +%Y%m%d.%H%M.%S)
echo -e ${RELEASETAG} > /tmp/builder-releasetag
echo -e "$(echo ${DISTRO_NAME} | tr '[:upper:]' '[:lower:]')_$(echo ${OS_CODENAME} | tr '[:upper:]' '[:lower:]')_${RELEASETAG}" > /tmp/build_temp_ver
export FLAVOR_BUILDVER=$(cat /tmp/build_temp_ver)
export IMAGEFILE="${FLAVOR_BUILDVER}"
export FLAVOR_CHROOT_SCRIPTS="sddm bluetooth sshd systemd-timesyncd NetworkManager steamos-offload.target var-lib-pacman.mount nix.mount opt.mount root.mount srv.mount usr-lib-debug.mount usr-local.mount var-cache-pacman.mount var-lib-docker.mount var-lib-flatpak.mount var-lib-systemd-coredump.mount var-log.mount var-tmp.mount powerbutton-chmod"
export FLAVOR_PLYMOUTH_THEME="steamos"
export FLAVOR_FINAL_DISTRIB_IMAGE=$FLAVOR_BUILDVER
export KERNELCHOICE="linux-lljy"
export BASE_BOOTSTRAP_PKGS="base base-devel linux-firmware amd-ucode intel-ucode sddm-wayland dkms jq btrfs-progs core-main/grub efibootmgr openssh"
export UI_BOOTSTRAP="lib32-gamescope perf pipewire-x11-bell wakehook zip zram-generator gst-plugin-pipewire caps criu cpupower lib32-libnm lib32-libpulse lib32-libsndfile lib32-libogg lib32-openal  python-build nano vim fuse vi flatpak plymouth python-installer python-setuptools python-wheel arch-install-scripts archlinux-keyring holo-keyring ark cups curl dolphin ffmpegthumbs gamescope git go gwenview hunspell hunspell-en_us kdegraphics-thumbnailers konsole kwrite lib32-pipewire lib32-pipewire-jack lib32-pipewire-v4l2 libva lib32-libva libva-utils libva-mesa-driver libva-intel-driver lib32-libva-mesa-driver lib32-libva-intel-driver lib32-vulkan-radeon lib32-vulkan-intel mangohud mesa lib32-mesa noto-fonts-cjk pipewire pipewire-alsa pipewire-jack wireplumber pipewire-pulse pipewire-v4l2 plasma-meta plasma-nm print-manager spectacle steam-jupiter-stable tar ufw vlc vulkan-intel vulkan-radeon wget zsh xbindkeys steam-im-modules ttf-twemoji-default ttf-hack ttf-dejavu pkgconf pavucontrol partitionmanager gamemode lib32-gamemode bluez-plugins bluez-utils xf86-video-amdgpu python-evdev dmidecode python-crcmod python-click python-progressbar python-hid jq alsa-utils parted e2fsprogs udisks2 kdialog gcc-libs glibc libcap.so libdisplay-info.so libdrm libliftoff.so libpipewire-0.3.so libvulkan.so libwlroots.so libx11 libxcb libxcomposite libxdamage libxext libxfixes libxkbcommon.so libxmu libxrender libxres libxtst libxxf86vm openvr sdl2 vulkan-icd-loader vulkan-mesa-layers lib32-vulkan-mesa-layers wayland xorg-server-xwayland"
export OS_RELEASE="NAME=\"SteamOS\"\nPRETTY_NAME="SteamOS"\nVERSION_CODENAME=holo\nID=steamos\nID_LIKE=arch\nANSI_COLOR=\"1;35\"\nHOME_URL=\"https://www.steampowered.com/\"\nDOCUMENTATION_URL=\"https://github.com/holoiso-staging/\"\nSUPPORT_URL=\"https://github.com/holoiso-staging/faq\"\nBUG_REPORT_URL=\"https://github.com/holoiso-staging/issuetracker\"\nLOGO=steamos\nVERSION_ID=\"${SNAPSHOTVERSION}\"\nVARIANT_ID=\"$(echo ${OS_CODENAME} | tr '[:upper:]' '[:lower:]')\"\nBUILD_ID=\"${RELEASETAG}\""
export POSTREMOVE_PACKAGES="a52dec vlc vulkan-mesa-layers lib32-vulkan-mesa-layers libliftoff libva-utils cups print-manager wlroots ffmpeg4.4 libmatroska bluez-plugins go kdegraphics-mobipocket kdegraphics-thumbnailers openvr jsoncpp python-annotated-types python-autocommand python-build python-fastjsonschema python-inflect python-installer python-jaraco.context python-jaraco.functools python-jaraco.text python-more-itertools python-ordered-set python-packaging python-platformdirs python-pydantic python-pydantic-core python-pyproject-hooks python-setuptools python-tomli python-trove-classifiers python-validate-pyproject python-wheel"
export HOLOISO_RELEASE="IMAGE_ID=\"${FLAVOR_BUILDVER}\"\nOS_TAG=${RELEASETAG}\nRELEASETYPE=$(echo ${OS_CODENAME} | tr '[:upper:]' '[:lower:]')\nISINTERNAL=no"
export UPDATE_METADATA="IMAGEFILE=\"${IMAGEFILE}\"\nSTAGING_OS_TAG=${RELEASETAG}\nSTAGING_RELEASETYPE=$(echo ${OS_CODENAME} | tr '[:upper:]' '[:lower:]')\nSTAGING_ISINTERNAL=no"
export PACMAN_ONLOAD="[Unit]\nDescription=${DISTRO_NAME} onload - /var/lib/pacman\n\n[Mount]\nWhat=/${OS_FS_PREFIX}_root/rootfs/${FLAVOR_FINAL_DISTRIB_IMAGE}/var/lib/pacman\nWhere=/var/lib/pacman\nType=none\nOptions=bind\n\n[Install]\nWantedBy=steamos-offload.target"
export MKNEWDIR="/nix"
export FSTAB="\nLABEL=${OS_FS_PREFIX}_root /          btrfs subvol=rootfs/${FLAVOR_BUILDVER},compress-force=zstd:1,discard,noatime,nodiratime 0 0\nLABEL=${OS_FS_PREFIX}_root /${OS_FS_PREFIX}_root btrfs rw,compress-force=zstd:1,discard,noatime,nodiratime,nodatacow 0 0\nLABEL=${OS_FS_PREFIX}_var /var       ext4 rw,relatime 0 0\nLABEL=${OS_FS_PREFIX}_home /home      ext4 rw,relatime 0 0\n"
export IMAGE_HOSTNAME="holoiso"
export POSTCOPY_BIN_EXECUTION="setuphandycon add_additional_pkgs"
