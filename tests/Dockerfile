ARG DOCKER_REPO
ARG DOCKER_TAG
FROM $DOCKER_REPO:$DOCKER_TAG
RUN git clone --single-branch --branch $ODOO_VERSION --depth 1 https://github.com/odoo/odoo.git $SOURCES/odoo
