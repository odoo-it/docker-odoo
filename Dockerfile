ARG PYTHON_VERSION
ARG DISTRIBUTION
FROM python:$PYTHON_VERSION-slim-$DISTRIBUTION

# System environment variables
ENV GIT_AUTHOR_NAME     odoo
ENV GIT_COMMITTER_NAME  odoo
ENV EMAIL               odoo@localhost
ENV LC_ALL              C.UTF-8
ENV PIP_NO_CACHE_DIR    1
ENV PATH                /home/odoo/.local/bin:$PATH

# Very likely, this layer is shared among builds of same distribution
ARG PYTHON_VERSION
ARG DISTRIBUTION
ARG WKHTMLTOPDF_VERSION
COPY --chmod=700 build/install/${DISTRIBUTION} /build/install/${DISTRIBUTION}
RUN apt-get -qq update \
    && xargs -a /build/install/${DISTRIBUTION}/apt-requirements.txt apt-get install -yqq --no-install-recommends \
    && /build/install/${DISTRIBUTION}/wkhtmltopdf-${WKHTMLTOPDF_VERSION}.sh \
    && /build/install/${DISTRIBUTION}/postgres-client.sh \
    && rm -rf /var/lib/apt/lists/* /tmp/* \
    && rm -rf /build \
    && sync

# Install and build Odoo dependencies
ARG ODOO_VERSION=master
ARG ODOO_SOURCE=odoo/odoo
ADD https://raw.githubusercontent.com/$ODOO_SOURCE/$ODOO_VERSION/requirements.txt /build/odoo/requirements.txt
COPY --chmod=700 build/ /build/
RUN apt-get -qq update \
    && xargs -a /build/install/${DISTRIBUTION}/apt-build-deps.txt apt-get install -yqq --no-install-recommends \
    # Python Packages
    && pip install --no-cache-dir -r /build/odoo/requirements.txt \
    && pip install --no-cache-dir -r /build/requirements.txt \
    && (python3 -m compileall -q /usr/local/lib/python3*/ || true) \
    # Cleanup
    && xargs -a /build/install/${DISTRIBUTION}/apt-build-deps.txt apt-get purge -yqq \
    && apt-get autopurge -yqq \
    && rm -rf /var/lib/apt/lists/* /tmp/* \
    && rm -rf /build \
    && sync

# Create directory structure
ENV SOURCES             /home/odoo/src
ENV REPOSITORIES        $SOURCES/repositories
ENV DATA_DIR            /home/odoo/data
ENV CONFIG_DIR          /home/odoo/.config
ENV RESOURCES           /home/odoo/.resources

# Config env
ENV ODOO_VERSION        $ODOO_VERSION
ENV OPENERP_SERVER      $CONFIG_DIR/odoo.conf
ENV ODOO_RC             $OPENERP_SERVER

# Add odoo user and directories
RUN useradd -md /home/odoo -s /bin/false odoo \
    && mkdir -p $REPOSITORIES \
    && mkdir -p $DATA_DIR \
    && mkdir -p $CONFIG_DIR \
    && mkdir -p $RESOURCES \
    && chown -R odoo.odoo /home/odoo \
    && sync

# Entrypoint scripts
COPY --chmod=777 bin/* /usr/local/bin/
COPY --chown=odoo.odoo --chmod=777 conf.d $RESOURCES/conf.d
COPY --chown=odoo.odoo --chmod=777 entrypoint.d $RESOURCES/entrypoint.d
COPY --chown=odoo.odoo --chmod=777 entrypoint.sh $RESOURCES/entrypoint.sh
RUN ln /usr/local/bin/direxec $RESOURCES/entrypoint

# Docker
EXPOSE 8069 8072
VOLUME "/home/odoo/data"
WORKDIR "/home/odoo"
ENTRYPOINT ["/home/odoo/.resources/entrypoint.sh"]
CMD "odoo"
USER odoo
