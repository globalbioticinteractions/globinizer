package org.globalbioticinteractions;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang.StringUtils;
import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetFinder;
import org.eol.globi.service.DatasetFinderException;

import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.Collection;
import java.util.Date;

public class DatasetFinderCaching implements DatasetFinder {

    public static final String MIME_TYPE_GLOBI = "application/globi";

    public DatasetFinder getFinder() {
        return finder;
    }

    private final DatasetFinder finder;

    public String getCacheDir() {
        return cacheDir;
    }

    private final String cacheDir;

    public DatasetFinderCaching(DatasetFinder finder, String cacheDir) {
        this.finder = finder;
        this.cacheDir = cacheDir;
    }

    @Override
    public Collection<String> findNamespaces() throws DatasetFinderException {
        return getFinder().findNamespaces();
    }


    @Override
    public Dataset datasetFor(String namespace) throws DatasetFinderException {
        Dataset dataset = getFinder().datasetFor(namespace);
        try {
            URIMeta meta = new URIMeta(namespace, dataset.getArchiveURI(), null, null, new Date());
            meta.setType(MIME_TYPE_GLOBI);
            CacheLog.appendAccessLog(meta, new File(getCacheDir()));
        } catch (IOException e) {
            throw new DatasetFinderException("failed to record access", e);
        }
        return new DatasetWithCache(dataset, cacheFor(namespace, getCacheDir()));

    }

    static ResourceCacheProxy cacheFor(String namespace, String cacheDir) {
        ResourceCache pullThroughCache = new PullThroughCache(namespace, cacheDir);
        LocalReadonlyCache readOnlyCache = new LocalReadonlyCache(namespace, cacheDir);
        return new ResourceCacheProxy(Arrays.asList(readOnlyCache, pullThroughCache));
    }


    static File getCacheDirForNamespace(String cachePath, String namespace) throws IOException {
        File cacheDir = new File(cachePath);
        FileUtils.forceMkdir(cacheDir);
        File directory = new File(cacheDir, namespace);
        FileUtils.forceMkdir(directory);
        return directory;
    }

}
