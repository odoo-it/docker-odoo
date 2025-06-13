[![ci](https://github.com/odoo-it/docker-odoo/actions/workflows/ci.yaml/badge.svg?branch=master&event=push)](https://github.com/odoo-it/docker-odoo/actions/workflows/ci.yaml)

# Docker Odoo

A docker image ready to run Odoo, either for dev or prod deployments, that doesn't
contain odoo.

## Usage

### Getting started

This image is prepared to run Odoo, but it doesn't include it. You're expected to cook an image for your project and include whatever Odoo fork you want in it. This gives you a lot of freedom to use this image however you want.

As an example, assuming you have a local Odoo fork in `./src` and your project addons repositories in `./repositories`, you could create a project image like this:

#### Dockerfile

```Docker
FROM ghcr.io/odoo-it/docker-odoo:17.0.4.0.0 AS base

# Install project requirements
RUN --mount=type=bind,src=requirements.txt,dst=$RESOURCES/requirements.txt \
    --mount=type=cache,target=/home/odoo/.cache/pip \
    pip install -r $RESOURCES/requirements.txt

# Copy sources
COPY --chown=odoo:odoo odoo $SOURCES/
COPY --chown=odoo:odoo repositories $SOURCES/repositories
COPY --chown=odoo:odoo addons $SOURCES/addons
RUN pip-install-odoo
```

#### compose.yaml

```yaml
services:

  odoo:
    build:
      context: .
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8069:8069"
      - "8072:8072"
    tty: true
    stdin_open: true
    volumes:
      - ./odoo/odoo:/home/odoo/src/odoo:rw,z
      # - ./odoo/enterprise:/home/odoo/src/enterprise:rw,z
      # - ./odoo/design-themes:/home/odoo/src/design-themes:rw,z
      - ./repositories:/home/odoo/src/repositories:rw,z
      - ./addons:/home/odoo/src/addons:rw,z
      - ./user:/home/odoo/src/user:rw,z
      - filestore:/home/odoo/data
    environment:
      PGHOST: db
      PGDATABASE: odoodb

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: odoo
      POSTGRES_DB: postgres
    volumes:
      - db:/var/lib/postgresql/data
    healthcheck:
      test: [ "CMD", "pg_isready", "-q", "-h", "localhost" ]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  db:
  filestore:
```

### Versions

| Tag | Description | Example |
| --- | --- | --- |
| `<odoo>` | Targets the latest release for this Odoo version | `17.0`, `16.0`, `master` |
| `<odoo>.<release>` | Targets a specific release for an Odoo version | `17.0.3.0.0` |
| `<odoo>-latest` | Targets the latest unreleased/unstable version for this Odoo version | `17.0-latest` |
| `<odoo>-<sha>` | Targets the a specific commit for this Odoo version | `17.0-a1bsz6` |

### Directory structure

Basically, every directory you have to worry about is found inside `/home/odoo`.
The directory structure is similar to [odoo.sh](odoo.sh), but not exactly the
same. This is the structure:

    src/
        odoo/
        repositories/
        user/
    data/
        addons/
        filestore/
        sessions/
    .resources/
        conf.d/
        entrypoint.d/
    .odoorc

| Path                      | Description                                                                                                   |
| ------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `src/odoo`                | Empty. Path where odoo source code is expected to be.                                                         |
| `src/enterprise`          | Optional. Path where odoo enterprise modules are expected to be.                                              |
| `src/design-themes`       | Optional. Path where odoo design themes are expected to be.                                                   |
| `src/user`                | Optional. Addons paths will be discovered recursively in this directory.                                      |
| `src/addons`              | Optional. Addons paths will be discovered recursively in this directory.                                      |
| `src/repositories`        | Optional. Addons paths will be discovered recursively in this directory.                                      |
| `data/`                   | Odoo data directory. You usually want to persist it.                                                          |
| `.resources/conf.d`       | Files here will be environment-variable-expanded and concatenated in the config file, during the entrypoint.  |
| `.resources/entrypoint.d` | Any executables found here will be run when you launch your container.                                        |
| `.odoorc`                 | Odoo configuration file. Generated automatically from `conf.d`.                                               |

### Runtime environment variables

The following variables can customize entrypoint behaviour and odoo configuration:

#### Odoo Configuration

##### Database

-   `PGHOST`
-   `PGPORT`
-   `PGDATABASE`
-   `PGUSER`
-   `PGPASSWORD`

##### SMTP

-   `SMTP_SERVER`
-   `SMTP_PORT`
-   `SMTP_USER`
-   `SMTP_PASSWORD`
-   `SMTP_SSL`
-   `EMAIL_FROM`

##### Performance

-   `WORKERS`
-   `MAX_CRON_THREADS`
-   `DB_MAXCONN`
-   `LIMIT_MEMORY_HARD`
-   `LIMIT_MEMORY_SOFT`
-   `LIMIT_TIME_CPU`
-   `LIMIT_TIME_REAL`
-   `LIMIT_TIME_REAL_CRON`

##### Proxy

-   `PROXY_MODE`
-   `ODOO_X_SENDFILE`

##### Other

-   `ADMIN_PASSWORD`
-   `UNACCENT`
-   `LOG_LEVEL`
-   `SERVER_WIDE_MODULES`

#### Entrypoint

-   `ODOO_ADDONS_DISCOVERY_PATHS`: Comma-separated list of paths to discover addons in. Defaults to `~/src/user,~/src/repositories`.
-   `AUTO_UPDATE_MODULES`: Run `click-odoo-update` to automatically update addons.
-   `PGTIMEOUT`: Seconds to wait for the postgres server to respond. Set to `0` to disable. (default: `10`)

## Development

### Build

This project uses [Bake](https://docs.docker.com/build/bake/) to build the different images.

The build configurations are defined in the `docker-bake.hcl` file.

Here are some useful commands:

| Command | Description |
| --- | --- |
| `docker buildx bake` | Build the default version |
| `VERSION=17.0 docker buildx bake` | Build the specified version (e.g: `17.0`, `master`, ...) |
| `VERSION=17.0 docker buildx bake --set="*.platform=linux/amd64"` | Build for amd64 arch only |

#### GeoIP

To include the GeoIP databases in the image, you can place the `GeoLite2-City.mmdb` and
`GeoLite2-Country.mmdb` files in the build directory and bake the image.

Alternatively, you can use the `LOCAL_GEOIP_PATH` argument to specify a path to the GeoIP
databases. However, keep in mind that the path must be relative to the build directory.
