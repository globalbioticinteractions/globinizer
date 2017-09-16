package org.globalbioticinteractions.dataset;

import org.apache.commons.lang3.StringUtils;
import org.codehaus.jackson.JsonNode;
import org.eol.globi.service.Dataset;
import org.eol.globi.util.ResourceCacheTmp;
import org.globalbioticinteractions.cache.Cache;
import org.globalbioticinteractions.cache.CachedURI;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Date;

public class DatasetWithCache extends DatasetLocal {
    private final Cache cache;

    public DatasetWithCache(Dataset dataset, Cache cache) {
        super(dataset, null, null, null);
        this.cache = cache;
    }

    @Override
    public InputStream getResource(String resourceName) throws IOException {
        return cache.asInputStream(getResourceURI2(resourceName));
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
            URI localArchiveURI = cache.asURI(getArchiveURI());
            URI archiveJarURI = DatasetFinderUtil.getLocalDatasetURIRoot(new File(localArchiveURI));
            uri = new ResourceCacheTmp().getAbsoluteResourceURI(archiveJarURI, resourceName);
        }
        return uri;
    }


    public URI getDatasetSourceURI() {
        CachedURI cachedUri = cache.asMeta(getDatasetCached().getArchiveURI());
        return cachedUri == null ? null : cachedUri.getSourceURI();
    }

    public Date getAccessedAt() {
        CachedURI cachedUri = cache.asMeta(getDatasetCached().getArchiveURI());
        return cachedUri == null ? null : cachedUri.getAccessedAt();
    }

    public String getHash() {
        CachedURI cachedUri = cache.asMeta(getDatasetCached().getArchiveURI());
        return cachedUri == null ? null : cachedUri.getSha256();
    }

    public URI getArchiveURI() {
        return getDatasetCached().getArchiveURI();
    }

    protected String mapResourceNameIfRequested(String resourceName, JsonNode config) {
        String mappedResource = resourceName;
        if (config != null && config.has("resources")) {
            JsonNode resources = config.get("resources");
            if (resources.isObject() && resources.has(resourceName)) {
                JsonNode resourceName1 = resources.get(resourceName);
                if (resourceName1.isTextual()) {
                    String resourceNameCandidate = resourceName1.asText();
                    mappedResource = StringUtils.isBlank(resourceNameCandidate) ? mappedResource : resourceNameCandidate;
                }
            }
        }
        return mappedResource;
    }

}
