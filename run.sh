DIR=.
QEMU=qemu-system-aarch64
SELECTED=$1
AARCH64_GCC_x64=/usr/bin/oeesdk/sysroots/x86_64-openeulersdk-linux/usr/bin/aarch64-openeuler-linux-gcc
MACHINE=virt-4.0,gic-version=3
MEM=1G
CPU=cortex-a57
IMG=$DIR/zImage
FS=./$DIR/$SELECTED
APP=$FS
if [ "$1" != "gui" ]; then
	GUI="-nographic"
fi

# ============ Networking =============
# In most cases, if you don't have any specific networking requirements 
# other than to be able to access to a web page from your guest, user networking (slirp) is a good choice. 
# However, if you are looking to run any kind of 
# network service or have your guest participate in a network in any meaningful way, tap is usually the best choice. "
# getway IP : 10.0.2.2 (ssh from guest to the host), DNS : 10.0.2.3
# -netdev user,id=mynet0,net=<IP specified, not default: 10.0.2.0/24>/24, dhcpstart=X.Y.Z.D
# options of NET_BACKEND="TYPE,id=..."
# -netdev tap,id=mynet0
# -netdev socket,id=mynet0,listen=:1234
# -netdev socket,id=mynet0,connect=:1234
# -netdev vde,......
ENABLE_ICMP="off" 
# arguments for option -object:
# 	filter-dump: capture network traffic 
#		filter-dump-output_file=dump.dat
# 	filter-dump-id=f1
#		filter-dump netdev=u1

### ====== enable ping for slirp backend  =======

# Enabling ping in the guest, on Linux hosts
# 1. get group id of the user that will run QEMUI with slirp, $(whoami)
# 2. `/etc/systctl.conf`
if [ "$ENABLE_ICMP" = "on" ] && [ "$NET_BACKEND" = "slirp" ]; then
	echo "trying to enable ping in the guest"
	if ! getent group qemu_ping > /dev/null; then
		echo "group qemu_ping does not exist, creating..."
		sudo groupadd qemu_ping
		echo "adding $(whoami) to group qemu_ping"
		sudo usermod --append --groups qemu_ping $(whoami)
	fi 
fi

### ====== SSH access to the guest ======
### $ ssh localhost -p 
### SSH_GUEST_PORT=22
### SSH_LOCAL_PORT=5555


# =================== Share the fs =======================
# QEMU's qpfska, why this name: plan 9 lightweight file system
MNT_9P=virtio-9p-device
MNT_FSDRIVER=local # local, security, proxy
MNT_TAG=host
MNT_ID=myfs
MNT_PATH=/home/egg/projects/oee/master/build/build_arm64/output/qemusys/shared_buf
MNT_SEC_MOD=passthrough # mapped-xattr | mapped-file | passthrough

MNT_DEVICE="-device $MNT_9P,fsdev=$MNT_ID,mount_tag=$MNT_TAG"
MNT_FSDEV="-fsdev $MNT_FSDRIVER,id=$MNT_ID,security_model=$MNT_SEC_MOD,path=$MNT_PATH"
MNT_OPTS=" $MNT_DEVICE $MNT_FSDEV"

# ================= Run ======================

NET0_MON="filter-dump,id=f1,netdev=bridge0,file=netdump.dat"

sh "$(pwd)/nat_forawrd.sh"

OPTS="-M $MACHINE -m $MEM \
	-cpu $CPU $GUI \
	-kernel $IMG \
	-initrd $APP \
	-netdev bridge,br=br_qemu,id=bridge0\
	-device virtio-net-pci,netdev=bridge0\
	-object $NET0_MON\
	$MNT_OPTS
	"

	# -netdev tap,id=tap0,script=/etc/qemu/qemu-ifup"
	# -device virtio-net-device,netdev=tap0 \
	# -nic tap,id=net0,ifname=tap0,script=no,downscript=no"

	
	# $NET_OPTS \

	# -device e1000,netdev=net0\
	# -netdev user,id=net0,hostfwd=tcp:::5555-:22

# $QEMU $OPTS

$QEMU $OPTS

