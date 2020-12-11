#!/usr/bin/env ash

opkg update
opkg install tmux bash shadow-su

cat > /etc/crontabs/root << EOF
30 22 * * * /sbin/wifi down
0 6 * * * /sbin/wifi up
EOF

cat > ~/.inputrc << EOF
# arrow up
"\e[A":history-search-backward
# arrow down
"\e[B":history-search-forward
EOF

cat >> /etc/passwd << EOF
$USER:x:1000:1000:$USER:/home/$USER:/bin/ash
EOF

passwd $USER

mkdir /home
mkdir /home/$USER
chown $USER /home/$USER
