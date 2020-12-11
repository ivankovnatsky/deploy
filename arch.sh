#!/usr/bin/env bash

# {{{ TODO
# * wifi hook after sleep/hibernate
# * shutdown/hibernate on low battery power
# * on lid close run slock
# }}}

# {{{ prepare installation
# check gist: arch.sh

tee /etc/wpa_supplicant/wpa_supplicant-wlan0.conf << EOF
network={
        ssid="{{ SSID }}"
        psk="{{ PASSWORD }}"
        scan_ssid=1
}
EOF

tee /etc/systemd/network/25-wireless.network << EOF
[Match]
Name=wlan0

[Network]
DHCP=ipv4
EOF

systemctl start wpa_supplicant@wlan0
systemctl start systemd-networkd

# install tools for convenience 
pacman -Sy git tmux
tmux

# now you can download this file

cfdisk /dev/sda
# set sda1 to "EFI System"
cryptsetup luksFormat /dev/sda2
lsblk
mkfs.vfat -F32 /dev/sda1
cryptsetup open /dev/sda2 luks
pvcreate /dev/mapper/luks
vgcreate laptop /dev/mapper/luks

lvcreate -L 8G laptop -n swap
lvcreate -l 100%FREE laptop -n root

mkfs.ext4 /dev/laptop/root
mkswap /dev/laptop/swap
mount /dev/laptop/root /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/laptop/swap

mv ~/dotfiles /mnt/dotfiles

pacstrap /mnt base base-devel zsh vim git efibootmgr dialog wpa_supplicant
genfstab -L /mnt >> /mnt/etc/fstab

# bootstrap 
arch-chroot /mnt

# install tools for convenience 
pacman -Sy git tmux
tmux

ln -s /usr/share/zoneinfo/{{ redacted }} /etc/localtime
hwclock --systohc
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen 
locale-gen 
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo laptop > /etc/hostname
hostnamectl 
passwd

tee /etc/mkinitcpio.conf << EOF
HOOKS=(base systemd autodetect modconf block keyboard sd-encrypt sd-lvm2 resume filesystems)
MODULES=(intel_agp i915)
EOF

pacman -S mkinitcpio linux linux-headers linux-firmware lvm2 intel-ucode iproute2 tmux bind-tools efitools sbsigntools
mkinitcpio -p linux
bootctl --path=/boot install
cryptsetup luksUUID /dev/sda2 >> /boot/loader/entries/arch.conf 

tee -a /boot/loader/entries/arch.conf << EOF
# UUID of /dev/sda2
title Arch
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options rw luks.name={{ UUID }}=luks root=/dev/laptop/root resume=/dev/laptop/swap mem_sleep_default=deep rng_core.default_quality=1000
EOF

vim /boot/loader/entries/arch.conf

tee -a /boot/loader/loader.conf << EOF
default arch
EOF

vim /boot/loader/loader.conf

# exiting chroot and rebooting
exit
reboot

# }}}

# {{{ booted into clean system

# configure wifi
tee /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf << EOF
network={
        ssid="{{ SSID }}"
        psk="{{ PASSWORD }}"
        scan_ssid=1
}
EOF

vim /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf

tee /etc/systemd/network/25-wireless.network << EOF
[Match]
Name=wlp3s0

[Network]
DHCP=ipv4
EOF

# enable and start
systemctl enable --now wpa_supplicant@wlp3s0
systemctl enable --now systemd-networkd
systemctl enable --now systemd-resolved
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
# }}}

# {{{ system configs
useradd -m -G wheel -s /bin/zsh {{ user }}

pacman-key --populate archlinux

git clone https://aur.archlinux.org/yay.git && cd yay/
makepkg -si

su - {{ user }}

yay -S \
    wget \
    noto-fonts \
    noto-fonts-extra \
    noto-fonts-cjk \
    noto-fonts-emoji \
    nerd-fonts-hack \
    ttf-symbola \
    xorg-xrandr \
    xorg-xinput \
    bitwarden-cli-bin \
    bitwarden-bin \
    openssh \
    xorg-server \
    xf86-video-intel \
    xorg-xinit \
    xorg-xbacklight \
    systemd-swap \
    util-linux \
    lshw \
    dmidecode \
    acpi \
    acpid \
    bat \
    slock \
    xorg-xprop \
    xorg-xdpyinfo \
    xorg-xset \
    xsel \
    jq \
    brightnessctl \
    xorg-xev \
    xorg-xsetroot \
    xfconf \
    tlp \
    gnome-themes-extra \
    bcwc-pcie-git \
    facetimehd-firmware \
    linux-headers \
    mpv \
    k9s \
    duf-bin \
    youtube-dl \
    ifuse \
    perl-image-exiftool \
    strace \
    iperf \
    imagemagick \
    arandr \
    ripgrep \
    tcpdump \
    signal-desktop \
    exa \
    dust-bin \
    dwm \
    st \
    surf \
    yay-bin \
    shellcheck-bin \
    powertop \
    lm_sensors \
    google-chrome \
    tfenv \
    tgenv \
    tflint-bin \
    openvpn-update-systemd-resolved \
    aws-cli \
    python-aws-mfa \
    python-pre-commit \
    neovim \
    neovim-symlinks \
    docker \
    kubectl \
    kubectx \
    kustomize \
    docker-compose \
    mysql-clients \
    postgresql \
    aws-iam-authenticator-bin

yay -R \
    yay \
    vim \
    ttf-liberation \
    vim-runtime

# clean not needed packages
yay -R $(pacman -Qtd|awk '{print $1}')

tee /etc/modprobe.d/hid_apple.conf << EOF
options hid_apple swap_opt_cmd=1 
EOF

mkinitcpio -p linux

tee /etc/X11/xorg.conf.d/50-mouse-acceleration.conf << EOF
Section "InputClass"
	Identifier "My Mouse"
	MatchIsPointer "yes"
	Option "AccelerationProfile" "-1"
	Option "AccelerationScheme" "none"
	Option "AccelSpeed" "-1"
EndSection
EOF

tee /etc/X11/xorg.conf.d/00-keyboard.conf << EOF
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "us,ua"
        Option "XkbOptions" "grp:caps_toggle"
EndSection
EOF

tee /etc/X11/xorg.conf.d/30-touchpad.conf << EOF
Section "InputClass"
        Identifier "devname"
        Driver "libinput"
        MatchIsTouchpad "on"
        Option "NaturalScrolling" "true"
EndSection
EOF

tee /etc/X11/xorg.conf.d/20-intel.conf << EOF
Section "Device"
        Identifier "Intel Graphics"
        Driver "intel"
        Option "TearFree" "true"
EndSection
EOF

tee /etc/X11/xorg.conf.d/10-monitor.conf << EOF
Section "Monitor"
  Identifier "eDP1"
  Option "RightOf" "DP1"
  Option "DPMS" "true"
EndSection

Section "Monitor"
  Identifier "DP1"
  Option "PreferredMode" "3840x2160
  Option "Position" "0 0"
  Option "LeftOf" "eDP1"
  Option "DPMS" "true"
EndSection
EOF

tee /etc/modprobe.d/50-sound.conf << EOF
options snd-hda-intel index=1,0
EOF

tee /etc/bluetooth/main.conf << EOF
[Policy]
AutoEnable=true
EOF

tee /etc/systemd/system/suspend@.service << EOF
[Unit]
Description=User suspend actions
Before=sleep.target,hibernate.target

[Service]
User=%I
Type=forking
Environment=DISPLAY=:0
ExecStart=/usr/bin/slock
ExecStartPost=/usr/bin/sleep 1

[Install]
WantedBy=sleep.target,hibernate.target
EOF

systemctl enable --now suspend@{{ user }}

tee /etc/systemd/system/root-resume.service << EOF
[Unit]
Description=Local system resume actions
After=sleep.target,hibernate.target

[Service]
Type=simple
ExecStartPre=/usr/bin/modprobe -r brcmfmac
ExecStart=/usr/bin/sleep 3
ExecStartPost=/usr/bin/modprobe brcmfmac

[Install]
WantedBy=sleep.target,hibernate.target
EOF

systemctl enable --now root-resume.service

systemctl enable --now bluetooth.service
systemctl enable --now tlp.service

tee /etc/systemd/timesyncd.conf << EOF
[Time]
NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org
EOF

systemctl enable --now systemd-timesyncd.service
systemctl enable --now docker.service

# don't wait for wifi
systemctl mask systemd-networkd-wait-online.service
# }}}

# {{{ userspace
groupadd -r autologin
groupadd -r nopasswdlogin
usermod -aG video,audio,docker,autologin,nopasswdlogin {{ user }}

tee -a /etc/openvpn/client/client.conf << EOF
script-security 2
setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
up /etc/openvpn/scripts/update-systemd-resolved
up-restart
down /etc/openvpn/scripts/update-systemd-resolved
down-pre
dhcp-option DOMAIN-ROUTE .
EOF

systemctl start openvpn-client@client.service

mkdir -p ~/Sources/GitHub
cd ~/Sources/GitHub

git clone git@github.com:{{ account }}/dwm.git && cd dwm
makepkg -si
cd src
ln -s ../config.h .
yay -R dwm
makepkg -sif --noconfirm && killall -9 dwm

git clone git@github.com:{{ account }}/st.git && cd st
makepkg -s
cp config.def.h config.h
cd src
ln -s ../config.h .
yay -R st
makepkg -sif --noconfirm

git clone git@github.com:{{ account }}/dwmstatus.git
cd dwmstatus
make
sudo mv dwmstatus /usr/local/bin/dwmstatus && /usr/local/bin/dwmstatus &!

xfconf-query -n -c xsettings -p /Net/ThemeName -s "Adwaita-dark" -t string

sudo wget https://github.com/flosell/iam-policy-json-to-terraform/releases/download/1.5.0/iam-policy-json-to-terraform_amd64 -P /tmp/
sudo mv /tmp/iam-policy-json-to-terraform_amd64 /usr/local/bin/iam-policy-json-to-terraform
sudo chmod +x /usr/local/bin/iam-policy-json-to-terraform
# }}}
