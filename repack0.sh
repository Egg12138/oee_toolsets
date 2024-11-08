FILES=unpacked
RNAME=$1
FORMAT=$2  # newc is default
if [ -f "$RNAME.cpio.gz" ]; then
	echo "$RNAME.cpio.gz exists."
	exit 1
fi


if [ -z "$RNAME" ]; then
	RNAME=myaarch64
fi

if [ -z "$FORMAT" ]; then
	FORMAT=newc
fi


cd $FILES
eza -l
# NOTICE: all files under $FILES will be included !
find ./* | cpio -H $FORMAT -o | gzip -9 -c > $RNAME.cpio.gz
# can we pass rootfs without gzip?
mv $RNAME.cpio.gz ../
# append: in case of multi-compressed file

