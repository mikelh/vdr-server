#!/bin/sh

TOP=`dirname $0`
VERSION=${TOP}/version

[ -f ${VERSION} ] && . ${VERSION}

DEBUG=0
BRANCH=

usage() {
    echo "build script for the 'vdr-server' docker image"
    echo ""
    echo "./build.sh"
    echo "\t-h --help             show this help"
    echo "\t--version=GIT_REV     build branch / version (default: ${VDR_VERSION})"
    echo ""
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --version)
            VDR_VERSION=${VALUE}
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

rm -Rf opt

docker build \
    --force-rm \
    --build-arg VDR_VERSION=${VDR_VERSION} \
    -t mikelh/vdr-server:${VDR_VERSION}-${DOCKER_BUILD} \
    -f ${TOP}/Dockerfile ${TOP}

docker tag mikelh/vdr-server:${VDR_VERSION}-${DOCKER_BUILD} mikelh/vdr-server:latest
