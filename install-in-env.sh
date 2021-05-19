#!/usr/bin/env bash 

SCRIPT_DIR=$(cd `dirname $0` && pwd)

scl enable devassist09 devtoolset-8 rh-nodejs12 rh-ruby23 ${SCRIPT_DIR}/install.sh


