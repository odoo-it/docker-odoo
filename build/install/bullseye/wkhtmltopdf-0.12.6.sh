#!/bin/bash
set -e

WKHTMLTOPDF_VERSION="0.12.6"
WKHTMLTOPDF_RELEASE="0.12.6.1-3"
WKHTMLTOPDF_DISTRIBUTION="bullseye"

case $TARGETPLATFORM in
    "linux/amd64")
        WKHTMLTOPDF_PLATFORM="amd64"
        WKHTMLTOPDF_CHECKSUM="9c687f0c58cf50e01f2a6375d2e34372f8feeec56a84690ea113d298fccadd98"
        ;;
    "linux/arm64")
        WKHTMLTOPDF_PLATFORM="arm64"
        WKHTMLTOPDF_CHECKSUM="e73435a82cf21ba0387bfee32a193f221fa43e48dda6ed38b12e4c1b70c69728"
        ;;
    *)
        echo "Unknown platform"
        exit 1
        ;;
esac

WKHTMLTOPDF_URL=https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_RELEASE}/wkhtmltox_${WKHTMLTOPDF_RELEASE}.${WKHTMLTOPDF_DISTRIBUTION}_${WKHTMLTOPDF_PLATFORM}.deb
echo "Downloading ${WKHTMLTOPDF_URL}..."
curl -SLo wkhtmltox.deb ${WKHTMLTOPDF_URL}
echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.deb" | sha256sum -c -

apt-get install -yqq --no-install-recommends ./wkhtmltox.deb
rm -rf wkhtmltox.deb
