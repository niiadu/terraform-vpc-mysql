#!/bin/bash
sudo apt update && sudo apt upgrade -y

# ss -tlpn| grep ssh
sudo -i
# systemctl edit ssh.socket
# vim /etc/systemd/system/ssh.socket.d/override.conf
mkdir -p /etc/systemd/system/ssh.socket.d

cat > /etc/systemd/system/ssh.socket.d/override.conf <<EOF
[Socket]
ListenStream=
ListenStream=2031
EOF

sudo systemctl daemon-reload
sudo systemctl restart ssh.socket