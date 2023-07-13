#!/bin/bash
#
#   imports single github globi data repository and check whether it can be read by GloBI.
#   If optional elton dataset dir is provided, no remote updates will be attempted.
#
#   usage:
#     check-dataset.sh [github repo name] [(optional) elton datasets dir]
# 
#   example:
#     ./check-dataset.sh globalbioticinteractions/template-dataset
#     ./check-dataset.sh globalbioticinteractions/template-dataset /var/cache/elton/datasets
#

#set -x

export REPO_NAME=$1
export ELTON_UPDATE_DISABLED=$2
export ELTON_DATASETS_DIR=${2:-./datasets}
export ELTON_VERSION=0.12.6
export ELTON_DATA_REPO_MAIN="https://raw.githubusercontent.com/${REPO_NAME}/main"
export ELTON_JAR="$PWD/elton.jar"
export ELTON_OPTS=""

export NOMER_VERSION=0.5.0
export NOMER_JAR="$PWD/nomer.jar"
export NOMER_PROPERTIES="$(mktemp)"
export NOMER_CACHE_DIR="${NOMER_CACHE_DIR:-~/.cache/nomer}"
export NOMER_OPTS=""

export REVIEW_REPO_HOST="blob.globalbioticinteractions.org"
export README=$(mktemp)
export REVIEW_DIR="review/${REPO_NAME}"

export MLR_TSV_INPUT_OPTS="--icsvlite --ifs tab"
export MLR_TSV_OUTPUT_OPTS="--ocsvlite --ofs tab"
export MLR_TSV_OPTS="${MLR_TSV_INPUT_OPTS} ${MLR_TSV_OUTPUT_OPTS}"

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
⚠️ Disclaimer: The results in this review should be considered
friendly, yet naive, notes from an unsophisticated robot. 
Please carefully review the results listed below and share issues/ideas
by email info at globalbioticinteractions.org or by opening an issue at 
https://github.com/globalbioticinteractions/globalbioticinteractions/issues .
_EOF_
)"
}

function echo_nomer_schema {
  # ignore authorship for now
  echo "$(cat <<_EOF_
nomer.cache.dir=${NOMER_CACHE_DIR}
nomer.schema.input=[{"column":0,"type":"externalId"},{"column": 1,"type":"name"}]
nomer.schema.output=[{"column":0,"type":"externalId"},{"column": 1,"type":"name"}]
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
  echo -e "\n\nIf you'd like, you can generate your own review notes by:"
  echo "  - installing GloBI's Elton via https://github.com/globalbioticinteractions/elton"
  echo "  - running \"elton update $REPO_NAME && elton review --type note --type summary $REPO_NAME > review.tsv\""
  echo "  - inspecting review.tsv"
  echo -e "\nPlease email info@globalbioticinteractions.org for questions/ comments."
}

function save_html_report {
  REVIEW_DATE="10 July 2023"

  cat > review.html <<_EOF_
<html>
<head>
    <meta content="text/html; charset=UTF-8" http-equiv="content-type">
    <style type="text/css">
        ol{margin:0;padding:0}table td,table th{padding:0}.c0{color:#595959;font-weight:400;text-decoration:none;vertical-align:baseline;font-size:12pt;font-family:"Arial";font-style:normal}.c5{color:#595959;font-weight:700;text-decoration:none;vertical-align:baseline;font-size:36pt;font-family:"Arial";font-style:normal}.c8{color:#000000;font-weight:400;text-decoration:none;vertical-align:baseline;font-size:11pt;font-family:"Arial";font-style:normal}.c11{padding-top:0pt;padding-bottom:0pt;line-height:1.15;orphans:2;widows:2;text-align:left}.c7{text-decoration-skip-ink:none;font-size:12pt;-webkit-text-decoration-skip:none;color:#0097a7;text-decoration:underline}.c1{padding-top:0pt;padding-bottom:12pt;line-height:1.15;text-align:left}.c10{font-size:24pt;color:#595959;font-weight:700}.c2{font-size:18pt;color:#595959;font-weight:700}.c4{background-color:#ffffff;max-width:468pt;padding:72pt 72pt 72pt 72pt}.c12{color:inherit;text-decoration:inherit}.c6{color:#595959;font-size:12pt}.c9{color:#595959;font-size:36pt}.c3{height:11pt}.title{padding-top:0pt;color:#000000;font-size:26pt;padding-bottom:3pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}.subtitle{padding-top:0pt;color:#666666;font-size:15pt;padding-bottom:16pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}li{color:#000000;font-size:11pt;font-family:"Arial"}p{margin:0;color:#000000;font-size:11pt;font-family:"Arial"}h1{padding-top:20pt;color:#000000;font-size:20pt;padding-bottom:6pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h2{padding-top:18pt;color:#000000;font-size:16pt;padding-bottom:6pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h3{padding-top:16pt;color:#434343;font-size:14pt;padding-bottom:4pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h4{padding-top:14pt;color:#666666;font-size:12pt;padding-bottom:4pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h5{padding-top:12pt;color:#666666;font-size:11pt;padding-bottom:4pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h6{padding-top:12pt;color:#666666;font-size:11pt;padding-bottom:4pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;font-style:italic;orphans:2;widows:2;text-align:left}
    </style>
</head>
<body class="c4 doc-content"><p class="c1"><span class="c6">Review of interactions in collection of the </span><span
        class="c7"><a class="c12"
                      href="https://github.com/$REPO_NAME">$REPO_NAME</a></span><span
        class="c0">&nbsp;as of $REVIEW_DATE </span></p>
<p class="c1"><span class="c0">According to GloBI's review process*, this collection contains</span></p>
<p class="c1"><span class="c9">&nbsp;</span><span class="c5">117,300 interactions</span></p>
<p class="c1"><span class="c6">involving </span><span class="c2">6 unique types of associations</span><span class="c0">, and these are the top 5:</span>
</p>
<p class="c1"><span class="c0">&nbsp; 81582 adjacentTo </span></p>
<p class="c1"><span class="c0">&nbsp; 34986 ectoparasiteOf</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp; 564 parasiteOf</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp; 166 interactsWith</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp; &nbsp; 1 hostOf</span></p>
<p class="c1 c3"><span class="c0"></span></p>
<p class="c1"><span class="c0">In these interactions, there appears to be </span></p>
<p class="c1"><span class="c10">19,263 primary taxa</span><span
        class="c0">&nbsp;(aka source taxa or subject taxa)</span></p>
<p class="c1"><span class="c0">top 5 most documented primary taxa in this dataset: </span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp;2638 Trichobius joblingi Wenzel, 1966</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp;1384 Marchantiophyta Stotler &amp; Crand.-Stotl.</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp;1287 Megistopoda aranea (Coquillétt, 1899)</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp;1162 Megistopoda proxima (Séguy, 1926)</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp;1012 Trichobius parasiticus Gervais, 1844</span></p>
<p class="c1"><span class="c0">and</span></p>
<p class="c1"><span class="c6">&nbsp;</span><span class="c10">31,896 associated taxa</span><span class="c0">&nbsp;(aka target taxa or object taxa)</span>
</p>
<p class="c1"><span class="c0">5 most frequently appearing associated taxa are:</span></p>
<p class="c1"><span class="c0">&nbsp; 2692 Carollia perspicillata</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp;1740 Artibeus jamaicensis</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp;1564 Desmodus rotundus</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp;1527 Sturnira lilium</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp;1373 ground</span></p>
<p class="c1"><span class="c0">Download the full datasets used in this review here. Learn more about the structure of this download here or contact mailto:info@globalbioticinteractions.org.</span>
</p>
<p class="c1"><span class="c6">To see all interactions on </span><span class="c7"><a class="c12"
                                                                                     href="https://www.google.com/url?q=https://globalbioticinteractions.org&amp;sa=D&amp;source=editors&amp;ust=1689279423357461&amp;usg=AOvVaw2c417cqTKPcVHoH4I-5kk6">GloBI website</a></span><span
        class="c0">, click here. https://www.globalbioticinteractions.org/?accordingTo=globi%3Aglobalbioticinteractions%2Ffmnh&amp;interactionType=interactsWith .</span>
</p>
<p class="c1"><span class="c0">As part of the review, all names are matched against GBIF Taxonomic Backbone, ITIS, Catalogue of Life, Parasite Tracker Taxonomy, and DiscoverLife. The top 5 names that for some reason, did not match any of our taxonomic resources are:</span>
</p>
<p class="c1"><span class="c0">&nbsp; &nbsp; &nbsp;57 Angiosperms</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp; &nbsp;47 Tree</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp; &nbsp;41 Oak</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp; &nbsp;37 Wood</span></p>
<p class="c1"><span class="c0">&nbsp; &nbsp; &nbsp;34 Inorganic</span></p>
<p class="c1"><span class="c0">Download the full list of names matches here. Learn more about the structure of the name reports here or contact mailto:info@globalbioticinteractions.org.</span>
</p>
<p class="c1"><span class="c0">For additional review resources go here. https://depot.globalbioticinteractions.org/reviews/globalbioticinteractions/fmnh/README.txt . </span>
</p>
<p class="c1 c3"><span class="c0"></span></p>
<p class="c1 c3"><span class="c0"></span></p>
<p class="c1 c3"><span class="c0"></span></p>
<p class="c1"><span class="c0">*⚠️ Disclaimer: The results in this review should be considered</span></p>
<p class="c1"><span class="c0">friendly, yet naive, notes from an unsophisticated robot. </span></p>
<p class="c1"><span class="c0">Please carefully review the results listed below and share issues/ideas</span></p>
<p class="c1"><span class="c0">by email info at globalbioticinteractions.org or by opening an issue at </span></p>
<p class="c1"><span class="c0">https://github.com/globalbioticinteractions/globalbioticinteractions/issues .</span></p>
<p class="c1 c3"><span class="c0"></span></p>
<p class="c3 c11"><span class="c8"></span></p></body>
</html>
_EOF_
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

function configure_elton {
  ELTON_OPTS=" --cache-dir=${ELTON_DATASETS_DIR}"

  if [[ $(which elton) ]]
  then 
    echo using local elton found at [$(which elton)]
    export ELTON_CMD="elton"
  else
    local ELTON_DOWNLOAD_URL="https://github.com/globalbioticinteractions/elton/releases/download/${ELTON_VERSION}/elton.jar"
    echo elton not found... installing from [${ELTON_DOWNLOAD_URL}]
    curl --silent -L "${ELTON_DOWNLOAD_URL}" > "${ELTON_JAR}"
    export ELTON_CMD="java -Xmx4G -jar ${ELTON_JAR}"
  fi

  export ELTON_VERSION=$(${ELTON_CMD} version)

  echo elton version "${ELTON_VERSION}"

  if [[ -n ${TRAVIS_REPO_SLUG} || -n ${GITHUB_REPOSITORY} ]]
    then
      ELTON_UPDATE="${ELTON_CMD} update ${ELTON_OPTS} --registry local"
      ELTON_NAMESPACE="local"
  else
    ELTON_UPDATE="${ELTON_CMD} update ${ELTON_OPTS} $REPO_NAME"
    ELTON_NAMESPACE="$REPO_NAME"
    # when running outside of travis, use a separate review directory'
    use_review_dir
  fi
}

function configure_taxonomy {
    mkdir -p ${NOMER_CACHE_DIR}
    local DOWNLOAD_URL="https://github.com/globalbioticinteractions/nomer/releases/download/${NOMER_VERSION}/$1_mapdb.zip"
    curl --silent -L "${DOWNLOAD_URL}" > "${NOMER_CACHE_DIR}/$1_mapdb.zip"
    unzip -qq  ${NOMER_CACHE_DIR}/$1_mapdb.zip -d ${NOMER_CACHE_DIR}
}

function configure_nomer {
  echo_nomer_schema | tee "${NOMER_PROPERTIES}"
  NOMER_OPTS=" --properties=${NOMER_PROPERTIES}"

  if [[ $(which nomer) ]]
  then 
    echo using local nomer found at [$(which nomer)]
    export NOMER_CMD="nomer"
  else
    local NOMER_DOWNLOAD_URL="https://github.com/globalbioticinteractions/nomer/releases/download/${NOMER_VERSION}/nomer.jar"
    echo nomer not found... installing from [${NOMER_DOWNLOAD_URL}]
    curl --silent -L "${NOMER_DOWNLOAD_URL}" > "${NOMER_JAR}"
    export NOMER_CMD="java -Xmx4G -jar ${NOMER_JAR}"
    
    configure_taxonomy col 
    configure_taxonomy ncbi
    configure_taxonomy discoverlife
    configure_taxonomy gbif
    configure_taxonomy itis
    configure_taxonomy tpt
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

configure_elton
configure_nomer

function resolve_names {
  local RESOLVED_STEM=indexed-names-resolved-$2
  local RESOLVED=${RESOLVED_STEM}.tsv.gz
  local RESOLVED_CSV=${RESOLVED_STEM}.csv.gz
  echo -e "\n--- [$2] start ---\n"
  time cat $1 | gunzip | tail -n+2 | sort | uniq\
    | ${NOMER_CMD} replace ${NOMER_OPTS} globi-correct\
    | ${NOMER_CMD} replace ${NOMER_OPTS} gn-parse\
    | ${NOMER_CMD} append ${NOMER_OPTS} $2 --include-header\
    | gzip > ${RESOLVED}
  cat ${RESOLVED}\
    | gunzip\
    | tsv2csv\
    | gzip\
    > ${RESOLVED_CSV}
  echo [$2] resolved $(cat $RESOLVED | gunzip | tail -n+2 | grep -v NONE | wc -l) out of $(cat $RESOLVED | gunzip | tail -n+2 | wc -l) names.
  echo [$2] first 10 unresolved names include:
  cat $RESOLVED | gunzip | tail -n+2 | grep NONE | cut -f1,2 | head -n11 
  echo -e "\n--- [$2] end ---\n"
}


echo -e "\nReview of [${ELTON_NAMESPACE}] started at [$(date -Iseconds)]." | tee_readme 

if [[ -z ${ELTON_UPDATE_DISABLED} ]]
then
  ${ELTON_UPDATE}
else
  echo no update: using provided elton datasets dir [${ELTON_DATASETS_DIR}] instead.
fi

${ELTON_CMD} review ${ELTON_OPTS} ${ELTON_NAMESPACE} --type note --type summary | gzip > review.tsv.gz
cat review.tsv.gz | gunzip | head -n501 > review-sample.tsv
cat review-sample.tsv | tsv2csv > review-sample.csv

${ELTON_CMD} interactions ${ELTON_OPTS} ${ELTON_NAMESPACE} | gzip > indexed-interactions.tsv.gz
cat indexed-interactions.tsv.gz | gunzip | tsv2csv | gzip > indexed-interactions.csv.gz

cat indexed-interactions.tsv.gz\
| gunzip\
| mlr ${MLR_TSV_OPTS} cut -f referenceDoi,referenceUrl,referenceCitation,namespace,citation,archiveURI\
| mlr ${MLR_TSV_OPTS} sort -f referenceDoi,referenceUrl,referenceCitation,namespace,citation,archiveURI\
| uniq\
| gzip > indexed-citations.tsv.gz 

cat indexed-citations.tsv.gz | gunzip | tsv2csv | gzip > indexed-citations.csv.gz 

${ELTON_CMD} names ${ELTON_OPTS} ${ELTON_NAMESPACE}\
| mlr ${MLR_TSV_OPTS} sort -f taxonName,taxonPath,taxonId,taxonPathIds,taxonRank,taxonPathNames\
| uniq\
| gzip > indexed-names.tsv.gz

cat indexed-names.tsv.gz | gunzip | tsv2csv | gzip > indexed-names.csv.gz
cat indexed-names.tsv.gz | gunzip | head -n501 > indexed-names-sample.tsv
cat indexed-names-sample.tsv | tsv2csv > indexed-names-sample.csv

# name resolving 
resolve_names indexed-names.tsv.gz col
resolve_names indexed-names.tsv.gz ncbi
resolve_names indexed-names.tsv.gz discoverlife
resolve_names indexed-names.tsv.gz gbif
resolve_names indexed-names.tsv.gz itis
resolve_names indexed-names.tsv.gz globi
resolve_names indexed-names.tsv.gz tpt

cat indexed-interactions.tsv.gz | gunzip | head -n501 > indexed-interactions-sample.tsv
cat indexed-interactions-sample.tsv | tsv2csv > indexed-interactions-sample.csv

${ELTON_CMD} nanopubs ${ELTON_OPTS} ${ELTON_NAMESPACE} | gzip > nanopub.trig.gz
cat nanopub.trig.gz | gunzip | head -n1 > nanopub-sample.trig

echo -e "\nReview of [${REPO_NAME}] included:" | tee_readme
cat review.tsv.gz | gunzip | tail -n3 | cut -f6 | sed s/^/\ \ -\ /g | tee_readme

NUMBER_OF_NOTES=$(cat review.tsv.gz | gunzip | cut -f5 | grep "^note$" | wc -l)

echo_review_badge $NUMBER_OF_NOTES > review.svg

if [ ${NUMBER_OF_NOTES} -gt 0 ]
then
  echo -e "\n[${REPO_NAME}] has ${NUMBER_OF_NOTES} reviewer note(s):" | tee_readme
  cat review.tsv.gz | gunzip | tail -n+2 | cut -f6 | tac | tail -n+5 | sort | uniq -c | sort -nr | tee_readme
else
  echo -e "\nHurray! [${REPO_NAME}] passed the GloBI review." | tee_readme
fi

echo_reproduce >> ${README}

save_readme

save_html_report

#
# publish review artifacts
#

function upload_file_io {
  echo -e "\nDownload the full review report with the single-use, and expiring, file.io link at:"
  curl --silent -F "file=@review.tsv.gz" https://file.io 
}

function upload {

  s3cmd --access_key "${ARTIFACTS_KEY}" --secret_key "${ARTIFACTS_SECRET}" --host "${REVIEW_REPO_HOST}" --host-bucket "${REVIEW_REPO_HOST}" put "$1" "s3://${ARTIFACTS_BUCKET}/reviews/${REPO_NAME}/$1" &> upload.log

  if [[ $? -ne 0 ]] ; then
     echo -e "\nfailed to upload $2, please check following upload log"
     cat upload.log
  else
     echo "https://depot.globalbioticinteractions.org/reviews/${REPO_NAME}/$1" | tee_readme
  fi

}

# atttempt to use travis artifacts tool if available
if [[ -n $(which s3cmd) ]] && [[ -n ${ARTIFACTS_KEY} ]] && [[ -n ${ARTIFACTS_SECRET} ]] && [[ -n ${ARTIFACTS_BUCKET} ]]
then
  echo -e "\nThis review generated the following resources:" | tee_readme
  upload review.html "review summary web page"
  upload review.svg "review badge"
  upload review.tsv.gz "data review"
  
  upload review-sample.tsv "data review sample tab-separated"
  upload review-sample.csv "data review sample csv"
  
  upload indexed-interactions.tsv.gz "indexed interactions"
  upload indexed-interactions.csv.gz "indexed interactions"
  
  upload indexed-interactions-sample.tsv "indexed interactions sample"
  upload indexed-interactions-sample.csv "indexed interactions sample"
  
  upload indexed-names.tsv.gz "indexed names"
  upload indexed-names.csv.gz "indexed names"

  upload indexed-names-resolved-col.tsv.gz "indexed names resolved against Catalogue of Life"  
  upload indexed-names-resolved-col.csv.gz "indexed names resolved against Catalogue of Life"  
  upload indexed-names-resolved-ncbi.tsv.gz "indexed names resolved against NCBI Taxonomy"  
  upload indexed-names-resolved-ncbi.csv.gz "indexed names resolved against NCBI Taxonomy"  
  upload indexed-names-resolved-discoverlife.tsv.gz "indexed names resolved against DiscoverLife Bee Checklist"  
  upload indexed-names-resolved-discoverlife.csv.gz "indexed names resolved against DiscoverLife Bee Checklist"  
  upload indexed-names-resolved-gbif.tsv.gz "indexed names resolved against GBIF backbone taxonomy"  
  upload indexed-names-resolved-gbif.csv.gz "indexed names resolved against GBIF backbone taxonomy"  
  upload indexed-names-resolved-itis.tsv.gz "indexed names resolved against Integrated Taxonomic Information System"  
  upload indexed-names-resolved-itis.csv.gz "indexed names resolved against Integrated Taxonomic Information System"  
  upload indexed-names-resolved-globi.tsv.gz "indexed names resolved against GloBI Taxon Graph"  
  upload indexed-names-resolved-globi.csv.gz "indexed names resolved against GloBI Taxon Graph"  
  upload indexed-names-resolved-tpt.tsv.gz "indexed names resolved against Terrestrial Parasite Tracker Taxonomy"  
  upload indexed-names-resolved-tpt.csv.gz "indexed names resolved against Terrestrial Parasite Tracker Taxonomy"  

  upload indexed-names-sample.tsv "indexed names sample"
  upload indexed-names-sample.csv "indexed names sample"
 
  upload indexed-citations.tsv.gz "indexed citations"
  upload indexed-citations.csv.gz "indexed citations"


  upload nanopub.trig.gz "interactions nanopubs"
  
  upload nanopub-sample.trig "interactions nanopub sample"

  if [[ -z ${ELTON_UPDATE_DISABLED} ]]
  then
    tar c datasets/* | gzip > datasets.tar.gz
    upload datasets.tar.gz "cached dataset archive"
  fi

  zip -r review.zip README.txt datasets/* indexed-* review*
  upload review.zip "review archive"
  
  save_readme
  upload README.txt "review summary"
else
  if [[ -n ${TRAVIS_REPO_SLUG} || -n ${GITHUB_REPOSITORY} ]]
  then
    upload_file_io
  else
    echo -e "\nFor detailed review results please see files in [$PWD].\n" | tee_readme
  fi
fi

echo_reproduce

exit ${NUMBER_OF_NOTES}
