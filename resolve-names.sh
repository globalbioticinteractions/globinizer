#!/bin/bash
#
#   imports single github globi data repository and check whether it can be read by GloBI.
#
#   usage:
#     check-dataset.sh [github repo name] 
# 
#   example:
#      ./check-dataset.sh globalbioticinteractions/template-dataset
#set -e

export REPO_NAME=$1
export ELTON_VERSION=0.9.2
export ELTON_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"

echo Reviewing [${ELTON_DATA_REPO_MASTER}] using Elton version [${ELTON_VERSION}]. 

export URL_PREFIX="https://github.com/globalbioticinteractions/elton/releases/download/${ELTON_VERSION}"

wget --quiet ${URL_PREFIX}/elton.jar -O elton.jar
curl -sL https://raw.githubusercontent.com/travis-ci/artifacts/master/install | bash

java -Xmx4G -jar elton.jar review --type note,summary > review.tsv

cat review.tsv | gzip > review.tsv.gz

echo -e "\nReview of [$REPO_NAME] included:"
zcat review.tsv.gz | tail -n3 | cut -f6 | sed s/^/\ \ -\ /g


NUMBER_OF_NOTES=$(zcat review.tsv.gz | cut -f5 | grep "^note$" | wc -l)

if [ $NUMBER_OF_NOTES -gt 0 ]
then
  echo -e "\n[$REPO_NAME] has $NUMBER_OF_NOTES reviewer note(s):"
  zcat review.tsv.gz | tail -n+2 | cut -f6 | tac | tail -n+5 | sort | uniq -c | sort -nr
else
  echo -e "\nHurray! [$REPO_NAME] passed the GloBI review."
fi

#
# publish review artifacts
#

function upload_file_io {
  echo -e "\nDownload the full review report with the single-use, and expiring, file.io link at:"
  curl -F "file=@review.tsv.gz" https://file.io 
  echo -e "\n\nIf https://file.io link above no longer works, access review notes by:"
  echo "  - installing GloBI's Elton via https://github.com/globalbioticinteractions/elton"
  echo "  - running \"elton update $REPO_NAME && elton review --type note,summary $REPO_NAME > review.tsv\""
  echo "  - inspecting review.tsv"
}


# atttempt to use travis artifacts tool if available
if [[ -n $(which artifacts) ]] && [[ -n ${ARTIFACTS_KEY} ]] && [[ -n ${ARTIFACTS_SECRET} ]] && [[ -n ${ARTIFACTS_BUCKET} ]]
then
  echo "got artifacts config"
  artifacts upload --target-paths "reviews/$TRAVIS_REPO_SLUG" review.tsv.gz 
  echo "see also https://depot.globalbioticinteractions.org/reviews/$TRAVIS_REPO_SLUG/review.tsv.gz"
  
  java -Xmx4G -jar elton.jar interactions | gzip > indexed-interactions.tsv.gz
  artifacts upload --target-paths "reviews/$TRAVIS_REPO_SLUG" indexed-interactions.tsv.gz
  echo "and https://depot.globalbioticinteractions.org/reviews/$TRAVIS_REPO_SLUG/indexed-interactions.tsv.gz"
else
  upload_file_io
fi

echo -e "\nPlease email info@globalbioticinteractions.org for questions/ comments."
exit $NUMBER_OF_NOTES
