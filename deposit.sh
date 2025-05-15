#!/bin/bash
#
#

set -xu

SCRIPT_DIR=$(dirname $(readlink -f $0))
NAMESPACE="$1"

DATA_DIR="review/$(uuidgen)"
mkdir -p "${DATA_DIR}"

OPTS="--data-dir ${DATA_DIR}"

preston track $OPTS -f <("${SCRIPT_DIR}/ls-review.sh" ${NAMESPACE})

preston head $OPTS\
 | preston cat $OPTS\
 | preston zenodo $OPTS
