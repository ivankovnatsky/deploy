#!/usr/bin/env bash

# systemd: mask
sudo systemctl mask systemd-networkd-wait-online.service

# systemd: disable GUI on boot
sudo systemctl set-default multi-user.target

# systemd: disable
sudo systemctl disable \
    accounts-daemon.service \
    snapd.autoimport.service \
    snapd.core-fixup.service \
    snapd.seeded.service \
    snapd.service \
    snapd.snap-repair.timer \
    snapd.socket \
    docker.service \
    lvm2-monitor.service \
    containerd.service \
    vpnagentd.service \
    systemd-networkd-wait-online.service \
    snapd.system-shutdown.service \
    apparmor.service \
    lvm2-lvmpolld.socket \
    atd \
    lxd.socket \
    lxd-containers.service \
    lxcfs.service
    lvm2-monitor.service \
    cron.service \
    gdm3.service

# generate cache
sudo apt-cache gencaches
sudo apt-file update

# user groups
sudo usermod --append "${USERNAME}" --groups=audio,tty,bluetooth,dialout,video,docker,lpadmin,lp

# add repos
sudo apt-add-repository multiverse

# edit apt sources
sudo vim /etc/apt/sources.list

# install
sudo apt install \
    alsa-base \
    alsa-utils \
    apt-file \
    bluetooth \
    build-essential \
    checkinstall \
    chromium-browser \
    command-not-found \
    ctags \
    curl \
    dnsutils \
    firefox \
    gimp \
    git \
    htop \
    imagemagick \
    inetutils-traceroute \
    jq \
    libasound2-dev \
    libfreetype6-dev \
    libgtk2.0-0 \
    libx11-dev \
    libxcb-util-dev \
    libxft-dev \
    libxinerama-dev \
    lm-sensors \
    mpv \
    neovim \
    nethogs \
    nmap \
    psmisc \
    pulseaudio \
    pulseaudio-bluetooth \
    pulseaudio-utils \
    python \
    python-pip \
    python-setuptools \
    ranger \
    shellcheck \
    suckless-tools \
    sysstat \
    tcpdump \
    tmux \
    traceroute \
    transmission-daemon \
    tree \
    ttf-ancient-fonts \
    ttf-ubuntu-font-family \
    unzip \
    vim-gtk3 \
    wget \
    whois \
    wireless-tools \
    wpasupplicant \
    x11-xserver-utils \
    xautolock \
    xinit \
    xinput \
    xsel \
    xserver-xorg \
    xserver-xorg-video-intel \
    youtube-dl \
    zsh

# for some fancy configuration install full desktop
sudo apt install ubuntu-desktop

# work specific
sudo apt install \
    uwsgi \
    inetutils-traceroute \
    traceroute

# golang
sudo add-apt-repository ppa:gophers/archive
sudo apt-get update
sudo apt-get install golang-1.10-go

mkdir -p "${HOME}/go"
mkdir -p "${HOME}/go/bin"
mkdir -p "${HOME}/go/src"

# docker
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

sudo apt-get update
sudo apt-get install docker-ce

# aws-iam-authenticator
sudo curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
sudo chmod +x /usr/local/bin/aws-iam-authenticator

# kubectl
cd /tmp || exit
# shellcheck disable=SC2046
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version

# install krew
(
  set -x; cd "$(mktemp -d)" &&
  curl -fsSLO "https://storage.googleapis.com/krew/v0.2.1/krew.{tar.gz,yaml}" &&
  tar zxvf krew.tar.gz &&
  ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install \
    --manifest=krew.yaml --archive=krew.tar.gz
)

# kubectx
# kubens
sudo wget -c \
    https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx \
    https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens \
    -P /usr/local/bin

sudo chmod +x /usr/local/bin/{kubectx,kubens}

mkdir -p ~/.oh-my-zsh/completions/
chmod -R 755 ~/.oh-my-zsh/completions
wget -c https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.zsh -O ~/.oh-my-zsh/completions/_kubectx.zsh
wget -c https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.zsh -O ~/.oh-my-zsh/completions/_kubens.zsh
chmod +x ~/.oh-my-zsh/completions/_kube*.zsh

# kops
# shellcheck disable=SC2046
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops

# helm
package_name=2.14.1
wget -c https://storage.googleapis.com/kubernetes-helm/helm-v${package_name}-linux-amd64.tar.gz -P /tmp
cd /tmp/ || exit
tar xfv helm-v${package_name}-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

# packer
package_name=packer
ver=1.3.2
platform=linux
platform=amd64
wget -c "https://releases.hashicorp.com/${package_name}/${ver}/${package_name}_${ver}_${platform}_${arch}.zip" -P /tmp
cd /tmp || exit
unzip "${package_name}_${ver}_${platform}_${arch}.zip"
sudo mv "${package_name}" /usr/local/bin/

# terraform
package_name=terraform
ver=0.12.4
arch=amd64
platform=linux
wget -c "https://releases.hashicorp.com/${package_name}/${ver}/${package_name}_${ver}_${platform}_${arch}.zip" -P /tmp
cd /tmp || exit
unzip "${package_name}_${ver}_${platform}_${arch}.zip"
sudo mv "${package_name}" /usr/local/bin/

# prometheus
prometheus_ver=2.3.2
prom_arch=darwin
wget -c https://github.com/prometheus/prometheus/releases/download/v${prometheus_ver}/prometheus-${prometheus_ver}.${prom_arch}-amd64.tar.gz -P /tmp
cd /tmp || exit
tar xf prometheus-${prometheus_ver}.${prom_arch}-amd64.tar.gz
cd prometheus-${prometheus_ver}.${prom_arch}-amd64 || exit
sudo mv promtool /usr/local/bin

# dive
dive_ver=0.7.2
dive_platform=linux
wget -c https://github.com/wagoodman/dive/releases/download/v${dive_ver}/dive_${dive_ver}_${dive_platform}_amd64.tar.gz -P /tmp
cd /tmp || exit
tar xf dive_${dive_ver}_${dive_platform}_amd64.tar.gz
cd dive_${dive_ver}_${dive_platform}_amd64 || exit
sudo mv dive /usr/local/bin

# hadolint
wget -c https://github.com/hadolint/hadolint/releases/download/v1.17.1/hadolint-Linux-x86_64 -P /tmp
sudo mv /tmp/hadolint-Linux-x86_64
sudo chmod +x /usr/local/bin/hadolint

# chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt-get update
sudo apt-get install google-chrome-stable

# code
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install code

# cisco anyconnect
chrome https://uci.service-now.com/kb_view.do?sysparm_article=KB0010201
cd ~/Downloads/ || exit
tar xfv anyconnect-linux64-4.6.02074-predeploy-k9.tar.gz
cd ~/Downloads/anyconnect-linux64-4.6.02074/vpn || exit
sudo ./vpn_install.sh

# nvidia
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update
sudo apt install nvidia-driver-415

# git
mkdir -p ~/Sources/GitHub
cd ~/Sources/GitHub || exit
git clone "git@github.com:${USERNAME}/dwm.git"
git clone "git@github.com/${USERNAME}/st.git"
git clone "git@github.com/${USERNAME}/dwmstatus.git"

# console-setup
sudo dpkg-reconfigure console-setup

# remove
sudo apt purge \
    nano \
    sound-theme-freedesktop \
    qpdf \
    eatmydata \
    gcr \
    printer-driver-gutenprint \
    cloud-init \
    colord \
    plymouth \
    libplymouth4 \
    mokutil \
    shim \
    shim-signed \
    phantomjs \
    vim \
    aufs-tools \
    modemmanager \
    run-one \
    xdg-user-dirs \
    xserver-xorg-input-wacom \
    xserver-xorg-video-all \
    xserver-xorg-video-amdgpu \
    xserver-xorg-video-ati \
    xserver-xorg-video-fbdev \
    xserver-xorg-video-intel \
    xserver-xorg-video-nouveau \
    xserver-xorg-video-qxl \
    xserver-xorg-video-radeon \
    xserver-xorg-video-vesa \
    xserver-xorg-video-vmware \
    iio-sensor-proxy \
    installation-report \
    intltool-debian \
    laptop-detect \
    krb5-locales \
    networkd-dispatcher \
    unattended-upgrades \
    secureboot-db \
    friendly-recovery \
    rsyslog \
    irqbalance \
    vim-nox

# lvm config
systemctl enable lvm2-lvmetad.service
systemctl enable lvm2-lvmetad.socket
systemctl start lvm2-lvmetad.service
systemctl start lvm2-lvmetad.socket

# cleaning up
sudo apt autoremove

# keyboard
item="2C:33:61:E2:CF:B0"
echo -e "remove ${item}\n" | bluetoothctl
echo -e "scan on\n" | bluetoothctl
sleep 10
echo -e "pair ${item}\nyes\nconnect ${item}\ntrust ${item}\n" | bluetoothctl

# mouse
item="F9:DA:D8:25:E3:B7"
echo -e "scan on\n" | bluetoothctl
sleep 10
echo -e "scan on\npair ${item}\nconnect ${item}\ntrust ${item}\n" | bluetoothctl

# airpods
item="7C:04:D0:98:E1:83"
echo -e "remove ${item}\n" | bluetoothctl
echo -e "scan on\n" | bluetoothctl
sleep 10
echo -e "pair ${item}\nconnect ${item}\ntrust ${item}\n" | bluetoothctl

# admin
/usr/bin/python2 -m pip install ansible j2cli

cat > ~/bin/gdm-stop.sh << EOF
#!/usr/bin/env bash

sudo systemctl stop gdm.service
sudo killall -9 gnome-session-binary
EOF
