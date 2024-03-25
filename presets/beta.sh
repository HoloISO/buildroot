#!/bin/bash
rm -rf /tmp/builder-releasetag
rm -rf /tmp/build_temp_ver
export DISTRO_NAME="HoloISO"
export OS_CODENAME="Beta"
export OS_FS_PREFIX="holo"
export RELEASETAG=snapshot$(date +%Y%m%d.%H%M.%S)
echo -e ${RELEASETAG} > /tmp/builder-releasetag
echo -e "$(echo ${DISTRO_NAME} | tr '[:upper:]' '[:lower:]')_$(echo ${OS_CODENAME} | tr '[:upper:]' '[:lower:]')_${RELEASETAG}" > /tmp/build_temp_ver
export FLAVOR_BUILDVER=$(cat /tmp/build_temp_ver)
export IMAGEFILE="${FLAVOR_BUILDVER}"
export FLAVOR_CHROOT_SCRIPTS="sddm bluetooth sshd systemd-timesyncd NetworkManager"
export FLAVOR_PLYMOUTH_THEME="steamos"
export FLAVOR_FINAL_DISTRIB_IMAGE=$FLAVOR_BUILDVER
export KERNELCHOICE="linux-lljy"
export BASE_BOOTSTRAP_PKGS="base base-devel linux-firmware amd-ucode intel-ucode sddm-wayland dkms jq btrfs-progs core-main/grub efibootmgr openssh"
export UI_BOOTSTRAP="python-build nano vim fuse vi flatpak plymouth python-installer python-setuptools python-wheel arch-install-scripts archlinux-keyring holo-keyring ark cups curl dolphin ffmpegthumbs gamescope git go gwenview hunspell hunspell-en_us kdegraphics-thumbnailers konsole kwrite lib32-pipewire lib32-pipewire-jack lib32-pipewire-v4l2 libva lib32-libva libva-utils libva-mesa-driver libva-intel-driver lib32-libva-mesa-driver lib32-libva-intel-driver lib32-vulkan-radeon lib32-vulkan-intel mangohud mesa lib32-mesa noto-fonts-cjk pipewire pipewire-alsa pipewire-jack wireplumber pipewire-pulse pipewire-v4l2 plasma-meta plasma-nm print-manager spectacle steam-jupiter-stable tar ufw vlc vulkan-intel vulkan-radeon wget zsh xbindkeys steam-im-modules systemd-swap ttf-twemoji-default ttf-hack ttf-dejavu pkgconf pavucontrol partitionmanager gamemode lib32-gamemode bluez-plugins bluez-utils xf86-video-amdgpu xf86-video-intel python-evdev dmidecode python-crcmod python-click python-progressbar python-hid jq alsa-utils parted e2fsprogs udisks2 kdialog gcc-libs glibc libcap.so libdisplay-info.so libdrm libliftoff.so libpipewire-0.3.so libvulkan.so libwlroots.so libx11 libxcb libxcomposite libxdamage libxext libxfixes libxkbcommon.so libxmu libxrender libxres libxtst libxxf86vm openvr sdl2 vulkan-icd-loader vulkan-mesa-layers lib32-vulkan-mesa-layers wayland xorg-server-xwayland"
export OS_RELEASE="NAME=\"SteamOS\"\nPRETTY_NAME="SteamOS"\nVERSION_CODENAME=holo\nID=steamos\nID_LIKE=arch\nANSI_COLOR=\"1;35\"\nHOME_URL=\"https://www.steampowered.com/\"\nDOCUMENTATION_URL=\"https://github.com/holoiso-staging/\"\nSUPPORT_URL=\"https://github.com/holoiso-staging/faq\"\nBUG_REPORT_URL=\"https://github.com/holoiso-staging/issuetracker\"\nLOGO=steamos\nVERSION_ID=\"${SNAPSHOTVERSION}\"\nVARIANT_ID=\"$(echo ${OS_CODENAME} | tr '[:upper:]' '[:lower:]')\"\nBUILD_ID=\"${RELEASETAG}\""
export HOLOISO_RELEASE="IMAGE_ID=\"${FLAVOR_BUILDVER}\"\nOS_TAG=${RELEASETAG}\nRELEASETYPE=$(echo ${OS_CODENAME} | tr '[:upper:]' '[:lower:]')\nISINTERNAL=no"
export UPDATE_METADATA="IMAGEFILE=\"${IMAGEFILE}\"\nSTAGING_OS_TAG=${RELEASETAG}\nSTAGING_RELEASETYPE=$(echo ${OS_CODENAME} | tr '[:upper:]' '[:lower:]')\nSTAGING_ISINTERNAL=no"
