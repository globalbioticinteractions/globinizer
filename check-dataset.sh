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
export ELTON_VERSION=0.10.7
export ELTON_DATA_REPO_MAIN="https://raw.githubusercontent.com/${REPO_NAME}/main"
export REVIEW_REPO_HOST="blob.globalbioticinteractions.org"
export README=$(mktemp)
export REVIEW_DIR="review/${REPO_NAME}"


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

function echo_reproduce {
  echo -e "\n\nIf you'd like, you can generate your own review notes by:"
  echo "  - installing GloBI's Elton via https://github.com/globalbioticinteractions/elton"
  echo "  - running \"elton update $REPO_NAME && elton review --type note,summary $REPO_NAME > review.tsv\""
  echo "  - inspecting review.tsv"
  echo -e "\nPlease email info@globalbioticinteractions.org for questions/ comments."
}

function tee_readme {
  tee --append $README
}

function install_deps {
  if [[ -n ${TRAVIS_REPO_SLUG} ]]
  then
    sudo apt-get -q update &> /dev/null
    sudo apt-get -q install miller jq -y &> /dev/null
    sudo pip install s3cmd &> /dev/null   
  fi

  if [[ $(which elton) ]]
  then 
    echo using local elton found at [$(which elton)]
    export ELTON_CMD="elton"
  else
    local ELTON_DOWNLOAD_URL="https://github.com/globalbioticinteractions/elton/releases/download/${ELTON_VERSION}/elton.jar"
    echo elton not found... installing from [${ELTON_DOWNLOAD_URL}]
    wget --quiet ${ELTON_DOWNLOAD_URL} -O elton.jar
    export ELTON_CMD="java -Xmx4G -jar elton.jar"
  fi

  export ELTON_VERSION=$(${ELTON_CMD} version)

  mlr --version
  s3cmd --version
  java -version
}

echo_logo | tee_readme 

install_deps

if [[ -n ${TRAVIS_REPO_SLUG} ]]
then
  ELTON_UPDATE="${ELTON_CMD} update --registry local"
  ELTON_NAMESPACE="local"
else
  ELTON_UPDATE="${ELTON_CMD} update $REPO_NAME"
  ELTON_NAMESPACE="$REPO_NAME"
fi

rm -rf ${REVIEW_DIR}
mkdir -p ${REVIEW_DIR}
cd ${REVIEW_DIR}

echo -e "\nreviewing [${ELTON_NAMESPACE}] using Elton version [${ELTON_VERSION}]." | tee_readme 

${ELTON_UPDATE}
${ELTON_CMD} review ${ELTON_NAMESPACE} --type note,summary | gzip > review.tsv.gz
cat review.tsv.gz | gunzip | head -n501 > review-sample.tsv
cat review-sample.tsv | tail -n+2 | cut -f15 | grep -v "^$" jq -c . > review-sample.json
cat review-sample.json | mlr --ijson --ocsv cat > review-sample.csv

${ELTON_CMD} interactions ${ELTON_NAMESPACE} | gzip > indexed-interactions.tsv.gz
cat indexed-interactions.tsv.gz | gunzip | head -n501 > indexed-interactions-sample.tsv

${ELTON_CMD} nanopubs ${ELTON_NAMESPACE} | gzip > nanopub.ttl.gz
cat nanopub.ttl.gz | gunzip | head -n1 > nanopub-sample.ttl

echo -e "\nreview of [${REPO_NAME}] included:" | tee_readme
cat review.tsv.gz | gunzip | tail -n3 | cut -f6 | sed s/^/\ \ -\ /g | tee_readme

NUMBER_OF_NOTES=$(cat review.tsv.gz | gunzip | cut -f5 | grep "^note$" | wc -l)

if [ ${NUMBER_OF_NOTES} -gt 0 ]
then
  echo -e "\n[${REPO_NAME}] has ${NUMBER_OF_NOTES} reviewer note(s):" | tee_readme
  cat review.tsv.gz | gunzip | tail -n+2 | cut -f6 | tac | tail -n+5 | sort | uniq -c | sort -nr | tee_readme
else
  echo -e "\nHurray! [${REPO_NAME}] passed the GloBI review." | tee_readme
fi

echo_reproduce >> ${README}

cat ${README} > README


#
# publish review artifacts
#

function upload_file_io {
  echo -e "\nDownload the full review report with the single-use, and expiring, file.io link at:"
  curl -F "file=@review.tsv.gz" https://file.io 
}

function upload {

  s3cmd --access_key "${ARTIFACTS_KEY}" --secret_key "${ARTIFACTS_SECRET}" --host "${REVIEW_REPO_HOST}" --host-bucket "${REVIEW_REPO_HOST}" put "$1" s3://${ARTIFACTS_BUCKET}/reviews/${REPO_NAME}/$1 &> upload.log

  if [[ $? -ne 0 ]] ; then
     echo -e "\nfailed to upload $2, please check following upload log"
     cat upload.log
  else
     echo -e "\nFor a detailed $2, please download:\nhttps://depot.globalbioticinteractions.org/reviews/${REPO_NAME}/$1\n"
  fi

}

# atttempt to use travis artifacts tool if available
if [[ -n $(which s3cmd) ]] && [[ -n ${ARTIFACTS_KEY} ]] && [[ -n ${ARTIFACTS_SECRET} ]] && [[ -n ${ARTIFACTS_BUCKET} ]]
then
  upload review.tsv.gz "data review"
  upload review-sample.tsv "data review sample tab-separated"
  upload review-sample.json "data review sample json"
  upload review-sample.csv "data review sample csv"
  
  upload indexed-interactions.tsv.gz "indexed interactions"

  upload indexed-interactions-sample.tsv "indexed interactions sample"

  upload nanopub.ttl.gz "interactions nanopubs"
  
  upload nanopub-sample.ttl "interactions nanopub sample"
  
  tar c datasets/* | gzip > datasets.tar.gz
  upload datasets.tar.gz "cached dataset archive"


  zip -r review.zip README datasets/* indexed-interactions* review* elton.jar
  upload review.zip "review archive"

else
  if [[ -n ${TRAVIS_REPO_SLUG} ]]
  then
    upload_file_io
  else
    echo -e "\nFor detailed review results please see files in [$PWD].\n" | tee_readme
  fi
fi

echo_reproduce

exit ${NUMBER_OF_NOTES}
