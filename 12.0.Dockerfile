FROM python:3.5-stretch AS base

EXPOSE 8069 8072

# Enable Odoo user and filestore
RUN useradd -md /home/odoo -s /bin/false odoo \
    && mkdir -p /var/lib/odoo \
    && chown -R odoo:odoo /var/lib/odoo \
    && sync

# System environment variables
ENV GIT_AUTHOR_NAME=docker-odoo \
    GIT_COMMITTER_NAME=docker-odoo \
    EMAIL=docker-odoo@example.com \
    LC_ALL=C.UTF-8 \
    NODE_PATH=/usr/local/lib/node_modules:/usr/lib/node_modules \
    PATH="/home/odoo/.local/bin:$PATH" \
    PIP_NO_CACHE_DIR=0 \
    PYTHONOPTIMIZE=1

# Default values of env variables used by scripts
ENV ODOO_SERVER=odoo \
    UNACCENT=True \
    PROXY_MODE=True \
    WITHOUT_DEMO=True \
    WAIT_PG=true \
    PGUSER=odoo \
    PGPASSWORD=odoo \
    PGHOST=db \
    PGPORT=5432 \
    ADMIN_PASSWORD=admin \
    DB_TEMPLATE=template1

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
ARG WKHTMLTOPDF_VERSION=0.12.5
ARG WKHTMLTOPDF_CHECKSUM='1140b0ab02aa6e17346af2f14ed0de807376de475ba90e1db3975f112fbd20bb'
RUN apt-get -qq update \
    && apt-get -yqq upgrade \
    && apt-get install -yqq --no-install-recommends \
        chromium \
        ffmpeg \
        fonts-liberation2 \
        gettext-base \
        gnupg2 \
        locales-all \
        nano \
        ruby \
        telnet \
        vim \
        zlibc \
        sudo \
    && echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' >> /etc/apt/sources.list.d/postgresql.list \
    && curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && curl https://bootstrap.pypa.io/get-pip.py | python3 /dev/stdin \
    && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt-get update \
    && apt-get install -yqq --no-install-recommends nodejs postgresql-client \
    && curl -SLo wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}-1.stretch_amd64.deb \
    && echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.deb" | sha256sum -c - \
    && apt-get install -yqq --no-install-recommends ./wkhtmltox.deb \
    && rm wkhtmltox.deb \
    && wkhtmltopdf --version \
    && rm -Rf /var/lib/apt/lists/* /tmp/*

# Special case to get latest Less
RUN ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install -g less \
    && rm -Rf ~/.npm /tmp/*

# Execute installation script by Odoo version
# This is at the end to benefit from cache at build time
# https://docs.docker.com/engine/reference/builder/#/impact-on-build-caching
ARG ODOO_SOURCE=odoo/odoo
ARG ODOO_VERSION=12.0
ENV ODOO_VERSION="$ODOO_VERSION"
RUN debs="libldap2-dev libsasl2-dev" \
    && apt-get update \
    && apt-get install -yqq --no-install-recommends $debs \
    && pip install \
        -r https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \
        phonenumbers \
        'websocket-client~=0.53' \
    && (python3 -m compileall -q /usr/local/lib/python3.5/ || true) \
    && apt-get purge -yqq $debs \
    && rm -Rf /var/lib/apt/lists/* /tmp/*

# Other pip requirements and utilities
RUN pip install --no-cache-dir \
    phonenumbers \
    git-aggregator \
    ipython \
    pysnooper \
    ipdb \
    git+git://github.com/OCA/openupgradelib.git \
    click-odoo-contrib

# Metadata
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION
LABEL org.label-schema.schema-version="$VERSION" \
      org.label-schema.vendor=Druidoo \
      org.label-schema.license=Apache-2.0 \
      org.label-schema.build-date="$BUILD_DATE" \
      org.label-schema.vcs-ref="$VCS_REF" \
      org.label-schema.vcs-url="https://github.com/Druidoo/docker-odoo"

# Create directory structure
ENV SOURCES /home/odoo/src
ENV CUSTOM /home/odoo/custom
ENV RESOURCES /home/odoo/.resources
ENV CONFIG_DIR /home/odoo/.config
ENV DATA_DIR /home/odoo/data

ENV OPENERP_SERVER=$CONFIG_DIR/odoo.conf
ENV ODOO_RC=$OPENERP_SERVER

RUN mkdir -p $SOURCES/repositories && \
    mkdir -p $CUSTOM/repositories && \
    mkdir -p $DATA_DIR && \
    mkdir -p $CONFIG_DIR && \
    mkdir -p $RESOURCES && \
    chown -R odoo.odoo /home/odoo && \
    sync

# Usefull aliases
RUN echo "alias odoo-shell='odoo shell --shell-interface ipython --no-http --limit-memory-hard=0 --limit-memory-soft=0'" >> /home/odoo/.bashrc

# Image building scripts
COPY bin/* /usr/local/bin/
COPY build.d $RESOURCES/build.d
COPY conf.d $RESOURCES/conf.d
COPY entrypoint.d $RESOURCES/entrypoint.d
COPY entrypoint.sh $RESOURCES/entrypoint.sh
COPY resources/* $RESOURCES/
RUN    ln /usr/local/bin/direxec $RESOURCES/entrypoint \
    && ln /usr/local/bin/direxec $RESOURCES/build \
    && chown -R odoo.odoo $RESOURCES \
    && chmod -R a+rx $RESOURCES/entrypoint* $RESOURCES/build* /usr/local/bin \
    && sync

# Run build scripts
RUN $RESOURCES/build && sync

# Entrypoint
WORKDIR "/home/odoo"
ENTRYPOINT ["/home/odoo/.resources/entrypoint.sh"]
CMD ["odoo"]
USER odoo

# HACK Special case for Werkzeug
RUN pip install --user Werkzeug==0.14.1

#
#   Odoo
#

FROM base AS odoo
COPY odoo.yml $RESOURCES/
RUN autoaggregate --config "$RESOURCES/odoo.yml" --install --output $SOURCES
RUN pip install --user --no-cache-dir $SOURCES/odoo

#
#   Odoo Enterprise
#

FROM odoo AS enterprise
ARG GITHUB_USER
ARG GITHUB_TOKEN
ENV GITHUB_USER="$GITHUB_USER"
ENV GITHUB_TOKEN="$GITHUB_TOKEN"
COPY odoo-e.yml $RESOURCES/
RUN autoaggregate --config "$RESOURCES/odoo-e.yml" --install --output $SOURCES
