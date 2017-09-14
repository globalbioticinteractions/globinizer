package org.globalbioticinteractions;

import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;
import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetFinderException;
import org.eol.globi.service.DatasetImpl;
import org.junit.Test;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.core.StringStartsWith.startsWith;
import static org.junit.Assert.assertThat;

public class DatasetRepositoryTest {

    @Test
    public void cacheDatasetLocal() throws DatasetFinderException, IOException, URISyntaxException {
        Dataset datasetCached = datasetCached();

        URI uri = datasetCached.getResourceURI("globi.json");
        assertThat(uri.isAbsolute(), is(true));
        assertThat(uri.toString(), startsWith("jar:file:"));

        InputStream is = datasetCached.getResource("globi.json");
        JsonNode jsonNode = new ObjectMapper().readTree(is);
        assertThat(jsonNode.has("citation"), is(true));
    }

    @Test
    public void accessLogEntry() throws DatasetFinderException, IOException, URISyntaxException {
        Dataset datasetCached = datasetCached();
        List<String> strings = DatasetRepository.accessLogEntries(new Date(0L), datasetCached, "1234");
        assertThat(strings, is(Arrays.asList("some/namespace", "http://example.com", "1234:SHA-256", "1970-01-01T00:00:00Z")));
    }

    private Dataset datasetCached() throws IOException, URISyntaxException {
        Dataset dataset = new DatasetImpl("some/namespace", URI.create("http://example.com"));
        URI archiveCacheURI = DatasetRepository.getArchiveCacheURI(new File(getClass().getResource("archive.zip").toURI()));
        return new DatasetLocal(dataset, archiveCacheURI, new Date());
    }
}
