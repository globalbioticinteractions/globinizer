package org.globalbioticinteractions.cache;

import org.eol.globi.service.DatasetFinderException;
import org.junit.Test;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.*;

public class CacheLogTest {

    @Test
    public void accessLogEntry() throws DatasetFinderException, IOException, URISyntaxException {
        CachedURI meta = new CachedURI("some/namespace", URI.create("http://example.com"), URI.create("cached:file.zip"), "1234", new Date(0L));
        List<String> strings = CacheLog.compileLogEntries(meta);
        assertThat(strings, is(Arrays.asList("some/namespace", "http://example.com", "1234", "1970-01-01T00:00:00Z", null)));
    }


}