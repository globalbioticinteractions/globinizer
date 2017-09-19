#!/bin/sh
#
#   imports single github globi data repository and check whether it can be read by GloBI.
#
#   usage:
#     check-dataset.sh [github repo name] 
# 
#   example:
#      ./check-dataset.sh globalbioticinteractions/template-dataset

export REPO_NAME=$1
export ELTON_VERSION=0.3.5
export ELTON_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"

echo Checking [${ELTON_DATA_REPO_MASTER}] using Elton version [${ELTON_VERSION}]. 

export URL_PREFIX="http://depot.globalbioticinteractions.org/release/org/globalbioticinteractions/elton/${ELTON_VERSION}/elton-${ELTON_VERSION}"

# poke jitpack to build if one is not available yet
wget ${URL_PREFIX}-jar-with-dependencies.jar -O elton.jar

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
${JAVA_HOME}/jre/bin/java -jar elton.jar check ${REPO_NAME}
