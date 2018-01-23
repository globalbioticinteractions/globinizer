#!/bin/bash

function create_taxon_cache_map_headers {
  SCHEME_DIR=$1
  TAXON_CACHE_HEADER="id\tname\trank\tcommonNames\tpath\tpathIds\tpathNames\texternalUrl\tthumbnailUrl"
  TAXON_MAP_HEADER="providedTaxonId\tprovidedTaxonName\tresolvedTaxonId\tresolvedTaxonName"
  echo -e $TAXON_MAP_HEADER | gzip > ${SCHEME_DIR}/taxonMap.tsv.gz
  echo -e $TAXON_CACHE_HEADER | gzip > ${SCHEME_DIR}/taxonCache.tsv.gz
}

function taxon_cache_map_for_scheme {
  TAXON_SCHEME=$1
  # create taxon specific mappings
  TAXON_SCHEME_DIRNAME=$(echo $1 | tr '[:upper:]' '[:lower:'])
  TAXON_SCHEME_DIR=${PWD}/$(echo $1 | tr '[:upper:]' '[:lower:'])
  mkdir -p ${TAXON_SCHEME_DIR}
  create_taxon_cache_map_headers ${TAXON_SCHEME_DIR}
  zcat taxonMap.tsv.gz | grep -P -e "\t${TAXON_SCHEME}:" | sort | uniq | gzip >> ${TAXON_SCHEME_DIR}/taxonMap.tsv.gz
  zcat taxonCache.tsv.gz | grep "^${TAXON_SCHEME}:" | sort | uniq | gzip >> ${TAXON_SCHEME_DIR}/taxonCache.tsv.gz
  zip -j taxon-${TAXON_SCHEME_DIRNAME}.zip ${TAXON_SCHEME_DIRNAME}/*
}

function create_taxon_cache_map_schemes {
  schemes=( "ITIS" "NCBI" "OTT" "GBIF" "WORMS" "INAT_TAXON" "EOL" "FBC" )
  for SCHEME in "${schemes[@]}" 
  do
    taxon_cache_map_for_scheme ${SCHEME}
  done

}


function create_taxon_cache_map {
  create_taxon_cache_map_headers ${PWD}
  cat $1 | grep -E -e "(SAME_AS|SYNONYM_OF)" | awk -F '\t' '{ print $1 "\t" $2 "\t" $4 "\t" $5 }' | sort | uniq | gzip >> taxonMap.tsv.gz
  cat $1 | grep -E -e "(SAME_AS|SYNONYM_OF)" | awk -F '\t' '{ print $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12  }' | sort | uniq | gzip >> taxonCache.tsv.gz
  cat $1 | grep -v -E -e "(SAME_AS|SYNONYM_OF)" | sort | uniq | gzip >> taxonUnresolved.tsv.gz
}
