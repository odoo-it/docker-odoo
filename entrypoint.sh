#!/bin/bash
set -e

echo "Preparing environment..."
run-parts --exit-on-error --report $RESOURCES/entrypoint.d

echo "Running command: $@"
case "$1" in
    # Simulate a login shell
    bash)
        exec bash -l -c "$@"
        ;;
    # Launch Odoo passing through the provided arguments
    --)
        shift
        exec odoo "$@"
        ;;
    -*)
        exec odoo "$@"
        ;;
    # Run the provided command
    *)
        exec "$@"
esac
