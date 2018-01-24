#!/bin/bash
#
#   imports single github globi data repository and check whether it can be read by GloBI.
#
#   usage:
#     resolve-names.sh [github repo name] 
# 
#   example:
#      ./resolve-names.sh globalbioticinteractions/template-dataset
set -x

function download_jar {
    NAME=$1
    VERSION=$2
    URL_PREFIX="https://depot.globalbioticinteractions.org/release/org/globalbioticinteractions/${NAME}/${VERSION}/${NAME}-${VERSION}"
    wget ${URL_PREFIX}-jar-with-dependencies.jar -O ${NAME}.jar
}

REPO_NAME=$1

NOMER_VERSION="0.0.5"
ELTON_VERSION="0.4.3"
GLOBI_TAXON_VERSION="0.2"
CACHE_DIR="$PWD/datasets"

function download_jars {
  download_jar nomer ${NOMER_VERSION}
  download_jar elton ${ELTON_VERSION}
}

function download_taxon_cache {
  wget https://depot.globalbioticinteractions.org/datasets/org/globalbioticinteractions/taxon/${GLOBI_TAXON_VERSION}/taxon-${GLOBI_TAXON_VERSION}.zip -O taxon.zip
  unzip taxon.zip
}

function download {
 download_jars
 download_taxon_cache
}

download

if [ -z $TRAVIS ]; then 
  JAVA_HOME=/usr/lib/jvm/java-8-oracle;
fi

JAVA=${JAVA_HOME}/jre/bin/java

ELTON="$JAVA -Xmx4G -jar elton.jar"

function check {
  echo Checking readability of [${REPO_NAME}] using Elton version [${ELTON_VERSION}].
  $ELTON update ${REPO_NAME}
  $ELTON check --offline ${REPO_NAME}
}

check

echo nomer.term.map.url=jar:file://${PWD}/taxon.zip!/taxonMap.tsv.gz > nomer.properties
echo nomer.term.cache.url=jar:file://${PWD}/taxon.zip!/taxonCache.tsv.gz >> nomer.properties

NOMER="${JAVA} -Xmx4G -jar nomer.jar append"

echo Checking names of [${REPO_NAME}] using Nomer version [${NOMER_VERSION}]. 
$ELTON names --cache-dir=${CACHE_DIR} ${REPO_NAME} | awk -F '\t' '{ print $1 "\t" $2 }' > names_orig.tsv
cat names_orig.tsv | sort | uniq | gzip > names_orig_uniq.tsv.gz

zcat names_orig_uniq.tsv.gz | $NOMER --properties nomer.properties globi-cache > names_map_cached.tsv

. ./create-taxon-cache-map.sh
create_taxon_cache_map names_map_cached.tsv
echo --- number of unmatched names
zcat taxonUnresolved.tsv.gz | awk -F '\t' '{ print $1 "\t" $2 }' | sort | uniq > names_unmatched.tsv
cat names_unmatched.tsv | wc -l
echo "--- unmatched names (first 10)"
head -n 10 names_unmatched.tsv
echo --- number of unique names
cat names_map_cached.tsv | grep -v NONE | awk -F '\t' '{ print $5 }' | sort | uniq > names_unique.tsv
cat names_unique.tsv | wc -l

echo "--- unique names (first 10)"
head -n 10 names_unique.tsv
echo "--- taxonMap (first 10)"
zcat taxonMap.tsv.gz | head -n 10
echo "--- taxonCache (first 10)"
zcat taxonCache.tsv.gz | head -n 10

echo "--- taxonUnresolved (first 10)"
zcat taxonUnresolved.tsv.gz | head -n 10
