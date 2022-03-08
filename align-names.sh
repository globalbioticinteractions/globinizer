#!/bin/bash
#
#   attempt to align names found in .txt files with various taxonomies using
#   GloBI's nomer. 
#
#   usage:
#     align-names.sh 
# 
#   example:
#     ./align-names.sh 
#

#set -x

export REPO_NAME=$1

export NOMER_VERSION=0.2.11
export NOMER_JAR="$PWD/nomer.jar"

export REVIEW_REPO_HOST="blob.globalbioticinteractions.org"
export README=$(mktemp)
export REVIEW_DIR="review/${REPO_NAME}"

export MLR_TSV_INPUT_OPTS="--icsvlite --ifs tab"
export MLR_TSV_OUTPUT_OPTS="--ocsvlite --ofs tab"
export MLR_TSV_OPTS="${MLR_TSV_INPUT_OPTS} ${MLR_TSV_OUTPUT_OPTS}"

function echo_logo {
  echo "$(cat <<_EOF_
███    ██  █████  ███    ███ ███████                                        
████   ██ ██   ██ ████  ████ ██                                             
██ ██  ██ ███████ ██ ████ ██ █████                                          
██  ██ ██ ██   ██ ██  ██  ██ ██                                             
██   ████ ██   ██ ██      ██ ███████                                        
                                                                            
 █████  ██      ██  ██████  ███    ██ ███    ███ ███████ ███    ██ ████████ 
██   ██ ██      ██ ██       ████   ██ ████  ████ ██      ████   ██    ██    
███████ ██      ██ ██   ███ ██ ██  ██ ██ ████ ██ █████   ██ ██  ██    ██    
██   ██ ██      ██ ██    ██ ██  ██ ██ ██  ██  ██ ██      ██  ██ ██    ██    
██   ██ ███████ ██  ██████  ██   ████ ██      ██ ███████ ██   ████    ██    
                                                                            
██████  ██    ██     ███    ██  ██████  ███    ███ ███████ ██████           
██   ██  ██  ██      ████   ██ ██    ██ ████  ████ ██      ██   ██          
██████    ████       ██ ██  ██ ██    ██ ██ ████ ██ █████   ██████           
██   ██    ██        ██  ██ ██ ██    ██ ██  ██  ██ ██      ██   ██          
██████     ██        ██   ████  ██████  ██      ██ ███████ ██   ██          
_EOF_
)"
}

function echo_review_badge {
  local number_of_review_notes=$1
  if [ ${number_of_review_notes} -gt 0 ] 
  then
    echo "$(cat <<_EOF_
<svg xmlns="http://www.w3.org/2000/svg" width="62" height="20">   <linearGradient id="b" x2="0" y2="100%">     <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>     <stop offset="1" stop-opacity=".1"/>   </linearGradient>   <mask id="a">     <rect width="62" height="20" rx="3" fill="#fff"/>   </mask>   <g mask="url(#a)">     <path fill="#555" d="M0 0h43v20H0z"/>     <path fill="#dfb317" d="M43 0h65v20H43z"/>     <path fill="url(#b)" d="M0 0h82v20H0z"/>   </g>   <g fill="#fff" text-anchor="middle"      font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">     <text x="21.5" y="15" fill="#010101" fill-opacity=".3">       review     </text>     <text x="21.5" y="14">       review     </text>     <text x="53" y="15" fill="#010101" fill-opacity=".3">       &#x1F4AC;     </text>     <text x="53" y="14">       &#x1F4AC;     </text>   </g> </svg>
_EOF_
)"
  else
    echo "$(cat <<_EOF_
<svg xmlns="http://www.w3.org/2000/svg" width="62" height="20">   <linearGradient id="b" x2="0" y2="100%">     <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>     <stop offset="1" stop-opacity=".1"/>   </linearGradient>   <mask id="a">     <rect width="62" height="20" rx="3" fill="#fff"/>   </mask>   <g mask="url(#a)">     <path fill="#555" d="M0 0h43v20H0z"/>     <path fill="#4c1" d="M43 0h65v20H43z"/>     <path fill="url(#b)" d="M0 0h82v20H0z"/>   </g>   <g fill="#fff" text-anchor="middle"      font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">     <text x="21.5" y="15" fill="#010101" fill-opacity=".3">       review     </text>     <text x="21.5" y="14">       review     </text>     <text x="51.5" y="15" fill="#010101" fill-opacity=".3">       &#x2713;     </text>     <text x="51.5" y="14">       &#x2713;     </text>   </g> </svg> 
_EOF_
)"
  fi
}

function echo_reproduce {
  echo -e "\n\nIf you'd like, you can generate your own name alignment by:"
  echo "  - installing GloBI's Nomer via https://github.com/globalbioticinteractions/nomer"
  echo "  - inspecting the align-names.sh script at https://github.com/globalbioticinteractions/globinizer/blob/master/align-names.sh\"\""
  echo "  - write your own script for name alignment"
  echo -e "\nPlease email info@globalbioticinteractions.org for questions/ comments."
}

function use_review_dir {
  rm -rf ${REVIEW_DIR}
  mkdir -p ${REVIEW_DIR}
  cd ${REVIEW_DIR}
}

function tee_readme {
  tee --append $README
}

function save_readme {
  cat ${README} > README.txt
}

function install_deps {
  if [[ -n ${TRAVIS_REPO_SLUG} || -n ${GITHUB_REPOSITORY} ]]
  then
    sudo apt-get -q update &> /dev/null
    sudo apt-get -q install miller jq -y &> /dev/null
    sudo pip install s3cmd &> /dev/null   
  fi

  mlr --version
  s3cmd --version
  java -version
}

function configure_taxonomy {
    mkdir -p .nomer
    local DOWNLOAD_URL="https://github.com/globalbioticinteractions/nomer/releases/download/${NOMER_VERSION}/$1_mapdb.zip"
    curl --silent -L "${DOWNLOAD_URL}" > ".nomer/$1_mapdb.zip"    
    unzip -qq  .nomer/$1_mapdb.zip -d .nomer
}

function configure_nomer {
  #NOMER_OPTS=" --cache-dir=\"${ELTON_DATASETS_DIR}\""

  if [[ $(which nomer) ]]
  then 
    echo using local nomer found at [$(which nomer)]
    export NOMER_CMD="nomer"
  else
    local NOMER_DOWNLOAD_URL="https://github.com/globalbioticinteractions/nomer/releases/download/${NOMER_VERSION}/nomer.jar"
    echo nomer not found... installing from [${NOMER_DOWNLOAD_URL}]
    curl --silent -L "${NOMER_DOWNLOAD_URL}" > "${NOMER_JAR}"
    export NOMER_CMD="java -Xmx4G -jar ${NOMER_JAR}"
    
    configure_taxonomy catalogue_of_life 
    configure_taxonomy ncbi
    configure_taxonomy discoverlife
    configure_taxonomy gbif
    configure_taxonomy itis
    configure_taxonomy globi
        
  fi

  export NOMER_VERSION=$(${NOMER_CMD} version)

  echo nomer version "${NOMER_VERSION}"
}


function tsv2csv {
  # for backward compatibility do not use
  #   mlr --itsv --ocsv cat
  # but use:
  mlr ${MLR_TSV_INPUT_OPTS} --ocsv cat
}

echo_logo | tee_readme 

install_deps

configure_nomer

function resolve_names {
  local RESOLVED=names-aligned-$2.tsv.gz
  echo -e "\n--- [$2] start ---\n"
  time cat $1 | gunzip | tail -n+2 | sort | uniq\
    | ${NOMER_CMD} append $2 --include-header\
    | gzip > $RESOLVED
  echo [$2] resolved $(cat $RESOLVED | gunzip | tail -n+2 | grep -v NONE | wc -l) out of $(cat $RESOLVED | gunzip | tail -n+2 | wc -l) names.
  echo [$2] first 10 unresolved names include:
  cat $RESOLVED | gunzip | tail -n+2 | grep NONE | cut -f1,2 | head -n11 
  echo -e "\n--- [$2] end ---\n"
}


echo -e "\nReview of [${ELTON_NAMESPACE}] started at [$(date -Iseconds)]." | tee_readme 


cat *.txt | sed 's/^/\t/g' | gzip > names.tsv.gz

# name resolving 
resolve_names names.tsv.gz col
resolve_names names.tsv.gz ncbi
resolve_names names.tsv.gz discoverlife
resolve_names names.tsv.gz gbif
resolve_names names.tsv.gz itis
${NOMER_CMD} clean 

NUMBER_OF_NOTES=$(cat *.tsv.gz | gunzip | cut -f5 | grep "^NONE$" | wc -l)

echo_review_badge $NUMBER_OF_NOTES > review.svg

if [ ${NUMBER_OF_NOTES} -gt 0 ]
then
  echo -e "\n[${REPO_NAME}] has ${NUMBER_OF_NOTES} names alignment note(s)" | tee_readme
else
  echo -e "\nHurray! [${REPO_NAME}] passed the GloBI review." | tee_readme
fi

echo_reproduce >> ${README}

save_readme

#
# publish review artifacts
#

function upload_file_io {
  echo -e "\nDownload the name alignment report with the single-use, and expiring, file.io link at:"
  curl --silent -F "file=@aligned-names.tsv.gz" https://file.io 
}


echo_reproduce



exit ${NUMBER_OF_NOTES}
