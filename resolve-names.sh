#!/bin/bash
#
#   extracts name from datasets and attempt to resolve them.
#
#   usage:
#     resolve-names.sh [github repo name] 
# 
#   example:
#      ./resolve-names.sh globalbioticinteractions/template-dataset
set -e
set -x

function download_jar {
    NAME=$1
    VERSION=$2
    URL_PREFIX="https://depot.globalbioticinteractions.org/release/org/globalbioticinteractions/${NAME}/${VERSION}/${NAME}-${VERSION}"
    curl -Ls ${URL_PREFIX}-jar-with-dependencies.jar > ${NAME}.jar
}

REPO_NAME=$1

NOMER_VERSION="0.0.5"
ELTON_VERSION="0.4.4"
GLOBI_TAXON_VERSION="0.4.1"
CACHE_DIR="$PWD/datasets"

function download_jars {
  download_jar nomer ${NOMER_VERSION}
  download_jar elton ${ELTON_VERSION}
}

function download_taxon_cache {
  curl -Ls https://depot.globalbioticinteractions.org/datasets/org/globalbioticinteractions/taxon/${GLOBI_TAXON_VERSION}/taxon-${GLOBI_TAXON_VERSION}.zip > taxon.zip
  unzip -o taxon.zip taxonCache.tsv.gz taxonMap.tsv.gz
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

function resolve {
  echo nomer.term.map.url=jar:file://${PWD}/taxon.zip!/taxonMap.tsv.gz > nomer.properties
  echo nomer.term.cache.url=jar:file://${PWD}/taxon.zip!/taxonCache.tsv.gz >> nomer.properties

  NOMER="${JAVA} -Xmx4G -jar nomer.jar append"

  echo Checking names of [${REPO_NAME}] using Nomer version [${NOMER_VERSION}]. 
  $ELTON names --cache-dir=${CACHE_DIR} ${REPO_NAME} | awk -F '\t' '{ print $1 "\t" $2 "\t" $7 }' > names_orig.tsv
  cat names_orig.tsv | sort | uniq | gzip > names_orig_uniq.tsv.gz

  # notify GloBI
  # echo notifying GloBI of names
  # git clone https://github.com/edenhill/kafkacat.git 
  # docker build -t kafkacat kafkacat/
  # zcat names_orig_uniq.tsv.gz | awk -F '\t' '{ print $1 $2 $3 "|" $1 "\t" $2 "\t" $3 }' | docker run -i --rm --net=host kafkacat -b 178.63.23.174 -t nomer_log -K '|' -z snappy
  #echo ${REPO_NAME} | docker run -i --rm --net=host kafkacat -b 178.63.23.174 -t dataset

  zcat names_orig_uniq.tsv.gz | awk -F '\t' '{ print $1 "\t" $2 }' | $NOMER --properties nomer.properties globi-cache > names_map_cached.tsv

  . ./create-taxon-cache-map.sh
  create_taxon_cache_map names_map_cached.tsv
  echo --- number of unmatched names
  zcat taxonUnresolved.tsv.gz | awk -F '\t' '{ print $1 "\t" $2 }' | sort | uniq > names_unmatched.tsv
  cat names_unmatched.tsv | wc -l
  echo "--- unmatched names (first 10)"
  head -n 10 names_unmatched.tsv
  echo "--- number of unique names"
  cat names_map_cached.tsv | grep -v NONE | awk -F '\t' '{ print $5 }' | sort | uniq > names_unique.tsv
  cat names_unique.tsv | wc -l
  echo "--- number of unique names (end)"
  echo "--- unique names (first 10)"
  head -n 10 names_unique.tsv
  echo "--- unique names (end)"
  echo "--- taxonMap (first 10)"
  zcat taxonMap.tsv.gz | head -n 10
  echo "--- taxonMap (end)"
  echo "--- taxonCache (first 10)"
  zcat taxonCache.tsv.gz | head -n 10
  echo "--- taxonCache (end)"

  echo "--- taxonUnresolved (first 10)"
  zcat taxonUnresolved.tsv.gz | head -n 10
  echo "--- taxonUnresolved (end)"
}

check
#name resolving disabled; re-enable after stable execution on travis
#resolve
