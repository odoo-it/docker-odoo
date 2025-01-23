# Base common layer
# -----------------

ARG PYTHON_VERSION=3.12
ARG DISTRIBUTION=bookworm
FROM python:$PYTHON_VERSION-slim-$DISTRIBUTION AS common
# System environment variables
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
# Upgrade pip to latest version
RUN python -m pip install --upgrade pip

# Python Builder Step
# -------------------
# Installs all python dependencies in a virtual environment, which will later be copied
# to the runtime image.

FROM common AS python-deps
# Update package lists
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get -qq update
# Install the build dependencies
ARG DISTRIBUTION
RUN --mount=type=bind,src=build/install/${DISTRIBUTION}/apt-build-deps.txt,dst=/build/apt-build-deps.txt \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    xargs -a /build/apt-build-deps.txt apt-get install -yqq --no-install-recommends
# Set up the virtual environment
ENV VIRTUAL_ENV=/home/odoo/venv
RUN python -m venv $VIRTUAL_ENV
# Install odoo requirements
ARG ODOO_VERSION
ARG ODOO_SOURCE=odoo/odoo
ADD https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt /build/odoo-requirements.txt
# Disable gevent version recommendation from odoo and use 21.12.0 instead
RUN sed -i -E "s/gevent==21\.8\.0/gevent==21.12.0/" /build/odoo-requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    $VIRTUAL_ENV/bin/pip install --prefer-binary --requirement /build/odoo-requirements.txt
# Install odoo extra requirements
RUN --mount=type=bind,src=build/extra-requirements.txt,dst=/build/extra-requirements.txt \
    --mount=type=cache,target=/root/.cache/pip \
    $VIRTUAL_ENV/bin/pip install --prefer-binary --requirement /build/extra-requirements.txt --constraint /build/odoo-requirements.txt
# Install odoo tests requirements
RUN --mount=type=bind,src=build/test-requirements.txt,dst=/build/test-requirements.txt \
    --mount=type=cache,target=/root/.cache/pip \
    $VIRTUAL_ENV/bin/pip install --prefer-binary --requirement /build/test-requirements.txt --constraint /build/odoo-requirements.txt
# Install image requirements
RUN --mount=type=bind,src=build/requirements.txt,dst=/build/requirements.txt \
    --mount=type=cache,target=/root/.cache/pip \
    $VIRTUAL_ENV/bin/pip install --prefer-binary --requirement /build/requirements.txt --constraint /build/odoo-requirements.txt


# The runtime image
# -----------------
# We try to minimize layers as much as possible, to result in a smaller image.

FROM common AS odoo

# System environment variables
ENV LC_ALL=C.UTF-8
ENV GIT_AUTHOR_NAME=odoo
ENV GIT_COMMITTER_NAME=odoo
ENV EMAIL=odoo@localhost

# Very likely, this layer is shared among builds of same distribution
ARG PYTHON_VERSION
ARG DISTRIBUTION
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG WKHTMLTOPDF_VERSION
RUN --mount=type=bind,src=build/install/${DISTRIBUTION},dst=/build/install,rw \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get -qq update \
    # Install all apt packages from all the *.packages files, ignoring comments and empty lines
    && find build/install -name "*.packages" -type f -exec grep -h -v -e '^#' -e '^$' {} + | xargs apt-get install -yqq --no-install-recommends \
    # Run the install scripts
    && chmod +x /build/install/*.sh \
    && /build/install/wkhtmltopdf-${WKHTMLTOPDF_VERSION}.sh \
    && /build/install/postgres-client.sh \
    # Cleanup
    && rm -rf /tmp/* \
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
ARG ODOO_VERSION
ENV ODOO_VERSION=$ODOO_VERSION
ENV ODOO_RC=/home/odoo/.odoorc

# Add odoo user and directories
RUN useradd -md /home/odoo -s /bin/false odoo \
    && mkdir -p $REPOSITORIES \
    && mkdir -p $DATA_DIR \
    && mkdir -p $RESOURCES \
    && chown -R odoo:odoo /home/odoo \
    && sync

# Copy the virtual environment
ENV VIRTUAL_ENV=/home/odoo/venv
COPY --from=python-deps --chown=odoo:odoo $VIRTUAL_ENV $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN echo "export \"PATH=${VIRTUAL_ENV}/bin:\$PATH\"" >> /etc/profile

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
