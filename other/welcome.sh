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
echo "You are running $(tput setaf 3)Odoo $ODOO_VERSION$(tput sgr0) connected to $(tput setaf 3)$PGDATABASE$(tput sgr0)."
