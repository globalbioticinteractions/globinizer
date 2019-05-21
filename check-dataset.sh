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

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export JAVA=${JAVA_HOME}/jre/bin/java
export REPO_NAME=$1
export ELTON_VERSION=0.5.9
export ELTON_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"

echo Checking [${ELTON_DATA_REPO_MASTER}] using Elton version [${ELTON_VERSION}]. 

export URL_PREFIX="https://github.com/globalbioticinteractions/elton/releases/download/${ELTON_VERSION}"

wget ${URL_PREFIX}/elton.jar -O elton.jar

$JAVA -Xmx1G -jar elton.jar check
