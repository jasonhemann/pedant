#!/usr/bin/env bash

set -o errexit
set -o nounset
set -eu -o pipefail

SCRIPT_DIR=$(cd `dirname $0` && pwd)

CURL_GIT_REPO="https://github.com/curl/curl.git"
CURL_INSTALL="${SCRIPT_DIR}/.curl_trash/"

GIT_INSTALL="${SCRIPT_DIR}/.git_trash/"
GIT_GIT_REPO="git://git.kernel.org/pub/scm/git/git.git"
GIT_EXEC_LOC="${HOME}/.local/bin/"

DICTION_VERSION="1.11"
DICTION_SOURCE="https://ftp.gnu.org/gnu/diction/"
DICTION_INSTALL="${SCRIPT_DIR}/.diction_trash/"
DICTION_FILE="diction-${DICTION_VERSION}"

VCPKG_GIT_REPO="https://github.com/microsoft/vcpkg"
VCPKG_INSTALL="${SCRIPT_DIR}/.vcpkg_trash/"

ENCHAT2_GIT_REPO="https://github.com/AbiWord/enchant.git"
ENCHANT2_INSTALL="${SCRIPT_DIR}/.enchant-2_trash/"

VALE_VERSION="2.10.3" 
VALE_SOURCE="https://github.com/errata-ai/vale/releases/download/v${VALE_VERSION}/" 
VALE_INSTALL="${SCRIPT_DIR}/.vale_trash/" 
VALE_FILE="vale_${VALE_VERSION}_Linux_64-bit" 
VALE_EXEC_LOC="${HOME}/.local/bin/"
VALE_STYLE_DIR_LOC="${HOME}"
VALE_STYLE_DIR_NAME="./styles/"

NPM_INSTALL_DIR="${HOME}/.local/"
RETEXT_INSTALL_DIR="${HOME}/grammar/"

ESPEAK_NG_VERSION="1.5"
ESPEAK_SOURCE="https://github.com/espeak-ng/espeak-ng/releases/download/${ESPEAK_NG_VERSION}/"
ESPEAK_NG_INSTALL="${SCRIPT_DIR}/.espeak-ng_trash/"
ESPEAK_FILE="espeak-ng-${VALE_VERSION}.tgz"
ESPEAK_DIR="espeak-ng"

ANORAK_INSTALL="${SCRIPT_DIR}/.anorak_trash/"

echo "Ensure that ~/.local/ subdirectories are on your path!"
echo "PATH=~/.local/bin/:~/.local/etc/:~/.local/include/:~/.local/lib/:~/.local/libexec/:~/.local/share/:$PATH"

# https://www.gnu.org/software/libtool/manual/html_node/Invoking-libtoolize.html
# LIBTOOLIZE, and the LTLIBRARIES 
# autoreconf -fi

if (test ! -x $(${GIT_EXEC_LOC}/git)) # &&  --version
then
    git clone ${GIT_GIT_REPO} ${GIT_INSTALL}
    pushd ${GIT_INSTALL}
    git checkout "$(git describe --tags --abbrev=0)" # not the most recent but this will do.
    libtoolize -i -f 
    HOME=${HOME}/.local/ NO_TCLTK=true make 
    HOME=${HOME}/.local/ NO_CURL=true NO_TCLTK=true make install
fi     

if (test ! -x "$(which vcpkg)")
then
    echo "Downloading vcpkg, for easy nuspell installation"
    git clone ${VCPKG_GIT_REPO} ${VCPKG_INSTALL}
    pushd ${VCPKG_INSTALL}
    ./bootstrap-vcpkg.sh
    ./vcpkg install curl
    pushd ${GIT_INSTALL}
    PATH=${VCPKG_INSTALL}/installed/x64-linux/share/:$PATH HOME=${HOME}/.local/ NO_TCLTK=true make
    PATH=${VCPKG_INSTALL}/installed/x64-linux/share/:$PATH HOME=${HOME}/.local/ NO_TCLTK=true make install
    pushd ${VCPKG_INSTALL}
    # ./vcpkg install nuspell # Currently breaks, perhaps vcpkg bug
fi
    
if (test ! -x "$(which style)") && (test ! -x "$(which diction)")
then
    echo "Downloading GNU style and diction"
    wget -P ${DICTION_INSTALL} ${DICTION_SOURCE}/${DICTION_FILE}.tar.gz
    tar -xvzf ${DICTION_INSTALL}/${DICTION_FILE}.tar.gz -C ${DICTION_INSTALL}
    pushd ${DICTION_INSTALL}/${DICTION_FILE} 
    ./configure prefix=${HOME}/.local/
    make 
    make install 
fi

# Waiting on nuspell to finish setup for enchant-2
# Might need nuspell by itself on the command line.
if (test ! -x "$(which enchant-2)")
then
    echo "Downloading Enchant 2"
    git clone ${ENCHAT2_GIT_REPO} ${ENCHANT2_INSTALL}
    pushd ${ENCHANT2_INSTALL}
    git checkout "$(git describe --tags --abbrev=0)" # not the most recent but this will do.
    ./bootstrap
    ./configure --prefix=${HOME}/.local/ --exec-prefix=${HOME}/.local/ --enable-relocatable
    make 
    make install 
fi

return 1

# https://github.com/errata-ai/vale.git
if (test ! -x "$(which vale)") && (test ! -d "${VALE_STYLE_DIR_PATH}/{VALE_STYLE_DIR_NAME}")
then
    echo "Downloading vale"
    git clone https://github.com/errata-ai/vale.git ${VALE_INSTALL}
#    wget -P ${VALE_INSTALL} ${VALE_SOURCE}/${VALE_FILE}.tar.gz
    tar -xvzf ${VALE_INSTALL}/${VALE_FILE}.tar.gz -C ${VALE_EXEC_LOC}
    pushd ${VALE_STYLE_DIR_PATH}
    echo "Downloading directory of styles" 
    git clone https://github.com/errata-ai/styles.git ${VALE_INSTALL}
    echo "We must now extract all styles to the right location"
    # 
fi

# https://www.gnu.org/software/libtool/manual/html_node/Invoking-libtoolize.html
# LIBTOOLIZE, and the LTLIBRARIES 
# autoreconf -fi
if (test ! -x "$(which espeak-ng)")
then
    echo "Downloading espeak for anorack"
    wget -P ${ESPEAK_NG_INSTALL} ${ESPEAK_SOURCE}/${ESPEAK_FILE}
    tar -xvzf ${ESPEAK_SOURCE}/${ESPEAK_FILE} -C ${ESPEAK_INSTALL}
    echo "Double check that this installed to ~/.local/lib/, rather than ~/local/lib/"
    ./autogen.sh
    ./autogen.sh
    ./configure --prefix=${HOME}/.local/
    # To work around a bug I found in the Makefile, just kill this line of config
    # Hella brittle hack!!
    sed -i '2417s/.*/\#\#\#\#\#/'
    make
    make install
fi

if (test ! -x "$(which retext)")
then
    echo "Installing retext node files, should have a directory"
    if (test ! -d ${NPM_INSTALL_DIR})
    then
	mkdir ${NPM_INSTALL_DIR}
    fi
    # babel-preset-es2015 babel-preset-env
    scl enable rh-nodejs12 npm install --prefix ${NPM_INSTALL_DIR} npx nspell babel-cli minimist dictionary-en \
	to-vfile unified vfile-reporter babel-preset-env retext-stringify retext-spell retext-readability \
	retext-indefinite-article retext-english retext-passive retext-repeated-words retext-simplify -g # write-good not needed b/c vale
    ${NPM_INSTALL_DIR}/bin/babel --presets=env ${NPM_INSTALL_DIR}/lib/node_modules/to-vfile/ --out-dir ${NPM_INSTALL_DIR}/lib/node_modules/to-vfile/
    ${NPM_INSTALL_DIR}/bin/babel --presets=env ${NPM_INSTALL_DIR}/lib/node_modules/vfile-reporter/ --out-dir ${NPM_INSTALL_DIR}/lib/node_modules/vfile-reporter/
    SCRIPT_DIR=$(cd `dirname $0` && pwd)
    if (test ! -d ${RETEXT_INSTALL_DIR})
    then
	mkdir ${RETEXT_INSTALL_DIR}
    fi
    cp ${SCRIPT_DIR}/retext-grammar.js ${RETEXT_INSTALL_DIR}
fi

if (test ! -x "$(which anorack)")
then
    echo "Downloading anorack"
    git clone https://github.com/jwilk/anorack  ${ANORAK_INSTALL}
    pushd ${ANORAK_INSTALL}
    ./configure
    make 
    make install prefix=${HOME}/.local/ exec-prefix=${HOME}
fi

