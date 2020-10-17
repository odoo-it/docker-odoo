#!/bin/bash
set -e

echo "Preparing environment..."
$RESOURCES/entrypoint

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
