FROM python:3.8.5-slim-buster AS base

# System environment variables
ENV GIT_AUTHOR_NAME=docker-odoo \
    GIT_COMMITTER_NAME=docker-odoo \
    EMAIL=docker-odoo@example.com \
    LC_ALL=C.UTF-8 \
    NODE_PATH=/usr/local/lib/node_modules:/usr/lib/node_modules \
    PATH="/home/odoo/.local/bin:$PATH" \
    PIP_NO_CACHE_DIR=1

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
ARG WKHTMLTOPDF_VERSION=0.12.5
ARG WKHTMLTOPDF_CHECKSUM='1140b0ab02aa6e17346af2f14ed0de807376de475ba90e1db3975f112fbd20bb'
ARG APT_REQUIREMENTS="\
    git \
    curl \
    wget \
    chromium \
    ffmpeg \
    fonts-liberation2 \
    gettext-base \
    gnupg2 \
    locales-all \
    npm \
    ruby \
    zlibc \
    "
ARG APT_TOOL_PACKAGES="\
    nano \
    openssh-client \
    telnet \
    htop \
    ftp \
    rsync \
"
RUN apt-get -qq update \
    && apt-get install -yqq --no-install-recommends $APT_REQUIREMENTS \
    && apt-get install -yqq --no-install-recommends $APT_TOOL_PACKAGES \
    # wkhtmltopdf
    && curl -SLo wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}-1.stretch_amd64.deb \
    && echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.deb" | sha256sum -c - \
    && apt-get install -yqq --no-install-recommends ./wkhtmltox.deb \
    && rm -rf wkhtmltox.deb \
    # postgres
    && echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' >> /etc/apt/sources.list.d/postgresql.list \
    && curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -yqq --no-install-recommends postgresql-client \
    # cleanup
    && apt-get autopurge -yqq \
    && rm -rf /var/lib/apt/lists/* /tmp/* \
    && sync

# Special case to get latest Less
RUN ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install -g less \
    && rm -Rf ~/.npm /tmp/*

# Install Odoo hard & soft dependencies, and utilities
ARG ODOO_VERSION=12.0
ARG ODOO_SOURCE=odoo/odoo
ARG BUILD_DEPS="\
    build-essential \
    libfreetype6-dev \
    libfribidi-dev \
    libghc-zlib-dev \
    libharfbuzz-dev \
    libjpeg-dev \
    liblcms2-dev \
    libldap2-dev \
    libopenjp2-7-dev \
    libpq-dev \
    libsasl2-dev \
    libtiff5-dev \
    libwebp-dev \
    libxml2-dev \
    libxslt-dev \
    tcl-dev \
    tk-dev \
    zlib1g-dev \
    "
ARG PIP_REQUIREMENTS="\
    git+git://github.com/OCA/openupgradelib.git \
    git-aggregator \
    click-odoo-contrib \
    phonenumbers \
    geoip2 \
    pg_activity \
    urllib3==1.24.2 \
    simplejson==3.11.1 \
    pyinotify==0.9.6 \
    python-stdnum==1.9 \
    websocket-client~=0.56 \
    xlrd==1.2.0 \
    xlsxwriter==1.2.2 \
    "
RUN apt-get update \
    && apt-get install -yqq --no-install-recommends $BUILD_DEPS \
    && pip install --no-cache-dir -r https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \
    && pip install --no-cache-dir $PIP_REQUIREMENTS \
    && (python3 -m compileall -q /usr/local/lib/python3*/ || true) \
    # cleanup
    && apt-get purge -yqq $BUILD_DEPS \
    && apt-get autopurge -yqq \
    && rm -Rf /var/lib/apt/lists/* /tmp/* \
    && sync

# Add odoo user
RUN useradd -md /home/odoo -s /bin/false odoo && sync

# Create directory structure
ENV SOURCES=/home/odoo/src \
    RESOURCES=/home/odoo/.resources \
    CONFIG_DIR=/home/odoo/.config \
    DATA_DIR=/home/odoo/data
RUN mkdir -p $SOURCES/repositories && \
    mkdir -p $DATA_DIR && \
    mkdir -p $CONFIG_DIR && \
    mkdir -p $RESOURCES && \
    chown -R odoo.odoo /home/odoo && \
    sync

# Config env
ENV OPENERP_SERVER=$CONFIG_DIR/odoo.conf
ENV ODOO_RC=$OPENERP_SERVER

# Image building scripts
COPY bin/* /usr/local/bin/
COPY build.d $RESOURCES/build.d
COPY conf.d $RESOURCES/conf.d
COPY entrypoint.d $RESOURCES/entrypoint.d
COPY entrypoint.sh $RESOURCES/entrypoint.sh
RUN    ln /usr/local/bin/direxec $RESOURCES/entrypoint \
    && ln /usr/local/bin/direxec $RESOURCES/build \
    && chown -R odoo.odoo $RESOURCES \
    && chmod -R a+rx $RESOURCES/entrypoint* $RESOURCES/build* /usr/local/bin \
    && $RESOURCES/build \
    && sync

# Docker
EXPOSE 8069 8072
VOLUME "/home/odoo/data"
WORKDIR "/home/odoo"
ENTRYPOINT ["/home/odoo/.resources/entrypoint.sh"]
CMD "odoo"

# ODOO CONF DEFAULT VALUES
ARG UNACCENT=true
ARG PROXY_MODE=true
ARG WITHOUT_DEMO=true
ARG WAIT_PG=true
ARG PGUSER=odoo
ARG PGPASSWORD=odoo
ARG PGHOST=db
ARG PGPORT=5432
ARG ADMIN_PASSWORD=admin
# Set env from args
ENV UNACCENT="$UNACCENT" \
    PROXY_MODE="$PROXY_MODE" \
    WITHOUT_DEMO="$WITHOUT_DEMO" \
    WAIT_PG="$WAIT_PG" \
    PGUSER="$PGUSER" \
    PGPASSWORD="$PGPASSWORD" \
    PGHOST="$PGHOST" \
    PGPORT="$PGPORT" \
    ADMIN_PASSWORD="$ADMIN_PASSWORD" \
    ODOO_VERSION="$ODOO_VERSION"

USER odoo
