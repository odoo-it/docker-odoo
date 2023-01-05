ARG DOCKER_REPO
ARG DOCKER_TAG
FROM $DOCKER_REPO:$DOCKER_TAG
ARG ODOO_SOURCE=odoo/odoo
RUN mkdir -p /tmp/odoo \
    && (curl -sSL https://github.com/$ODOO_SOURCE/tarball/$ODOO_VERSION | tar -C /tmp/odoo -xz) \
    && mv /tmp/odoo/* $SOURCES/odoo \
    && rm -rf /tmp/odoo \
    && pip-install-odoo
