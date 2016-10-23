# Download geoserver extensions and other resources
pushd resources
#Java
#Webupd8
#wget -c https://launchpad.net/~webupd8team/+archive/ubuntu/java/+files/oracle-java8-installer_8u101+8u101arm-1~webupd8~2.tar.xz
#Oracle
#wget -c http://download.oracle.com/otn-pub/java/jdk/8u112-b15/jdk-8u112-linux-x64.tar.gz
wget -c --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u112-b15/server-jre-8u112-linux-x64.tar.gz
#Policy
wget -c --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip

#JAI
wget -c http://download.java.net/media/jai/builds/release/1_1_3/jai-1_1_3-lib-linux-amd64.tar.gz

#JAI Image i/o
wget -c  http://download.java.net/media/jai-imageio/builds/release/1.1/jai_imageio-1_1-lib-linux-amd64.tar.gz

#Geoserver
VERSION=2.9.2

wget -c http://sourceforge.net/projects/geoserver/files/GeoServer/$VERSION/geoserver-$VERSION-war.zip -O geoserver.zip
pushd plugins
#Extensions
#Control flow
wget -c https://sourceforge.net/projects/geoserver/files/GeoServer/$VERSION/extensions/geoserver-$VERSION-control-flow-plugin.zip/download -O geoserver-$VERSION-control-flow-plugin.zip
#Image pyramid
wget -c https://sourceforge.net/projects/geoserver/files/GeoServer/$VERSION/extensions/geoserver-$VERSION-pyramid-plugin.zip/download -O geoserver-$VERSION-pyramid-plugin.zip
#GDAL
wget -c https://sourceforge.net/projects/geoserver/files/GeoServer/$VERSION/extensions/geoserver-$VERSION-gdal-plugin.zip/download -O geoserver-$VERSION-gdal-plugin.zip
mkdir gdal
pushd gdal
wget -c http://demo.geo-solutions.it/share/github/imageio-ext/releases/1.1.X/1.1.15/native/gdal/gdal-data.zip
popd
wget -c http://demo.geo-solutions.it/share/github/imageio-ext/releases/1.1.X/1.1.15/native/gdal/linux/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz

popd
popd
