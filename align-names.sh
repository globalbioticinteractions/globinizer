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

export NOMER_VERSION=0.5.0
export NOMER_JAR="$PWD/nomer.jar"
export NOMER_MATCHERS="col ncbi gbif itis wfo"
export NOMER_CACHE_DIR=${NOMER_CACHE_DIR:-~/.cache/nomer}

export PRESTON_VERSION=0.7.1
export PRESTON_JAR="$PWD/preston.jar"

export REVIEW_REPO_HOST="blob.globalbioticinteractions.org"
export README=$(mktemp)
export HEADER=$(mktemp)
export REVIEW_DIR="review/${REPO_NAME}"

export MLR_TSV_INPUT_OPTS="--icsvlite --ifs tab"
export MLR_TSV_OUTPUT_OPTS="--ocsvlite --ofs tab"
export MLR_TSV_OPTS="${MLR_TSV_INPUT_OPTS} ${MLR_TSV_OUTPUT_OPTS}"

export YQ_VERSION=4.25.3

echo_logo() {
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

names_aligned_header() {
  echo "$(cat <<_EOF_
providedExternalId	providedName	parseRelation	parsedExternalId	parsedName	parsedAuthority	parsedRank	parsedCommonNames	parsedPath	parsedPathIds	parsedPathNames	parsedPathAuthorships	parsedNameSource	parsedNameSourceUrl	parsedNameSourceAccessedAt	alignRelation	alignedExternalId	alignedName	alignedAuthority	alignedRank	alignedCommonNames	alignedKingdomName	alignedKingdomId	alignedPhylumName	alignedPhylumId	alignedClassName	alignedClassId	alignedOrderName	alignedOrderId	alignedFamilyName	alignedFamilyId	alignedSubfamilyName	alignedSubfamilyId	alignedTribeName	alignedTribeId	alignedSubtribeName	alignedSubtribeId	alignedGenusName	alignedGenusId	alignedSubgenusName	alignedSubgenusId	alignedSpeciesName	alignedSpeciesId	alignedSubspeciesName	alignedSubspeciesId	alignedPath	alignedPathIds	alignedPathNames	alignedPathAuthorships	alignedNameSource	alignedNameSourceUrl	alignedNameSourceAccessedAt
_EOF_
)"
}

names_aligned_header | gzip > $HEADER

parse_schema() {
  # ignore authorship for now
  echo "$(cat <<_EOF_
nomer.cache.dir=${NOMER_CACHE_DIR}
nomer.schema.input=[{"column":0,"type":"externalId"},{"column": 1,"type":"name"}]
nomer.schema.output=[{"column":0,"type":"externalId"},{"column": 1,"type":"name"}]
nomer.append.schema.output=[{"column":0,"type":"externalUrl"},{"column": 1,"type":"name"},{"column": 2,"type":"authorship"},{"column": 3,"type":"rank"},{"column": 4,"type":"commonNames"},{"column": 5,"type":"path"},{"column": 6,"type":"pathIds"},{"column": 7,"type":"pathNames"},{"column": 8,"type":"pathAuthorships"},{"column": 9,"type":"nameSource"},{"column": 10,"type":"nameSourceUrl"},{"column": 11,"type":"nameSourceAccessedAt"}]
_EOF_
)"
}


align_schema() {
  echo "$(cat <<_EOF_
nomer.schema.input=[{"column":3,"type":"externalId"},{"column": 4,"type":"name"}]
nomer.append.schema.output=[{"column":0,"type":"externalUrl"},{"column": 1,"type":"name"},{"column": 2,"type":"authorship"},{"column": 3,"type":"rank"},{"column": 4,"type":"commonNames"},{"column": 5, "type":"path.kingdom.name"},{"column": 6, "type":"path.kingdom.id"},{"column": 7, "type":"path.phylum.name"},{"column": 8, "type":"path.phylum.id"},{"column":9, "type":"path.class.name"},{"column":10, "type":"path.class.id"},{"column":11, "type":"path.order.name"},{"column":12, "type":"path.order.id"},{"column":13, "type":"path.family.name"},{"column":14, "type":"path.family.id"},{"column":15, "type":"path.subfamily.name"},{"column":16, "type":"path.subfamily.id"},{"column":17, "type":"path.tribe.name"},{"column":18, "type":"path.tribe.id"},{"column":19, "type":"path.subtribe.name"},{"column":20, "type":"path.subtribe.id"},{"column":21, "type":"path.genus.name"},{"column":22, "type":"path.genus.id"},{"column":23, "type":"path.subgenus.name"},{"column":24, "type":"path.subgenus.id"},{"column":25, "type":"path.species.name"},{"column":26, "type":"path.species.id"},{"column":27, "type":"path.subspecies.name"},{"column":28, "type":"path.subspecies.id"},{"column":29,"type":"path"},{"column":30,"type":"pathIds"},{"column":31,"type":"pathNames"},{"column":32,"type":"pathAuthorships"},{"column":33,"type":"nameSource"},{"column":34,"type":"nameSourceUrl"},{"column":35,"type":"nameSourceAccessedAt"}]
_EOF_
)"
}

echo_review_badge() {
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

echo_reproduce() {
  echo -e "\n\nIf you'd like, you can generate your own name alignment by:"
  echo "  - installing GloBI's Nomer via https://github.com/globalbioticinteractions/nomer"
  echo "  - inspecting the align-names.sh script at https://github.com/globalbioticinteractions/globinizer/blob/master/align-names.sh"
  echo "  - write your own script for name alignment"
  echo -e "\nPlease email info@globalbioticinteractions.org for questions/ comments."
}

use_review_dir() {
  rm -rf ${REVIEW_DIR}
  mkdir -p ${REVIEW_DIR}
  cd ${REVIEW_DIR}
}

tee_readme() {
  tee --append $README
}

save_readme() {
  cat ${README} > README.txt
}

install_deps() {
  if [[ -n ${TRAVIS_REPO_SLUG} || -n ${GITHUB_REPOSITORY} ]]
  then
    sudo apt-get -q update &> /dev/null
    sudo apt-get -q install miller jq -y &> /dev/null
    sudo curl --silent -L https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_386 > /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq 
    curl --silent -L https://github.com/jgm/pandoc/releases/download/3.1.6.1/pandoc-3.1.6.1-1-amd64.deb > pandoc.deb && sudo apt install -q ./pandoc.deb
    sudo pip install s3cmd &> /dev/null
  fi

  mlr --version
  s3cmd --version
  java -version
  yq --version
  pandoc --version
}

configure_taxonomy() {
    mkdir -p ${NOMER_CACHE_DIR}
    local DOWNLOAD_URL="https://github.com/globalbioticinteractions/nomer/releases/download/${NOMER_VERSION}/$1_mapdb.zip"
    curl --silent -L "${DOWNLOAD_URL}" > "${NOMER_CACHE_DIR}/$1_mapdb.zip"
    unzip -qq  ${NOMER_CACHE_DIR}/$1_mapdb.zip -d ${NOMER_CACHE_DIR}
}

configure_preston() {
  if [[ $(which preston) ]]
  then
    echo using local preston found at [$(which preston)]
    export PRESTON_CMD="preston"
  else
    local PRESTON_DOWNLOAD_URL="https://github.com/bio-guoda/preston/releases/download/${PRESTON_VERSION}/preston.jar"
    echo preston not found... installing from [${PRESTON_DOWNLOAD_URL}]
    curl --silent -L "${PRESTON_DOWNLOAD_URL}" > "${PRESTON_JAR}"
    export PRESTON_CMD="java -Xmx4G -jar ${PRESTON_JAR}"
  fi
}

configure_nomer() {
  local TAXONOMY_IDS=$(cat README.md | yq --front-matter=extract --header-preprocess '.taxonomies[] | select(.["enabled"] != false) | .id' | sort | uniq)
  if [ $(echo ${TAXONOMY_IDS} | grep -v null | tr ' ' '\n' | wc -l) -gt 0 ]
  then
    NOMER_MATCHERS=${TAXONOMY_IDS}
  fi

  echo nomer configured to use matchers: [${NOMER_MATCHERS}]

  if [[ $(which nomer) ]]
  then 
    echo using local nomer found at [$(which nomer)]
    export NOMER_CMD="nomer"
  else
    local NOMER_DOWNLOAD_URL="https://github.com/globalbioticinteractions/nomer/releases/download/${NOMER_VERSION}/nomer.jar"
    echo nomer not found... installing from [${NOMER_DOWNLOAD_URL}]
    curl --silent -L "${NOMER_DOWNLOAD_URL}" > "${NOMER_JAR}"
    export NOMER_CMD="java -Xmx4G -jar ${NOMER_JAR}"

    for matcher in ${NOMER_MATCHERS}
    do
      configure_taxonomy $matcher
    done
  fi

  export NOMER_VERSION=$(${NOMER_CMD} version)
  echo nomer version "${NOMER_VERSION}"

}


tsv2csv() {
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
  pandoc --embed-resources --standalone --metadata title=${REPO_NAME} --css=styling.css --to=html5 --from=tsv -o -
}


echo_logo | tee_readme

install_deps

configure_nomer
configure_preston

resolve_names() {
  local RESOLVED_NO_HEADER=names-aligned-$2-no-header.tsv.gz
  local RESOLVED=names-aligned-$2.tsv.gz
  parse_schema > parse.properties
  align_schema > align.properties

  echo -e "\n--- [$2] start ---\n"
  time cat $1 | gunzip | sort | uniq\
    | ${NOMER_CMD} append --properties parse.properties gbif-parse\
    | ${NOMER_CMD} append --properties align.properties  $2\
    | gzip > $RESOLVED_NO_HEADER
  NUMBER_OF_PROVIDED_NAMES=$(cat $1 | gunzip | cut -f1,2 | sort | uniq | wc -l)
  NUMBER_RESOLVED_NAMES=$(cat $RESOLVED_NO_HEADER | gunzip | grep -v NONE | sort | uniq | wc -l)
  cat $HEADER ${RESOLVED_NO_HEADER} >${RESOLVED}

  # insert catalogue name (or "matcher")
  # https://github.com/globalbioticinteractions/name-alignment-template/issues/6
    cat ${RESOLVED}\
  | gunzip\
  | mlr --tsvlite put -s catalogName="${2}" '$alignedCatalogName = @catalogName'\
  | mlr --tsvlite reorder -f alignedCatalogName -a alignRelation\
  | gzip\
  > ${RESOLVED}.new

  mv ${RESOLVED}.new ${RESOLVED}
  cat ${RESOLVED} | gunzip | tail -n+2 | gzip > ${RESOLVED_NO_HEADER}

  echo [$2] aligned $NUMBER_RESOLVED_NAMES resolved names to $NUMBER_OF_PROVIDED_NAMES provided names.
  echo [$2] first 10 unresolved names include:
  echo
  cat $RESOLVED | gunzip | grep NONE | cut -f1,2 | head
  echo -e "\n--- [$2] end ---\n"
}


echo -e "\nReview of [${REPO_NAME}] started at [$(date -Iseconds)]." | tee_readme

if [ $(cat README.md | yq --front-matter=extract --header-preprocess '.datasets[].url' | wc -l) -gt 0 ]
then
  export TSV_LOCAL=$(cat README.md | yq --front-matter=extract --header-preprocess '.datasets[] | select(.["enabled"] != false) | select(.type == "text/tab-separated-values") | .url' | grep -v -P "^http[s]{0,1}://") 
  export CSV_LOCAL=$(cat README.md | yq --front-matter=extract --header-preprocess '.datasets[] | select(.["enabled"] != false) | select(.type == "text/csv") | .url' | grep -v -P "^http[s]{0,1}://") 
  export DWCA_REMOTE=$(cat README.md | yq --front-matter=extract --header-preprocess '.datasets[] | select(.["enabled"] != false) | select(.type == "application/dwca" or .type == "application/rss+xml") | .url' | grep -P "^http[s]{0,1}://") 
  export NOMER_CATALOGS=$(cat README.md | yq --front-matter=extract --header-preprocess '.datasets[] | select(.["enabled"] != false) | select(.type == "application/nomer") | .id' | grep -Po "[a-z]+$") 
else
  export TSV_LOCAL=$(ls -1 *.txt *.tsv)
  export CSV_LOCAL=$(ls -1 *.csv)
  export DWCA_REMOTE=
  export NOMER_CATALOGS=
fi

preston_track_uri() {
  if [ $(echo "$1" | wc -c) -gt 1  ]
  then
    echo -e "$1" | xargs ${PRESTON_CMD} track
  fi
}

preston_track_local() {
  # exclude empty lists
  if [ $(echo "$1" | wc -c) -gt 1  ]
  then
    preston_track_uri $(echo -e "$1" | sed "s+^+file://$PWD/+g")
  fi
}

preston_head() {
  ${PRESTON_CMD} head
}

if [ $(echo "$TSV_LOCAL" | wc -c) -gt 1  ]
then
  preston_track_local "$TSV_LOCAL"
  ${PRESTON_CMD} cat $(preston_head) | grep "hasVersion" | ${PRESTON_CMD} cat | mlr --tsvlite put 'if (is_absent($id)) { $id = "" }' | mlr --tsvlite reorder -f id,scientificName | mlr --tsvlite cut -f id,scientificName | tail -n+2 | gzip >> names.tsv.gz  
fi


if [ $(echo "$CSV_LOCAL" | wc -c) -gt 1  ]
then
  preston_track_local "$CSV_LOCAL"
  ${PRESTON_CMD} cat $(preston_head) | grep "hasVersion" | ${PRESTON_CMD} cat | mlr --icsv --otsvlite --ifs ';' put 'if (is_absent($id)) { $id = "" }' | mlr --tsvlite reorder -f id,scientificName | mlr --tsvlite cut -f id,scientificName | tail -n+2 | gzip >> names.tsv.gz
fi

if [ $(echo "$DWCA_REMOTE" | wc -c) -gt 1  ]
then
  preston_track_uri "$DWCA_REMOTE"
  ${PRESTON_CMD} cat $(preston_head) | ${PRESTON_CMD} dwc-stream | jq --raw-output 'select(.["http://rs.tdwg.org/dwc/terms/scientificName"]) | [ .["http://www.w3.org/ns/prov#wasDerivedFrom"] , .["http://rs.tdwg.org/dwc/terms/scientificName"] ] | @tsv ' | gzip >> names.tsv.gz
fi

if [ $(echo "$NOMER_CATALOGS" | wc -c) -gt 1  ]
then
  for catalog in "$NOMER_CATALOGS"
  do
    ${NOMER_CMD} ls ${catalog} > ${catalog}.tsv
    preston_track_local "${catalog}.tsv"
    ${PRESTON_CMD} cat $(preston_head) | grep "hasVersion" | ${PRESTON_CMD} cat | cut -f1,2 | gzip >> names.tsv.gz
  done
fi


if [ $(cat names.tsv.gz | gunzip | wc -l) -lt 1 ]
then
  echo "no names found: please check your configuration"
  exit 1
fi

# name resolving
for matcher in ${NOMER_MATCHERS}
do
  echo using matcher [$matcher]
  resolve_names names.tsv.gz $matcher
done

ls names-aligned-*.tsv.gz | grep -v "no-header" | xargs cat | gunzip | head -n1 | gzip > names-aligned.tsv.gz
ls names-aligned-*.tsv.gz | grep "no-header" | xargs cat >> names-aligned.tsv.gz


echo "top 10 unresolved names sorted by decreasing number of mismatches across taxonomies"
echo '---'
cat names-aligned.tsv.gz | gunzip | grep NONE | cut -f2 | sort | uniq -c | sort -nr | head | sed 's/^[ ]+//g'
echo -e '---\n\n'

# sort by provided name to help visually compare the matches across catalogs for a provided name
# as suggested in https://github.com/globalbioticinteractions/name-alignment-template/issues/7
cat names-aligned.tsv.gz\
 | gunzip\
 | mlr --tsvlite sort -f providedName\
 | gzip\
 > names-aligned-sorted.tsv.gz

mv names-aligned-sorted.tsv.gz names-aligned.tsv.gz

cat names-aligned.tsv.gz | gunzip | mlr --itsvlite --ocsv --ofs ';' cat > names-aligned.csv
cat names-aligned.tsv.gz | gunzip > names-aligned.tsv
cat names-aligned.tsv.gz | gunzip > names-aligned.txt
cat names-aligned.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f providedName,alignRelation,alignedCatalogName,alignedExternalId,alignedName,alignedAuthority,alignedRank,alignedKingdomName,alignedFamilyName | tsv2html > names-aligned.html

zip -r names-aligned.zip names-aligned.csv names-aligned.tsv names-aligned.txt names-aligned.html data/

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

echo_reproduce
