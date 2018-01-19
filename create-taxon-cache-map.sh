create_taxon_cache_map() {
  TAXON_CACHE_HEADER="id\tname\trank\tcommonNames\tpath\tpathIds\tpathNames\texternalUrl\tthumbnailUrl"
  TAXON_MAP_HEADER="providedTaxonId\tprovidedTaxonName\tresolvedTaxonId\tresolvedTaxonName"
  echo -e $TAXON_MAP_HEADER | gzip > taxonMap.tsv.gz
  echo -e $TAXON_CACHE_HEADER | gzip > taxonCache.tsv.gz
  cat $1 | grep -E -e "(SAME_AS|SYNONYM_OF)" | awk -F '\t' '{ print $1 "\t" $2 "\t" $4 "\t" $5 }' | sort | uniq | gzip >> taxonMap.tsv.gz
  cat $1 | grep -E -e "(SAME_AS|SYNONYM_OF)" | awk -F '\t' '{ print $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12  }' | sort | uniq | gzip >> taxonCache.tsv.gz
  cat $1 | grep -v -E -e "(SAME_AS|SYNONYM_OF)" | sort | uniq | gzip >> taxonUnresolved.tsv.gz
}
