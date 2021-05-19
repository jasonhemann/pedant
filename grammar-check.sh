#!/usr/bin/env bash

SCRIPT_DIR="${HOME}/.local/shared/retext/lib/"

set -o errexit
set -o nounset
set -eu -o pipefail

diction -L en -s -b $1
style -L en $1
# enchant-2 -l -L $1 Waiting on nupell, waiting on ms installer waiting on c++
# This should be it's own script

echo $NODE_PATH
NODE_PATH=${NODE_PATH}:~/.local/node_modules/ node ${SCRIPT_DIR}/retext-grammar.js -a $1 
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:~/.local/lib/ anorack $1
vale --version
# vale vale.ini $1 #rn missing good vale.ini w/scripts subdir
