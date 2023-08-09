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

export MLR_TSV_OPTS="--csvlite --fs tab"
export MLR_TSV_INPUT_OPTS="--icsvlite --ifs tab"
export MLR_TSV_OUTPUT_OPTS="--ocsvlite --ofs tab"
export MLR_TSV_OPTS="${MLR_TSV_INPUT_OPTS} ${MLR_TSV_OUTPUT_OPTS}"

export TAXONOMIES="col ncbi discoverlife gbif itis globi tpt"

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
  cat > review.html <<_EOF_
<html>
<head>
    <meta content="text/html; charset=UTF-8" http-equiv="content-type">
    <style type="text/css">
        ol{margin:0;padding:0}table td,table th{padding:0}.c0{color:#595959;font-weight:400;text-decoration:none;vertical-align:baseline;font-size:12pt;font-family:"Arial";font-style:normal}.c5{color:#595959;font-weight:700;text-decoration:none;vertical-align:baseline;font-size:36pt;font-family:"Arial";font-style:normal}.c8{color:#000000;font-weight:400;text-decoration:none;vertical-align:baseline;font-size:11pt;font-family:"Arial";font-style:normal}.c11{padding-top:0pt;padding-bottom:0pt;line-height:1.15;orphans:2;widows:2;text-align:left}.c7{text-decoration-skip-ink:none;font-size:12pt;-webkit-text-decoration-skip:none;color:#0097a7;text-decoration:underline}.c1{padding-top:0pt;padding-bottom:12pt;line-height:1.15;text-align:left}.c10{font-size:24pt;color:#595959;font-weight:700}.c2{font-size:18pt;color:#595959;font-weight:700}.c4{background-color:#ffffff;max-width:468pt;padding:72pt 72pt 72pt 72pt}.c12{color:inherit;text-decoration:inherit}.c6{color:#595959;font-size:12pt}.c9{color:#595959;font-size:36pt}.c3{height:11pt}.title{padding-top:0pt;color:#000000;font-size:26pt;padding-bottom:3pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}.subtitle{padding-top:0pt;color:#666666;font-size:15pt;padding-bottom:16pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}li{color:#000000;font-size:11pt;font-family:"Arial"}p{margin:0;color:#000000;font-size:11pt;font-family:"Arial"}h1{padding-top:20pt;color:#000000;font-size:20pt;padding-bottom:6pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h2{padding-top:18pt;color:#000000;font-size:16pt;padding-bottom:6pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h3{padding-top:16pt;color:#434343;font-size:14pt;padding-bottom:4pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h4{padding-top:14pt;color:#666666;font-size:12pt;padding-bottom:4pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h5{padding-top:12pt;color:#666666;font-size:11pt;padding-bottom:4pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;orphans:2;widows:2;text-align:left}h6{padding-top:12pt;color:#666666;font-size:11pt;padding-bottom:4pt;font-family:"Arial";line-height:1.15;page-break-after:avoid;font-style:italic;orphans:2;widows:2;text-align:left}
    </style>
</head>
<body class="c4 doc-content"><p class="c1"><span class="c6">Review of interactions in collection found via </span><span
        class="c7"><a class="c12"
                      href="https://github.com/$REPO_NAME">$REPO_NAME</a></span><span
        class="c0">&nbsp;as of $(date) </span>.</p>
<p class="c1"><span class="c0">According to GloBI's review process*, this collection contains</span></p>
<p class="c1"><span class="c9">&nbsp;</span><span class="c5">$(printf "%'d" $(cat indexed-interactions.tsv.gz | gunzip | tail -n+2 | sort | uniq | wc -l)) interactions</span></p>
<p class="c1"><span class="c6">involving </span><span class="c2">$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f interactionTypeName | tail -n+2 | sort | uniq | wc -l)  unique types of associations</span><span class="c0">, and these are the top 5:</span>
</p>
$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f interactionTypeName | tail -n+2 | sort | uniq -c | sort -nr | head -n5 | sed 's+^+<p class="c1"><span class="c0">\&nbsp; \&nbsp;+g' | sed 's+$+</span></p>+g')
<p class="c1 c3"><span class="c0"></span></p>
<p class="c1"><span class="c0">In these interactions, there appears to be </span></p>
<p class="c1"><span class="c10">$(printf "%'d" $(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f sourceTaxonName | tail -n+2 | sort | uniq | wc -l)) primary taxa</span><span
        class="c0">&nbsp;(aka source taxa or subject taxa)</span></p>
<p class="c1"><span class="c0">top 5 most documented primary taxa in this dataset: </span></p>
$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f sourceTaxonName | tail -n+2 | sort | uniq -c | sort -nr | head -n5 | sed 's+^+<p class="c1"><span class="c0">\&nbsp; \&nbsp;+g' | sed 's+$+</span></p>+g')
<p class="c1"><span class="c0">and</span></p>
<p class="c1"><span class="c6">&nbsp;</span><span class="c10">$(printf "%'d" $(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f targetTaxonName | tail -n+2 | sort | uniq | wc -l)) associated taxa</span><span class="c0">&nbsp;(aka target taxa or object taxa)</span>
</p>
<p class="c1"><span class="c0">5 most frequently appearing associated taxa are:</span></p>
$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f targetTaxonName | tail -n+2 | sort | uniq -c | sort -nr | head -n5 | sed 's+^+<p class="c1"><span class="c0">\&nbsp; \&nbsp;+g' | sed 's+$+</span></p>+g')
<p class="c1"><span class="c0">Download the full datasets used in this review here. Learn more about the structure of this download here or contact mailto:info@globalbioticinteractions.org.</span>
</p>
<p class="c1"><span class="c6">To see all interactions on </span><span class="c7"><a class="c12"
                                                                                     href="https://globalbioticinteractions.org">GloBI website</a></span><span
        class="c0">, click <a class="c12" href="https://www.globalbioticinteractions.org/?accordingTo=globi%3A$(echo ${REPO_NAME} | sed 's+/+%2F+g')">here<a> .</span>
</p>
<p class="c1"><span class="c0">As part of the review, all names are matched against GBIF Taxonomic Backbone, ITIS, NCBI Taxonomy, Catalogue of Life, Parasite Tracker Taxonomy, and DiscoverLife. The top 5 names that for some reason, did not match some or any of our taxonomic resources are:</span>
</p>
$(cat indexed-names-resolved.tsv.gz | gunzip | tail -n+2 | grep NONE | cut -f2 | sort | uniq -c | sort -nr | head -n5 | sed 's+^+<p class="c1"><span class="c0">\&nbsp; \&nbsp;+g' | sed 's+$+</span></p>+g')
<p class="c1"><span class="c0">Download the full list of names matches <a class="c12" href="https://depot.globalbioticinteractions.org/reviews/${REPO_NAME}/indexed-names-resolved.csv">here</a>. Learn more about the structure of the name reports here or contact us by <a class="c12" href="mailto:info@globalbioticinteractions.org">email</a>.</span>
</p>
<p class="c1"><span class="c0">For additional review resources go <a class="c12" href="https://depot.globalbioticinteractions.org/reviews/${REPO_NAME}/README.txt">here</a> . </span>
</p>
<p class="c1 c3"><span class="c0"></span></p>
<p class="c1 c3"><span class="c0"></span></p>
<p class="c1 c3"><span class="c0"></span></p>
<p class="c1"><span class="c0">*⚠️ Disclaimer: The results in this review should be considered</span></p>
<p class="c1"><span class="c0">friendly, yet naive, notes from an unsophisticated robot. </span></p>
<p class="c1"><span class="c0">Please carefully review the results listed below and share issues/ideas</span></p>
<p class="c1"><span class="c0">by <a class="c12" href="mailto:info@globalbioticinteractions.org>email</a> or by opening an <a class="c12" href="https://github.com/globalbioticinteractions/globalbioticinteractions/issues">issue</a>. at </span></p>
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
    sudo apt -q update &> /dev/null
    sudo apt -q install miller jq -y &> /dev/null
    curl --silent -L https://github.com/jgm/pandoc/releases/download/2.19.2/pandoc-2.19.2-1-amd64.deb > pandoc.deb && sudo install -q ./pandoc.deb &> /dev/null
    sudo pip install s3cmd &> /dev/null   
  fi

  mlr --version
  s3cmd --version
  java -version
  pandoc --version
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
   
    for taxonomy in ${TAXONOMIES}; do configure_taxonomy ${taxonomy}; done; 
        
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

function tsv2html {
  # from http://b.enjam.info/panam/styling.css
  cat > styling.css <<_EOF_ 
@import url(//fonts.googleapis.com/css?family=Libre+Baskerville:400,400italic,700);@import url(//fonts.googleapis.com/css?family=Source+Code+Pro:400,400italic,700,700italic);/* normalize.css v3.0.0 | MIT License | git.io/normalize */html{font-family:sans-serif;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}body{margin:0}article,aside,details,figcaption,figure,footer,header,hgroup,main,nav,section,summary{display:block}audio,canvas,progress,video{display:inline-block;vertical-align:baseline}audio:not([controls]){display:none;height:0}[hidden],template{display:none}a{background:transparent}a:active,a:hover{outline:0}abbr[title]{border-bottom:1px dotted}b,strong{font-weight:bold}dfn{font-style:italic}h1{font-size:2em;margin:0.67em 0}mark{background:#ff0;color:#000}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sup{top:-0.5em}sub{bottom:-0.25em}img{border:0}svg:not(:root){overflow:hidden}figure{margin:1em 40px}hr{-moz-box-sizing:content-box;box-sizing:content-box;height:0}pre{overflow:auto}code,kbd,pre,samp{font-family:monospace, monospace;font-size:1em}button,input,optgroup,select,textarea{color:inherit;font:inherit;margin:0}button{overflow:visible}button,select{text-transform:none}button,html input[type="button"],input[type="reset"],input[type="submit"]{-webkit-appearance:button;cursor:pointer}button[disabled],html input[disabled]{cursor:default}button::-moz-focus-inner,input::-moz-focus-inner{border:0;padding:0}input{line-height:normal}input[type="checkbox"],input[type="radio"]{box-sizing:border-box;padding:0}input[type="number"]::-webkit-inner-spin-button,input[type="number"]::-webkit-outer-spin-button{height:auto}input[type="search"]{-webkit-appearance:textfield;-moz-box-sizing:content-box;-webkit-box-sizing:content-box;box-sizing:content-box}input[type="search"]::-webkit-search-cancel-button,input[type="search"]::-webkit-search-decoration{-webkit-appearance:none}fieldset{border:1px solid #c0c0c0;margin:0 2px;padding:0.35em 0.625em 0.75em}legend{border:0;padding:0}textarea{overflow:auto}optgroup{font-weight:bold}table{border-collapse:collapse;border-spacing:0}td,th{padding:0}body,code,tr.odd,tr.even,figure{background-image:url("data:image/png;base64,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")}body{font-family:"Libre Baskerville",Baskerville,Georgia,serif;background-color:#f8f8f8;color:#111;line-height:1.3;text-align:justify;-moz-hyphens:auto;-ms-hyphens:auto;-webkit-hyphens:auto;hyphens:auto}@media (max-width: 400px){body{font-size:12px;margin-left:10px;margin-right:10px;margin-top:10px;margin-bottom:15px}}@media (min-width: 401px) and (max-width: 600px){body{font-size:14px;margin-left:10px;margin-right:10px;margin-top:10px;margin-bottom:15px}}@media (min-width: 601px) and (max-width: 900px){body{font-size:15px;margin-left:100px;margin-right:100px;margin-top:20px;margin-bottom:25px}}@media (min-width: 901px) and (max-width: 1800px){body{font-size:17px;margin-left:200px;margin-right:200px;margin-top:30px;margin-bottom:25px;max-width:800px}}@media (min-width: 1801px){body{font-size:18px;margin-left:20%;margin-right:20%;margin-top:30px;margin-bottom:25px;max-width:1000px}}p{margin-top:10px;margin-bottom:18px}em{font-style:italic}strong{font-weight:bold}h1,h2,h3,h4,h5,h6{font-weight:bold;padding-top:0.25em;margin-bottom:0.15em}header{line-height:2.475em;padding-bottom:0.7em;border-bottom:1px solid #bbb;margin-bottom:1.2em}header>h1{border:none;padding:0;margin:0;font-size:225%}header>h2{border:none;padding:0;margin:0;font-style:normal;font-size:175%}header>h3{padding:0;margin:0;font-size:125%;font-style:italic}header+h1{border-top:none;padding-top:0px}h1{border-top:1px solid #bbb;padding-top:15px;font-size:150%;margin-bottom:10px}h1:first-of-type{border:none}h2{font-size:125%;font-style:italic}h3{font-size:105%;font-style:italic}hr{border:0px;border-top:1px solid #bbb;width:100%;height:0px}hr+h1{border-top:none;padding-top:0px}ul,ol{font-size:90%;margin-top:10px;margin-bottom:15px;padding-left:30px}ul{list-style:circle}ol{list-style:decimal}ul ul,ol ol,ul ol,ol ul{font-size:inherit}li{margin-top:5px;margin-bottom:7px}q,blockquote,dd{font-style:italic;font-size:90%}blockquote,dd{quotes:none;border-left:0.35em #bbb solid;padding-left:1.15em;margin:0 1.5em 0 0}blockquote blockquote,dd blockquote,blockquote dd,dd dd,ol blockquote,ol dd,ul blockquote,ul dd,blockquote ol,dd ol,blockquote ul,dd ul{font-size:inherit}a,a:link,a:visited,a:hover{color:inherit;text-decoration:none;border-bottom:1px dashed #111}a:hover,a:link:hover,a:visited:hover,a:hover:hover{border-bottom-style:solid}a.footnoteRef,a:link.footnoteRef,a:visited.footnoteRef,a:hover.footnoteRef{border-bottom:none;color:#666}code{font-family:"Source Code Pro","Consolas","Monaco",monospace;font-size:85%;background-color:#ddd;border:1px solid #bbb;padding:0px 0.15em 0px 0.15em;-webkit-border-radius:3px;-moz-border-radius:3px;border-radius:3px}pre{margin-right:1.5em;display:block}pre>code{display:block;font-size:70%;padding:10px;-webkit-border-radius:5px;-moz-border-radius:5px;border-radius:5px;overflow-x:auto}blockquote pre,dd pre,ul pre,ol pre{margin-left:0;margin-right:0}blockquote pre>code,dd pre>code,ul pre>code,ol pre>code{font-size:77.77778%}caption,figcaption{font-size:80%;font-style:italic;text-align:right;margin-bottom:5px}caption:empty,figcaption:empty{display:none}table{width:100%;margin-top:1em;margin-bottom:1em}table+h1{border-top:none}tr td,tr th{padding:0.2em 0.7em}tr.header{border-top:1px solid #222;border-bottom:1px solid #222;font-weight:700}tr.odd{background-color:#eee}tr.even{background-color:#ccc}tbody:last-child{border-bottom:1px solid #222}dt{font-weight:700}dt:after{font-weight:normal;content:":"}dd{margin-bottom:10px}figure{margin:1.3em 0 1.3em 0;text-align:center;padding:0px;width:100%;background-color:#ddd;border:1px solid #bbb;-webkit-border-radius:8px;-moz-border-radius:8px;border-radius:8px;overflow:hidden}img{display:block;margin:0px auto;padding:0px;max-width:100%}figcaption{margin:5px 10px 5px 30px}.footnotes{color:#666;font-size:70%;font-style:italic}.footnotes li p:last-child a:last-child{border-bottom:none}
_EOF_
  pandoc --self-contained --metadata title=${REPO_NAME} --css=styling.css --to=html5 --from=tsv -o -
}

echo_logo | tee_readme 

install_deps

configure_elton
configure_nomer

function resolve_names {
  local RESOLVED_STEM=indexed-names-resolved-$2
  local RESOLVED=${RESOLVED_STEM}.tsv.gz
  local RESOLVED_CSV=${RESOLVED_STEM}.csv.gz
  local RESOLVED_HTML=${RESOLVED_STEM}.html.gz
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
  cat ${RESOLVED}\
    | gunzip\
    | tsv2html\
    | gzip\
    > ${RESOLVED_HTML}
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
cat review.tsv.gz | gunzip | tsv2csv | gzip > review-sample.csv.gz
cat review.tsv.gz | gunzip | tsv2html | gzip > review-sample.html.gz
cat review.tsv.gz | gunzip | head -n501 > review-sample.tsv
cat review-sample.tsv | tsv2csv > review-sample.csv
cat review-sample.tsv | tsv2html > review-sample.html

${ELTON_CMD} interactions ${ELTON_OPTS} ${ELTON_NAMESPACE} | gzip > indexed-interactions.tsv.gz
cat indexed-interactions.tsv.gz | gunzip | tsv2csv | gzip > indexed-interactions.csv.gz
cat indexed-interactions.tsv.gz | gunzip | tsv2html | gzip > indexed-interactions.html.gz

cat indexed-interactions.tsv.gz\
| gunzip\
| mlr ${MLR_TSV_OPTS} cut -f referenceDoi,referenceUrl,referenceCitation,namespace,citation,archiveURI\
| mlr ${MLR_TSV_OPTS} sort -f referenceDoi,referenceUrl,referenceCitation,namespace,citation,archiveURI\
| uniq\
| gzip > indexed-citations.tsv.gz 

cat indexed-citations.tsv.gz | gunzip | tsv2csv | gzip > indexed-citations.csv.gz 
cat indexed-citations.tsv.gz | gunzip | tsv2html | gzip > indexed-citations.html.gz 

${ELTON_CMD} names ${ELTON_OPTS} ${ELTON_NAMESPACE}\
| mlr ${MLR_TSV_OPTS} sort -f taxonName,taxonPath,taxonId,taxonPathIds,taxonRank,taxonPathNames\
| uniq\
| gzip > indexed-names.tsv.gz

cat indexed-names.tsv.gz | gunzip | tsv2csv | gzip > indexed-names.csv.gz
cat indexed-names.tsv.gz | gunzip | tsv2html | gzip > indexed-names.html.gz
cat indexed-names.tsv.gz | gunzip | head -n501 > indexed-names-sample.tsv
cat indexed-names-sample.tsv | tsv2csv > indexed-names-sample.csv
cat indexed-names-sample.tsv | tsv2html > indexed-names-sample.html

# name resolving 
for taxonomy in ${TAXONOMIES}; do resolve_names indexed-names.tsv.gz ${taxonomy}; done;

# concatenate all name alignments
echo ${TAXONOMIES} | tr ' ' '\n' | awk '{ print "indexed-names-resolved-" $1 ".tsv.gz" }' | xargs mlr --prepipe gunzip ${MLR_TSV_OPTS} cat | mlr ${MLR_TSV_OPTS} sort -f providedName | uniq | gzip > indexed-names-resolved.tsv.gz
mlr ${MLR_TSV_OPTS} --ocsv --prepipe gunzip cat indexed-names-resolved.tsv.gz | gzip > indexed-names-resolved.csv.gz

cat indexed-interactions.tsv.gz | gunzip | head -n501 > indexed-interactions-sample.tsv
cat indexed-interactions-sample.tsv | tsv2csv > indexed-interactions-sample.csv
cat indexed-interactions-sample.tsv | tsv2html > indexed-interactions-sample.html

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

  s3cmd --config "${S3CMD_CONFIG}" put "$1" "s3://${ARTIFACTS_BUCKET}/reviews/${REPO_NAME}/$1" &> upload.log

  if [[ $? -ne 0 ]] ; then
     echo -e "\nfailed to upload $2, please check following upload log"
     cat upload.log
  else
     echo "https://depot.globalbioticinteractions.org/reviews/${REPO_NAME}/$1" | tee_readme
  fi

}

function upload_package_gz {
  upload $1.tsv.gz $2
  upload $1.csv.gz $2
  upload $1.html.gz $2
}

function upload_package {
  upload $1.tsv $2
  upload $1.csv $2
  upload $1.html $2
}


# atttempt to use s3cmd tool if available and configured
if [[ -n $(which s3cmd) ]] && [[ -n ${S3CMD_CONFIG} ]]
then
  echo -e "\nThis review generated the following resources:" | tee_readme
  upload review.html "review summary web page"
  upload review.svg "review badge"
  upload review.tsv.gz "data review"
  
  upload_package review-sample "data review sample"
  
  upload_package_gz indexed-interactions "indexed interactions"
  
  upload_package indexed-interactions-sample "indexed interactions sample"
  
  upload_package_gz indexed-names "indexed names"

  upload_package_gz indexed-names-resolved "indexed names resolved across taxonomies [${TAXONOMIES}]"  
  upload_package_gz indexed-names-resolved-col "indexed names resolved against Catalogue of Life"  
  upload_package_gz indexed-names-resolved-ncbi "indexed names resolved against NCBI Taxonomy"  
  upload_package_gz indexed-names-resolved-discoverlife "indexed names resolved against DiscoverLife Bee Checklist"  
  upload_package_gz indexed-names-resolved-gbif "indexed names resolved against GBIF backbone taxonomy"  
  upload_package_gz indexed-names-resolved-itis "indexed names resolved against Integrated Taxonomic Information System"  
  upload_package_gz indexed-names-resolved-globi "indexed names resolved against GloBI Taxon Graph"  
  upload_package_gz indexed-names-resolved-tpt "indexed names resolved against Terrestrial Parasite Tracker Taxonomy"  

  upload_package indexed-names-sample "indexed names sample"
 
  upload_package indexed-citations "indexed citations"

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
