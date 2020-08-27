#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

patch < "$DIR/config.patch"
sed -i 's/^\(CONFIG_LOCALVERSION="[^"]*\)"$/\1-asl"/g' .config
