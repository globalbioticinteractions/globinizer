package org.globalbioticinteractions;

import org.apache.commons.lang.StringUtils;
import org.codehaus.jackson.JsonNode;
import org.eol.globi.data.ReferenceUtil;
import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetZenodo;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.ISODateTimeFormat;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Date;

public class DatasetLocal implements Dataset {

    public static final String ZENODO_URL_PREFIX = "https://zenodo.org/record/";
    private final URI datasetSourceURI;
    private final Dataset datasetCached;
    private final Date accessedAt;
    private final String hash;

    public DatasetLocal(Dataset datasetCached, URI datasetSourceURI, Date accessedAt, String hash) {
        this.datasetCached = datasetCached;
        this.datasetSourceURI = datasetSourceURI;
        this.accessedAt = accessedAt;
        this.hash = hash;
    }

    @Override
    public InputStream getResource(String resourceName) throws IOException {
        return datasetCached.getResource(resourceName);
    }

    @Override
    public URI getResourceURI(String resourceName) {
        return datasetCached.getResourceURI(resourceName);
    }

    @Override
    public String getOrDefault(String key, String defaultValue) {
        if (StringUtils.equalsIgnoreCase("accessedAt", key)) {
            return ISODateTimeFormat.dateTime().withZoneUTC().print(accessedAt.getTime());
        } else if (StringUtils.equalsIgnoreCase("contentHash", key)) {
            return hash;
        } else {
            return datasetCached.getOrDefault(key, defaultValue);
        }
    }


    public URI getArchiveURI() {
        return this.datasetSourceURI;
    }

    public String getNamespace() {
        return datasetCached.getNamespace();
    }

    public JsonNode getConfig() {
        return datasetCached.getConfig();
    }

    public String getDOI() {
        String doi = datasetCached.getDOI();
        if (StringUtils.isBlank(doi)
                && StringUtils.startsWith(this.getArchiveURI().toString(), ZENODO_URL_PREFIX)) {
            doi = new DatasetZenodo(getNamespace(), getArchiveURI()).getDOI();
        }
        return doi;
    }

    public String getCitation() {
        StringBuilder citationGenerated = new StringBuilder();
        citationGenerated.append(StringUtils.trim(ReferenceUtil.citationOrDefaultFor(this, "")));
        String doi = getDOI();
        if (StringUtils.isNotBlank(doi)) {
            citationGenerated.append(ReferenceUtil.separatorFor(citationGenerated.toString()));
            citationGenerated.append("<");
            citationGenerated.append(doi);
            citationGenerated.append(">");
        }
        citationGenerated.append(ReferenceUtil.separatorFor(citationGenerated.toString()));
        citationGenerated.append("Accessed on ")
                .append(DateTimeFormat.forPattern("dd MMM YYYY").print(accessedAt.getTime()))
                .append(" via <")
                .append(getArchiveURI()).append(">.");
        return citationGenerated.toString();
    }

    public String getFormat() {
        return datasetCached.getFormat();
    }

    public URI getConfigURI() {
        return datasetCached.getConfigURI();
    }

    @Override
    public void setConfig(JsonNode config) {
        datasetCached.setConfig(config);
    }

    @Override
    public void setConfigURI(URI configURI) {
        datasetCached.setConfigURI(configURI);
    }

}


