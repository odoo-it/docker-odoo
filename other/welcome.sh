#!/bin/bash

# Banner
tput setaf 5
cat << "EOF"
 __        __   _                             _            ___      _
 \ \      / /__| | ___ ___  _ __ ___   ___   | |_ ___     / _ \  __| | ___   ___
  \ \ /\ / / _ \ |/ __/ _ \| '_ ` _ \ / _ \  | __/ _ \   | | | |/ _` |/ _ \ / _ \
   \ V  V /  __/ | (_| (_) | | | | | |  __/  | || (_) |  | |_| | (_| | (_) | (_) |
    \_/\_/ \___|_|\___\___/|_| |_| |_|\___|   \__\___/    \___/ \__,_|\___/ \___/
EOF
tput sgr0

# Print Odoo version and database information
echo ""
echo "You are running Odoo $(tput setaf 3)$ODOO_VERSION$(tput sgr0) connected to $(tput setaf 3)$PGDATABASE$(tput sgr0)."
echo "The configuration file is $(tput setaf 3)$ODOO_RC$(tput sgr0), generated from $(tput setaf 3)$RESOURCES/conf.d$(tput sgr0)."

# Print some useful commands
echo ""
echo "Here are some useful commands:"
echo "  $(tput setaf 6)odoo$(tput sgr0): Launch Odoo"
echo "  $(tput setaf 6)psql$(tput sgr0): Connect to the database"
