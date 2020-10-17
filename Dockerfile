# Generic Dockerfile used to build the odoo included images
# We base this images on top of the onbuild tag.
# All the magic happens there, and in the build hook.

ARG DOCKER_REPO
ARG DOCKER_TAG
FROM $DOCKER_REPO:$DOCKER_TAG-onbuild AS odoo
