package org.globalbioticinteractions;

import org.apache.commons.io.FileUtils;
import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetFinder;
import org.eol.globi.service.DatasetFinderException;

import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.Collection;

public class DatasetFinderCaching implements DatasetFinder {

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
