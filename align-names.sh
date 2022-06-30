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

set -x

export REPO_NAME=$1

export NOMER_VERSION=0.2.13
export NOMER_JAR="$PWD/nomer.jar"

export PRESTON_VERSION=0.3.10
export PRESTON_JAR="$PWD/preston.jar"

export REVIEW_REPO_HOST="blob.globalbioticinteractions.org"
export README=$(mktemp)
export REVIEW_DIR="review/${REPO_NAME}"

export MLR_TSV_INPUT_OPTS="--icsvlite --ifs tab"
export MLR_TSV_OUTPUT_OPTS="--ocsvlite --ofs tab"
export MLR_TSV_OPTS="${MLR_TSV_INPUT_OPTS} ${MLR_TSV_OUTPUT_OPTS}"

export YQ_VERSION=4.25.3

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

⚠️ Disclaimer: The name alignment results in this review should be considered
friendly, yet naive, notes from an unsophisticated taxonomic robot. 
Please carefully review the results listed below and share issues/ideas
by email info at globalbioticinteractions.org or by opening an issue at 
https://github.com/globalbioticinteractions/globalbioticinteractions/issues .


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
  echo "  - inspecting the align-names.sh script at https://github.com/globalbioticinteractions/globinizer/blob/master/align-names.sh"
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
    sudo curl --silent -L https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_386 > /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq 
    sudo pip install s3cmd &> /dev/null   
  fi

  mlr --version
  s3cmd --version
  java -version
  yq --version
}

function configure_taxonomy {
    mkdir -p .nomer
    local DOWNLOAD_URL="https://github.com/globalbioticinteractions/nomer/releases/download/${NOMER_VERSION}/$1_mapdb.zip"
    curl --silent -L "${DOWNLOAD_URL}" > ".nomer/$1_mapdb.zip"    
    unzip -qq  .nomer/$1_mapdb.zip -d .nomer
}

function configure_preston {
  if [[ $(which preston) ]]
  then
    echo using local preston found at [$(which preston)]
    export NOMER_CMD="preston"
  else
    local PRESTON_DOWNLOAD_URL="https://github.com/bio-guoda/preston/releases/download/${PRESTON_VERSION}/preston.jar"
    echo preston not found... installing from [${PRESTON_DOWNLOAD_URL}]
    curl --silent -L "${PRESTON_DOWNLOAD_URL}" > "${PRESTON_JAR}"
    export PRESTON_CMD="java -Xmx4G -jar ${PRESTON_JAR}"
  fi
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
configure_preston

function resolve_names {
  local RESOLVED=names-aligned-$2.tsv.gz
  echo  'nomer.schema.input=[{"column":3,"type":"externalId"},{"column": 4,"type":"name"}]' > resolve.properties

  echo -e "\n--- [$2] start ---\n"
  time cat $1 | gunzip | tail -n+2 | sort | uniq\
    | ${NOMER_CMD} append --include-header gbif-parse\
    | ${NOMER_CMD} append --properties resolve.properties --include-header $2\
    | gzip > $RESOLVED
  NUMBER_OF_PROVIDED_NAMES=$(cat $1 | gunzip | tail -n+2 | cut -f1,2 | sort | uniq | wc -l)
  NUMBER_RESOLVED_NAMES=$(cat $RESOLVED | gunzip | tail -n+2 | grep -v NONE | sort | uniq | wc -l)
  echo [$2] aligned $NUMBER_RESOLVED_NAMES resolved names to $NUMBER_OF_PROVIDED_NAMES provided names.
  echo [$2] first 10 unresolved names include:
  echo 
  cat $RESOLVED | gunzip | tail -n+2 | grep NONE | cut -f1,2 | head -n11 | mlr --itsvlite --omd cat 
  echo -e "\n--- [$2] end ---\n"
}


echo -e "\nReview of [${REPO_NAME}] started at [$(date -Iseconds)]." | tee_readme 

if [ $(cat README.md | yq --front-matter=extract --header-preprocess '.datasets[].url' | wc -l) -gt 0 ]
then
  export TSV_LOCAL=$(cat README.md | yq --front-matter=extract --header-preprocess '.datasets[] | select(.type == "text/tab-separated-values") | .url' | grep -v "^http[s]{0,1}://") 
  export CSV_LOCAL=$(cat README.md | yq --front-matter=extract --header-preprocess '.datasets[] | select(.type == "text/csv") | .url' | grep -v "^http[s]{0,1}://") 
else 
  export TSV_LOCAL=$(ls -1 *.txt *.tsv)
  export CSV_LOCAL=$(ls -1 *.csv)
fi


function preston_track_local {
  # exclude empty lists
  if [ $(echo "$1" | wc -c) -gt 1  ]
  then
    echo -e "$1" | sed "s+^+file://$PWD/+g" | xargs ${PRESTON_CMD} track
  fi
}

function preston_head {
  ${PRESTON_CMD} history --log tsv\
  | tail -n1\
  | tr '\t' '\n'\
  | grep "^hash://"\
  | head -n1  
}

preston_track_local "$TSV_LOCAL"
${PRESTON_CMD} cat $(preston_head) | mlr --tsvlite cut -f scientificName | sed 's/^/\t/g' | gzip >> names.tsv.gz

preston_track_local "$CSV_LOCAL"

${PRESTON_CMD} cat $(preston_head) | mlr --icsv --otsv --ifs ';' cut -f scientificName | sed 's/^/\t/g' | tail -n+2 | gzip >> names.tsv.gz

if [ $(cat names.tsv.gz | gunzip | wc -l) -lt 2 ]
then
  echo "no names found: please check your configuration"
  exit 1
fi

# name resolving
resolve_names names.tsv.gz col
resolve_names names.tsv.gz ncbi
resolve_names names.tsv.gz gbif
resolve_names names.tsv.gz itis
ls names-aligned-*.tsv.gz | xargs -I '{}' sh -c "cat '{}' | gunzip | tail -n+2" | gzip > names-aligned.tsv.gz

echo "top 10 unresolved names sorted by decreasing number of mismatches across taxonomies"
echo '---'
cat names-aligned.tsv.gz | gunzip | grep NONE | cut -f2 | sort | uniq -c | sort -nr | head | sed 's/^[ ]+//g'
echo -e '---\n\n'



cat names-aligned.tsv.gz | gunzip | mlr --itsvlite --ocsv --ofs ';' cat > names-aligned.csv
cat names-aligned.tsv.gz | gunzip > names-aligned.tsv
cat names-aligned.tsv.gz | gunzip > names-aligned.txt

zip -r names-aligned.zip names-aligned.csv names-aligned.tsv names-aligned.txt data/

${NOMER_CMD} clean 

NUMBER_OF_NOTES=$(cat *.tsv.gz | gunzip | grep "NONE" | wc -l)

echo_review_badge $NUMBER_OF_NOTES > review.svg

if [ ${NUMBER_OF_NOTES} -gt 0 ]
then
  echo -e "\n[${REPO_NAME}] has ${NUMBER_OF_NOTES} names alignment note(s)" | tee_readme
else
  echo -e "\nHurray! [${REPO_NAME}] was able to align all names against various taxonomies." | tee_readme
fi

echo_reproduce >> ${README}

save_readme

#
# publish review artifacts
#

function upload_file_io {
  echo -e "\nDownload the name alignment results with the single-use, and expiring, file.io link at:"
  curl --silent -F "file=@names-aligned.zip" https://file.io | jq --raw-output .link  
}


echo_reproduce

upload_file_io


exit ${NUMBER_OF_NOTES}
