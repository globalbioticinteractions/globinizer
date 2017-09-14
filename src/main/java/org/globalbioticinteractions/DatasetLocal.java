package org.globalbioticinteractions;

import org.codehaus.jackson.JsonNode;
import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetImpl;
import org.eol.globi.util.ResourceUtil;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Date;

public class DatasetLocal implements Dataset {

    private final URI archiveCacheURI;
    private final Dataset dataset;
    private final Date accessedAt;

    public DatasetLocal(Dataset dataset, URI archiveCacheURI, Date accessedAt) {
        this.dataset = dataset;
        this.archiveCacheURI = archiveCacheURI;
        this.accessedAt = accessedAt;
    }

    @Override
    public InputStream getResource(String resourceName) throws IOException {
        return ResourceUtil.asInputStream(getResourceURI(DatasetImpl.mapResourceNameIfRequested(resourceName, getConfig())), DatasetImpl.class);
    }

    @Override
    public URI getResourceURI(String resourceName) {
        return ResourceUtil.getAbsoluteResourceURI(archiveCacheURI, DatasetImpl.mapResourceNameIfRequested(resourceName, getConfig()));
    }

    @Override
    public String getOrDefault(String key, String defaultValue) {
        return dataset.getOrDefault(key, defaultValue);
    }


    public URI getArchiveURI() {
        return dataset.getArchiveURI();
    }

    public String getNamespace() {
        return dataset.getNamespace();
    }

    public JsonNode getConfig() {
        return dataset.getConfig();
    }

    public String getCitation() {
        return dataset.getCitation();
    }

    public String getFormat() {
        return dataset.getFormat();
    }


    public String getDOI() {
        return dataset.getDOI();
    }

    public URI getConfigURI() {
        return dataset.getConfigURI();
    }

    @Override
    public void setConfig(JsonNode config) {
        dataset.setConfig(config);
    }

    @Override
    public void setConfigURI(URI configURI) {
        dataset.setConfigURI(configURI);
    }

}


