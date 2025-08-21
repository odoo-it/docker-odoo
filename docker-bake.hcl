variable "REGISTRY" {
    default = "ghcr.io/odoo-it/docker-odoo"
}

variable "VERSION" {
    default = "18.0"
}

variable "LOCAL_GEOIP_PATH" {
    default = "."
}

function "version2target" {
    params = [string]
    result = trimsuffix(string, ".0")
}

group "default" {
    targets = ["${version2target(VERSION)}"]
}

group "all" {
    targets = ["master"]
}

target "_local" {
    tags = ["${REGISTRY}:${VERSION}"]
}

target "docker-metadata-action" {
}

target "_common" {
    inherits = ["_local", "docker-metadata-action"]
    target = "odoo"
    args = {
        LOCAL_GEOIP_PATH = LOCAL_GEOIP_PATH
    }
}

target "12" {
    inherits = ["_common"]
    platforms = ["linux/amd64"]
    args = {
        ODOO_VERSION="12.0"
        DISTRIBUTION="buster"
        PYTHON_VERSION="3.7"
        WKHTMLTOPDF_VERSION="0.12.5"
    }
}

target "13" {
    inherits = ["_common"]
    platforms = ["linux/amd64"]
    args = {
        ODOO_VERSION="13.0"
        DISTRIBUTION="buster"
        PYTHON_VERSION="3.7"
        WKHTMLTOPDF_VERSION="0.12.5"
    }
}

target "14" {
    inherits = ["_common"]
    platforms = ["linux/amd64"]
    args = {
        ODOO_VERSION="14.0"
        DISTRIBUTION="buster"
        PYTHON_VERSION="3.10"
        WKHTMLTOPDF_VERSION="0.12.5"
    }
}

target "15" {
    inherits = ["_common"]
    platforms = ["linux/amd64"]
    args = {
        ODOO_VERSION="15.0"
        DISTRIBUTION="bullseye"
        PYTHON_VERSION="3.10"
        WKHTMLTOPDF_VERSION="0.12.5"
    }
}

target "16" {
    inherits = ["_common"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        ODOO_VERSION="16.0"
        DISTRIBUTION="bookworm"
        PYTHON_VERSION="3.10"
        WKHTMLTOPDF_VERSION="0.12.6"
    }
}

target "17" {
    inherits = ["_common"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        ODOO_VERSION="17.0"
        DISTRIBUTION="bookworm"
        PYTHON_VERSION="3.12"
        WKHTMLTOPDF_VERSION="0.12.6"
    }
}

target "18" {
    inherits = ["_common"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        ODOO_VERSION="18.0"
        DISTRIBUTION="bookworm"
        PYTHON_VERSION="3.12"
        WKHTMLTOPDF_VERSION="0.12.6"
    }
}

target "master" {
    inherits = ["_common"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        ODOO_VERSION="master"
        DISTRIBUTION="bookworm"
        PYTHON_VERSION="3.12"
        WKHTMLTOPDF_VERSION="0.12.6"
    }
}
