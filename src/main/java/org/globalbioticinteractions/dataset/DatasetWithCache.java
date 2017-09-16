package org.globalbioticinteractions.dataset;

import org.apache.commons.lang3.StringUtils;
import org.codehaus.jackson.JsonNode;
import org.eol.globi.data.ReferenceUtil;
import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetZenodo;
import org.eol.globi.util.ResourceCacheTmp;
import org.globalbioticinteractions.cache.Cache;
import org.globalbioticinteractions.cache.CachedURI;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.ISODateTimeFormat;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Date;

public class DatasetWithCache implements Dataset {
    private final Cache cache;
    private final Dataset datasetCached;

    public DatasetWithCache(Dataset dataset, Cache cache) {
        this.datasetCached = dataset;
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

    private static final String ZENODO_URL_PREFIX = "https://zenodo.org/record/";

    @Override
    public String getOrDefault(String key, String defaultValue) {
        if (org.apache.commons.lang.StringUtils.equalsIgnoreCase("accessedAt", key)) {
            return ISODateTimeFormat.dateTime().withZoneUTC().print(getAccessedAt().getTime());
        } else if (org.apache.commons.lang.StringUtils.equalsIgnoreCase("contentHash", key)) {
            return getHash();
        } else {
            return datasetCached.getOrDefault(key, defaultValue);
        }
    }

    public String getNamespace() {
        return getDatasetCached().getNamespace();
    }

    public JsonNode getConfig() {
        return getDatasetCached().getConfig();
    }

    public String getDOI() {
        String doi = getDatasetCached().getDOI();
        if (org.apache.commons.lang.StringUtils.isBlank(doi)
                && org.apache.commons.lang.StringUtils.startsWith(this.getArchiveURI().toString(), ZENODO_URL_PREFIX)) {
            doi = new DatasetZenodo(getNamespace(), getArchiveURI()).getDOI();
        }
        return doi;
    }

    public String getCitation() {
        StringBuilder citationGenerated = new StringBuilder();
        citationGenerated.append(org.apache.commons.lang.StringUtils.trim(ReferenceUtil.citationOrDefaultFor(this, "")));
        String doi = getDOI();
        if (org.apache.commons.lang.StringUtils.isNotBlank(doi)) {
            citationGenerated.append(ReferenceUtil.separatorFor(citationGenerated.toString()));
            citationGenerated.append("<");
            citationGenerated.append(doi);
            citationGenerated.append(">");
        }
        citationGenerated.append(ReferenceUtil.separatorFor(citationGenerated.toString()));
        citationGenerated.append("Accessed on ")
                .append(DateTimeFormat.forPattern("dd MMM YYYY").print(getAccessedAt().getTime()))
                .append(" via <")
                .append(getArchiveURI()).append(">.");
        return citationGenerated.toString();
    }

    public String getFormat() {
        return getDatasetCached().getFormat();
    }

    public URI getConfigURI() {
        return getDatasetCached().getConfigURI();
    }

    @Override
    public void setConfig(JsonNode config) {
        getDatasetCached().setConfig(config);
    }

    @Override
    public void setConfigURI(URI configURI) {
        getDatasetCached().setConfigURI(configURI);
    }

    private Dataset getDatasetCached() {
        return datasetCached;
    }
}
