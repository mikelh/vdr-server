FROM ubuntu:18.04 AS vdr-server
MAINTAINER Connie                     

ENV DEBIAN_FRONTEND noninteractive
ENV _clean="rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"
ENV _apt_clean="eval apt-get clean && $_clean"

# fix locale.
#RUN apt-get update && apt-get install -y locales tzdata && rm -rf /var/lib/apt/lists/* \
#    && localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-

# Set your local timezone
RUN echo "Europe/Berlin" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

RUN locale-gen de_DE.UTF-8
ENV LANG de_DE.UTF-8  
ENV LANGUAGE de_DE:de  
ENV LC_ALL de_DE.UTF-8


RUN apt-get update && apt-get upgrade -y

# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.15.0.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar zxf /tmp/s6-overlay-amd64.tar.gz -C / && $_clean

######################################

ARG VDR_VERSION=2.4.0

USER root


RUN apt-get update -qq && \
	apt-get install -qy \
	wget \
	rsyslog \
	build-essential \
	libfreetype6-dev \
	libfontconfig-dev \
	libgettextpo-dev \
	libjpeg-dev \
	libcap-dev \
	libpugixml-dev \
	libcurl4-openssl-dev \
	libcxxtools-dev \
	git \
	bzip2 \
	libncurses-dev \
	libncursesw5-dev \
	libmagick++-dev \
	libtntnet.de \
	libssl.dev \
	gettext \
	bash \
	uuid \
	groff \
	nano && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /build
WORKDIR /build

RUN echo "building VDR container version '${VDR_VERSION}'"
###
## plugin list:
#.	vdr-plugin-epgsearch \
# #	vdr-plugin-femon \
#.	vdr-plugin-satip \
#.	vdr-plugin-live \
#.	vdr-plugin-restfulapi \
#.	vdr-plugin-dvbapi \
#.	vdr-plugin-vnsiserver \
# #	vdr-plugin-xvdr \
#.	vdr-plugin-wirbelscan \
# #	vdr-plugin-lcdproc \
# #	vdr-plugin-remote \
# #	vdr-plugin-vdrmanager \
# #	vdr-plugin-remotetimers \
# #	vdr-plugin-svdrpservice \
#.	vdr-plugin-streamdev-server \
# #	vdr-plugin-svdrposd \
###

RUN wget ftp://ftp.tvdr.de/vdr/vdr-${VDR_VERSION}.tar.bz2 
RUN tar -jxf vdr-${VDR_VERSION}.tar.bz2
RUN git clone https://github.com/manio/vdr-plugin-dvbapi.git vdr-${VDR_VERSION}/PLUGINS/src/dvbapi
RUN git clone https://github.com/CvH/vdr-plugin-wirbelscan.git vdr-${VDR_VERSION}/PLUGINS/src/wirbelscan
RUN git clone https://github.com/vdr-projects/vdr-plugin-epgsearch.git vdr-${VDR_VERSION}/PLUGINS/src/epgsearch
RUN git clone https://github.com/rofafor/vdr-plugin-satip vdr-${VDR_VERSION}/PLUGINS/src/satip
RUN git clone https://github.com/vdr-projects/vdr-plugin-streamdev.git vdr-${VDR_VERSION}/PLUGINS/src/streamdev
RUN git clone https://github.com/yavdr/vdr-plugin-restfulapi vdr-${VDR_VERSION}/PLUGINS/src/restfulapi
RUN git clone https://github.com/vdr-projects/vdr-plugin-live vdr-${VDR_VERSION}/PLUGINS/src/live
RUN git clone https://github.com/FernetMenta/vdr-plugin-vnsiserver vdr-${VDR_VERSION}/PLUGINS/src/vnsiserver

WORKDIR vdr-${VDR_VERSION}

### apply patches if necessary
COPY templates/Make.* /build/vdr-${VDR_VERSION}/

#RUN mkdir -p /build/patches
#COPY patches/ /build/patches/
#
#RUN for patch in `ls /build/patches/vdr`; do \
#        echo ${patch} ; \
#        patch -p1 < /build/patches/vdr/${patch} ; \
#    done
#
#WORKDIR PLUGINS/src/epgsearch
##RUN patch -p1 < /build/patches/epgsearch/install-conf.patch
#
#WORKDIR ../../..
#

#RUN locale-gen de_DE.UTF-8
#ENV LANG de_DE.UTF-8  
#ENV LANGUAGE de_DE:de  
#ENV LC_ALL de_DE.UTF-8

RUN	make && make install

#copy templates for live plugin to destination folder
RUN cp -a /build/vdr-${VDR_VERSION}/PLUGINS/src/live/live /usr/share/vdr/plugins

#RUN	make && make install && \
#	apt-get purge -qy binutils build-essential bzip2 cpp dpkg-dev fakeroot g++ gcc \
#			  libalgorithm-diff-perl libalgorithm-diff-xs-perl \
#			  libalgorithm-merge-perl libatomic1 libc-dev-bin libc6-dev \
#			  libdpkg-perl libfakeroot libfile-fcntllock-perl \
#			  libgmp10 libitm1 libmpc3 libquadmath0 \
#			  libtsan0 linux-libc-dev make manpages manpages-dev patch \
#			  xz-utils && \
#	apt-get autoremove -qy $(apt-cache showsrc vdr-plugin-satip | sed -e '/Build-Depends/!d;s/Build-Depends: \|,\|([^)]*),*\|\[[^]]*\]//g') && \ 
#	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD vdr.sh /etc/services.d/vdr/run
ADD vdr-finish.sh /etc/services.d/vdr/finish
ADD rsyslog.sh /etc/services.d/rsyslog/run

# add configs
#ADD var/lib/vdr/* /var/lib/vdr/
#ADD var/lib/vdr/plugins/streamdev-server/* /var/lib/vdr/plugins/streamdev-server/
#RUN rm /etc/vdr/conf.d/*
#ADD etc/vdr/conf.d/* /etc/vdr/conf.d/
ADD etc/rsyslog.conf /etc/

# Configure the vdr user account and it's folders
#RUN groupadd -g 666 vdr
RUN adduser vdr
RUN groupmod -o -g 666 vdr \
 && usermod -o -u 666 vdr \
 && install -o vdr -g vdr -d /recordings /var/cache/vdr /var/lib/vdr

#EXPOSE 2004 3000 6419 8002 8008 4010-4020/udp 34890 34891
EXPOSE 2004 3000 6419 8002 8008 4010-4020/udp 34890
VOLUME /recordings /etc/vdr /var/lib/vdr

ENTRYPOINT [ "/init" ]
