# assumes a travis-ci.org environment
export GLOBI_VERSION=`curl -s https://api.github.com/repos/jhpoelen/eol-globi-data/releases/latest | grep -o '[0-9]\.[0-9]\.[0-9]' | head -n 1`
export GLOBI_DATA_REPO_MASTER="https://raw.githubusercontent.com/${TRAVIS_REPO_SLUG}/master"

wget http://globi.s3.amazonaws.com/release/org/eol/eol-globi-data-tool/$GLOBI_VERSION/eol-globi-data-tool-$GLOBI_VERSION-jar-with-dependencies.jar -O globi-tool.jar

java -cp globi-tool.jar org.eol.globi.tool.GitHubRepoCheck ${TRAVIS_REPO_SLUG} ${GLOBI_DATA_REPO_MASTER}

