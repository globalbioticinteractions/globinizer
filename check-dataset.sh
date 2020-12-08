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
export ELTON_VERSION=0.10.4
export ELTON_DATA_REPO_MASTER="https://raw.githubusercontent.com/${REPO_NAME}/master"
export REVIEW_REPO_ENDPOINT="https://blob.globalbioticinteractions.org"
export README=$(mktemp)

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
  sudo apt-get -q update &> /dev/null
  sudo apt-get -q install awscli miller jq -y &> /dev/null
  aws --version
  mlr --version
  # see https://docs.aws.amazon.com/cli/latest/topic/s3-config.html
  aws configure set default.s3.multipart_threshold 10MB
  aws configure set default.s3.multipart_chunksize 10MB
}

echo_logo | tee_readme 

install_deps

echo Reviewing [${ELTON_DATA_REPO_MASTER}] using Elton version [${ELTON_VERSION}]. | tee_readme 

export URL_PREFIX="https://github.com/globalbioticinteractions/elton/releases/download/${ELTON_VERSION}"

wget --quiet ${URL_PREFIX}/elton.jar -O elton.jar

java -Xmx4G -jar elton.jar update --registry local
java -Xmx4G -jar elton.jar review local --type note,summary | gzip > review.tsv.gz
cat review.tsv.gz | gunzip | head -n501 > review-sample.tsv
cat review-sample.tsv | tail -n+2 | cut -f15 | jq -c . > review-sample.json
cat review-sample.json | mlr --ijson --ocsv cat > review-sample.csv


echo -e "\nReview of [$REPO_NAME] included:" | tee_readme
cat review.tsv.gz | gunzip | tail -n3 | cut -f6 | sed s/^/\ \ -\ /g | tee_readme

NUMBER_OF_NOTES=$(cat review.tsv.gz | gunzip | cut -f5 | grep "^note$" | wc -l)

if [ $NUMBER_OF_NOTES -gt 0 ]
then
  echo -e "\n[$REPO_NAME] has $NUMBER_OF_NOTES reviewer note(s):" | tee_readme
  cat review.tsv.gz | gunzip | tail -n+2 | cut -f6 | tac | tail -n+5 | sort | uniq -c | sort -nr | tee_readme
else
  echo -e "\nHurray! [$REPO_NAME] passed the GloBI review." | tee_readme
fi

#
# publish review artifacts
#

function upload_file_io {
  echo -e "\nDownload the full review report with the single-use, and expiring, file.io link at:"
  curl -F "file=@review.tsv.gz" https://file.io 
}

function upload {
  aws s3 ${ENDPOINT_CONFIG} cp $1 s3://${ARTIFACTS_BUCKET}/reviews/$TRAVIS_REPO_SLUG/$1 &> upload.log
  if [[ $? -ne 0 ]] ; then
     echo -e "\nfailed to upload $2, please check following upload log"
     cat upload.log
  else
     echo -e "\nFor a detailed $2, please download:\nhttps://depot.globalbioticinteractions.org/reviews/$TRAVIS_REPO_SLUG/$1\n"
  fi

}


echo_reproduce >> $README

# atttempt to use travis artifacts tool if available
if [[ -n $(which aws) ]] && [[ -n ${ARTIFACTS_KEY} ]] && [[ -n ${ARTIFACTS_SECRET} ]] && [[ -n ${ARTIFACTS_BUCKET} ]]
then
  export AWS_ACCESS_KEY_ID=${ARTIFACTS_KEY}
  export AWS_SECRET_ACCESS_KEY=${ARTIFACTS_SECRET}
  export ENDPOINT_CONFIG="--endpoint-url=${REVIEW_REPO_ENDPOINT}"
  if [ -n "${ARTIFACTS_ENDPOINT}" ]
  then
    export ENDPOINT_CONFIG="--endpoint-url=${ARTIFACTS_ENDPOINT}"
  fi
 
  upload review.tsv.gz "data review"
  upload review-sample.tsv "data review sample tab-separated"
  upload review-sample.json "data review sample json"
  upload review-sample.csv "data review sample csv"
  
  java -Xmx4G -jar elton.jar interactions local | gzip > indexed-interactions.tsv.gz
  upload indexed-interactions.tsv.gz "indexed interactions"

  cat indexed-interactions.tsv.gz | gunzip | head -n501 > indexed-interactions-sample.tsv
  upload indexed-interactions-sample.tsv "indexed interactions sample"

  tar c datasets/* | gzip > datasets.tar.gz
  upload datasets.tar.gz "cached dataset archive"

  cat $README > README

  zip -r review.zip README datasets/* indexed-interactions* review* elton.jar
  upload review.zip "review archive"

else
  upload_file_io
fi

echo_reproduce

exit $NUMBER_OF_NOTES


