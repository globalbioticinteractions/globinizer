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
export ELTON_VERSION=0.9.1
export ELTON_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"

function echo_logo {
  echo "$(cat <<_EOF_
   _____ _       ____ _____   _____            _                
  / ____| |     |  _ \_   _| |  __ \          (_)               
 | |  __| | ___ | |_) || |   | |__) |_____   ___  _____      __ 
 | | |_ | |/ _ \|  _ < | |   |  _  // _ \ \ / / |/ _ \ \ /\ / / 
 | |__| | | (_) | |_) || |_  | | \ \  __/\ V /| |  __/\ V  V /  
  \_____|_|\___/|____/_____| |_|  \_\___| \_/ |_|\___| \_/\_/   
 | |           |  ____| | |                                     
 | |__  _   _  | |__  | | |_ ___  _ __                          
 | '_ \| | | | |  __| | | __/ _ \| '_ \                         
 | |_) | |_| | | |____| | || (_) | | | |                        
 |_.__/ \__, | |______|_|\__\___/|_| |_|                        
         __/ |                                                  
        |___/                                                   
_EOF_
)"
}

echo_logo 

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


sudo apt-get update -q
sudo apt-get install awscli -y -q

# atttempt to use travis artifacts tool if available
if [[ -n $(which aws) ]] && [[ -n ${ARTIFACTS_KEY} ]] && [[ -n ${ARTIFACTS_SECRET} ]] && [[ -n ${ARTIFACTS_BUCKET} ]]
then
  export AWS_ACCESS_KEY_ID=${ARTIFACTS_KEY}
  export AWS_SECRET_ACCESS_KEY=${ARTIFACTS_SECRET}
  export ENDPOINT_CONFIG=""
  if [ -n "${ARTIFACT_ENDPOINT}" ]
  then
    export ENDPOINT_CONFIG="--endpoint-url=${ARTIFACT_ENDPOINT}"
  fi
  aws s3 ${ENDPOINT_CONFIG} cp review.tsv.gz s3://${ARTIFACTS_BUCKET}/reviews/$TRAVIS_REPO_SLUG/review.tsv.gz
  #artifacts --quiet upload --target-paths "reviews/$TRAVIS_REPO_SLUG" review.tsv.gz
  echo -e "\nFor a detailed review, please download:\nhttps://depot.globalbioticinteractions.org/reviews/$TRAVIS_REPO_SLUG/review.tsv.gz\n"
  
  java -Xmx4G -jar elton.jar interactions | gzip > indexed-interactions.tsv.gz
  aws s3 ${ENDPOINT_CONFIG} cp indexed-interactions.tsv.gz s3://${ARTIFACTS_BUCKET}/reviews/$TRAVIS_REPO_SLUG/indexed-interactions.tsv.gz
  #artifacts --quiet upload --target-paths "reviews/$TRAVIS_REPO_SLUG" indexed-interactions.tsv.gz
  echo -e "\nFor a list of indexed interactions, please download:\nhttps://depot.globalbioticinteractions.org/reviews/$TRAVIS_REPO_SLUG/indexed-interactions.tsv.gz"
else
  upload_file_io
fi

echo -e "\nPlease email info@globalbioticinteractions.org for questions/ comments."
exit $NUMBER_OF_NOTES


