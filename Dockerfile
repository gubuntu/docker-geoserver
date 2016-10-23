FROM tomcat:8.5
MAINTAINER Tim Sutton<tim@kartoza.com>

RUN  dpkg-divert --local --rename --add /sbin/initctl

# Use local cached debs from host (saves your bandwidth!)
# Change ip below to that of your apt-cacher-ng host
# Or comment this line out if you do not wish to use caching
ADD 71-apt-cacher-ng /etc/apt/apt.conf.d/71-apt-cacher-ng

#RUN apt-get -y update

#-------------Application Specific Stuff ----------------------------------------------------

ENV GS_VERSION 2.9.2
ENV GEOSERVER_DATA_DIR /opt/geoserver/data_dir
ENV GEOSERVER_OPTS "-Djava.awt.headless=true -server -Xms2G -Xmx4G -Xrs -XX:PerfDataSamplingInterval=500 -Dorg.geotools.referencing.forceXY=true -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParallelGC -XX:NewRatio=2 -XX:+CMSClassUnloadingEnabled"
#-XX:+UseConcMarkSweepGC use this rather than parallel GC?  
ENV JAVA_OPTS "$JAVA_OPTS $GEOSERVER_OPTS"
ENV GDAL_DATA /usr/local/gdal_data
ENV LD_LIBRARY_PATH /usr/local/gdal_native_libs
ENV GEOSERVER_LOG_LOCATION /opt/geoserver/data_dir/logs/geoserver.log

RUN mkdir -p $GEOSERVER_DATA_DIR

# Unset Java related ENVs since they may change with Oracle JDK
ENV JAVA_VERSION=
ENV JAVA_DEBIAN_VERSION=

# Set JAVA_HOME to /usr/lib/jvm/default-java and link it to OpenJDK installation
RUN ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/default-java
ENV JAVA_HOME /usr/lib/jvm/default-java

ADD resources /tmp/resources

#Install Oracle JRE
RUN if ls /tmp/resources/*jre-*-linux-x64.tar.gz > /dev/null 2>&1; then \
      rm -f /usr/lib/jvm/default-java; \
      mkdir /usr/lib/jvm/default-java;  \
      tar zxvf /tmp/resources/*jre-*-linux-x64.tar.gz --strip-components=1 -C /usr/lib/jvm/default-java && \
      apt-get autoremove --purge -y openjdk-8-jre-headless; \
       if [ -f /tmp/resources/jce_policy.zip ]; then \
         unzip -j /tmp/resources/jce_policy.zip -d $JAVA_HOME/jre/lib/security/; \
       fi; \
    fi;
RUN ls -l $JAVA_HOME/jre/lib/security

#Add JAI and ImageIO for great speedy speed.
WORKDIR /tmp/resources
RUN if [ ! -f jai-1_1_3-lib-linux-amd64.tar.gz ]; then \
    wget http://download.java.net/media/jai/builds/release/1_1_3/jai-1_1_3-lib-linux-amd64.tar.gz; \
    fi; \
    if [ ! -f jai_imageio-1_1-lib-linux-amd64.tar.gz ]; then \
    wget http://download.java.net/media/jai-imageio/builds/release/1.1/jai_imageio-1_1-lib-linux-amd64.tar.gz; \
    fi; \
    gunzip -c jai-1_1_3-lib-linux-amd64.tar.gz | tar xf - && \
    gunzip -c jai_imageio-1_1-lib-linux-amd64.tar.gz | tar xf - && \
    mv jai-1_1_3/lib/*.jar $JAVA_HOME/jre/lib/ext/ && \
    mv jai-1_1_3/lib/*.so $JAVA_HOME/jre/lib/amd64/ && \
    mv jai_imageio-1_1/lib/*.jar $JAVA_HOME/jre/lib/ext/ && \
    mv jai_imageio-1_1/lib/*.so $JAVA_HOME/jre/lib/amd64/
WORKDIR $CATALINA_HOME

# A little logic that will fetch the geoserver war zip file if it
# is not available locally in the resources dir
RUN if [ ! -f /tmp/resources/geoserver.zip ]; then \
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_VERSION}/geoserver-${GS_VERSION}-war.zip \
      -O /tmp/resources/geoserver.zip; \
    fi; \
    unzip /tmp/resources/geoserver.zip -d /tmp/geoserver \
    && unzip /tmp/geoserver/geoserver.war -d $CATALINA_HOME/webapps/geoserver \
    && rm -rf $CATALINA_HOME/webapps/geoserver/data \
    && rm -f $CATALINA_HOME/webapps/geoserver/data/WEB-INF/lib/jai_core-*jar $CATALINA_HOME/webapps/geoserver/data/WEB-INF/lib/jai_imageio-*.jar $CATALINA_HOME/webapps/geoserver/data/WEB-INF/lib/jai_codec-*.jar \
    && rm -rf /tmp/geoserver

# Install any plugin zip files in resources/plugins
RUN if ls /tmp/resources/plugins/*.zip > /dev/null 2>&1; then \
      for p in /tmp/resources/plugins/*.zip; do \
        unzip $p -d /tmp/gs_plugin \
        && mv /tmp/gs_plugin/*.jar $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/ \
        && rm -rf /tmp/gs_plugin; \
      done; \
    fi; \
    if ls /tmp/resources/plugins/*gdal*.tar.gz > /dev/null 2>&1; then \
    mkdir /usr/local/gdal_data && mkdir /usr/local/gdal_native_libs; \
    unzip /tmp/resources/plugins/gdal/gdal-data.zip -d /usr/local/gdal_data && \
    tar xzf /tmp/resources/plugins/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz -C /usr/local/gdal_native_libs; \
    fi;
#TODO
#install http://docs.geoserver.org/2.9.2/user/extensions/libjpeg-turbo/index.html#community-libjpeg-turbo
#install Apache Tomcat Native library

# Overlay files and directories in resources/overlays if they exist
RUN rm -f /tmp/resources/overlays/README.txt && \
    if ls /tmp/resources/overlays/* > /dev/null 2>&1; then \
      cp -rf /tmp/resources/overlays/* /; \
    fi;

# Optionally remove Tomcat manager, docs, and examples
#ARG TOMCAT_EXTRAS=true #moved to docker-compose.yml
RUN if [ "$TOMCAT_EXTRAS" = false ]; then \
    rm -rf $CATALINA_HOME/webapps/ROOT && \
    rm -rf $CATALINA_HOME/webapps/docs && \
    rm -rf $CATALINA_HOME/webapps/examples && \
    rm -rf $CATALINA_HOME/webapps/host-manager && \
    rm -rf $CATALINA_HOME/webapps/manager; \
  fi;

# Delete resources after installation
RUN rm -rf /tmp/resources
