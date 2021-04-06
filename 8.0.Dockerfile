FROM debian:8 AS base

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

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
ARG WKHTMLTOPDF_VERSION=0.12.5
ARG WKHTMLTOPDF_CHECKSUM='2583399a865d7604726da166ee7cec656b87ae0a6016e6bce7571dcd3045f98b'
RUN sed -Ei 's@(^deb http://deb.debian.org/debian jessie-updates main$)@#\1@' /etc/apt/sources.list \
    && apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
        python ruby-compass \
        fontconfig libfreetype6 libxml2 libxslt1.1 libjpeg62-turbo zlib1g \
        fonts-liberation \
        libfreetype6 liblcms2-2 libopenjpeg5 libtiff5 tk tcl libpq5 \
        libldap-2.4-2 libsasl2-2 libx11-6 libxext6 libxrender1 \
        locales-all zlibc \
        bzip2 ca-certificates curl gettext-base git nano \
        openssh-client telnet xz-utils \
        sudo \
        wget \
    && curl https://bootstrap.pypa.io/pip/2.7/get-pip.py | python /dev/stdin \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -yqq --force-yes nodejs \
    && curl -SLo fonts-liberation2.deb http://ftp.debian.org/debian/pool/main/f/fonts-liberation2/fonts-liberation2_2.00.1-3_all.deb \
    && dpkg --install fonts-liberation2.deb \
    && curl -SLo wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}-1.jessie_amd64.deb \
    && echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.deb" | sha256sum -c - \
    && (dpkg --install wkhtmltox.deb || true) \
    && apt-get install -yqq --no-install-recommends --fix-broken \
    && rm fonts-liberation2.deb wkhtmltox.deb \
    && wkhtmltopdf --version \
    && rm -Rf /var/lib/apt/lists/*

# Special case to get latest PostgreSQL client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' >> /etc/apt/sources.list.d/postgresql.list \
    && curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    && rm -Rf /var/lib/apt/lists/* /tmp/*

# Special case to get latest Less and PhantomJS
RUN ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install -g less@2 less-plugin-clean-css@1 phantomjs-prebuilt@2 \
    && rm -Rf ~/.npm /tmp/*

# Special case to get bootstrap-sass, required by Odoo for Sass assets
RUN gem install --no-rdoc --no-ri --no-update-sources autoprefixer-rails --version '<9.8.6' \
    && gem install --no-rdoc --no-ri --no-update-sources bootstrap-sass --version '<3.4' \
    && rm -Rf ~/.gem /var/lib/gems/*/cache/

# Execute installation script by Odoo version
# This is at the end to benefit from cache at build time
# https://docs.docker.com/engine/reference/builder/#/impact-on-build-caching
ARG ODOO_VERSION=8.0
ARG ODOO_SOURCE=odoo/odoo
RUN debs="python-dev build-essential libxml2-dev libxslt1-dev libjpeg-dev libfreetype6-dev liblcms2-dev libopenjpeg-dev libtiff5-dev tk-dev tcl-dev linux-headers-amd64 libpq-dev libldap2-dev libsasl2-dev" \
    && apt-get update \
    && apt-get install -yqq --no-install-recommends $debs \
    && pip install \
        -r https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt \
        phonenumbers \
        watchdog \
    && apt-get purge -yqq $debs \
    && rm -Rf /var/lib/apt/lists/* /tmp/*

# Other pip requirements and utilities
RUN pip install --no-cache-dir \
    phonenumbers \
    git-aggregator \
    click-odoo-contrib

# Create directory structure
ENV SOURCES=/home/odoo/src \
    CUSTOM=/home/odoo/custom \
    RESOURCES=/home/odoo/.resources \
    CONFIG_DIR=/home/odoo/.config \
    DATA_DIR=/home/odoo/data
RUN mkdir -p $SOURCES/repositories && \
    mkdir -p $CUSTOM/repositories && \
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
    && sync

# Metadata
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION
LABEL org.label-schema.schema-version="$VERSION" \
      org.label-schema.vendor=Adhoc \
      org.label-schema.license=Apache-2.0 \
      org.label-schema.build-date="$BUILD_DATE" \
      org.label-schema.vcs-ref="$VCS_REF" \
      org.label-schema.vcs-url="https://github.com/ingadhoc/docker-odoo"

# onbuild version
# This is the real deal

FROM base AS onbuild
ONBUILD VOLUME ["/home/odoo/data"]
ONBUILD WORKDIR "/home/odoo"
ONBUILD ENTRYPOINT ["/home/odoo/.resources/entrypoint.sh"]
ONBUILD CMD ["odoo"]
# ODOO CONF DEFAULT VALUES
ONBUILD ARG UNACCENT=true
ONBUILD ARG PROXY_MODE=true
ONBUILD ARG WITHOUT_DEMO=true
ONBUILD ARG WAIT_PG=true
ONBUILD ARG PGUSER=odoo
ONBUILD ARG PGPASSWORD=odoo
ONBUILD ARG PGHOST=db
ONBUILD ARG PGPORT=5432
ONBUILD ARG ADMIN_PASSWORD=admin
# BUILD ARGS
ONBUILD ARG GITHUB_USER
ONBUILD ARG GITHUB_TOKEN
ONBUILD ARG ODOO_VERSION=8.0
ONBUILD ARG ODOO_SOURCE=odoo/odoo
ONBUILD ARG ODOO_SOURCE_DEPTH=1
ONBUILD ARG INSTALL_ODOO=false
ONBUILD ARG INSTALL_ENTERPRISE=false
# Set env from args
ONBUILD ENV \
    UNACCENT="$UNACCENT" \
    PROXY_MODE="$PROXY_MODE" \
    WITHOUT_DEMO="$WITHOUT_DEMO" \
    WAIT_PG="$WAIT_PG" \
    PGUSER="$PGUSER" \
    PGPASSWORD="$PGPASSWORD" \
    PGHOST="$PGHOST" \
    PGPORT="$PGPORT" \
    ADMIN_PASSWORD="$ADMIN_PASSWORD" \
    ODOO_VERSION="$ODOO_VERSION"
# Run build scripts
ONBUILD COPY conf.d/*       $RESOURCES/conf.d/
ONBUILD COPY entrypoint.d/* $RESOURCES/entrypoint.d/
ONBUILD COPY build.d/*      $RESOURCES/build.d/
ONBUILD COPY repos.d/*      $RESOURCES/repos.d/
ONBUILD COPY requirements/* $RESOURCES/requirements/
ONBUILD RUN  chown -R odoo.odoo $RESOURCES \
             && chmod -R a+rx $RESOURCES/entrypoint* $RESOURCES/build* \
             && $RESOURCES/build \
             && sync
ONBUILD USER odoo
# HACK Special case for Werkzeug
ONBUILD RUN pip install --user Werkzeug==0.14.1
