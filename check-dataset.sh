#!/bin/bash
#
#   imports single github globi data repository and generates a review report if suitable for indexing by GloBI.
#   If optional elton dataset dir is provided, no remote updates will be attempted.
#
#   usage:
#     check-dataset.sh [github repo name] [(optional) elton datasets dir]
# 
#   example:
#     ./check-dataset.sh globalbioticinteractions/template-dataset
#     ./check-dataset.sh globalbioticinteractions/template-dataset /var/cache/elton/datasets
#

set -x

export REVIEW_SCRIPT=$(readlink -f "$0")

export REPO_NAME=$1
export ELTON_UPDATE_DISABLED=$2
export ELTON_DATASETS_DIR=${2:-./datasets}
export ELTON_VERSION=0.13.2
export ELTON_DATA_REPO_MAIN="https://raw.githubusercontent.com/${REPO_NAME}/main"
export ELTON_JAR="$PWD/elton.jar"
export ELTON_OPTS=""

export NOMER_VERSION=0.5.6
export NOMER_JAR="$PWD/nomer.jar"
export NOMER_PROPERTIES="$(mktemp)"
export NOMER_CACHE_DIR="${NOMER_CACHE_DIR:-~/.cache/nomer}"
export NOMER_OPTS=""

export NETWORK_COMPILER_SCRIPT="$(echo "$REVIEW_SCRIPT" | sed -E 's+/[^/]{1,}$++g')/compile-network.sh"
export NETWORK_COMPILER_PRESENT=""
export NETWORK_CATALOG="col"
export NETWORK_CATALOG_DESCRIPTION="Catalogue of Life"

export REVIEW_REPO_HOST="blob.globalbioticinteractions.org"
export README=$(mktemp)
export REVIEW_DIR="${PWD}/review/${REPO_NAME}"

export MLR_TSV_OPTS="--csvlite --fs tab"
export MLR_TSV_INPUT_OPTS="--icsvlite --ifs tab"
export MLR_TSV_OUTPUT_OPTS="--ocsvlite --ofs tab"
export MLR_TSV_OPTS="${MLR_TSV_INPUT_OPTS} ${MLR_TSV_OUTPUT_OPTS}"

export TAXONOMIES="col ncbi discoverlife gbif itis globi mdd tpt pbdb"

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
    sudo apt -q install graphviz
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

function version_of {
  head -n1\
  | grep -o -E "([0-9]+[.]{0,1})+"
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

function generate_process_diagram {
 cat << _EOF_
digraph review {
      origin [label="dataset origin"];
      elton [label="Elton (a naive review bot)"];
      elton -> origin [label="pull (1)"];
      interactions [label="indexed interactions"];
      elton -> interactions [label="generates (2)"];
      alignment [label="name alignments"];
      nomer [label="Nomer (a naive review bot)"];
      catalog [label="name catalog"];
      nomer -> interactions [label="extract names (3)"];
      nomer -> catalog [label="uses (4)"];
      nomer -> alignment [label="generates (5)"];
}
_EOF_
}

function generate_model_diagram {
 cat << _EOF_
digraph model {
    primaryTaxon [label="Primary Taxon"];
    associatedTaxon [label="Associated Taxon"];
    { 
      rank=same;
      primaryOrganism [label="Primary Organism"];
      associatedOrganism [label="Associated Organism"];
      primaryOrganism -> associatedOrganism [label="interactsWith"];
    }
    primaryOrganism -> primaryTaxon [label="classifiedAs"];
    associatedOrganism -> associatedTaxon [label="classifiedAs"];
}
_EOF_
}


function generate_bibliography {
  cat << _EOF_
@article{Poelen_2014,
	doi = {10.1016/j.ecoinf.2014.08.005},
	url = {https://doi.org/10.1016%2Fj.ecoinf.2014.08.005},
	year = 2014,
	month = {nov},
	publisher = {Elsevier {BV}},
	volume = {24},
	pages = {148--159},
	author = {Jorrit H. Poelen and James D. Simons and Chris J. Mungall},
	title = {Global biotic interactions: An open infrastructure to share and analyze species-interaction datasets},
	journal = {Ecological Informatics}}

@article{Wilkinson_2016,
	doi = {10.1038/sdata.2016.18},
	url = {https://doi.org/10.1038%2Fsdata.2016.18},
	year = 2016,
	month = {mar},
	publisher = {Springer Science and Business Media {LLC}},
	volume = {3},
	number = {1},
	author = {Mark D. Wilkinson and Michel Dumontier and IJsbrand Jan Aalbersberg and Gabrielle Appleton and Myles Axton and Arie Baak and Niklas Blomberg and Jan-Willem Boiten and Luiz Bonino da Silva Santos and Philip E. Bourne and Jildau Bouwman and Anthony J. Brookes and Tim Clark and Merc{\`{e}} Crosas and Ingrid Dillo and Olivier Dumon and Scott Edmunds and Chris T. Evelo and Richard Finkers and Alejandra Gonzalez-Beltran and Alasdair J.G. Gray and Paul Groth and Carole Goble and Jeffrey S. Grethe and Jaap Heringa and Peter A.C 't Hoen and Rob Hooft and Tobias Kuhn and Ruben Kok and Joost Kok and Scott J. Lusher and Maryann E. Martone and Albert Mons and Abel L. Packer and Bengt Persson and Philippe Rocca-Serra and Marco Roos and Rene van Schaik and Susanna-Assunta Sansone and Erik Schultes and Thierry Sengstag and Ted Slater and George Strawn and Morris A. Swertz and Mark Thompson and Johan van der Lei and Erik van Mulligen and Jan Velterop and Andra Waagmeester and Peter Wittenburg and Katherine Wolstencroft and Jun Zhao and Barend Mons},
	title = {The {FAIR} Guiding Principles for scientific data management and stewardship},
	journal = {Scientific Data}
}

@misc{trekels_maarten_2023_8176978,
  author       = {Trekels, Maarten and
                  Pignatari Drucker, Debora and
                  Salim, José Augusto and
                  Ollerton, Jeff and
                  Poelen, Jorrit and
                  Miranda Soares, Filipi and
                  Rünzel, Max and
                  Kasina, Muo and
                  Groom, Quentin and
                  Devoto, Mariano},
  title        = {{WorldFAIR Project (D10.1) Agriculture-related 
                   pollinator data standards use cases report}},
  month        = jul,
  year         = 2023,
  publisher    = {Zenodo},
  version      = 1,
  doi          = {10.5281/zenodo.8176978},
  url          = {https://doi.org/10.5281/zenodo.8176978}
}


@misc{ICZN_1999,
  author       = {ICZN},
  title        = {International Code of Zoological Nomenclature},
  year         = 1999,
  publisher    = {The International Trust for Zoological Nomenclature, London, UK.},
  version      = {Fourth Edition},
  isbn         = {0853010064},
  url          = {https://www.iczn.org/the-code/the-code-online/}
}

_EOF_
}

function get_eml {
  find datasets/ -type f\
  | grep -E "[a-f0-9]{64}$"\
  | awk '{ print "-p " $1 " eml.xml" }'\
  | xargs -L1 unzip\
  | xmllint -
}

function generate_title {
  eml="$(get_eml)"
  if [[ $? -eq 0 ]]
  then
    collectionName=$(echo "${eml}" | xmllint --xpath '//collectionName' - | head -n1)
    echo "Versioned archive of datasets shared by the ${collectionName}, including a Review of Biotic Interactions and Taxon Names Found within the Darwin Core Archive."
  else
    echo "A Review of Biotic Interactions and Taxon Names Found in ${REPO_NAME}"
  fi
}

function generate_dataset_section {
  eml="$(get_eml)"
  if [[ $? -eq 0 ]]
  then
    datasetInfoUrl=$(echo "${eml}" | xmllint --xpath '//alternateIdentifier/text()' - | head -n1)
    collectionName=$(echo "${eml}" | xmllint --xpath '//collectionName' - | head -n1)
    licenseUrl=$(echo "${eml}" | xmllint --xpath '//intellectualRights/text()' - | head -n1)
    cat <<_EOF_
## Dataset

![logo of ${collectionName}]($(echo "${eml}" | xmllint --xpath '//resourceLogoUrl/text()' - | head -n1))

$(echo "${eml}" | xmllint --xpath '//dataset/abstract//text()' -)

The dataset darwin core archive was published on $(echo "${eml}" | xmllint --xpath '//pubDate/text()' -) and provided by $(echo "${eml}" | xmllint --xpath '//organizationName/text()' -). This dataset is published under a ${licenseUrl} license. 

**For more information**, see [${datasetInfoUrl}](${datasetInfoUrl}). 

_EOF_
 fi
}

function generate_md_report {
  headCount=21
  headCountWithoutHeader=20
  numberOfInteractions="$(printf "%'d" $(cat indexed-interactions.tsv.gz | gunzip | tail -n+2 | sort | uniq | wc -l))"
  numberOfInteractionTypes="$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f interactionTypeName | tail -n+2 | sort | uniq | wc -l)"
  mostFrequentInteractionTypes="$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} count-distinct -f interactionTypeName then sort -nr count then cut -f interactionTypeName | tail -n+2 | head -n1 | tr -d '\n')"
  uniqueSourceTaxa="$(printf "%'d" $(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f sourceTaxonName | tail -n+2 | sort | uniq | wc -l))"
  mostFrequentSourceTaxa="$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} count-distinct -f sourceTaxonName then sort -nr count then cut -f sourceTaxonName | tail -n+2 | head -n1 | tr -d '\n')"
  uniqueTargetTaxa="$(printf "%'d" $(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f targetTaxonName | tail -n+2 | sort | uniq | wc -l))"
  mostFrequentTargetTaxa="$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} count-distinct -f targetTaxonName then sort -nr count then cut -f targetTaxonName | tail -n+2 | head -n1 | tr -d '\n')"
  datasetVolume="$(${ELTON_CMD} log ${ELTON_OPTS} ${ELTON_NAMESPACE} | sort | uniq | ${ELTON_CMD} cat ${ELTON_OPTS} ${ELTON_NAMESPACE} | pv -f -b 2>&1 1>/dev/null | tr '\r' '\n' | grep -E '[0-9]' | tail -n1)"
  summaryPhrase="dataset under review (aka $REPO_NAME) has size ${datasetVolume} and contains ${numberOfInteractions} interactions with ${numberOfInteractionTypes} (e.g., ${mostFrequentInteractionTypes}) unique types of associations between ${uniqueSourceTaxa} primary taxa (e.g., ${mostFrequentSourceTaxa}) and ${uniqueTargetTaxa} associated taxa (e.g., ${mostFrequentTargetTaxa})."
  
  cat <<_EOF_
---
title: $(generate_title)
date: $(date --iso-8601)
author: 
  - by Nomer and Elton, two naive review bots
  - review@globalbioticinteractions.org
  - https://globalbioticinteractions.org/contribute 
  - https://github.com/${REPO_NAME}/issues 
abstract: |
  Life on earth is sustained by complex interactions between organisms and their environment. These biotic interactions can be captured in datasets and published digitally. We describe a review process of such an openly accessible digital interaction datasets of known origin, and discuss their outcome. The ${summaryPhrase} The report includes detailed summaries of interactions data as well as a taxonomic review from multiple perspectives.
bibliography: biblio.bib
keywords:
  - biodiversity informatics
  - ecology
  - species interactions
  - biotic interactions
  - automated manuscripts
  - taxonomic names
  - taxonomic name alignment
  - biology
reference-section-title: References
---

# Introduction

$(generate_dataset_section)

## Data Review

Data review can be a time consuming process, especially when done manually. This review report aims to help facilitate data review of species interaction claims made in datasets registered with Global Biotic Interactions [@Poelen_2014]. The review includes summary statistics of, and observations about, the dataset under review:

> $(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f citation,archiveURI,lastSeenAt,contentHash | tail -n+2 | sort | uniq | tr '\t' ' ')

For additional metadata related to this dataset, please visit [https://github.com/${REPO_NAME}](https://github.com/${REPO_NAME}) and inspect associated metadata files including, but not limited to, _README.md_, _eml.xml_, and/or _globi.json_.

# Methods

The review is performed through programmatic scripts that leverage tools like Preston, Elton, Nomer combined with third-party tools like grep, mlr, tail and head. 

 | tool name | version | 
 | --- | --- | 
 | [elton](httpsmisc://github.com/globalbioticinteractions/elton) | $(echo "${ELTON_VERSION}" | version_of) | 
 | [nomer](https://github.com/globalbioticinteractions/nomer) | $(echo "${NOMER_VERSION}" | version_of) |  
 | [mlr](https://miller.readthedocs.io/en/6.8.0/) | $(mlr --version | version_of) |  
 | [pandoc](https://pandoc.org/) | $(pandoc --version | version_of) |  
: Tools used in this review process

The review process can be described in the form of the script below ^[Note that you have to first get the data (e.g., via elton pull ${REPO_NAME}) before being able to generate reviews (e.g., elton review ${REPO_NAME}), extract interaction claims (e.g., elton interactions ${REPO_NAME}), or list taxonomic names (e.g., elton names ${REPO_NAME})].

~~~
# get versioned copy of the dataset (size approx. ${datasetVolume}) under review 
elton pull ${REPO_NAME}

# generate review notes
elton review ${REPO_NAME}\\
 > review.tsv

# export indexed interaction records
elton interactions ${REPO_NAME}\\
 > interactions.tsv

# export names and align them with the Catalogue of Life using Nomer 
elton names ${REPO_NAME}\\
 | nomer append col\\
 > name-alignment.tsv
~~~

or visually, in a process diagram.

![Review Process Overview](process.svg)

You can find a recent copy of the full review script at [check-data.sh](https://github.com/globalbioticinteractions/globinizer/blob/master/check-dataset.sh). 

# Results

In the following sections, the results of the review are summarized [^1]. Then, links to the detailed review reports are provided.

## Biotic Interactions

![Biotic Interaction Data Model](interaction.svg)

In this review, biotic interactions (or biotic associations) are modeled as a primary (aka subject, source) organism interacting with an associate (aka object, target) organism. The dataset under review classified the primary/associate organisms with specific taxa. The primary and associate organisms The kind of interaction is documented as an interaction type. 

The ${summaryPhrase}

An exhaustive list of indexed interaction claims can be found in [csv](indexed-interactions.csv) and [tsv](indexed-interactions.tsv) archives. To facilitate discovery, the first 500 claims available on the html page at [indexed-interactions.html](indexed-interactions.html) are shown below.

The exhaustive list was used to create the following data summaries below.

 
$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} --omd cut -r -f sourceTaxonName,interactionTypeName,targetTaxonName,referenceCitation | head -n6)
: Sample of Indexed Interaction Claims

$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} --omd count-distinct -f interactionTypeName then sort -nr count | head -n${headCount})
: Most Frequently Mentioned Interaction Types (up to ${headCountWithoutHeader} most frequent)

$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} --omd count-distinct -f sourceTaxonName then sort -nr count | head -n${headCount})
: Most Frequently Mentioned Primary Taxa (up to ${headCountWithoutHeader} most frequent)

$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} --omd count-distinct -f targetTaxonName then sort -nr count | head -n${headCount})
: Most Frequently Mentioned Associate Taxa (up to ${headCountWithoutHeader} most frequent)

$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} --omd count-distinct -f sourceTaxonName,interactionTypeName,targetTaxonName then sort -nr count | head -n${headCount})
: Most Frequent Interactions between Primary and Associate Taxa (up to ${headCountWithoutHeader} most frequent)

$(generate_network_graphs)

You can download the indexed dataset under review at [indexed-interactions.csv](indexed-interactions.csv). A tab-separated file can be found at [indexed-interactions.tsv](indexed-interactions.tsv) 

Learn more about the structure of this download at [GloBI website](https://globalbioticinteractions.org), by opening a [GitHub issue](https://github.com/globalbioticinteractions/globalbioticinteractions/issues/new), or by sending an [email](mailto:info@globalbioticinteractions.org).

Another way to discover the dataset under review is by searching for it on the [GloBI website](https://www.globalbioticinteractions.org/?accordingTo=globi%3A$(echo ${REPO_NAME} | sed 's+/+%2F+g')).


## Taxonomic Alignment

As part of the review, all names are aligned against various name catalogs (e.g., ${TAXONOMIES}). These alignments may serve as a way to review name usage or aid in selecting of a suitable taxonomic name resource to use. 

$(cat indexed-names-resolved.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f providedName,relationName,resolvedCatalogName,resolvedName | mlr ${MLR_TSV_INPUT_OPTS} --omd uniq -f providedName,relationName,resolvedCatalogName,resolvedName | head -n6) 
: Sample of Name Alignments

$(cat indexed-names-resolved.tsv.gz | gunzip | mlr --tsvlite uniq -f providedName,resolvedCatalogName,resolvedRank |  sed 's/\t$/\tNA/g' | mlr --itsvlite --omd count-distinct -f resolvedCatalogName,resolvedRank then sort -nr resolvedCatalogName,count)
: Distribution of Taxonomic Ranks of Aligned Names by Catalog. Names that were not aligned with a catalog are counted as NAs. So, the total number of unaligned names for a catalog will be listed in their NA row. 


$(cat indexed-names-resolved.tsv.gz | gunzip | mlr ${MLR_TSV_INPUT_OPTS} --omd count-distinct -f resolvedCatalogName,relationName then sort -f resolvedCatalogName)
: Name relationship types per catalog. Name relationship type "NONE" means that a name was not recognized by the associated catalog. "SAME_AS" indicates either a "HAS_ACCEPTED_NAME" or "SYNONYM_OF" name relationship type. We recognize that "SYNONYM_OF" encompasses many types of nomenclatural synonymies [@ICZN_1999] (e.g., junior synonym, senior synonyms). 

| catalog name | alignment results |
| --- | --- |
$(echo "${TAXONOMIES}" | tr ' ' '\n' | awk '{ print "| " $1 " | [associated names alignments (first 500](indexed-names-resolved-" $1 ".html), full [csv](indexed-names-resolved-" $1 ".csv)/[tsv](indexed-names-resolved-" $1 ".tsv)) |"}') 
: List of Available Name Alignment Reports

## Additional Reviews

Elton, Nomer, and other tools may have difficulties interpreting existing species interaction datasets. Or, they may misbehave, or otherwise show unexpected behavior. As part of the review process, detailed review notes are kept that document possibly misbehaving, or confused, review bots. An sample of review notes associated with this review can be found below.

$(cat review.tsv.gz | gunzip | mlr ${MLR_TSV_INPUT_OPTS} --omd cut -f reviewDate,reviewCommentType,reviewComment | head -n6)
: First few lines in the review notes.

In addtion, you can find the most frequently occurring notes in the table below.

$(cat review.tsv.gz | gunzip | mlr ${MLR_TSV_INPUT_OPTS} --omd cut -f reviewCommentType,reviewComment then filter '$reviewCommentType == "note"' then count-distinct -f reviewComment then sort -nr count | head -n6)
: Most frequently occurring review notes, if any.

For addition information on review notes, please have a look at the first 500 [Review Notes](review.html) or the download full [csv](review.csv) or [tsv](review.tsv) archives.

## GloBI Review Badge

As part of the review, a review badge is generated. This review badge can be included in webpages to indicate the review status of the dataset under review. 

![Sample of a GloBI Review Badge ^[Up-to-date status of the GloBI Review Badge can be retrieved from the [GloBI Review Depot](https://depot.globalbioticinteractions.org/reviews/${REPO_NAME}/review.svg)]](review.svg) 

Note that if the badge is green, no review notes were generated. If the badge is yellow, the review bots may need some help with interpreting the species interaction data.

## GloBI Index Badge

If the dataset under review has been [registered with GloBI](https://globalbioticinteractions.org/contribute), and has been succesfully indexed by GloBI, the GloBI Index Status Badge will turn green. This means that the dataset under review was indexed by GloBI and is available through GloBI services and derived data products. 

![Sample of a GloBI Index Badge ^[Up-to-date status of the GloBI Index Badge can be retrieved from [GloBI's API](https://api.globalbioticinteractions.org/interaction.svg?interactionType=ecologicallyRelatedTo&accordingTo=globi:${REPO_NAME}&refutes=true&refutes=false)]](https://api.globalbioticinteractions.org/interaction.svg?interactionType=ecologicallyRelatedTo&accordingTo=globi:${REPO_NAME}&refutes=true&refutes=false)

If you'd like to keep track of reviews or index status of the dataset under review, please visit [GloBI's dataset index ^[At time of writing ($(date --iso-8601)) the version of the GloBI dataset index was available at [https://globalbioticinteractions.org/datasets](https://globalbioticinteractions.org/datasets)]](https://globalbioticinteractions.org/datasets) for badge examples. 


# Discussion

This review is intended to provide a perspective on the dataset to aid understanding of species interaction claims discovered. However, this review should *not* be considered as fitness of use or other kind of quality assessment. Instead, the review may be used as in indication of the open-ness[^2] and FAIRness [@Wilkinson_2016; @trekels_maarten_2023_8176978] of the dataset: in order to perform this review, the data was likely openly available, **F**indable, **A**ccessible, **I**nteroperable and **R**eusable. Currently, this Open-FAIR assessment is qualitative, and with measurement units specified, a more quantitative approach can be implemented. 

# Acknowledgements

We thank the many humans that created us and those who created and maintained the data, software and other intellectual resources that were used for producing this review. In addition, we are grateful for the natural resources providing the basis for these human and bot activities.

[^1]: Disclaimer: The results in this review should be considered friendly, yet naive, notes from an unsophisticated robot. Please keep that in mind when considering the review results. 
[^2]: According to http://opendefinition.org/: "Open data is data that can be freely used, re-used and redistributed by anyone - subject only, at most, to the requirement to attribute and sharealike."
_EOF_
}


function clean_review_dir {
  rm -rf ${REVIEW_DIR}
}

function use_review_dir {
  clean_review_dir
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
    curl --silent -L https://github.com/jgm/pandoc/releases/download/3.1.6.1/pandoc-3.1.6.1-1-amd64.deb > pandoc.deb && sudo apt install -q ./pandoc.deb &> /dev/null
    sudo apt -q install pandoc-citeproc
    sudo apt -q install texlive texlive-xetex lmodern
    sudo apt -q install graphviz
    sudo apt -q install librsvg2-bin
    sudo apt -q install libxml2-utils
    sudo apt -q install pv
    sudo pip install s3cmd &> /dev/null   
  fi

  mlr --version
  s3cmd --version
  java -version
  pandoc --version
}

function configure_network_compiler {
  if [[ -x "${NETWORK_COMPILER_SCRIPT}" ]]
  then
    NETWORK_COMPILER_PRESENT=true
    echo found network compile script at [${NETWORK_COMPILER_SCRIPT}]
  fi
}

function patch_svg_width {
  # replace graphviz's dot absolute svg width/height with relative
  sed -E 's/^<svg width=\"[^\"]+\" height=\"[^\"]+\"/<svg width=\"100%\" height=\"auto\"/g'
}


function generate_network_graphs {
 
  echo -e "\n### Interaction Networks"

  local taxon_category_1="kingdom"
  local taxon_category_2="family"

  if [[ ! -z "${NETWORK_COMPILER_PRESENT}" ]]
  then
    source_target_args=("${NETWORK_CATALOG}-${taxon_category_1}-${NETWORK_CATALOG}-${taxon_category_1}" "${NETWORK_CATALOG}-${taxon_category_2}-${NETWORK_CATALOG}-${taxon_category_2}")
    for source_target in ${source_target_args[@]}
    do
      local network_graph_name="indexed-interactions-${source_target}.svg" 
      cat indexed-interactions.tsv.gz | gunzip | ${NETWORK_COMPILER_SCRIPT} $(echo "${source_target}" | tr '-' ' ') | tee indexed-interactions-${source_target}.dot | sfdp -Tsvg > "$network_graph_name"
      echo "${network_graph_name}" >> network-graph-names.txt
    done 
    echo "$(cat <<_EOF_

The figures below provide a graph view on the dataset under review. The first shows a summary network on the ${taxon_category_1} level, and the second shows how interactions on the ${taxon_category_2} level. Note that both network graphs were first aligned taxonomically via the ${NETWORK_CATALOG_DESCRIPTION}. Please refer to the original (or verbatim) taxonomic names for a more original view on the interaction data.  

![Interactions on taxonomic ${taxon_category_1} rank as interpreted by the ${NETWORK_CATALOG_DESCRIPTION} [download svg](indexed-interactions-${NETWORK_CATALOG}-${taxon_category_1}-${NETWORK_CATALOG}-${taxon_category_1}.svg)](indexed-interactions-${NETWORK_CATALOG}-${taxon_category_1}-${NETWORK_CATALOG}-${taxon_category_1}.svg)

![Interactions on the taxonomic ${taxon_category_2} rank as interpreted by the ${NETWORK_CATALOG_DESCRIPTION}. [download svg](indexed-interactions-${NETWORK_CATALOG}-${taxon_category_2}-${NETWORK_CATALOG}-${taxon_category_2}.svg)](indexed-interactions-${NETWORK_CATALOG}-${taxon_category_2}-${NETWORK_CATALOG}-${taxon_category_2}.svg)

_EOF_
)"
  else 
echo -e "\nNo interaction network graphs were generated at this time. If you'd like to include network diagrams, please make sure that ${NETWORK_COMPILER_SCRIPT} is available and executable.\n"
  fi
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

  export NOMER_VERSION=$(${NOMER_CMD} version | sed 's/@.*//g')

  echo nomer version "${NOMER_VERSION}"
}


function tsv2csv {
  # for backward compatibility do not use
  #   mlr --itsv --ocsv cat
  # but use:
  mlr ${MLR_TSV_INPUT_OPTS} --ocsv cat
}

function generate_styling {
  # from http://b.enjam.info/panam/styling.css
  cat <<_EOF_ 
@import url(//fonts.googleapis.com/css?family=Libre+Baskerville:400,400italic,700);@import url(//fonts.googleapis.com/css?family=Source+Code+Pro:400,400italic,700,700italic);/* normalize.css v3.0.0 | MIT License | git.io/normalize */html{font-family:sans-serif;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}body{margin:0}article,aside,details,figcaption,figure,footer,header,hgroup,main,nav,section,summary{display:block}audio,canvas,progress,video{display:inline-block;vertical-align:baseline}audio:not([controls]){display:none;height:0}[hidden],template{display:none}a{background:transparent}a:active,a:hover{outline:0}abbr[title]{border-bottom:1px dotted}b,strong{font-weight:bold}dfn{font-style:italic}h1{font-size:2em;margin:0.67em 0}mark{background:#ff0;color:#000}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sup{top:-0.5em}sub{bottom:-0.25em}img{border:0}svg:not(:root){overflow:hidden}figure{margin:1em 40px}hr{-moz-box-sizing:content-box;box-sizing:content-box;height:0}pre{overflow:auto}code,kbd,pre,samp{font-family:monospace, monospace;font-size:1em}button,input,optgroup,select,textarea{color:inherit;font:inherit;margin:0}button{overflow:visible}button,select{text-transform:none}button,html input[type="button"],input[type="reset"],input[type="submit"]{-webkit-appearance:button;cursor:pointer}button[disabled],html input[disabled]{cursor:default}button::-moz-focus-inner,input::-moz-focus-inner{border:0;padding:0}input{line-height:normal}input[type="checkbox"],input[type="radio"]{box-sizing:border-box;padding:0}input[type="number"]::-webkit-inner-spin-button,input[type="number"]::-webkit-outer-spin-button{height:auto}input[type="search"]{-webkit-appearance:textfield;-moz-box-sizing:content-box;-webkit-box-sizing:content-box;box-sizing:content-box}input[type="search"]::-webkit-search-cancel-button,input[type="search"]::-webkit-search-decoration{-webkit-appearance:none}fieldset{border:1px solid #c0c0c0;margin:0 2px;padding:0.35em 0.625em 0.75em}legend{border:0;padding:0}textarea{overflow:auto}optgroup{font-weight:bold}table{border-collapse:collapse;border-spacing:0}td,th{padding:0}body,code,tr.odd,tr.even,figure{background-image:url("data:image/png;base64,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")}body{font-family:"Libre Baskerville",Baskerville,Georgia,serif;background-color:#f8f8f8;color:#111;line-height:1.3;text-align:justify;-moz-hyphens:auto;-ms-hyphens:auto;-webkit-hyphens:auto;hyphens:auto}@media (max-width: 400px){body{font-size:12px;margin-left:10px;margin-right:10px;margin-top:10px;margin-bottom:15px}}@media (min-width: 401px) and (max-width: 600px){body{font-size:14px;margin-left:10px;margin-right:10px;margin-top:10px;margin-bottom:15px}}@media (min-width: 601px) and (max-width: 900px){body{font-size:15px;margin-left:100px;margin-right:100px;margin-top:20px;margin-bottom:25px}}@media (min-width: 901px) and (max-width: 1800px){body{font-size:17px;margin-left:200px;margin-right:200px;margin-top:30px;margin-bottom:25px;max-width:800px}}@media (min-width: 1801px){body{font-size:18px;margin-left:20%;margin-right:20%;margin-top:30px;margin-bottom:25px;max-width:1000px}}p{margin-top:10px;margin-bottom:18px}em{font-style:italic}strong{font-weight:bold}h1,h2,h3,h4,h5,h6{font-weight:bold;padding-top:0.25em;margin-bottom:0.15em}header{line-height:2.475em;padding-bottom:0.7em;border-bottom:1px solid #bbb;margin-bottom:1.2em}header>h1{border:none;padding:0;margin:0;font-size:225%}header>h2{border:none;padding:0;margin:0;font-style:normal;font-size:175%}header>h3{padding:0;margin:0;font-size:125%;font-style:italic}header+h1{border-top:none;padding-top:0px}h1{border-top:1px solid #bbb;padding-top:15px;font-size:150%;margin-bottom:10px}h1:first-of-type{border:none}h2{font-size:125%;font-style:italic}h3{font-size:105%;font-style:italic}hr{border:0px;border-top:1px solid #bbb;width:100%;height:0px}hr+h1{border-top:none;padding-top:0px}ul,ol{font-size:90%;margin-top:10px;margin-bottom:15px;padding-left:30px}ul{list-style:circle}ol{list-style:decimal}ul ul,ol ol,ul ol,ol ul{font-size:inherit}li{margin-top:5px;margin-bottom:7px}q,blockquote,dd{font-style:italic;font-size:90%}blockquote,dd{quotes:none;border-left:0.35em #bbb solid;padding-left:1.15em;margin:0 1.5em 0 0}blockquote blockquote,dd blockquote,blockquote dd,dd dd,ol blockquote,ol dd,ul blockquote,ul dd,blockquote ol,dd ol,blockquote ul,dd ul{font-size:inherit}a,a:link,a:visited,a:hover{color:inherit;text-decoration:none;border-bottom:1px dashed #111}a:hover,a:link:hover,a:visited:hover,a:hover:hover{border-bottom-style:solid}a.footnoteRef,a:link.footnoteRef,a:visited.footnoteRef,a:hover.footnoteRef{border-bottom:none;color:#666}code{font-family:"Source Code Pro","Consolas","Monaco",monospace;font-size:85%;background-color:#ddd;border:1px solid #bbb;padding:0px 0.15em 0px 0.15em;-webkit-border-radius:3px;-moz-border-radius:3px;border-radius:3px}pre{margin-right:1.5em;display:block}pre>code{display:block;font-size:70%;padding:10px;-webkit-border-radius:5px;-moz-border-radius:5px;border-radius:5px;overflow-x:auto}blockquote pre,dd pre,ul pre,ol pre{margin-left:0;margin-right:0}blockquote pre>code,dd pre>code,ul pre>code,ol pre>code{font-size:77.77778%}caption,figcaption{font-size:80%;font-style:italic;text-align:right;margin-bottom:5px}caption:empty,figcaption:empty{display:none}table{width:100%;margin-top:1em;margin-bottom:1em}table+h1{border-top:none}tr td,tr th{padding:0.2em 0.7em}tr.header{border-top:1px solid #222;border-bottom:1px solid #222;font-weight:700}tr.odd{background-color:#eee}tr.even{background-color:#ccc}tbody:last-child{border-bottom:1px solid #222}dt{font-weight:700}dt:after{font-weight:normal;content:":"}dd{margin-bottom:10px}figure{margin:1.3em 0 1.3em 0;text-align:center;padding:0px;width:100%;background-color:#ddd;border:1px solid #bbb;-webkit-border-radius:8px;-moz-border-radius:8px;border-radius:8px;overflow:hidden}img{display:block;margin:0px auto;padding:0px;max-width:100%}figcaption{margin:5px 10px 5px 30px}.footnotes{color:#666;font-size:70%;font-style:italic}.footnotes li p:last-child a:last-child{border-bottom:none}
_EOF_
}

function tsv2html {
  generate_styling > styling.css
  head -n501 | pandoc --embed-resources --standalone --metadata title=${REPO_NAME} --css=styling.css --to=html5 --from=tsv -o - | pv -l
}

echo_logo | tee_readme 

install_deps

configure_elton
configure_nomer
configure_network_compiler

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
    | mlr ${MLR_TSV_OPTS} put -s catalogName="${2}" '$resolvedCatalogName = @catalogName'\
    | mlr ${MLR_TSV_OPTS} reorder -f resolvedCatalogName -a relationName\
    | gzip > ${RESOLVED}
  cat ${RESOLVED}\
    | gunzip\
    | tsv2csv\
    | gzip\
    > ${RESOLVED_CSV}
  cat ${RESOLVED}\
    | gunzip\
    | mlr ${MLR_TSV_OPTS} cut -f providedExternalId,providedName,relationName,resolvedCatalogName,resolvedExternalUrl,resolvedName,resolvedAuthorship,resolvedRank\
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
cat review.tsv.gz | gunzip | tsv2csv | gzip > review.csv.gz
cat review.tsv.gz | gunzip | tsv2html | gzip > review.html.gz
cat review.tsv.gz | gunzip | head -n501 > review-sample.tsv
cat review-sample.tsv | tsv2csv > review-sample.csv
cat review-sample.tsv | tsv2html > review-sample.html

${ELTON_CMD} interactions ${ELTON_OPTS} ${ELTON_NAMESPACE} | gzip > indexed-interactions.tsv.gz
cat indexed-interactions.tsv.gz | gunzip | tsv2csv | gzip > indexed-interactions.csv.gz
cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -r -f sourceTaxon*,interactionTypeName,targetTaxon*,referenceCitation | tsv2html | gzip > indexed-interactions.html.gz

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
cat indexed-names.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -r -f taxon* | tsv2html | gzip > indexed-names.html.gz
cat indexed-names.tsv.gz | gunzip | head -n501 > indexed-names-sample.tsv
cat indexed-names-sample.tsv | tsv2csv > indexed-names-sample.csv
cat indexed-names-sample.tsv | mlr ${MLR_TSV_OPTS} cut -r -f taxon* | tsv2html > indexed-names-sample.html

# name resolving 
for taxonomy in ${TAXONOMIES}; do resolve_names indexed-names.tsv.gz ${taxonomy}; done;

# concatenate all name alignments
echo ${TAXONOMIES} | tr ' ' '\n' | awk '{ print "indexed-names-resolved-" $1 ".tsv.gz" }' | xargs mlr --prepipe gunzip ${MLR_TSV_OPTS} cat | mlr ${MLR_TSV_OPTS} sort -f providedName | uniq | gzip > indexed-names-resolved.tsv.gz
mlr ${MLR_TSV_INPUT_OPTS} --ocsv --prepipe gunzip cat indexed-names-resolved.tsv.gz | gzip > indexed-names-resolved.csv.gz
cat indexed-names-resolved.tsv.gz | gunzip | tsv2html | gzip > indexed-names-resolved.html.gz

cat indexed-interactions.tsv.gz | gunzip | head -n501 > indexed-interactions-sample.tsv
cat indexed-interactions-sample.tsv | tsv2csv > indexed-interactions-sample.csv
cat indexed-interactions-sample.tsv | mlr ${MLR_TSV_OPT} cut -r -f sourceTaxon*,interactionTypeName,targetTaxon*,referenceCitation | tsv2html > indexed-interactions-sample.html

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

generate_model_diagram\
 | dot -Tsvg\
 > interaction.svg

generate_process_diagram\
 | dot -Tsvg\
 > process.svg

generate_bibliography\
 > biblio.bib

generate_styling\
 > styling.css

function export_report_as {
  pandoc --embed-resources --standalone --toc --citeproc -t $1 -o -
}

generate_md_report\
 | tee index.md\
 > review.md
 
 
cat index.md\
 | export_report_as docx\
 > index.docx

cat index.md\
 | export_report_as pdf\
 > index.pdf

cat index.md\
 | export_report_as jats\
 > index.xml

function patch_network_graphs {
  for figure in $(cat network-graph-names.txt)
  do
    local figurePatched="$(basename $figure .svg).patched.svg"
    cat "${figure}"\
    | patch_svg_width\
    > "${figurePatched}"
    mv "${figurePatched}" "${figure}"
  done
}

patch_network_graphs

cat index.md\
 | export_report_as html5\
 > index.html


function upload {

  s3cmd --config "${S3CMD_CONFIG}" put "$PWD/$1" "s3://${ARTIFACTS_BUCKET}/reviews/${REPO_NAME}/$1" &> upload.log
  LAST_UPLOAD_RESULT=$?
  if [[ ${LAST_UPLOAD_RESULT} -ne 0 ]] ; then
     echo -e "\nfailed to upload [$1], please check following upload log"
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

if [[ -n ${TRAVIS_REPO_SLUG} || -n ${GITHUB_REPOSITORY} ]]
then 
  gunzip -f *.gz
fi

mkdir -p tmp-review
cp -R README.txt index.* datasets/* indexed-* review* *.css *.svg *.png *.bib tmp-review/
OLD_DIR="${PWD}"
cd tmp-review && gunzip -f *.gz && zip -R ../review.zip *
cd ${OLD_DIR}
rm -rf tmp-review

# attempt to use s3cmd tool if available and configured
if [[ -n $(which s3cmd) ]] && [[ -n ${S3CMD_CONFIG} ]]
then
  echo -e "\nThis review generated the following resources:" | tee_readme
  upload index.html "review summary web page"
  upload index.md "review pandoc page"
  upload index.docx "review pandoc word document"
  upload index.pdf "review pandoc pdf document"
  upload index.jats "review pandoc jats document"
  upload review.svg "review badge"
  upload process.svg "review process diagram"
  upload interaction.svg "interaction data model diagram"

  for networkgraph in $(cat network-graph-names.txt)
  do
    upload ${networkgraph} "summary network graph ${networkgraph}"
  done
  upload biblio.bib "bibliography"
  
  upload_package review-sample "data review sample"
  upload_package_gz review "review notes"
  
  upload_package_gz indexed-interactions "indexed interactions"
  
  upload_package indexed-interactions-sample "indexed interactions sample"
  
  upload_package_gz indexed-names "indexed names"

  upload_package_gz indexed-names-resolved "indexed names resolved across taxonomies [${TAXONOMIES}]"  
  
  for taxonomy in ${TAXONOMIES}; do 
    upload_package_gz "indexed-names-resolved-${taxonomy}" "indexed names resolved against [${taxonomy}" ; 
  done;

  upload_package indexed-names-sample "indexed names sample"
 
  upload_package_gz indexed-citations "indexed citations"

  upload nanopub.trig.gz "interactions nanopubs"
  
  upload nanopub-sample.trig "interactions nanopub sample"

  if [[ -z ${ELTON_UPDATE_DISABLED} ]]
  then
    tar c datasets/* | gzip > datasets.tar.gz
    upload datasets.tar.gz "cached dataset archive"
  fi
  
  upload review.zip "review archive"
  
  save_readme
  upload README.txt "review summary"
  if [[ ${LAST_UPLOAD_RESULT} -eq 0 ]]
  then
    clean_review_dir
  fi
fi

echo_reproduce

#exit ${NUMBER_OF_NOTES}
