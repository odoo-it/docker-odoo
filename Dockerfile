ARG PYTHON_VERSION=3.12
ARG DISTRIBUTION=bookworm
FROM python:$PYTHON_VERSION-slim-$DISTRIBUTION

# Multi-arch builds
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# System environment variables
ENV PATH=/home/odoo/.local/bin:$PATH
ENV LC_ALL=C.UTF-8
ENV GIT_AUTHOR_NAME=odoo
ENV GIT_COMMITTER_NAME=odoo
ENV EMAIL=odoo@localhost
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Very likely, this layer is shared among builds of same distribution
ARG PYTHON_VERSION
ARG DISTRIBUTION
ARG WKHTMLTOPDF_VERSION
RUN --mount=type=bind,src=build/install/${DISTRIBUTION},dst=/build/install,rw \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    # Make all script executable
    chmod +x /build/install/*.sh \
    # Execute all the pre-install hooks, if any
    && find /build/install -name "pre-install-*.sh" -executable -exec {} \; \
    # Install
    && apt-get -qq update \
    && xargs -a /build/install/apt-requirements.txt apt-get install -yqq --no-install-recommends \
    && /build/install/wkhtmltopdf-${WKHTMLTOPDF_VERSION}.sh \
    && /build/install/postgres-client.sh \
    && rm -rf /tmp/* \
    && sync

# Install and build Odoo dependencies
ARG ODOO_VERSION=master
ARG ODOO_SOURCE=odoo/odoo
ADD https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt /build/odoo-requirements.txt
RUN --mount=type=bind,src=build/install/${DISTRIBUTION}/apt-build-deps.txt,dst=/build/apt-build-deps.txt \
    --mount=type=bind,src=build/extra-requirements.txt,dst=/build/extra-requirements.txt \
    --mount=type=bind,src=build/test-requirements.txt,dst=/build/test-requirements.txt \
    --mount=type=bind,src=build/requirements.txt,dst=/build/requirements.txt \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip \
    # Install the build dependencies
    apt-get -qq update \
    && xargs -a /build/apt-build-deps.txt apt-get install -yqq --no-install-recommends \
    # disable gevent version recommendation from odoo and use 21.12.0 instead
    && sed -i -E "s/gevent==21\.8\.0/gevent==21.12.0/" /build/odoo-requirements.txt \
    # Python Packages
    && pip install --prefer-binary \
        --requirement /build/odoo-requirements.txt \
        --requirement /build/requirements.txt \
        --requirement /build/extra-requirements.txt \
        --requirement /build/test-requirements.txt \
        --constraint /build/odoo-requirements.txt \
    && (python3 -m compileall -q /usr/local/lib/python3*/ || true) \
    # Cleanup
    && xargs -a /build/apt-build-deps.txt apt-get purge -yqq \
    && apt-get autopurge -yqq \
    && rm -rf /tmp/* \
    && rm -rf /build/odoo-requirements.txt \
    && sync

# Install GeoIP database (optional)
# The LOCAL_GEOIP_PATH is used to specify the path to the GeoIP database files
ARG LOCAL_GEOIP_PATH="."
COPY ${LOCAL_GEOIP_PATH}/GeoLite2-*.mmdb /usr/share/GeoIP/

# Create directory structure
ENV SOURCES=/home/odoo/src
ENV REPOSITORIES=$SOURCES/repositories
ENV DATA_DIR=/home/odoo/data
ENV RESOURCES=/home/odoo/.resources

# Config env
ENV ODOO_VERSION=$ODOO_VERSION
ENV ODOO_RC=/home/odoo/.odoorc

# Add odoo user and directories
RUN useradd -md /home/odoo -s /bin/false odoo \
    && mkdir -p $REPOSITORIES \
    && mkdir -p $DATA_DIR \
    && mkdir -p $RESOURCES \
    && chown -R odoo:odoo /home/odoo \
    && sync

# Entrypoint scripts
COPY --chmod=777 bin/* /usr/local/bin/
COPY --chown=odoo.odoo --chmod=777 conf.d $RESOURCES/conf.d
COPY --chown=odoo.odoo --chmod=777 entrypoint.d $RESOURCES/entrypoint.d
COPY --chown=odoo.odoo --chmod=777 entrypoint.sh $RESOURCES/entrypoint.sh

# Other files
COPY --chown=odoo.odoo --chmod=777 other/welcome.sh /etc/profile.d/

# Default values for postgres
ENV PGHOST=db
ENV PGUSER=odoo
ENV PGPASSWORD=odoo

# Docker
EXPOSE 8069 8072
VOLUME "/home/odoo/data"
WORKDIR "/home/odoo"
ENTRYPOINT ["/home/odoo/.resources/entrypoint.sh"]
CMD ["odoo"]
USER odoo
