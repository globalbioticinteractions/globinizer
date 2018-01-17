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

NOMER_VERSION="0.0.4"
ELTON_VERSION="0.4.2"

download_jar nomer ${NOMER_VERSION}
download_jar elton ${ELTON_VERSION}

wget https://depot.globalbioticinteractions.org/datasets/org/globalbioticinteractions/taxon/0.1/taxon-0.1.zip -O taxon.zip
unzip taxon.zip

if [ -z $TRAVIS ]; then 
  JAVA_HOME=/usr/lib/jvm/java-8-oracle;
fi

JAVA=${JAVA_HOME}/jre/bin/java

ELTON="$JAVA -jar elton.jar"
echo Checking readability of [${REPO_NAME}] using Elton version [${ELTON_VERSION}].
$ELTON update ${REPO_NAME}
$ELTON check --offline ${REPO_NAME}

echo nomer.term.map.url=file://${PWD}/taxonMap.tsv.gz > nomer.properties
echo nomer.term.cache.url=file://${PWD}/taxonCache.tsv.gz >> nomer.properties

NOMER="${JAVA} -Xmx4G -jar nomer.jar append"

echo Checking names of [${REPO_NAME}] using Nomer version [${NOMER_VERSION}]. 
$ELTON names ${REPO_NAME} | awk -F '\t' '{ print $1 "\t" $2 }' | sort | uniq > names_orig.tsv

cat names_orig.tsv | $NOMER --properties nomer.properties globi-cache > names_map_cached.tsv

. ./create-taxon-cache-map.sh
create_taxon_cache_map names_map_cached.tsv

echo number of unmatched names
zcat taxonUnresolved.tsv.gz | awk -F '\t' '{ print $1 "\t" $2 }' | sort | uniq > names_unmatched.tsv
cat names_unmatched.tsv | wc -l
echo first 10 unmatched names
head -n 10 names_unmatched.tsv

echo number of unique names
cat names_orig.tsv | grep -v NONE | awk -F '\t' '{ print $5 }' | sort | uniq > names_unique.tsv
cat names_unique.tsv | wc -l
echo first 10 unique names
head -n 10 names_unique.tsv

echo taxonMap (first 10)
zcat taxonMap.tsv.gz | head -n 10
echo taxonCache (first 10)
zcat taxonCache.tsv.gz | head -n 10

echo taxonUnresolved (first 10)
zcat taxonUnresolved.tsv.gz | head -n 10
