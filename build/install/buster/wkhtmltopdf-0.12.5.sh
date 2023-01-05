#!/bin/bash
set -e

WKHTMLTOPDF_VERSION="0.12.5"
WKHTMLTOPDF_RELEASE="0.12.5-1"
WKHTMLTOPDF_DISTRIBUTION="buster"
WKHTMLTOPDF_CHECKSUM="dfab5506104447eef2530d1adb9840ee3a67f30caaad5e9bcb8743ef2f9421bd"

curl -SLo wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_RELEASE}.${WKHTMLTOPDF_DISTRIBUTION}_amd64.deb
echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.deb" | sha256sum -c -
apt-get install -yqq --no-install-recommends ./wkhtmltox.deb
rm -rf wkhtmltox.deb
