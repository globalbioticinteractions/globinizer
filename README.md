## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [Contribute](#contribute)
- [License](#license)

**globinizer** is a software tool designed to discover and review species interaction datasets as interpreted by Global Biotic Interactions. Key functionalities include:

**Dataset Review:** The tool verifies whether a given dataset can be read and processed by GloBI. It imports registered GitHub [GloBI](https://globalbioticinteractions.org) data repository and checks whether it can be interpreted. The primary script, _check-dataset.sh_, checks to see how many species interactions in the dataset are discoverable by GloBI, and how they are interpreted. In addition, scientific names in the dataset are compared to available name catalogs. The results from these reviews are exported in tab-delimited format and a summary PDF publication is created.

**Integration Testing:** globinizer facilitates integration testing through automated reviews of datasets using GitHub Actions. This provides a means of triggering new reviews, archives and indexing into GloBI when new versions of a dataset is submitted.

**Dataset Archiving in Zenodo:** The tool also includes functiona lity for archiving datasets in Zenodo, a long-term, publicly accessible repository. This integration provides datasets with a Digital Object Identifier (DOI), making them easily citable in publications and ensuring their preservation for future use.

By using globinizer, dataset managers can streamline the process of preparing, validating, and archiving their datasets, while ensuring they are properly indexed and citable within the GloBI platform.

Example see https://github.com/globalbioticinteractions/template-dataset/blob/main/.github/workflows/review.yml and https://github.com/globalbioticinteractions/template-dataset#enable-integration-testing .

## Install

```
wget "https://raw.githubusercontent.com/globalbioticinteractions/globinizer/main/check-dataset.sh" -O check-dataset.sh
chmod +x check-dataset.sh
```

# Usage 
```
   usage:
     check-dataset.sh [github repo name] 
 
   example:
      ./check-dataset.sh globalbioticinteractions/template-dataset
```

## Contribute

Feel free to join in. All welcome. Open an [issue](https://github.com/globalbioticinteractions/globinizer/issues)!

## License

[MIT](LICENSE)
