#!/bin/bash
#
#

function map_interactions {
  INTERACTIONS_FILE=$1
  cat ${INTERACTIONS_FILE} | $NOMER append --properties nomer.properties globi-cache > $INTERACTIONS_FILE.source
  cat ${INTERACTIONS_FILE} | $NOMER append --properties nomer-target.properties globi-cache > $INTERACTIONS_FILE.source.target
  cat ${INTERACTIONS_FILE}.source.target | awk -F '\t' '{ print $24 "\t" $25 "\t" $26 "\t" $27 "\t" $28 "\t" $29 "\t" $30 "\t" $31 "\t" $7 "\t" $8 "\t" $23 "\t" $34 "\t" $35 "\t" $36 "\t" $37 "\t" $38 "\t" $39 "\t" $15 "\t" $16 "\t" $17 "\t" $18 "\t" $19 "\t" $20 "\t" $21 "\t" $22 }' > ${INTERACTIONS_FILE}.mapped.tsv
}

map_interactions interactions.tsv
