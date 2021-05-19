#!/usr/bin/env bash

SCRIPT_DIR="${HOME}/grammar/"

set -o errexit
set -o nounset
set -eu -o pipefail
echo $NODE_PATH
diction -L en -s -b $1
style -L en $1
# enchant-2 -l -L $1 Waiting on nupell, waiting on ms installer waiting on c++
NODE_PATH=${NODE_PATH}:~/.local/lib/node_modules/ node ${SCRIPT_DIR}/retext-grammar.js -a $1 
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:~/.local/lib/ anorack $1
#vale vale.ini $1 #rn missing good vale.ini w/scripts subdir

~/Documents/grammar/retext-grammar.js ~/testnode
