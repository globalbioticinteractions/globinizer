package org.globalbioticinteractions;

import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetFactory;
import org.eol.globi.service.DatasetFinder;
import org.eol.globi.service.DatasetFinderException;
import org.eol.globi.service.DatasetFinderGitHubArchive;
import org.eol.globi.service.DatasetFinderZenodo;
import org.hamcrest.CoreMatchers;
import org.junit.Test;

import java.io.File;
import java.io.IOException;

import static org.hamcrest.core.Is.is;
import static org.hamcrest.core.StringContains.containsString;
import static org.hamcrest.core.StringStartsWith.startsWith;
import static org.junit.Assert.assertThat;

public class DatasetRepositoryIT {

    @Test
    public void zenodoTest() throws DatasetFinderException, IOException {
        String cacheDir = "target/cache/datasets";
        DatasetFinder finder = new DatasetRepository(new DatasetFinderZenodo(), cacheDir);

        Dataset dataset = DatasetFactory.datasetFor("globalbioticinteractions/template-dataset", finder);

        assertThat(dataset.getArchiveURI().toString(), containsString("zenodo.org"));
        assertThat(dataset.getResourceURI("globi.json").toString(), startsWith("jar:file:/"));
        assertThat(dataset.getCitation(), is("Jorrit H. Poelen. 2014. Species associations manually extracted from literature. https://doi.org/10.5281/zenodo.207958"));


    }

    @Test
    public void cacheDatasetGitHub() throws DatasetFinderException, IOException {
        Dataset dataset = new DatasetFinderGitHubArchive()
                .datasetFor("globalbioticinteractions/template-dataset");
        File archiveCache = DatasetRepository.cache(dataset, "target/cache/dataset");
        assertThat(archiveCache.exists(), CoreMatchers.is(true));
        assertThat(archiveCache.toURI().toString(), startsWith("file:/"));
    }

    @Test
    public void gitHubTest() throws DatasetFinderException {
        DatasetFinder finder = new DatasetRepository(new DatasetFinderGitHubArchive());

        Dataset dataset = DatasetFactory.datasetFor("globalbioticinteractions/Catalogue-of-Afrotropical-Bees", finder);

        assertThat(dataset.getArchiveURI().toString(), containsString("github.com"));
        assertThat(dataset.getResourceURI("globi.json").toString(), startsWith("jar:file:/"));
        assertThat(dataset.getCitation(), is("Catalogue of Afrotropical Bees. 2011. http://doi.org/10.15468/u9ezbh"));

    }
}
