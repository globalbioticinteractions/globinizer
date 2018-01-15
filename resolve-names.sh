#!/bin/sh
#
#   imports single github globi data repository and check whether it can be read by GloBI.
#
#   usage:
#     check-dataset.sh [github repo name] 
# 
#   example:
#      ./check-dataset.sh globalbioticinteractions/template-dataset

download_jar() {
    NAME=$1
    VERSION=$2
    URL_PREFIX="https://depot.globalbioticinteractions.org/release/org/globalbioticinteractions/${NAME}/${VERSION}/${NAME}-${VERSION}"
    wget ${URL_PREFIX}-jar-with-dependencies.jar -O ${NAME}.jar
}

REPO_NAME=$1

NOMER_VERSION="0.0.3"
ELTON_VERSION="0.4.2"

download_jar nomer ${NOMER_VERSION}
download_jar elton ${ELTON_VERSION}


JAVA_HOME=/usr/lib/jvm/java-8-oracle
JAVA=${JAVA_HOME}/jre/bin/java

echo Checking [${REPO_NAME}] readability using Elton version [${ELTON_VERSION}].
${JAVA} -jar elton.jar update ${REPO_NAME}
${JAVA} -jar elton.jar check --offline ${REPO_NAME}

echo Checking names of [${REPO_NAME}] using Nomer version [${NOMER_VERSION}]. 
${JAVA} -jar elton.jar names ${REPO_NAME} | awk -F '\t' '{ print $1 "\t" $2 }' | sort | uniq | ${JAVA} -jar nomer.jar append globi-globalnames > names.tsv

echo number of unmatched names
cat names.tsv | grep NONE | sort | uniq > names_unmatched.tsv
cat names_unmatched.tsv | wc -l
echo first 10 unmatched names
head -n 10 names_unmatched.tsv

echo number of unique names
cat names.tsv | grep -v NONE | sort | uniq > names_unique.tsv
cat names_unique.tsv | wc -l
echo first 10 unique names
head -n 10 names_unique.tsv
