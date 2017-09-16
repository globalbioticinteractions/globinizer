Imports single github [GloBI](https://globalbioticinteractions.org) data repository and check whether it can be read.

Used for automated travis checks for GloBI datasets. Example see https://github.com/globalbioticinteractions/template-dataset/blob/master/.travis.yml and https://github.com/globalbioticinteractions/template-dataset#enable-integration-testing .

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [Building](#building)
- [Contribute](#contribute)
- [License](#license)

## Install

```
wget "https://raw.githubusercontent.com/globalbioticinteractions/globinizer/master/check-dataset.sh" -O check-dataset.sh
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

[GLP](LICENSE)
