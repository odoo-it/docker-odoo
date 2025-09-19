#!/bin/bash
set -e

WKHTMLTOPDF_VERSION="0.12.6"
WKHTMLTOPDF_RELEASE="0.12.6.1-3"
WKHTMLTOPDF_DISTRIBUTION="bookworm"

case $TARGETPLATFORM in
    "linux/amd64")
        WKHTMLTOPDF_PLATFORM="amd64"
        WKHTMLTOPDF_CHECKSUM="98ba0d157b50d36f23bd0dedf4c0aa28c7b0c50fcdcdc54aa5b6bbba81a3941d"
        ;;
    "linux/arm64")
        WKHTMLTOPDF_PLATFORM="arm64"
        WKHTMLTOPDF_CHECKSUM="b6606157b27c13e044d0abbe670301f88de4e1782afca4f9c06a5817f3e03a9c"
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
