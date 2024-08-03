#!/bin/bash
sudo apt update && sudo apt upgrade -y

# sudo systemctl status ssh
# ss -tlpn| grep ssh
sudo -i
# systemctl edit ssh.socket
# vim /etc/systemd/system/ssh.socket.d/override.conf

cat > /etc/systemd/system/ssh.socket.d/override.conf <<EOF
 [Socket]
ListenStream=
ListenStream=2031
EOF

systemctl restart ssh.socket