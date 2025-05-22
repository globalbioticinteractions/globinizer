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
export ELTON_VERSION=0.15.7
export ELTON_DATA_REPO_MAIN="https://raw.githubusercontent.com/${REPO_NAME}/main"
export ELTON_JAR="$PWD/elton.jar"
export ELTON_OPTS=""

export HASH_ALGO="md5"

export PRESTON_VERSION=0.10.5
export PRESTON_JAR="$PWD/preston.jar"
export PRESTON_OPTS=" --algo ${HASH_ALGO}"

export NOMER_VERSION=0.5.15
export GLOBINIZER_VERSION=0.4.0
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

export TAXONOMIES="col ncbi discoverlife gbif itis wfo mdd tpt pbdb worms"

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
<svg xmlns="http://www.w3.org/2000/svg" width="62" height="20">   <linearGradient id="b" x2="0" y2="100%">     <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>     <stop offset="1" stop-opacity=".1"/>   </linearGradient>   <mask id="a">     <rect width="62" height="20" rx="3" fill="#fff"/>   </mask>   <g mask="url(#a)">     <path fill="#555" d="M0 0h43v20H0z"/>     <path fill="#4c1" d="M43 0h65v20H43z"/>     <path fill="url(#b)" d="M0 0h82v20H0z"/>   </g>   <g fill="#fff" text-anchor="middle"      font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">     <text x="21.5" y="15" fill="#010101" fill-opacity=".3">       review     </text>     <text x="21.5" y="14">       review     </text>     <text x="53" y="15" fill="#010101" fill-opacity=".3">       &#x1F4AC;     </text>     <text x="53" y="14">       &#x1F4AC;     </text>   </g> </svg>
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

@software{Preston,
  author       = {Michael Elliott and
                  Jorrit Poelen and
                  Icaro Alzuru and
                  Emilio Berti and
                  partha04patel},
  title        = {bio-guoda/preston: 0.10.5},
  month        = jan,
  year         = 2025,
  publisher    = {Zenodo},
  version      = {0.10.5},
  doi          = {10.5281/zenodo.14662206},
  url          = {https://doi.org/10.5281/zenodo.14662206},
}

@software{Nomer,
  author       = {José Augusto Salim and
                  Jorrit Poelen},
  title        = {globalbioticinteractions/nomer: 0.5.15},
  month        = feb,
  year         = 2025,
  publisher    = {Zenodo},
  version      = {0.5.15},
  doi          = {10.5281/zenodo.14893840},
  url          = {https://doi.org/10.5281/zenodo.14893840},
  swhid        = {swh:1:dir:521e44bf3950da369f4a2d7320e1ef108fa7a5f9
                   ;origin=https://doi.org/10.5281/zenodo.1145474;vis
                   it=swh:1:snp:cce707ad24abf51bac5504eb6eb8be7d774af
                   34f;anchor=swh:1:rel:5a29f84e40efcdfbbb76ae119af59
                   cb5ec6a8c7d;path=globalbioticinteractions-
                   nomer-a430fb0
                  },
}

@software{Elton,
  author       = {Tobias Kuhn and
                  Jorrit Poelen and
                  Katrin Leinweber},
  title        = {globalbioticinteractions/elton: 0.15.1},
  month        = feb,
  year         = 2025,
  publisher    = {Zenodo},
  version      = {0.15.1},
  doi          = {10.5281/zenodo.14927734},
  url          = {https://doi.org/10.5281/zenodo.14927734},
  swhid        = {swh:1:dir:2dfac02f031fe77f75189bdc9b0318ebf2f1fc96
                   ;origin=https://doi.org/10.5281/zenodo.998263;visi
                   t=swh:1:snp:b4c744faa133fc25e44c287102e8690b7e7b6a
                   b0;anchor=swh:1:rel:65fdfa5fed21a599250c2bf3740332
                   9048e7443c;path=globalbioticinteractions-
                   elton-6a3ed51
                  },
}

@software{globinizer,
  author       = {Jorrit Poelen and
                  Katja Seltmann and
                  Daniel Mietchen},
  title        = {globalbioticinteractions/globinizer: 0.4.0},
  month        = feb,
  year         = 2024,
  publisher    = {Zenodo},
  version      = {0.4.5},
  doi          = {10.5281/zenodo.10647565},
  url          = {https://doi.org/10.5281/zenodo.10647565},
}
 
@dataset{NomerCorpus,
  author       = {Poelen, Jorrit H. (ed.)},
  title        = {Nomer Corpus of Taxonomic Resources hash://sha256/
                   b60c0d25a16ae77b24305782017b1a270b79b5d1746f832650
                   f2027ba536e276
                   hash://md5/17f1363a277ee0e4ecaf1b91c665e47e
                  },
  month        = jul,
  year         = 2024,
  publisher    = {Zenodo},
  version      = {0.27},
  doi          = {10.5281/zenodo.12695629},
  url          = {https://doi.org/10.5281/zenodo.12695629},
}

@InProceedings{Nanopub,
author="Kuhn, Tobias
and Dumontier, Michel",
editor="Presutti, Valentina
and d'Amato, Claudia
and Gandon, Fabien
and d'Aquin, Mathieu
and Staab, Steffen
and Tordai, Anna",
title="Trusty URIs: Verifiable, Immutable, and Permanent Digital Artifacts for Linked Data",
booktitle="The Semantic Web: Trends and Challenges",
year="2014",
publisher="Springer International Publishing",
address="Cham",
pages="395--410",
abstract="To make digital resources on the web verifiable, immutable, and permanent, we propose a technique to include cryptographic hash values in URIs. We call them trusty URIs and we show how they can be used for approaches like nanopublications to make not only specific resources but their entire reference trees verifiable. Digital artifacts can be identified not only on the byte level but on more abstract levels such as RDF graphs, which means that resources keep their hash values even when presented in a different format. Our approach sticks to the core principles of the web, namely openness and decentralized architecture, is fully compatible with existing standards and protocols, and can therefore be used right away. Evaluation of our reference implementations shows that these desired properties are indeed accomplished by our approach, and that it remains practical even for very large files.",
isbn="978-3-319-07443-6"
}
 

_EOF_
}

function get_eml {
  find "${ELTON_DATASETS_DIR}/${ELTON_NAMESPACE}" -type f\
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
    echo "Versioned Darwin Core Archive Shared by ${collectionName}, Including a Review of Biotic Interactions and Taxon Names ${DATASET_VERSION}"
  else
    echo "Versioned Archive and Review of Biotic Interactions and Taxon Names Found within ${REPO_NAME} ${DATASET_VERSION}"
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

function pluralize {
  if [ $1 -gt 1 ]
  then 
    echo -e s
  fi    
}

function pluralize_taxon {
  if [ $1 -gt 1 ]
  then 
    echo -e taxa
  else
    echo -e taxon
  fi
}

function generate_zenodo_deposit_metadata {
  local report_md="${1}"
  cat <<_EOF_
 {
  "metadata": {
    "related_identifiers": [
      {
        "relation": "isAlternateIdentifier",
        "identifier": "${DATASET_VERSION}"
      },
      {
        "relation": "isAlternateIdentifier",
        "identifier": "${DATASET_ID}"
      },
      {
        "relation": "hasVersion",
        "identifier": "${DATASET_VERSION}"
      },
      {
        "relation": "isCompiledBy",
        "identifier": "10.5281/zenodo.14927734",
        "resource_type": "software"
      },
      {
        "relation": "isCompiledBy",
        "identifier": "10.5281/zenodo.14893840",
        "resource_type": "software"
      },
      {
        "relation": "isCompiledBy",
        "identifier": "10.5281/zenodo.14662206",
        "resource_type": "software"
      }
    ],
    "communities": [
      {
        "identifier": "globi-review"
      }
    ],
    "upload_type": "publication",
    "creators": [
      {
        "name": "Elton"
      },
      {
        "name": "Nomer"
      },
      {
        "name": "Preston"
      }
    ],
    "publication_type": "datapaper",
    "title": $(cat ${report_md} | yq -o json --front-matter=extract .title),
    "publication_date": "$(cat ${report_md} | yq --front-matter=extract .date)",
    "keywords": $(cat ${report_md} | yq -o json --front-matter=extract .keywords),
    "description": $(cat ${report_md} | pandoc --citeproc - | jq -s -R . | sed -E 's/href=\\"([^.\":]+[.][a-z][^\":]+|HEAD)\\"/href=\\"\{\{ ZENODO_DEPOSIT_ID \}\}\/files\/\1?download=1\\"/g')
  }
} 
_EOF_
}

function generate_md_report {
  headCount=21
  headCountWithoutHeader=20
  numberOfInteractions="$(printf "%'d" $(cat indexed-interactions.tsv.gz | gunzip | tail -n+2 | wc -l))"
  numberOfInteractionTypes="$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f interactionTypeName | tail -n+2 | sort | uniq | wc -l)"
  mostFrequentInteractionTypes="$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} count-distinct -f interactionTypeName then sort -nr count then cut -f interactionTypeName | tail -n+2 | head -n1 | tr -d '\n')"
  uniqueSourceTaxa="$(printf "%'d" $(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f sourceTaxonName | tail -n+2 | sort | uniq | wc -l))"
  mostFrequentSourceTaxa="$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} count-distinct -f sourceTaxonName then sort -nr count then cut -f sourceTaxonName | tail -n+2 | head -n1 | tr -d '\n')"
  uniqueTargetTaxa="$(printf "%'d" $(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f targetTaxonName | tail -n+2 | sort | uniq | wc -l))"
  mostFrequentTargetTaxa="$(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} count-distinct -f targetTaxonName then sort -nr count then cut -f targetTaxonName | tail -n+2 | head -n1 | tr -d '\n')"
  datasetVolume="$(${PRESTON_CMD} head ${PRESTON_OPTS} | ${PRESTON_CMD} cat | ${PRESTON_CMD} cat | pv -f -b 2>&1 1>/dev/null | tr '\r' '\n' | grep -E '[0-9]' | tail -n1)"
  summaryPhrase="dataset under review, named $REPO_NAME, has fingerprint ${DATASET_VERSION}, is ${datasetVolume} in size and contains ${numberOfInteractions} interaction$(pluralize ${numberOfInteractions}) with ${numberOfInteractionTypes} unique type$(pluralize ${numberOfInteractionTypes}) of association$(pluralize ${numberOfInteractionTypes}) (e.g., ${mostFrequentInteractionTypes}) between ${uniqueSourceTaxa} primary $(pluralize_taxon ${uniqueSourceTaxa}) (e.g., ${mostFrequentSourceTaxa}) and ${uniqueTargetTaxa} associated $(pluralize_taxon ${uniqueTargetTaxa}) (e.g., ${mostFrequentTargetTaxa})."
  
  cat <<_EOF_
---
title: $(generate_title)
date: $(date --iso-8601)
author: 
  - by Nomer, Elton and Preston, three naive review bots
  - review@globalbioticinteractions.org
  - https://globalbioticinteractions.org/contribute 
  - https://github.com/${REPO_NAME}/issues 
abstract: |
  Life on Earth is sustained by complex interactions between organisms and their environment. These biotic interactions can be captured in datasets and published digitally. We present a review and archiving process for such an openly accessible digital interactions dataset of known origin and discuss its outcome. The ${summaryPhrase} This report includes detailed summaries of interaction data, a taxonomic review from multiple catalogs, and an archived version of the dataset from which the reviews are derived.
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

## Data Review and Archive

Data review and archiving can be a time-consuming process, especially when done manually. This review report aims to help facilitate both activities. It automates the archiving of datasets, including Darwin Core archives, and is a citable backup of a version of the dataset. Additionally, an automatic review of species interaction claims made in the dataset is generated and registered with Global Biotic Interactions [@Poelen_2014].

This review includes summary statistics about, and observations about, the dataset under review:

> $(cat indexed-interactions.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f citation,archiveURI,lastSeenAt | tail -n+2 | sort | uniq | tr '\t' ' ') ${DATASET_VERSION}

For additional metadata related to this dataset, please visit [https://github.com/${REPO_NAME}](https://github.com/${REPO_NAME}) and inspect associated metadata files including, but not limited to, _README.md_, _eml.xml_, and/or _globi.json_.

# Methods

The review is performed through programmatic scripts that leverage tools like Preston [@Preston], Elton [@Elton], Nomer [@Nomer], globinizer [@globinizer] combined with third-party tools like grep, mlr, tail and head.

 | tool name | version | 
 | --- | --- | 
 | [preston](https://github.com/bio-guoda/preston) | $(echo "${PRESTON_VERSION}" | version_of) |  
 | [elton](https://github.com/globalbioticinteractions/elton) | $(echo "${ELTON_VERSION}" | version_of) | 
 | [nomer](https://github.com/globalbioticinteractions/nomer) | $(echo "${NOMER_VERSION}" | version_of) |  
 | [globinizer](https://github.com/globalbioticinteractions/globinizer) | $(echo "${GLOBINIZER_VERSION}" | version_of) |  
 | [mlr](https://miller.readthedocs.io/en/6.8.0/) | $(mlr --version | version_of) |  
 | [jq](https://jqlang.org/) | $(jq --version | version_of) |  
 | [yq](https://mikefarah.gitbook.io/yq) | $(yq --version | version_of) |  
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

You can find a copy of the full review script at [check-data.sh](check-dataset.sh). See also [GitHub](https://github.com/globalbioticinteractions/globinizer/blob/master/check-dataset.sh) and [Codeberg](https://codeberg.org/globalbioticinteractions/globinizer/src/branch/master/check-dataset.sh). 

# Results

In the following sections, the results of the review are summarized [^1]. Then, links to the detailed review reports are provided.

## Files

The following files are produced in this review:

 filename | description
 --- | ---  
 [biblio.bib](biblio.bib) | list of bibliographic reference of this review 
 [check-dataset.sh](check-dataset.sh) | data review workflow/process as expressed in a bash script
 [data.zip](data.zip) | a versioned archive of the data under review
 [HEAD](HEAD) | the digital signature of the data under review
 [index.docx](index.docx) | review in MS Word format 
 [index.html](index.html) | review in HTML format 
 [index.md](index.md) |  review in Pandoc markdown format
 [index.pdf](index.pdf) | review in PDF format
 [indexed-citations.csv.gz](indexed-citations.csv.gz) | list of distinct reference citations for reviewed species interaction claims in gzipped comma-separated values file format 
 [indexed-citations.html.gz](indexed-citations.html.gz) | list of distinct reference citations for reviewed species interactions claims in gzipped html file format
 [indexed-citations.tsv.gz](indexed-citations.tsv.gz) | list of distinct reference citations for reviewed species interaction claims in gzipped tab-separated values format
 [indexed-interactions-col-family-col-family.svg](indexed-interactions-col-family-col-family.svg) | network diagram showing the taxon family to taxon family interaction claims in the dataset under review as interpreted by the Catalogue of Life via Nomer Corpus of Taxonomic Resources [@NomerCorpus]
 [indexed-interactions-col-kingdom-col-kingdom.svg](indexed-interactions-col-kingdom-col-kingdom.svg) | network diagram showing the taxon kingdom to taxon kingom interaction claims in the dataset under review as interpreted by the Catalogue of Life via Nomer Corpus of Taxonomic Resources [@NomerCorpus]
 [indexed-interactions.csv.gz](indexed-interactions.csv.gz) | species interaction claims indexed from the dataset under review in gzipped comma-separated values format 
 [indexed-interactions.html.gz](indexed-interactions.html.gz) | species interaction claims indexed from the dataset under review in gzipped html format
 [indexed-interactions.tsv.gz](indexed-interactions.tsv.gz) | species interaction claims indexed from the dataset under review in gzipped tab-separated values format
 [indexed-interactions-sample.csv](indexed-interactions-sample.csv) | list of species interaction claims indexed from the dataset under review in gzipped comma-separated values format
 [indexed-interactions-sample.html](indexed-interactions-sample.html) | first 500 species interaction claims indexed from the dataset under review in html format 
 [indexed-interactions-sample.tsv](indexed-interactions-sample.tsv) | first 500 species interaction claims indexed from the dataset under review in tab-separated values format
 [indexed-names.csv.gz](indexed-names.csv.gz) | taxonomic names indexed from the dataset under review in gzipped comma-separated values format 
 [indexed-names.html.gz](indexed-names.html.gz) | taxonomic names found in the dataset under review in gzipped html format
 [indexed-names.tsv.gz](indexed-names.tsv.gz) | taxonomic names found in the dataset under review in gzipped tab-separated values format
 [indexed-names-resolved-col.csv.gz](indexed-names-resolved-col.csv.gz) | taxonomic names found in the dataset under review aligned with the Catalogue of Life as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped comma-separated values format
 [indexed-names-resolved-col.html.gz](indexed-names-resolved-col.html.gz) | taxonomic names found in the dataset under review aligned with the Catalogue of Life as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped html format
 [indexed-names-resolved-col.tsv.gz](indexed-names-resolved-col.tsv.gz) | taxonomic names found in the dataset under review aligned with the Catalogue of Life as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped tab-separated values format
 [indexed-names-resolved-discoverlife.csv.gz](indexed-names-resolved-discoverlife.csv.gz) | taxonomic names found in the dataset under review aligned with Discover Life bee species checklist as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped comma-separated values format
 [indexed-names-resolved-discoverlife.html.gz](indexed-names-resolved-discoverlife.html.gz) | taxonomic names found in the dataset under review aligned with Discover Life bee species checklist as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped html format
 [indexed-names-resolved-discoverlife.tsv.gz](indexed-names-resolved-discoverlife.tsv.gz) | taxonomic names found in the dataset under review aligned with Discover Life bee species checklist as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped tab-separated values format
 [indexed-names-resolved-gbif.csv.gz](indexed-names-resolved-gbif.csv.gz) | taxonomic names found in the dataset under review aligned with GBIF Backbone Taxonomy as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped comma-separated values format
 [indexed-names-resolved-gbif.html.gz](indexed-names-resolved-gbif.html.gz) | taxonomic names found in the dataset under review aligned with GBIF Backbone Taxonomy as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped html format
 [indexed-names-resolved-gbif.tsv.gz](indexed-names-resolved-gbif.tsv.gz) | taxonomic names found in the dataset under review aligned with GBIF Backbone Taxonomy as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus]  in gzipped tab-separated values format
 [indexed-names-resolved-itis.csv.gz](indexed-names-resolved-itis.csv.gz) | taxonomic names found in the dataset under review aligned with  Integrated Taxonomic Information System (ITIS) as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus]  in gzipped comma-separated values format
 [indexed-names-resolved-itis.html.gz](indexed-names-resolved-itis.html.gz) | taxonomic names found in the dataset under review aligned with Integrated Taxonomic Information System (ITIS) as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus]  in gzipped html format
 [indexed-names-resolved-itis.tsv.gz](indexed-names-resolved-itis.tsv.gz) | taxonomic names found in the dataset under review aligned with Integrated Taxonomic Information System (ITIS) as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus]  in gzipped tab-separated values format
 [indexed-names-resolved-mdd.csv.gz](indexed-names-resolved-mdd.csv.gz) | taxonomic names found in the dataset under review aligned with the Mammal Diversity Database as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped comma-separated values format
 [indexed-names-resolved-mdd.html.gz](indexed-names-resolved-mdd.html.gz) | taxonomic names found in the dataset under review aligned with Mammal Diversity Database as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped html format
 [indexed-names-resolved-mdd.tsv.gz](indexed-names-resolved-mdd.tsv.gz) | taxonomic names found in the dataset under review aligned with Mammal Diversity Database as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped tab-separated values format
 [indexed-names-resolved-ncbi.csv.gz](indexed-names-resolved-ncbi.csv.gz) | taxonomic names found in the dataset under review aligned with the NCBI Taxonomy as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped comma-separated values format
 [indexed-names-resolved-ncbi.html.gz](indexed-names-resolved-ncbi.html.gz) | taxonomic names found in the dataset under review aligned with the NCBI Taxonomy as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped html format
 [indexed-names-resolved-ncbi.tsv.gz](indexed-names-resolved-ncbi.tsv.gz) | taxonomic names found in the dataset under review aligned with the NCBI Taxonomy as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped tab-separated values format
 [indexed-names-resolved-pbdb.csv.gz](indexed-names-resolved-pbdb.csv.gz) | taxonomic names found in the dataset under review aligned with the Paleobiology Database as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped comma-separated values format 
 [indexed-names-resolved-pbdb.html.gz](indexed-names-resolved-pbdb.html.gz) | taxonomic names found in the dataset under review aligned with Paleobiology Database as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped html format
 [indexed-names-resolved-pbdb.tsv.gz](indexed-names-resolved-pbdb.tsv.gz) | taxonomic names found in the dataset under review aligned with Paleobiology Database as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped tab-separated values format
 [indexed-names-resolved-tpt.csv.gz](indexed-names-resolved-tpt.csv.gz) | taxonomic names found in the dataset under review aligned with the Terrestrial Parasite Tracker (TPT) Taxonomic Resource as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped comma-separated values format
 [indexed-names-resolved-tpt.html.gz](indexed-names-resolved-tpt.html.gz) | taxonomic names found in the dataset under review aligned with the Terrestrial Parasite Tracker (TPT) Taxonomic Resource as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped html format
 [indexed-names-resolved-tpt.tsv.gz](indexed-names-resolved-tpt.tsv.gz) | taxonomic names found in the dataset under review aligned with the Terrestrial Parasite Tracker (TPT) Taxonomic Resource as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped tab-separated values format 
 [indexed-names-resolved-wfo.csv.gz](indexed-names-resolved-wfo.csv.gz) | taxonomic names found in the dataset under review aligned with the World of Flora Online as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped comma-separated values format
 [indexed-names-resolved-wfo.html.gz](indexed-names-resolved-wfo.html.gz) | taxonomic names found in the dataset under review aligned with the World of Flora Online as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped html format
 [indexed-names-resolved-wfo.tsv.gz](indexed-names-resolved-wfo.tsv.gz) | taxonomic names found in the dataset under review aligned with the World of Flora Online as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped tab-separated values format
 [indexed-names-resolved-worms.csv.gz](indexed-names-resolved-worms.csv.gz) | taxonomic names found in the dataset under review aligned with the World Register of Marine Species (WoRMS) as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped comma-separated values format
 [indexed-names-resolved-worms.html.gz](indexed-names-resolved-worms.html.gz) | taxonomic names found in the dataset under review aligned with the World Register of Marine Species (WoRMS) as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped html format
 [indexed-names-resolved-worms.tsv.gz](indexed-names-resolved-worms.tsv.gz) | taxonomic names found in the dataset under review aligned with the World Register of Marine Species (WoRMS) as accessed through the Nomer Corpus of Taxonomic Resources [@NomerCorpus] in gzipped tab-separated values format
 [indexed-names-sample.csv](indexed-names-sample.csv) | first 500 taxonomic names found in the dataset under review in comma-separated values format
 [indexed-names-sample.html](indexed-names-sample.html) | first 500 taxonomic names found in the dataset under review in html format
 [indexed-names-sample.tsv](indexed-names-sample.tsv) | first 500 taxonomic names found in the dataset under review in tab-separated values format
 [interaction.svg](interaction.svg) | diagram summarizing the data model used to index species interaction claims
 [nanopub-sample.trig](nanopub-sample.trig) | first 500 species interaction claims as expressed in the nanopub format [@Nanopub]
 [nanopub.trig.gz](nanopub.trig.gz) | species interaction claims as expressed in the nanopub format [@Nanopub]
 [process.svg](process.svg) | diagram summarizing the data review processing workflow 
 [prov.nq](prov.nq) | origin of the dataset under review as expressed in rdf/nquads 
 [review.csv.gz](review.csv.gz) | review notes associated with the dataset under review in gzipped comma-separated values format 
 [review.html.gz](review.html.gz) | review notes associated with the dataset under review in gzipped html format
 [review.tsv.gz](review.tsv.gz) | review notes associated with the dataset under review in gzipped tab-separated values format
 [review-sample.csv](review-sample.csv) | first 500 review notes associated with the dataset under review in comma-separated values format
 [review-sample.html](review-sample.html) | first 500 review notes associated with the dataset under review in html format
 [review-sample.tsv](review-sample.tsv) | first 500 review notes associated with the dataset under review in tab-separated values format
 [review.svg](review.svg) | a review badge generated as part of the dataset review process
 [zenodo.json](zenodo.json) | metadata of this review expressed in Zenodo record metadata

## Archived Dataset

Note that [_data.zip_](data.zip) file in this archive contains the complete, unmodified archived dataset under review. 

## Biotic Interactions

![Biotic Interaction Data Model](interaction.svg)

In this review, biotic interactions (or biotic associations) are modeled as a primary (aka subject, source) organism interacting with an associate (aka object, target) organism. The dataset under review classified the primary/associate organisms with specific taxa. The primary and associate organisms The kind of interaction is documented as an interaction type. 

The ${summaryPhrase}

An exhaustive list of indexed interaction claims can be found in gzipped [csv](indexed-interactions.csv.gz) and [tsv](indexed-interactions.tsv.gz) archives. To facilitate discovery, a preview of claims available in the gzipped html page at [indexed-interactions.html.gz](indexed-interactions.html.gz) are shown below.

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

You can download the indexed dataset under review at [indexed-interactions.csv.gz](indexed-interactions.csv.gz). A tab-separated file can be found at [indexed-interactions.tsv.gz](indexed-interactions.tsv.gz) 

Learn more about the structure of this download at [GloBI website](https://globalbioticinteractions.org), by opening a [GitHub issue](https://github.com/globalbioticinteractions/globalbioticinteractions/issues/new), or by sending an [email](mailto:info@globalbioticinteractions.org).

Another way to discover the dataset under review is by searching for it on the [GloBI website](https://www.globalbioticinteractions.org/?accordingTo=globi%3A$(echo ${REPO_NAME} | sed 's+/+%2F+g')).


## Taxonomic Alignment

As part of the review, all names are aligned against various name catalogs (e.g., $(echo ${TAXONOMIES} | sed 's/ /, /g' | sed -E 's/, ([a-z]+)$/, and \1/g')). These alignments can help review name usage or aid in selecting of a suitable taxonomic name resource. 

$(cat indexed-names-resolved.tsv.gz | gunzip | mlr ${MLR_TSV_OPTS} cut -f providedName,relationName,resolvedCatalogName,resolvedName | mlr ${MLR_TSV_INPUT_OPTS} --omd uniq -f providedName,relationName,resolvedCatalogName,resolvedName | head -n6) 
: Sample of Name Alignments

$(cat indexed-names-resolved.tsv.gz | gunzip | mlr --tsvlite uniq -f providedName,resolvedCatalogName,resolvedRank |  sed 's/\t$/\tNA/g' | mlr --itsvlite --omd count-distinct -f resolvedCatalogName,resolvedRank then sort -f resolvedCatalogName,resolvedRank)
: Distribution of Taxonomic Ranks of Aligned Names by Catalog. Names that were not aligned with a catalog are counted as NAs. So, the total number of unaligned names for a catalog will be listed in their NA row. 


$(cat indexed-names-resolved.tsv.gz | gunzip | mlr ${MLR_TSV_INPUT_OPTS} --omd count-distinct -f resolvedCatalogName,relationName then sort -f resolvedCatalogName)
: Name relationship types per catalog. Name relationship type "NONE" means that a name was not recognized by the associated catalog. "SAME_AS" indicates either a "HAS_ACCEPTED_NAME" or "SYNONYM_OF" name relationship type. We recognize that "SYNONYM_OF" encompasses many types of nomenclatural synonymies [@ICZN_1999] (e.g., junior synonym, senior synonyms). 

| catalog name | alignment results |
| --- | --- |
$(echo "${TAXONOMIES}" | tr ' ' '\n' | awk '{ print "| " $1 " | associated names alignments report in gzipped [html](indexed-names-resolved-" $1 ".html.gz), [csv](indexed-names-resolved-" $1 ".csv.gz), and [tsv](indexed-names-resolved-" $1 ".tsv.gz)) |"}') 
: List of Available Name Alignment Reports

## Additional Reviews

Elton, Nomer, and other tools may have difficulties interpreting existing species interaction datasets. Or, they may misbehave, or otherwise show unexpected behavior. As part of the review process, detailed review notes are kept that document possibly misbehaving, or confused, review bots. An sample of review notes associated with this review can be found below.

$(cat review.tsv.gz | gunzip | mlr ${MLR_TSV_INPUT_OPTS} --omd cut -f reviewDate,reviewCommentType,reviewComment | head -n6)
: First few lines in the review notes.

In addition, you can find the most frequently occurring notes in the table below.

$(cat review.tsv.gz | gunzip | mlr ${MLR_TSV_INPUT_OPTS} --omd cut -f reviewCommentType,reviewComment then filter '$reviewCommentType == "note"' then count-distinct -f reviewComment then sort -nr count | head -n6)
: Most frequently occurring review notes, if any.

For additional information on review notes, please have a look at the first 500 [Review Notes](review-sample.html) in html format or the download full gzipped [csv](review.csv.gz) or [tsv](review.tsv.gz) archives.

## GloBI Review Badge

As part of the review, a review badge is generated. This review badge can be included in webpages to indicate the review status of the dataset under review. 

![Picture of a GloBI Review Badge ^[Up-to-date status of the GloBI Review Badge can be retrieved from the [GloBI Review Depot](https://depot.globalbioticinteractions.org/reviews/${REPO_NAME}/review.svg)]](review.svg) 

Note that if the badge is green, no review notes were generated. If the badge is yellow, the review bots may need some help with interpreting the species interaction data.

## GloBI Index Badge

If the dataset under review has been [registered with GloBI](https://globalbioticinteractions.org/contribute), and has been succesfully indexed by GloBI, the GloBI Index Status Badge will turn green. This means that the dataset under review was indexed by GloBI and is available through GloBI services and derived data products. 

![Picture of a GloBI Index Badge ^[Up-to-date status of the GloBI Index Badge can be retrieved from [GloBI's API](https://api.globalbioticinteractions.org/interaction.svg?interactionType=ecologicallyRelatedTo&accordingTo=globi:${REPO_NAME}&refutes=true&refutes=false)]](https://api.globalbioticinteractions.org/interaction.svg?interactionType=ecologicallyRelatedTo&accordingTo=globi:${REPO_NAME}&refutes=true&refutes=false)

If you'd like to keep track of reviews or index status of the dataset under review, please visit GloBI's dataset index ^[At time of writing ($(date --iso-8601)) the version of the GloBI dataset index was available at [https://globalbioticinteractions.org/datasets](https://globalbioticinteractions.org/datasets)] for badge examples. 


# Discussion

This review and archive provides a means of creating citable versions of datasets that change frequently. This may be useful for dataset managers, including natural history collection data managers, as a backup archive of a shared Darwin Core archive. It also serves as a means of creating a trackable citation for the dataset in an automated way, while also including some information about the contents of the dataset.

This review aims to provide a perspective on the dataset to aid in understanding of species interaction claims discovered. However, it is important to note that this review does *not* assess the quality of the dataset. Instead, it serves as an indication of the open-ness[^2] and FAIRness [@Wilkinson_2016; @trekels_maarten_2023_8176978] of the dataset: to perform this review, the data was likely openly available, **F**indable, **A**ccessible, **I**nteroperable and **R**eusable. The current Open-FAIR assessment is qualitative, and a more quantitative approach can be implemented with specified measurement units. 

This report also showcases the reuse of machine-actionable (meta)data, something highly recommended by the FAIR Data Principles [@Wilkinson_2016]. Making (meta)data machine-actionable enables more precise procesing by computers, enabling even naive review bots like Nomer and Elton to interpret the data effectively. This capability is crucial for not just automating the generation of reports, but also for facilitating seamless data exchanges, promoting interoperability. 

# Acknowledgements

We thank the many humans that created us and those who created and maintained the data, software and other intellectual resources that were used for producing this review. In addition, we are grateful for the natural resources providing the basis for these human and bot activities. Also, thanks to https://github.com/zygoballus for helping improve the layout of the review tables. 

# Author contributions

Nomer was responsible for name alignments. Elton carried out dataset extraction, and generated the review notes. Preston tracked, versioned, and packaged, the dataset under review.

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
    curl --silent -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 > /usr/local/bin/yq && chmod +x /usr/local/bin/yq &> /dev/null
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

The figures below provide a graph view on the dataset under review. The first shows a summary network on the ${taxon_category_1} level, and the second shows how interactions on the ${taxon_category_2} level. It is important to note that both network graphs were first aligned taxonomically using the ${NETWORK_CATALOG_DESCRIPTION}. Please refer to the original (or verbatim) taxonomic names for a more original view on the interaction data.  

![Interactions on taxonomic ${taxon_category_1} rank as interpreted by the ${NETWORK_CATALOG_DESCRIPTION} [download svg](indexed-interactions-${NETWORK_CATALOG}-${taxon_category_1}-${NETWORK_CATALOG}-${taxon_category_1}.svg)](indexed-interactions-${NETWORK_CATALOG}-${taxon_category_1}-${NETWORK_CATALOG}-${taxon_category_1}.svg)

![Interactions on the taxonomic ${taxon_category_2} rank as interpreted by the ${NETWORK_CATALOG_DESCRIPTION}. [download svg](indexed-interactions-${NETWORK_CATALOG}-${taxon_category_2}-${NETWORK_CATALOG}-${taxon_category_2}.svg)](indexed-interactions-${NETWORK_CATALOG}-${taxon_category_2}-${NETWORK_CATALOG}-${taxon_category_2}.svg)

_EOF_
)"
  else 
echo -e "\nNo interaction network graphs were generated at this time. If you'd like to include network diagrams, please make sure that ${NETWORK_COMPILER_SCRIPT} is available and executable.\n"
  fi
}

function configure_elton {
  ELTON_OPTS_DIRS=" --prov-dir ${ELTON_DATASETS_DIR} --data-dir ${ELTON_DATASETS_DIR}"
  ELTON_OPTS="${ELTON_OPTS_DIRS} --algo ${HASH_ALGO}"

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
      ELTON_UPDATE="${ELTON_CMD} update --prov-mode ${ELTON_OPTS} --registry local"
      ELTON_NAMESPACE="local"
  else
    ELTON_UPDATE="${ELTON_CMD} update --prov-mode ${ELTON_OPTS} ${REPO_NAME}"
    ELTON_NAMESPACE="$REPO_NAME"
    # when running outside of travis, use a separate review directory'
    use_review_dir
  fi
}

function configure_preston {
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

  export PRESTON_VERSION=$(${PRESTON_CMD} version)

  echo preston version "${PRESTON_VERSION}"

  if [[ -n ${TRAVIS_REPO_SLUG} || -n ${GITHUB_REPOSITORY} ]]
    then
      echo "likely running in travis/github actions environment"
  else
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
@import url(//fonts.googleapis.com/css?family=Libre+Baskerville:400,400italic,700);@import url(//fonts.googleapis.com/css?family=Source+Code+Pro:400,400italic,700,700italic);/* normalize.css v3.0.0 | MIT License | git.io/normalize */html{font-family:sans-serif;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}body{margin:1em}article,aside,details,figcaption,figure,footer,header,hgroup,main,nav,section,summary{display:block}audio,canvas,progress,video{display:inline-block;vertical-align:baseline}audio:not([controls]){display:none;height:0}[hidden],template{display:none}a{background:transparent}a:active,a:hover{outline:0}abbr[title]{border-bottom:1px dotted}b,strong{font-weight:bold}dfn{font-style:italic}h1{font-size:2em;margin:0.67em 0}mark{background:#ff0;color:#000}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sup{top:-0.5em}sub{bottom:-0.25em}img{border:0}svg:not(:root){overflow:hidden}figure{margin:1em 40px}hr{-moz-box-sizing:content-box;box-sizing:content-box;height:0}pre{overflow:auto}code,kbd,pre,samp{font-family:monospace, monospace;font-size:1em}button,input,optgroup,select,textarea{color:inherit;font:inherit;margin:0}button{overflow:visible}button,select{text-transform:none}button,html input[type="button"],input[type="reset"],input[type="submit"]{-webkit-appearance:button;cursor:pointer}button[disabled],html input[disabled]{cursor:default}button::-moz-focus-inner,input::-moz-focus-inner{border:0;padding:0}input{line-height:normal}input[type="checkbox"],input[type="radio"]{box-sizing:border-box;padding:0}input[type="number"]::-webkit-inner-spin-button,input[type="number"]::-webkit-outer-spin-button{height:auto}input[type="search"]{-webkit-appearance:textfield;-moz-box-sizing:content-box;-webkit-box-sizing:content-box;box-sizing:content-box}input[type="search"]::-webkit-search-cancel-button,input[type="search"]::-webkit-search-decoration{-webkit-appearance:none}fieldset{border:1px solid #c0c0c0;margin:0 2px;padding:0.35em 0.625em 0.75em}legend{border:0;padding:0}textarea{overflow:auto}optgroup{font-weight:bold}table{border-collapse:collapse;border-spacing:0}td,th{padding:0}body,code,tr.odd,tr.even,figure{background-image:url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAMAAAAp4XiDAAABOFBMVEWDg4NycnJnZ2ebm5tjY2OgoKCurq5lZWWoqKiKiopmZmahoaGOjo5TU1N6enp7e3uRkZGJiYmFhYWxsbFOTk6Xl5eBgYGkpKRhYWFRUVGvr69dXV2wsLBiYmKnp6dUVFR5eXmdnZ1sbGxYWFh2dnZ0dHSmpqaZmZlVVVVqamqsrKyCgoJ3d3dubm5fX19tbW2ioqKSkpJWVlaHh4epqalSUlKTk5OVlZWysrJoaGhzc3N+fn5wcHBaWlqcnJxkZGRpaWlvb2+zs7NcXFxPT09/f3+lpaWWlpaQkJCjo6OIiIitra2enp6YmJhQUFBZWVmqqqqLi4uNjY1eXl6rq6ufn599fX2AgIB8fHyEhIRxcXFra2tbW1uPj4+MjIyGhoaamppgYGB4eHhNTU1XV1d1dXW0tLSUlJSHWuNDAAAAaHRSTlMNDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDUnKohIAAAaZSURBVHhelZWFrmZVDEb3cffzq7u7u7u7u9z7/m8AhISQwMDMAzRN2/WtAhO7zOd0x0U/UNb0oWQZGLWhIHBK/lC96klgkA+3B5JoqI9ozRcn4306YeDweKG9vxo5YbGbqBkln93ZFGs3SA0RRpSO4dpdpg+VnMUv8BEqmiIcli8gJeRZc29K51qOg0OWHRGyA0ccrmbmSRj1r7x5JisCpAs+iuCd8GFc0pMGldB2BOC0VoY37qKJh5nqZNjb4XtnjRlYMQYxsN0KWTdk77hnJZB7s+MbXK3Mxawrwu8cHGNKynDQTUqhbrxmNQ+belwSPemILVuUu1p4G6xGI0yUA0lh26IduYnd2soQ0KVmwUxo7D6U0QdCJwLWDTwzFij0cE/ZvorI7kl/QuCHUy7ibZCHT9mtLaY4HJLhIHOJ+jt5DAI9MJqOs0refRcF5H7S9mb2vnsqo21xvTPVgZGrLDCTJ+kk9eQ67kPk+xP4697EDY+boY3tC4zs3yy+5XRqg58EivoohEownfBzjpeQN6v6gaY0TCzADte1m2pbFSUbpKfDqU0iq+4UPNyxFlW00Q70b9jGpIbqdoCQLZ1Lax+Bv3XUj5ZnoT1N0j3CZS95FfHDRump2ujpuLY47oI5VWjmR2PwietdJbJGZRYFFm6SWPiwmhFZqWKEwNM6Nlw7XmZuQmKu8FHq8DFcaYjAYojsS6NrLKNnMRgyu2oaXaNpyLa0Nncawan7eDOxZVSxv4GYoLCF184C0EAvuhuJNvZ1gosWDdHUfJ05uHdwhRKYb/5+4W90jQxT/pHd2hnkBgn3GFzCCzcVXPbZ3qdqLlYrDl0dUWqkXYc6LStL8QLPI3G3gVDdAa2Pr0co8wQgwRYBlTB5AEmteLPCRHMgoHi56glp5rMSrwAllRSatomKatJdy0nXEkCI2z5065bpKav5/bKgSXr+L0HgDwSsvwQaeC0SjH1cnu7WZTcxJn0kVLI/HEzNK1j8W7etR/BfXDXhak8LmTQdwMqaF/jh+k+ZVMUvWU/+OfUwz5TDJhclFAtiMYD8ss6TFNluVg6lYZaeXXv/FzqQ3yjupMEIyzlf6yt2zmyHxI43held1dMbGkLMY5Kpv4llTCazqHbKsakh+DPPZdHvqYQF1onZpg1W/H7b6DJr019WhPWucVJTcStosCf1fQ1kLWA/12vjb3PItlBUuo6FO/4kFTPGNXC4e/TRMDGwPpSG1RJwYXNH4vkHK8BSmFNrXVTwJjLAphVEKq7HS2d8pSqoZdCBAv6mdJ72revxET6giWB7PgbJph+2i011uUifL7xruTb3zv+NKvgpqRSU0yBSckeKeQzSgeZZcaQb8+JYzehtPraBkg3Jc3e8boxVXJzNW23deFoZ74Vzy6xd1+FemwZ/neOnHQh2ufopy5c/r69Cz+scIrx+uN+dzhyzEjCeNLL0hgjGUOHdvb25YDijfq/An/D+iv7BBDutUsyuvBrH2ya6j2SIkLvjxFIpk8H37wcAt9KHX9cLeNmn+8CR1xtKgrzojVXl/qikMqAsDcO1coQrEanpsrB3DlAImIwS07oN2k3C2x2jSE3jxSm908P1tUXUMD15Lpp50CHii7i2BDSdYMcfB7+X7QdqymsDWH6BJ5APN+qIRhTVc/msYf5CjOyA82VSuIEtZA3GmUuXBK2r6xJ2LXO8fCU9kmCvydDptoECLq+XXLs4w8U+DUZyir9Cw+XL3rHFGoDNI9Rw3baFy/fZwTY2Gr0WMuLaxMrWaC5rh+IeyZijp0fdaDLPg8YtugLgnwYZss1xIh1o13qB7L8pC6wEutNQVuy5aIpNkSSl2yWAiRADUVXSMqpTH8Da3gCNr8maodNIxjY7CXyvzHHfiJoto/CE9UMmX+cRqPC8RKdks7OV35txMGkdXzOkkhX9wTr+tIOGKZzjoo+qbWy3hsJJtz5D7nP+syyjxYe7eCAMIOywwFNfv/ZMNyBSxV0g7ZEJCPVE8IA5sw7jg9Kx3RXdfCQXGxpH+0kyHYpBj0H4y2VdAHRW9RyegOPPB+5NudysJji/lnxHQ9pFOMLMLeZ0O9hrnsuFsstbjczbC+14JHS+xsDf3pPgQXvUG6Q/H2fKV/B7jYX8RdOrug5BjG/1jueAPq1ElQb4AeH/sRNwnNyoFqsJwT9tWhChzL/IP/gxfleLSIgVQDdRvKBZVfu9wgKkeHEEfgIqa/F6fJ0HM8knJtkbCn4hKFvNDLWXDr8BGMywGD1Lh54AAAAASUVORK5CYII=")}body{font-family:"Libre Baskerville",Baskerville,Georgia,serif;background-color:#f8f8f8;color:#111;line-height:1.3;text-align:justify;-moz-hyphens:auto;-ms-hyphens:auto;-webkit-hyphens:auto;hyphens:auto}@media (max-width: 400px){body{font-size:11px}}@media (min-width: 401px) and (max-width: 900px){body{font-size:12px}}@media (min-width: 901px){body{font-size:14px}}p{margin-top:10px;margin-bottom:18px}em{font-style:italic}strong{font-weight:bold}h1,h2,h3,h4,h5,h6{font-weight:bold;padding-top:0.25em;margin-bottom:0.15em}header{line-height:2.475em;padding-bottom:0.7em;border-bottom:1px solid #bbb;margin-bottom:1.2em}header>h1{border:none;padding:0;margin:0;font-size:225%}header>h2{border:none;padding:0;margin:0;font-style:normal;font-size:175%}header>h3{padding:0;margin:0;font-size:125%;font-style:italic}header+h1{border-top:none;padding-top:0px}h1{border-top:1px solid #bbb;padding-top:15px;font-size:150%;margin-bottom:10px}h1:first-of-type{border:none}h2{font-size:125%;font-style:italic}h3{font-size:105%;font-style:italic}hr{border:0px;border-top:1px solid #bbb;width:100%;height:0px}hr+h1{border-top:none;padding-top:0px}ul,ol{font-size:90%;margin-top:10px;margin-bottom:15px;padding-left:30px}ul{list-style:circle}ol{list-style:decimal}ul ul,ol ol,ul ol,ol ul{font-size:inherit}li{margin-top:5px;margin-bottom:7px}q,blockquote,dd{font-style:italic;font-size:90%}blockquote,dd{quotes:none;border-left:0.35em #bbb solid;padding-left:1.15em;margin:0 1.5em 0 0}blockquote blockquote,dd blockquote,blockquote dd,dd dd,ol blockquote,ol dd,ul blockquote,ul dd,blockquote ol,dd ol,blockquote ul,dd ul{font-size:inherit}a,a:link,a:visited,a:hover{color:inherit;text-decoration:none;border-bottom:1px dashed #111}a:hover,a:link:hover,a:visited:hover,a:hover:hover{border-bottom-style:solid}a.footnoteRef,a:link.footnoteRef,a:visited.footnoteRef,a:hover.footnoteRef{border-bottom:none;color:#666}code{font-family:"Source Code Pro","Consolas","Monaco",monospace;font-size:85%;background-color:#ddd;border:1px solid #bbb;padding:0px 0.15em 0px 0.15em;-webkit-border-radius:3px;-moz-border-radius:3px;border-radius:3px}pre{margin-right:1.5em;display:block}pre>code{display:block;font-size:70%;padding:10px;-webkit-border-radius:5px;-moz-border-radius:5px;border-radius:5px;overflow-x:auto}blockquote pre,dd pre,ul pre,ol pre{margin-left:0;margin-right:0}blockquote pre>code,dd pre>code,ul pre>code,ol pre>code{font-size:77.77778%}caption,figcaption{font-size:80%;font-style:italic;text-align:right;margin-bottom:5px}caption:empty,figcaption:empty{display:none}table{width:100%;margin-top:1em;margin-bottom:1em}table+h1{border-top:none}tr td,tr th{padding:0.2em 0.7em}tr.header{border-top:1px solid #222;border-bottom:1px solid #222;font-weight:700}tr.odd{background-color:#eee}tr.even{background-color:#ccc}tbody:last-child{border-bottom:1px solid #222}dt{font-weight:700}dt:after{font-weight:normal;content:":"}dd{margin-bottom:10px}figure{margin:1.3em 0 1.3em 0;text-align:center;padding:0px;width:100%;background-color:#ddd;border:1px solid #bbb;-webkit-border-radius:8px;-moz-border-radius:8px;border-radius:8px;overflow:hidden}img{display:block;margin:0px auto;padding:0px;max-width:100%}figcaption{margin:5px 10px 5px 30px}.footnotes{color:#666;font-size:70%;font-style:italic}.footnotes li p:last-child a:last-child{border-bottom:none}
_EOF_
}

function tsv2html {
  generate_styling > styling.css
  head -n501 | pandoc --embed-resources --standalone --metadata title=${REPO_NAME} --css=styling.css --to=html5 --from=tsv -o - | pv -l
}

echo_logo | tee_readme 

install_deps

configure_preston
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
  cat ${RESOLVED}\
    | gunzip\
    | mlr ${MLR_TSV_OPTS} cut -f providedExternalId,providedName,relationName,resolvedCatalogName,resolvedExternalUrl,resolvedName,resolvedAuthorship,resolvedRank\
    | tail -n501\
    | tsv2html\
    | gzip\
    > ${RESOLVED_STEM}-sample.html
  echo [$2] resolved $(cat $RESOLVED | gunzip | tail -n+2 | grep -v NONE | wc -l) out of $(cat $RESOLVED | gunzip | tail -n+2 | wc -l) names.
  echo [$2] first 10 unresolved names include:
  cat $RESOLVED | gunzip | tail -n+2 | grep NONE | cut -f1,2 | head -n11 
  echo -e "\n--- [$2] end ---\n"
}


echo -e "\nReview of [${ELTON_NAMESPACE}] started at [$(date -Iseconds)]." | tee_readme 

if [[ -z ${ELTON_UPDATE_DISABLED} ]]
then
  echo update using local
  ${ELTON_UPDATE} | ${ELTON_CMD} tee ${ELTON_OPTS} | ${PRESTON_CMD} append ${PRESTON_OPTS}
else
  echo no update: using provided elton datasets dir [${ELTON_DATASETS_DIR}] instead.
  # run [elton prov] twice to cover sha256 -> md5 and md5 -> sha256  
  ${ELTON_CMD} prov ${ELTON_OPTS_DIRS} ${REPO_NAME} | ${ELTON_CMD} tee ${ELTON_OPTS}
  ${ELTON_CMD} prov ${ELTON_OPTS} ${REPO_NAME} | ${ELTON_CMD} tee ${ELTON_OPTS} | ${PRESTON_CMD} append ${PRESTON_OPTS}
fi

if [[ ${REVIEW_SCRIPT} != $(readlink -f check-dataset.sh) ]]; then
  echo "include the review script [${REVIEW_SCRIPT}]"
  cat "${REVIEW_SCRIPT}" > check-dataset.sh
else 
  echo "review script [${REVIEW_SCRIPT}] already present"
fi 

echo "getting dataset version..."

# capture data package version
DATASET_VERSION=$(${PRESTON_CMD} head ${PRESTON_OPTS})
DATASET_VERSION_HEX=$(echo "${DATASET_VERSION}" | sed -E "s+hash://[^/]*/++g")

DATASET_ID="urn:lsid:globalbioticinteractions.org:dataset:${REPO_NAME}"
DATASET_ID_VERSIONED="${DATASET_ID}:${DATASET_VERSION_HEX}"

${PRESTON_CMD} head ${PRESTON_OPTS} | tee HEAD | ${PRESTON_CMD} cat > prov.nq

${ELTON_CMD} review ${ELTON_OPTS} ${ELTON_NAMESPACE} --type note --type summary | gzip > review.tsv.gz
cat review.tsv.gz | gunzip | tsv2csv | gzip > review.csv.gz
cat review.tsv.gz | gunzip | tsv2html | gzip > review.html.gz
cat review.tsv.gz | gunzip | head -n501 > review-sample.tsv
cat review-sample.tsv | tsv2csv > review-sample.csv
cat review-sample.tsv | tsv2html > review-sample.html

# pending https://github.com/globalbioticinteractions/fishbase/issues/1
# cat prov.nq | ${ELTON_CMD} stream --record-type interaction --data-dir data | gzip > indexed-interactions.tsv.gz
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

# pending https://github.com/globalbioticinteractions/fishbase/issues/1
# cat prov.nq | ${ELTON_CMD} stream --data-dir data --record-type name\
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

# name alignment reports

NAME_REPORT_FILENAMES=$(echo ${TAXONOMIES} | tr ' ' '\n' | sort | awk '{ print "indexed-names-resolved-" $1 ".tsv.gz" }')

gzipped_name_header() {
  cat\
 $(echo ${NAME_REPORT_FILENAMES} | tr ' ' '\n' | head -n1)\
 | gunzip\
 | head -n1\
 | gzip
}

gzipped_name_tails() {
  echo ${NAME_REPORT_FILENAMES}\
    | tr ' ' '\n'\
    | awk -F ' ' '{ print "cat " $1 " | gunzip | tail -n+2 | gzip" }'\
    | bash -s
}

# concatenate all name alignments
cat <(gzipped_name_header) <(gzipped_name_tails)  > indexed-names-resolved.tsv.gz

mlr ${MLR_TSV_INPUT_OPTS} --ocsv --prepipe gunzip cat indexed-names-resolved.tsv.gz | gzip > indexed-names-resolved.csv.gz
cat indexed-names-resolved.tsv.gz | gunzip | tsv2html | gzip > indexed-names-resolved.html.gz

cat indexed-interactions.tsv.gz | gunzip | head -n501 > indexed-interactions-sample.tsv
cat indexed-interactions-sample.tsv | tsv2csv > indexed-interactions-sample.csv
cat indexed-interactions-sample.tsv | mlr ${MLR_TSV_OPT} cut -r -f sourceTaxon*,interactionTypeName,targetTaxon*,referenceCitation | tsv2html > indexed-interactions-sample.html

${ELTON_CMD} nanopubs ${ELTON_OPTS} ${ELTON_NAMESPACE} | gzip > nanopub.trig.gz
cat nanopub.trig.gz | gunzip | head -n1 > nanopub-sample.trig

echo -e "\nReview of [${REPO_NAME}@${DATASET_VERSION}] included:" | tee_readme
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
  pandoc --embed-resources --standalone --toc --citeproc -t $1 $2 -o -
}

generate_md_report\
 | tee index.md\
 > review.md


generate_zenodo_deposit_metadata "index.md"\
 | jq -c .\
 > zenodo.json 
 
cat index.md\
 | export_report_as docx\
 > index.docx


#!/bin/bash

pandoc_opts=""
if (which xelatex); then
  # https://github.com/globalbioticinteractions/NeoBat_Interactions/issues/1
  # https://github.com/globalbioticinteractions/neofrugivory/issues/1
  pandoc_opts="--pdf-engine=xelatex"
fi

# see https://github.com/mammalbase/database/issues/3
cat index.md\
 | sed 's+[\]N+NA+g'\
 | export_report_as pdf "${pandoc_opts}"\
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

#if [[ -n ${TRAVIS_REPO_SLUG} || -n ${GITHUB_REPOSITORY} ]]
#then 
#  gunzip -f *.gz
#fi

mkdir -p tmp-review
zip -r data.zip data/

# attempt to use s3cmd tool if available and configured
if [[ -n $(which s3cmd) ]] && [[ -n ${S3CMD_CONFIG} ]]
then
  echo -e "\nThis review generated the following resources:" | tee_readme
  upload check-dataset.sh "review workflow bash script"
  upload index.html "review summary web page"
  upload index.md "review pandoc page"
  upload index.docx "review pandoc word document"
  upload index.pdf "review pandoc pdf document"
  upload index.jats "review pandoc jats document"
  upload review.svg "review badge"
  upload process.svg "review process diagram"
  upload interaction.svg "interaction data model diagram"
  upload HEAD "fingerprint (or version) of dataset under review"
  upload prov.nq "description of origin of dataset under review"
  upload zenodo.json "metadata for Zenodo record deposit"
  upload data.zip "Preston archive of dataset under review"

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

  if [[ -z ${ELTON_UPDATE_DISABLED} ]]
  then
    tar c data/* | gzip > data.tar.gz
    upload data.tar.gz "preston data archive"
  fi

  save_readme
  upload README.txt "review summary"
  if [[ ${LAST_UPLOAD_RESULT} -eq 0 ]]
  then
    clean_review_dir
  fi
fi

echo_reproduce

#exit ${NUMBER_OF_NOTES}
