# Generic Dockerfile used to build the odoo included images

ARG DOCKER_REPO
ARG DOCKER_TAG
FROM $DOCKER_REPO:$DOCKER_TAG AS odoo
ARG ODOO_SOURCE_DEPTH=1
RUN git clone -b $ODOO_VERSION --depth $ODOO_SOURCE_DEPTH --single-branch https://github.com/$ODOO_SOURCE $SOURCES/odoo
RUN $RESOURCES/entrypoint.d/100-pip-install-odoo

FROM odoo AS enterprise
ARG GITHUB_USER
ARG GITHUB_TOKEN
RUN git clone -b $ODOO_VERSION --depth $ODOO_SOURCE_DEPTH --single-branch https://$GITHUB_USER:$GITHUB_TOKEN@github.com/odoo/enterprise.git $SOURCES/enterprise
