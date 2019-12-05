#!/bin/bash
set -e

echo "Running entrypoint.d..."
$RESOURCES/entrypoint

echo "Running command... $@"
case "$1" in
    --)
        shift
        exec $ODOO_SERVER "$@"
        ;;
    -*)
        exec $ODOO_SERVER "$@"
        ;;
    *)
        exec "$@"
esac
