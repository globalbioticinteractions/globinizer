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
providedExternalId	providedName	parseRelation	parsedExternalId	parsedName	parsedAuthority	parsedRank	parsedCommonNames	parsedPath	parsedPathIds	parsedPathNames	parsedPathAuthorships	parsedNameSource	parsedNameSourceUrl	parsedNameSourceAccessedAt	alignRelation	alignedExternalId	alignedName	alignedAuthority	alignedRank	alignedCommonNames	alignedKingdomName	alignedKingdomId	alignedPhylumName	alignedPhylumId	alignedClassName	alignedClassId	alignedOrderName	alignedOrderId	alignedFamilyName	alignedFamilyId	alignedGenusName	alignedGenusId	alignedSubgenusName	alignedSubgenusId	alignedSpeciesName	alignedSpeciesId	alignedSubspeciesName	alignedSubspeciesId	alignedPath	alignedPathIds	alignedPathNames	alignedPathAuthorships	alignedNameSource	alignedNameSourceUrl	alignedNameSourceAccessedAt
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
nomer.append.schema.output=[{"column":0,"type":"externalUrl"},{"column": 1,"type":"name"},{"column": 2,"type":"authorship"},{"column": 3,"type":"rank"},{"column": 4,"type":"commonNames"},{"column": 5, "type":"path.kingdom.name"},{"column": 6, "type":"path.kingdom.id"},{"column": 7, "type":"path.phylum.name"},{"column": 8, "type":"path.phylum.id"},{"column":9, "type":"path.class.name"},{"column":10, "type":"path.class.id"},{"column":11, "type":"path.order.name"},{"column":12, "type":"path.order.id"},{"column":13, "type":"path.family.name"},{"column":14, "type":"path.family.id"},{"column":15, "type":"path.genus.name"},{"column":16, "type":"path.genus.id"},{"column":17, "type":"path.subgenus.name"},{"column":18, "type":"path.subgenus.id"},{"column":19, "type":"path.species.name"},{"column":20, "type":"path.species.id"},{"column":21, "type":"path.subspecies.name"},{"column":22, "type":"path.subspecies.id"},{"column":23,"type":"path"},{"column":24,"type":"pathIds"},{"column":25,"type":"pathNames"},{"column":26,"type":"pathAuthorships"},{"column":27,"type":"nameSource"},{"column":28,"type":"nameSourceUrl"},{"column":29,"type":"nameSourceAccessedAt"}]
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
    sudo pip install s3cmd &> /dev/null
  fi

  mlr --version
  s3cmd --version
  java -version
  yq --version
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

zip -r names-aligned.zip names-aligned.csv names-aligned.tsv names-aligned.txt data/

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
