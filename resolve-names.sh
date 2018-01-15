#!/bin/sh
#
#   imports single github globi data repository and check whether it can be read by GloBI.
#
#   usage:
#     check-dataset.sh [github repo name] 
# 
#   example:
#      ./check-dataset.sh globalbioticinteractions/template-dataset

. ./check-dataset.sh

export REPO_NAME=$1
export NOMER_VERSION=0.0.3
export NOMER_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"

echo Checking names of [${NOMER_DATA_REPO_MASTER}] using Nomer version [${NOMER_VERSION}]. 

export URL_PREFIX="http://depot.globalbioticinteractions.org/release/org/globalbioticinteractions/nomer/${NOMER_VERSION}/nomer-${NOMER_VERSION}"

wget ${URL_PREFIX}-jar-with-dependencies.jar -O nomer.jar

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export JAVA=${JAVA_HOME}/jre/bin/java
${JAVA} -jar elton update ${REPO_NAME}
${JAVA} -jar elton names ${REPO_NAME} | ${JAVA} -jar nomer.jar append globi-globalnames | tee names.tsv

echo unmatched names
cat names.tsv | grep NONE | sort | uniq

echo number of unique names
cat names.tsv | grep -v NONE | sort | uniq | wc -l
