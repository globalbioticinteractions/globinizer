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
export ELTON_VERSION=0.7.0
export ELTON_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"

echo Reviewing [${ELTON_DATA_REPO_MASTER}] using Elton version [${ELTON_VERSION}]. 

export URL_PREFIX="https://github.com/globalbioticinteractions/elton/releases/download/${ELTON_VERSION}"

wget --quiet ${URL_PREFIX}/elton.jar -O elton.jar

java -Xmx4G -jar elton.jar review --type note,summary > review.tsv
REVIEW_RESULT=$?

cat review.tsv | gzip > review.tsv.gz

echo -e "\nReview of [$REPO_NAME] included:"
zcat review.tsv.gz | tail -n3 | cut -f6 | sed s/^/\ \ -\ /g

echo -e "\nDownload the full review report with the single-use, and expiring, file.io link at:"
curl -F "file=@review.tsv.gz" https://file.io 
echo -e "\n\nIf https://file.io link above no longer works, access review notes by:"
echo "  - installing GloBI's Elton via https://github.com/globalbioticinteractions/elton"
echo "  - running \"elton update $REPO_NAME && elton review --type note,summary $REPO_NAME > review.tsv\""
echo "  - inspecting review.tsv"
echo -e "\nPlease email info@globalbioticinteractions.org for questions/ comments."

if [ $REVIEW_RESULT -gt 0 ]
then
  echo -e "[$REPO_NAME] has the following reviewer comments:"
  zcat review.tsv.gz | tail -n+2 | cut -f5 | tac | tail -n+5 | sort | uniq -c | sort -nr
else
  echo -e "Hurray! [$REPO_NAME] passed the GloBI review."
fi

exit $REVIEW_RESULT
