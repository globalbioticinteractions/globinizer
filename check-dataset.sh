#!/bin/bash
#
#   imports single github globi data repository and check whether it can be read by GloBI.
#
#   usage:
#     check-dataset.sh [github repo name] 
# 
#   example:
#      ./check-dataset.sh globalbioticinteractions/template-dataset
set -e
set -x

export REPO_NAME=$1
export ELTON_VERSION=0.5.4
export ELTON_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"

echo Checking [${ELTON_DATA_REPO_MASTER}] using Elton version [${ELTON_VERSION}]. 

export URL_PREFIX="http://depot.globalbioticinteractions.org/release/org/globalbioticinteractions/elton/${ELTON_VERSION}/elton-${ELTON_VERSION}"

wget ${URL_PREFIX}-jar-with-dependencies.jar -O elton

chmod +x elton

./elton check
