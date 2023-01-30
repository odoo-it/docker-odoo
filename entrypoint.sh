#!/bin/bash
set -e

echo "Preparing environment..."
run-parts --exit-on-error --report $RESOURCES/entrypoint.d

echo "Running command: $@"
case "$1" in
    --)
        shift
        exec odoo "$@"
        ;;
    -*)
        exec odoo "$@"
        ;;
    *)
        exec "$@"
esac
