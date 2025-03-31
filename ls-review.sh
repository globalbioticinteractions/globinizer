#!/bin/bash
#
# list review urls for a GloBI namespace
# 
# usage:
#   list-review-files globalbioticinteractions/template-dataset 
#

set -eu

namespace=${1:-aeiche01/MojaveFoodWeb}

curl "https://depot.globalbioticinteractions.org/reviews/${namespace}/README.txt"\
 | grep "https://depot.globalbioticinteractions.org/reviews/"\
 | sed 's+[.]gz$++'\
 | sort\
 | uniq


