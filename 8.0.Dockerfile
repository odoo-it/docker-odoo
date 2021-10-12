FROM python:2.7.16-slim-jessie AS base

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
ARG WKHTMLTOPDF_CHECKSUM='2583399a865d7604726da166ee7cec656b87ae0a6016e6bce7571dcd3045f98b'
ARG APT_REQUIREMENTS="\
    git \
    curl \
    wget \
    ruby-compass \
    fontconfig \
    libfreetype6 \
    libxml2 \
    libxslt1.1 \
    libjpeg62-turbo \
    zlib1g \
    fonts-liberation \
    libfreetype6 \
    liblcms2-2 \
    libopenjpeg5 \
    libtiff5 \
    tk \
    tcl \
    libpq5 \
    libldap-2.4-2 \
    libsasl2-2 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    locales-all \
    zlibc \
    bzip2 \
    ca-certificates \
    gettext-base \
    xz-utils \
    xfonts-base xfonts-75dpi fontconfig xvfb \
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
    # Fix letsencrypt DST_Root_CA_X3 expired root certificate
    # https://medium.com/geekculture/will-you-be-impacted-by-letsencrypt-dst-root-ca-x3-expiration-d54a018df257
    && sed -i 's/mozilla\/DST_Root_CA_X3.crt/!mozilla\/DST_Root_CA_X3.crt/g' /etc/ca-certificates.conf && update-ca-certificates \
    # npm / nodejs
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get update \
    && apt-get install -yqq --no-install-recommends --force-yes nodejs \
    # fonts-liberation2
    && curl -SLo fonts-liberation2.deb http://ftp.debian.org/debian/pool/main/f/fonts-liberation2/fonts-liberation2_2.00.1-3_all.deb \
    && dpkg --install fonts-liberation2.deb \
    && rm -rf fonts-liberation2.deb \
    # wkhtmltopdf
    && curl -SLo wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}-1.jessie_amd64.deb \
    && echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.deb" | sha256sum -c - \
    && dpkg --install wkhtmltox.deb \
    && rm -rf wkhtmltox.deb \
    && apt-get install -yqq --no-install-recommends --fix-broken \
    # postgres
    && echo 'deb http://apt-archive.postgresql.org/pub/repos/apt/ jessie-pgdg main' >> /etc/apt/sources.list.d/postgresql.list \
    && curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    # cleanup
    && rm -rf /var/lib/apt/lists/* /tmp/* \
    && sync

# Install Odoo hard & soft dependencies, and utilities
ARG ODOO_VERSION=8.0
ARG ODOO_SOURCE=odoo/odoo
ARG BUILD_DEPS="\
    python-dev \
    build-essential \
    libxml2-dev \
    libxslt1-dev \
    libjpeg-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libopenjpeg-dev \
    libtiff5-dev \
    tk-dev \
    tcl-dev \
    linux-headers-amd64 \
    libpq-dev \
    libldap2-dev \
    libsasl2-dev \
    ruby-dev \
    ruby-ffi \
    bzip2 \
    "
ARG PIP_REQUIREMENTS="\
    openupgradelib \
    git-aggregator \
    click-odoo-contrib \
    phonenumbers \
    geoip2 \
    pg_activity \
    "
RUN apt-get update \
    && apt-get install -yqq --no-install-recommends $BUILD_DEPS \
    && pip install --no-cache-dir -r https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \
    && pip install --no-cache-dir $PIP_REQUIREMENTS \
    && (python2 -m compileall -q /usr/local/lib/python2*/ || true) \
    # Special case to get bootstrap-sass, required by Odoo for Sass assets
    && ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install --unsafe-perm -g less@2 less-plugin-clean-css@1 phantomjs-prebuilt@2 \
    && rm -rf ~/.npm /tmp/* \
    # Special case to get latest Less and PhantomJS
    && gem install --no-rdoc --no-ri --no-update-sources autoprefixer-rails --version '<9.8.6' \
    && gem install --no-rdoc --no-ri --no-update-sources bootstrap-sass --version '<3.4' \
    && rm -rf ~/.gem /var/lib/gems/*/cache/ \
    # Cleanup
    && apt-get purge -yqq $BUILD_DEPS \
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
