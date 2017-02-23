#!/bin/sh
#
#   imports single github globi data repository and attempts to resolve names.
#
#   usage:
#     check-dataset.sh [github repo name] 
# 
#   example:
#      ./check-dataset.sh globalbioticinteractions/template-dataset

export REPO_NAME=$1
#export GLOBI_VERSION=`curl -s https://api.github.com/repos/jhpoelen/eol-globi-data/releases/latest | grep -o '[0-9]\.[0-9]\.[0-9]' | head -n 1`
export GLOBI_VERSION=0.8.13
export GLOBI_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"

echo Checking [${GLOBI_DATA_REPO_MASTER}] using GloBI tools version [${GLOBI_VERSION}]. 

wget http://globi.s3.amazonaws.com/release/org/eol/eol-globi-data-tool/${GLOBI_VERSION}/eol-globi-data-tool-${GLOBI_VERSION}-jar-with-dependencies.jar -O globi-tool.jar

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
${JAVA_HOME}/jre/bin/java -cp globi-tool.jar org.eol.globi.tool.GitHubRepoCheck ${REPO_NAME} ${GLOBI_DATA_REPO_MASTER}
