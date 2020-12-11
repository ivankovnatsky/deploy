#!/usr/bin/env bash

# {{{ tpm2
dd if=/dev/random of=luks.key iflag=fullblock count=1 bs=32
cryptsetup luksAddKey /dev/sda2 /root/luks.key --verbose
chmod 000 luks.key 

tpm2_pcrread 

# Script for readding the key if PCR is changed
#!/bin/bash
# Clear old key
tpm2_evictcontrol -c 0x81000000

tpm2_createpolicy --policy-pcr -l sha1:0,1,2,3,4,5,6,7 -L policy.digest
tpm2_createprimary -c primary.ctx
tpm2_create -C primary.ctx -u obj.pub -r obj.priv -L policy.digest -a "noda|adminwithpolicy|fixedparent|fixedtpm" -i luks.key 
tpm2_flushcontext -t
tpm2_load -C primary.ctx -u obj.pub -r obj.priv -c load.ctx
tpm2_evictcontrol -c load.ctx
tpm2_flushcontext -t
tpm2_getcap handles-persistent
rm load.ctx obj.p* policy.digest primary.ctx

cat > /etc/initcpio/install/sd-tpm2 << EOF
#!/bin/bash
build() {
    local mod
    add_module "tpm_crb"
    add_module "tpm_tis"
    add_binary "tpm2_unseal"
    add_binary "/usr/lib/libtss2-tcti-device.so"
    add_systemd_unit "cryptsetup-pre.target"
    add_systemd_unit "tpm2-unseal.service"
    add_symlink "/usr/lib/systemd/system/sysinit.target.wants/cryptsetup-pre.service" "../cryptsetup-pre.target"
    add_symlink "/usr/lib/systemd/system/sysinit.target.wants/tpm2-unseal.service" "../tpm2-unseal.service"
}
help() {
    cat <<HELPEOF
This hook allows for reading the encryption key from TPM.
HELPEOF
}
EOF

cat > /usr/lib/systemd/system/tpm2-unseal.service << EOF
[Unit]
Description=Get key from TPM
Before=cryptsetup-pre.target
DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/usr/bin/modprobe -a -q tpm_crb tpm_tis
ExecStart=/usr/bin/tpm2_unseal -c 0x81000000 -p pcr:sha1:0,1,2,3,4,5,6,7 -o /luks
EOF

vim /etc/mkinitcpio.conf
# with tpm2
# HOOKS=(base systemd autodetect sd-tpm2 modconf block keyboard sd-encrypt sd-lvm2 resume filesystems)
# with tpm2
pacman -S mkinitcpio linux linux-firmware lvm2 intel-ucode broadcom-wl-dkms iproute2 tpm2-tools tmux bind-tools efitools sbsigntools
# }}}
# {{{ secure boot
uuidgen --random > GUID.txt
openssl req -newkey rsa:4096 -nodes -keyout PK.key -new -x509 -sha256 -days 3650 -subj "/CN=my Platform Key/" -out PK.crt
openssl x509 -outform DER -in PK.crt -out PK.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" PK.crt PK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt PK PK.esl PK.auth
sign-efi-sig-list -g "$(< GUID.txt)" -c PK.crt -k PK.key PK /dev/null rm_PK.auth
openssl req -newkey rsa:4096 -nodes -keyout KEK.key -new -x509 -sha256 -days 3650 -subj "/CN=my Key Exchange Key/" -out KEK.crt
openssl x509 -outform DER -in KEK.crt -out KEK.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" KEK.crt KEK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt KEK KEK.esl KEK.auth

openssl req -newkey rsa:4096 -nodes -keyout db.key -new -x509 -sha256 -days 3650 -subj "/CN=my Signature Database key/" -out db.crt
openssl x509 -outform DER -in db.crt -out db.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" db.crt db.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k KEK.key -c KEK.crt db db.esl db.auth

sbsign --key db.key --cert db.crt --output /boot/vmlinuz-linux /boot/vmlinuz-linux
sbsign --key db.key --cert db.crt --output /boot/EFI/boot/bootx64.efi /boot/EFI/boot/bootx64.efi

systemctl reboot --firmware
# }}}
