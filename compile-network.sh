#!/bin/bash
#
# generates graphviz compatible network diagram 
#  from interaction records aligned with provided 
#  catalog on specified taxonomic rank.
#
#  default source catalog: Catalogue of Life
#  default source taxonomic rank: genus  
#  default target catalog: Catalogue of Life
#  default source taxonomic rank: kingdon  
#
#  where:
#     source: the subject of the interaction, 
#     target: target is the object of the interaction.
#     taxonomic rank: level at which the taxon is aligned (e.g., genus, species, family, order, phylum, kingdom) according to the selected catalog.
#
#  So, in "bat eats fruit", "bat" is the source and "fruit" is the target.
#
# Usage:
#  ./compile-network.sh [source catalogue name] [source taxonomic rank] [target catalogue name] [target taxonomic rank]
#
#  Example 1: Generate a SVG diagram from provided interactions
#      cat interactions.tsv | ./compile-network.sh | sfdp -Tsvg > network.svg
#
#  Example 2: Generate a PNG diagram from provided interactions 
#      where the source 
#      cat interactions.tsv | ./compile-network.sh batnames family gbif kingdom | sfdp -Tpng > network.png
#
#  Example 3: Generate a PNG diagram from provided interactions
#      cat interactions.tsv | compile-network.sh | sfdp -Tpng > network.png
#
#  Example 4: Generate a SVG diagram from bat-co-roosting-dataset
#      curl "https://depot.globalbioticinteractions.org/reviews/globalbioticinteractions/bat-co-roosting-database/indexed-interactions.tsv"\
#       | ./compile-network.sh\
#       | sfdp -Tpng > network.png
#
# This scripts assumed that Nomer, graphviz, and miller are installed.
#

set -x 
LABEL='["label" = "\3"]'
LABEL=

REPLACE_SCHEMA_SOURCE=$(mktemp)

SOURCE_CATALOG=${1:-col}
TARGET_CATALOG=${3:-col}
SOURCE_RANK=${2:-genus}
TARGET_RANK=${4:-kingdom}

NOMER_CMD="${NOMER_CMD:-nomer}"
NOMER_CACHE_DIR="${NOMER_CACHE_DIR:-${HOME}/.cache/nomer}"

cat > "${REPLACE_SCHEMA_SOURCE}" <<_EOF_
nomer.cache.dir=${NOMER_CACHE_DIR}
nomer.schema.input=[{"column": 0,"type":"name"}]
nomer.schema.output=[{"column": 0,"type":"path.${SOURCE_RANK}.name"}]
_EOF_

REPLACE_SCHEMA_TARGET=$(mktemp)

cat > "${REPLACE_SCHEMA_TARGET}" <<_EOF_
nomer.cache.dir=${NOMER_CACHE_DIR}
nomer.schema.input=[{"column": 2,"type":"name"}]
nomer.schema.output=[{"column": 2,"type":"path.${TARGET_RANK}.name"}]
_EOF_


HEADER=$(cat <<_EOF_
digraph interactions {
  edge [width=0.05 label="" color="#cc990088"]
  node [shape=circle width=0.1 style=filled color="#0000ff11"]
_EOF_
)

FOOTER=$(cat <<_EOF_
  }
_EOF_
)

cat <(echo ${HEADER})\
 <(cat /dev/stdin\
  | mlr --tsvlite cut -f sourceTaxonName,interactionTypeName,targetTaxonName\
  | tail -n+2\
  | ${NOMER_CMD} replace --properties ${REPLACE_SCHEMA_SOURCE} ${SOURCE_CATALOG}\
  | ${NOMER_CMD} replace --properties ${REPLACE_SCHEMA_TARGET} ${TARGET_CATALOG}\
  | grep -P "^[A-Za-z ]+\t[A-Za-z ]+\t[A-Za-z ]+$"\
  | sort | uniq\
  | sed -E "s/^([^\t]+)(\t)([^\t]+)(\t)(.*)$/\"\1\" -> \"\5\" ${LABEL};/g"\
)\
 <(echo ${FOOTER}) 
