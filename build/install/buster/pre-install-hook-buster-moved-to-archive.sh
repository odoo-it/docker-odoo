#!/bin/bash
set -ex

# Debian buster was moved to archive
sed -i 's,http://deb.debian.org,http://archive.debian.org,g;s,http://security.debian.org,http://archive.debian.org,g' /etc/apt/sources.list
