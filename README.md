# Docker Odoo

## Image usage

Basically, every directory you have to worry about is found inside `/home/odoo`.
The directory structure is similar to [odoo.sh](odoo.sh), but not exactly the
same. This is the structure:

    custom/
        repositories/
    src/
        odoo/
        enterprise/
        repositories/
    data/
        addons/
        filestore/
        sessions/
    .config/
        odoo.conf
    .resources/
        build.d/
        conf.d/
        entrypoint.d/
        repos.d/
        requirements/
            build_deps.txt
            apt.txt
            pip.txt

| Path                      | Description                                                                                                   |
| ------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `custom/repositories`     | Repositories cloned here are loaded with higher priority. Usefull for local development.                      |
| `src/odoo`                | Odoo source code. Installed automatically if `INCLUDE_ODOO`.                                                  |
| `src/enterprise`          | Odoo enterprise code. Installed automatically if `INCLUDE_ENTERPRISE`.                                        |
| `src/repositories`        | Project repositories. They are automatically aggregated from `repos.d`.                                       |
| `data/`                   | Odoo data directory. You usually want to persist it.                                                          |
| `.config/odoo.conf`       | Odoo configuration file. Generated automatically from `conf.d`.                                               |
| `.resources/build.d`      | Image build scripts. They run in alphabetical order ON BUILD.                                                 |
| `.resources/conf.d`       | Files here will be environment-variable-expanded and concatenated in `odoo.conf` in the entrypoint.           |
| `.resources/entrypoint.d` | Any executables found here will be run when you launch your container.                                        |
| `.resources/repos.d`      | All repositories files in this directory will be aggregated ON BUILD by git-aggregator in `src/repositories`. |
| `.resources/requirements` | Image dependencies declarations. They're installed ON BUILD.                                                  |

## Runtime environment variables

The following variables can customize entrypoint behaviour and `odoo.conf`:

### Odoo Configuration

#### Database

-   `PGHOST`
-   `PGPORT`
-   `PGDATABASE`
-   `PGUSER`
-   `PGPASSWORD`
-   `PROXY_MODE`

#### SMTP

-   `SMTP_SERVER`
-   `SMTP_PORT`
-   `SMTP_USER`
-   `SMTP_PASSWORD`
-   `SMTP_SSL`
-   `EMAIL_FROM`

#### Performance

-   `WORKERS`
-   `MAX_CRON_THREADS`
-   `DB_MAXCONN`
-   `LIMIT_MEMORY_HARD`
-   `LIMIT_MEMORY_SOFT`
-   `LIMIT_TIME_CPU`
-   `LIMIT_TIME_REAL`
-   `LIMIT_TIME_REAL_CRON`

#### Other

-   `UNACCENT`
-   `ADMIN_PASSWORD`
-   `LOG_LEVEL`
-   `SERVER_WIDE_MODULES`

### Entrypoint

-   `CUSTOM_CONFIG`: Custom configuration to be added to `odoo.conf`.
-   `CUSTOM_REPOSITORIES`: Custom git-aggregator yaml, repositories will be aggregated at runtime.
-   `CUSTOM_REQUIREMENTS`: Custom pip requirements.txt, to be installed at runtime.
-   `CUSTOM_ENTRYPOINT`: Custom script to be executed at runtime.
-   `AUTO_UPDATE_MODULES`: Run `click-odoo-update` to automatically update addons.

## Configuration

The following ON BUILD arguments are available to customize some behaviours:

-   `ODOO_SOURCE` (default: `odoo/odoo`)
-   `ODOO_SOURCE_DEPTH` (default: `1`)
-   `INSTALL_ODOO` (default: `false`)
-   `INSTALL_ENTERPRISE` (default: `false`)
-   `GITHUB_USER`: Required if `INSTALL_ENTERPRISE`
-   `GITHUB_TOKEN`: Required if `INSTALL_ENTERPRISE`

For convenience, the following arguments are available when building this image:

-   `BUILD_TAG_BASE`: besides building the -onbuild image, will also build a tag without onbuild.
-   `BUILD_TAG_COMMUNITY`: besides building the -onbuild image, will also build a tag containing Odoo CE.
-   `BUILD_TAG_ENTERPRISE`: besides building the -onbuild image, will also build a tag containing Odoo EE.
