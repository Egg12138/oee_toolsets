# GATEWAY=192.168.122.1/24
# ifconfig br_qemu $GATEWAY
# ifconfig br_qemu up
# ipv4 forward is enabled

iptables -A FORWARD -i br_qemu -o wlx502b73c00260 -j ACCEPT
iptables -A FORWARD -o br_qemu -i wlx502b73c00260 -j ACCEPT
iptables -t nat -A POSTROUTING -s 192.168.122.0/24 -j MASQUERADE


echo "NAT forward is set!"