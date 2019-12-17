#!/bin/bash

set -e

if [[ "$(id -u)" != 0 ]]; then
	echo "Installer must be run as root (or with sudo)."
	exit 1
fi

echo "* Setting up /usr/src links from host"

for i in $(ls ${WIREGUARD_HOST_ROOT}/usr/src)
do 
	ln -s ${WIREGUARD_HOST_ROOT}/usr/src/${i} /usr/src/${i}
done

# Load the kernel module
ARCH=$(uname -m)
KERNEL_RELEASE=$(uname -r)
PACKAGE_NAME=wireguard
MODULE_VERSION=$(dpkg -l | grep 'wireguard-dkms' | awk '{ print $3 }' | awk -F '-' '{ print $1 }')

echo "* Running dkms install for ${PACKAGE_NAME}/${MODULE_VERSION}"
if dkms install -m "${PACKAGE_NAME}" -v "${MODULE_VERSION}" -k "${KERNEL_RELEASE}"; then
    echo "* Successful dkms installation"
else
    DKMS_LOG="/var/lib/dkms/${PACKAGE_NAME}/${MODULE_VERSION}/build/make.log"
    if [[ -f "${DKMS_LOG}" ]]; then
        echo "* Running dkms build failed, dumping ${DKMS_LOG}"
        cat "${DKMS_LOG}"
    else
        echo "* Running dkms build failed, couldn't find ${DKMS_LOG}"
    fi
    exit 1
fi

echo "* Trying to load a dkms ${PACKAGE_NAME}, if present"
if insmod "/var/lib/dkms/${PACKAGE_NAME}/${MODULE_VERSION}/${KERNEL_RELEASE}/${ARCH}/module/${PACKAGE_NAME}.ko"; then
    echo "${PACKAGE_NAME} found and loaded in dkms"
    exit 0
elif insmod "/var/lib/dkms/${PACKAGE_NAME}/${MODULE_VERSION}/${KERNEL_RELEASE}/${ARCH}/module/${PACKAGE_NAME}.ko.xz"; then
    echo "${PACKAGE_NAME} found and loaded in dkms (xz)"
    exit 0
else
    echo "* Unable to insmod"
    exit 1
fi

exec "$@"
