#!/bin/sh
#
#   imports single github globi data repository and check whether it can be read by GloBI.
#
#   usage:
#     check-dataset.sh [github repo name] 
# 
#   example:
#      ./check-dataset.sh globalbioticinteractions/template-dataset

function download_jar() {
    local NAME=$1
    local JAR_VERSION=$2
    export URL_PREFIX="https://depot.globalbioticinteractions.org/release/org/globalbioticinteractions/${NAME}/${VERSION}/${NAME}-${VERSION}"
    wget ${URL_PREFIX}-jar-with-dependencies.jar -O ${NAME}.jar
}

export REPO_NAME=$1

export NOMER_VERSION=0.0.3
export ELTON_VERSION=0.4.2

download_jar nomer ${NOMER_VERSION}
download_jar elton ${ELTON_VERSION}


export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export JAVA=${JAVA_HOME}/jre/bin/java

echo Checking [${REPO_NAME}] readability using Elton version [${ELTON_VERSION}].
${JAVA} -jar elton.jar update ${REPO_NAME}
${JAVA} -jar elton.jar check --offline ${REPO_NAME}

echo Checking names of [${REPO_NAME}] using Nomer version [${NOMER_VERSION}]. 
${JAVA} -jar elton.jar names ${REPO_NAME} | sort | uniq | ${JAVA} -jar nomer.jar append globi-globalnames | tee names.tsv

echo number of unmatched names
cat names.tsv | grep NONE | sort | uniq > names_unmatched.tsv
echo first 10 unmatched names
head -n 10 names_unmatched.tsv

echo number of unique names
cat names.tsv | grep -v NONE | sort | uniq > names_unique.tsv
echo first 10 unique names
head -n 10 names_unique.tsv
