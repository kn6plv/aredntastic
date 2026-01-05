#! /bin/sh

VERSION=0.0.1

ROOT=/tmp/raven-build-$$
SRC=../..

rm -rf $ROOT/

mkdir -p $ROOT/control \
    $ROOT/data/www/cgi-bin/apps/raven \
    $ROOT/data/www/apps/raven \
    $ROOT/tmp/apps/raven \
    $ROOT/data/usr/local/raven/platform/aredn $ROOT/data/usr/local/raven/crypto \
    $ROOT/data/etc/init.d

cat > $ROOT/debian-binary <<__EOF__
2.0
__EOF__
cat > $ROOT/control/control <<__EOF__
Package: raven
Version: ${VERSION}
Depends: ucode
Provides:
Source: package/raven
Section: net
Priority: optional
Maintainer: Tim Wilkinson (KN6PLV)
Architecture: all
Description: Mesh communications
__EOF__
cat > $ROOT/control/postinst <<__EOF__
#!/bin/sh
/etc/init.d/raven enable
/etc/init.d/raven start
exit 0
__EOF__
cat > $ROOT/control/prerm <<__EOF__
#!/bin/sh
/etc/init.d/raven stop
/etc/init.d/raven disable
exit 0
__EOF__
chmod 755 $ROOT/control/postinst $ROOT/control/prerm

cp $SRC/*.uc $ROOT/data/usr/local/raven/
cp $SRC/crypto/*.uc $ROOT/data/usr/local/raven/crypto/
cp $SRC/platform/aredn/*.uc $ROOT/data/usr/local/raven/platform/aredn/
cp $SRC/

cp $SRC/ui/index.html $SRC/ui/ui.js $SRC/ui/ui.css $SRC/ui/raven.svg $ROOT/data/www/apps/raven/
cp $SRC/platform/aredn/admin.sh $ROOT/data/www/cgi-bin/raven/admin

cp $SRC/platform/aredn/raven.init $ROOT/data/etc/init.d/

(cd $ROOT/control ; tar cfz ../control.tar.gz)
(cd $ROOT/data ; tar cfz ../data.tar.gz)
(cd $ROOT ; tar cfz raven_${VESION}_all.ipk control.tar.gz data.tar.gz debian-binary)

mv $ROOT/raven_${VESION}_all.ipk .
rm -rf $ROOT/
