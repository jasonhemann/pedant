#!/usr/bin/env bash

set -o errexit
set -o nounset
set -eu -o pipefail

SCRIPT_DIR=$(cd `dirname $0` && pwd)
LOCAL_INSTALL_DIR="${HOME}/.local/"

GIT_INSTALL="${SCRIPT_DIR}/.git_trash/"
GIT_GIT_REPO="git://git.kernel.org/pub/scm/git/git.git"

DICTION_VERSION="1.11"
DICTION_SOURCE="https://ftp.gnu.org/gnu/diction/"
DICTION_INSTALL="${SCRIPT_DIR}/.diction_trash/"
DICTION_FILE="diction-${DICTION_VERSION}"

VCPKG_GIT_REPO="https://github.com/microsoft/vcpkg"
VCPKG_INSTALL="${SCRIPT_DIR}/.vcpkg_trash/"

ENCHAT2_GIT_REPO="https://github.com/AbiWord/enchant.git"
ENCHANT2_INSTALL="${SCRIPT_DIR}/.enchant-2_trash/"

VALE_GIT_REPO="https://github.com/errata-ai/vale.git"
VALE_INSTALL="${SCRIPT_DIR}/.vale_trash/" 
VALE_EXEC_LOC="${LOCAL_INSTALL_DIR}/bin/"

VALE_STYLE_GIT_REPO="https://github.com/errata-ai/styles.git"
VALE_STYLE_INSTALL="${SCRIPT_DIR}/.vale_style_trash/" 
VALE_STYLE_LOC="${LOCAL_INSTALL_DIR}/styles/"

VALE_VERSION="2.10.3" \ 
VALE_SOURCE="https://github.com/errata-ai/vale/releases/download/v${VALE_VERSION}/" \ 
VALE_FILE="vale_${VALE_VERSION}_Linux_64-bit"   

NPM_INSTALL_DIR=${LOCAL_INSTALL_DIR}
RETEXT_INSTALL_DIR="${LOCAL_INSTALL_DIR}/share/retext/lib/"

ESPEAK_NG_VERSION="1.5"
ESPEAK_GIT_REPO="https://github.com/espeak-ng/espeak-ng.git"
ESPEAK_SOURCE="https://github.com/espeak-ng/espeak-ng/releases/download/${ESPEAK_NG_VERSION}/"
ESPEAK_NG_INSTALL="${SCRIPT_DIR}/.espeak-ng_trash/"
ESPEAK_FILE="espeak-ng-${VALE_VERSION}.tgz"

ANORAK_GIT_REPO="https://github.com/jwilk/anorack"
ANORAK_INSTALL="${SCRIPT_DIR}/.anorak_trash/"

echo "Ensure that ~/.local/ subdirectories are on your path!"
echo "PATH=~/.local/bin/:~/.local/etc/:~/.local/include/:~/.local/lib/:~/.local/libexec/:~/.local/share/:$PATH"

if (test ! -x $(${GIT_EXEC_LOC}/git)) # && version check, but it's okay
then
    git clone ${GIT_GIT_REPO} ${GIT_INSTALL}
    pushd ${GIT_INSTALL}
    git checkout "$(git describe --tags --abbrev=0)" 
    libtoolize -i -f 
    HOME=${HOME}/.local/ NO_CURL=true NO_TCLTK=true make 
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
    CXX=g++ ./vcpkg install nuspell # It doesn't, however, seem to *give* me an ./bin/nuspell as e.g. aspell
fi
    
if (test ! -x "$(which style)") && (test ! -x "$(which diction)")
then
    echo "Downloading GNU style and diction"
    wget -P ${DICTION_INSTALL} ${DICTION_SOURCE}/${DICTION_FILE}.tar.gz
    tar -xvzf ${DICTION_INSTALL}/${DICTION_FILE}.tar.gz -C ${DICTION_INSTALL}
    pushd ${DICTION_INSTALL}/${DICTION_FILE} 
    ./configure prefix=${LOCAL_INSTALL_DIR}
    make 
    make install 
fi

# Waiting on nuspell to finish setup for enchant-2
if (test ! -x "$(which enchant-2)")
then
    echo "Downloading Enchant 2"
    git clone ${ENCHAT2_GIT_REPO} ${ENCHANT2_INSTALL}
    pushd ${ENCHANT2_INSTALL}
    git checkout "$(git describe --tags --abbrev=0)" # not the most recent but this will do.
    ./bootstrap
    ./configure --prefix=${LOCAL_INSTALL_DIR} --exec-prefix=${LOCAL_INSTALL_DIR} --enable-relocatable --with-nuspell
    make 
    make install 
fi

if (test ! -x "$(which vale)")
then
    echo "Downloading vale"
    # This strategy doesn't seem to work, so ...
    # git clone ${VALE_GIT_REPO} ${VALE_INSTALL}
    # pushd ${VALE_INSTALL}
    # make build os=linux
    # mv ./bin/* ${VALE_EXEC_LOC}
    # popd 
    wget -P ${VALE_INSTALL} ${VALE_SOURCE}/${VALE_FILE}.tar.gz 
    tar -xvzf ${VALE_INSTALL}/${VALE_FILE}.tar.gz -C ${VALE_EXEC_LOC}
fi

if (test ! -d "${VALE_STYLE_LOC}")
then    
    echo "Downloading directory of styles" 
    git clone ${VALE_STYLE_GIT_REPO} ${VALE_STYLE_INSTALL}
    pushd ${VALE_STYLE_INSTALL}
    echo "We must now extract all styles to the right location"
    # Some way to get these styles in the right structure to ${VALE_STYLE_LOC}
fi

return 1

if (test ! -x "$(which espeak-ng)")
then
    echo "Downloading espeak for anorack"
    git clone ${ESPEAK_GIT_REPO} ${ESPEAK_NG_INSTALL}
    pushd ${ESPEAK_NG_INSTALL}
    git checkout "$(git describe --tags --abbrev=0)" # not the most recent but this will do.
    autoreconf -fi
    ./configure --prefix=${LOCAL_INSTALL_DIR}
    # Makefile errors. Maybe b/c I'm missing Kramdown. 
    # https://github.com/espeak-ng/espeak-ng/issues/941
    # To work around that bug/limitation,
    # I just kill this line of config
    # Hella brittle hack!!
    sed -i '2417s/.*/\#\#\#\#\#/' Makefile
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
    npm install --prefix ${NPM_INSTALL_DIR} npx nspell minimist dictionary-en \
	to-vfile unified vfile-reporter babel-preset-env retext-stringify retext-spell retext-readability \
	retext-indefinite-article retext-english retext-passive retext-repeated-words retext-simplify # write-good not needed b/c vale
    npx babel-cli --presets=env ${NPM_INSTALL_DIR}/node_modules/to-vfile/ --out-dir ${NPM_INSTALL_DIR}/node_modules/to-vfile/
    npx babel-cli --presets=env ${NPM_INSTALL_DIR}/node_modules/vfile-reporter/index.js --out-file ${NPM_INSTALL_DIR}/node_modules/vfile-reporter/index.js
    if (test ! -d ${RETEXT_INSTALL_DIR})
    then
	mkdir ${RETEXT_INSTALL_DIR}
    fi
    cp ${SCRIPT_DIR}/retext-grammar.js ${RETEXT_INSTALL_DIR}
    # Should also create a bash script ./bin/retext
    # that will call ../shared/retext/lib/retext-grammar.js with the right cli args
fi

# Also somehow not working as expected/intended
if (test ! -x "$(which anorack)")
then
    echo "Downloading anorack"
    git clone ${ANORAK_GIT_REPO} ${ANORAK_INSTALL}
    pushd ${ANORAK_INSTALL}
    python3 -m pip install nose libcli # A dependency
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:~/.local/lib/ PREFIX="" DESTDIR="${HOME}/.local/" make -e
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:~/.local/lib/ PREFIX="" DESTDIR="${HOME}/.local/" make install -e

fi

