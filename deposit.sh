#!/bin/bash
#
#

set -xu

NAMESPACE="$1"

DATA_DIR="review/$(uuidgen)"
mkdir -p "${DATA_DIR}"

OPTS="--data-dir ${DATA_DIR}"

preston track $OPTS -f <(./ls-review.sh ${NAMESPACE})

preston head $OPTS\
 | preston cat $OPTS\
 | preston zenodo $OPTS
