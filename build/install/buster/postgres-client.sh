#!/bin/bash
set -e

echo "deb https://apt-archive.postgresql.org/pub/repos/apt $DISTRIBUTION-pgdg main" >> /etc/apt/sources.list.d/postgresql.list
curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -yqq --no-install-recommends postgresql-client
