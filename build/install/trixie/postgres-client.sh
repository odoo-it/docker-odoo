#!/bin/bash
set -e

echo "deb  [arch=${TARGETPLATFORM/linux\//} signed-by=/etc/apt/keyrings/postgresql.asc] http://apt.postgresql.org/pub/repos/apt/ ${DISTRIBUTION}-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /etc/apt/keyrings/postgresql.asc
apt-get update
apt-get install -yqq --no-install-recommends postgresql-client
