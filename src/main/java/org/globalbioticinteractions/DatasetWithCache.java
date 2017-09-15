package org.globalbioticinteractions;

import org.eol.globi.service.Dataset;
import org.eol.globi.util.ResourceUtil;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Date;

import static org.eol.globi.service.DatasetImpl.mapResourceNameIfRequested;

public class DatasetWithCache extends DatasetLocal {
    private final ResourceCache resourceCache;

    public DatasetWithCache(Dataset dataset, ResourceCache resourceCache) {
        super(dataset, null, null, null);
        this.resourceCache = resourceCache;
    }

    @Override
    public InputStream getResource(String resourceName) throws IOException {
        return resourceCache.asInputStream(getResourceURI2(resourceName));
    }

    @Override
    public URI getResourceURI(String resourceName) {
        URI uri;
        try {
            uri = getResourceURI2(resourceName);
        } catch (IOException e) {
            throw new RuntimeException("failed to get resource [" + resourceName + "]", e);
        }
        return uri;
    }

    private URI getResourceURI2(String resourceName) throws IOException {
        String mappedResourceName = mapResourceNameIfRequested(resourceName, this.getConfig());

        URI resourceURI = URI.create(mappedResourceName);

        URI uri;
        if (resourceURI.isAbsolute()) {
            uri = resourceURI;
        } else {
            URI localArchiveURI = resourceCache.asURI(getArchiveURI());
            URI archiveJarURI = DatasetFinderUtil.getLocalDatasetURIRoot(new File(localArchiveURI));
            uri = ResourceUtil.absoluteURIFor(archiveJarURI, resourceName);
        }
        return uri;
    }


    public URI getDatasetSourceURI() {
        URIMeta uriMeta = resourceCache.asMeta(getDatasetCached().getArchiveURI());
        return uriMeta == null ? null : uriMeta.getSourceURI();
    }

    public Date getAccessedAt() {
        URIMeta uriMeta = resourceCache.asMeta(getDatasetCached().getArchiveURI());
        return uriMeta == null ? null : uriMeta.getAccessedAt();
    }

    public String getHash() {
        URIMeta uriMeta = resourceCache.asMeta(getDatasetCached().getArchiveURI());
        return uriMeta == null ? null : uriMeta.getSha256();
    }

    public URI getArchiveURI() {
        return getDatasetCached().getArchiveURI();
    }



}
