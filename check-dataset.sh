#!/bin/bash
#
#   imports single github globi data repository and check whether it can be read by GloBI.
#
#   usage:
#     check-dataset.sh [github repo name] 
# 
#   example:
#      ./check-dataset.sh globalbioticinteractions/template-dataset
set -e

export REPO_NAME=$1
export ELTON_VERSION=0.6.1
export ELTON_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"

echo Reviewing [${ELTON_DATA_REPO_MASTER}] using Elton version [${ELTON_VERSION}]. 

export URL_PREFIX="https://github.com/globalbioticinteractions/elton/releases/download/${ELTON_VERSION}"

wget --quiet ${URL_PREFIX}/elton.jar -O elton.jar

java -Xmx4G -jar elton.jar check > review.tsv
REVIEW_RESULT=$?

cat review.tsv | gzip > review.tsv.gz
zcat review.tsv.gz | tail

curl -F "file=@review.tsv.gz" https://file.io

if [ $REVIEW_RESULT -gt 0 ]
then
  echo "[$REPO_NAME] has reviewer comments, including:"
  zcat review.tsv.gz | tail -n+2 | cut -f5 | sort | uniq -c | sort -nr
  echo "For full review, please install GloBI's Elton via https://github.com/globalbioticinteractions/elton and run \"elton update $REPO_NAME && elton check $REPO_NAME > review.tsv\""
else
  echo "Hurray! [$REPO_NAME] passed the GloBI review."
fi

exit $REVIEW_RESULT
