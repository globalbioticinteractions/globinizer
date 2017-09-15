package org.globalbioticinteractions;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.joda.time.format.ISODateTimeFormat;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Date;

public class LocalReadonlyCache implements ResourceCache {
    private final Log LOG = LogFactory.getLog(LocalReadonlyCache.class);

    private final String namespace;
    private final String cachePath;

    public LocalReadonlyCache(String namespace, String cachePath) {
        this.namespace = namespace;
        this.cachePath = cachePath;
    }

    @Override
    public URI asURI(URI resourceURI) throws IOException {
        URIMeta uriMeta = asMeta(resourceURI);
        return uriMeta == null ? null : uriMeta.getCachedURI();
    }

    @Override
    public URIMeta asMeta(URI resourceURI) {
        URIMeta meta = null;
        File accessFile;
        try {
            File cacheDirForNamespace = DatasetFinderCaching.getCacheDirForNamespace(cachePath, namespace);

            String hashCandidate = getHashCandidate(resourceURI, cacheDirForNamespace);
            accessFile = new File(cacheDirForNamespace, "access.tsv");
            if (accessFile.exists()) {
                String[] rows = IOUtils.toString(accessFile.toURI()).split("\n");
                for (String row : rows) {
                    String[] split = row.split("\t");
                    if (split.length > 3) {
                        String hashFull = split[2];
                        String hash = hashFull.split(":")[0];
                        URI sourceURI = URI.create(split[1]);
                        if (StringUtils.equals(resourceURI.toString(), sourceURI.toString())
                                || StringUtils.equals(hashCandidate, hash)) {
                            File cachedArchiveFile = new File(accessFile.getParent(), hash);
                            Date accessedAt = ISODateTimeFormat.dateTimeParser().withZoneUTC().parseDateTime(split[3]).toDate();
                            meta = new URIMeta(namespace, sourceURI, cachedArchiveFile.toURI(), hash, accessedAt);
                        }
                    }
                }
            }
        } catch (IOException e) {
            LOG.error("unexpected exception on getting meta for [" + resourceURI + "]", e);
        }
        return meta;

    }

    private String getHashCandidate(URI resourceURI, File cacheDirForNamespace) {
        String hashCandidate = null;
        if (StringUtils.startsWith(resourceURI.toString(), cacheDirForNamespace.toURI().toString())) {
            hashCandidate = StringUtils.replace(resourceURI.toString(), cacheDirForNamespace.toURI().toString(), "");
        }
        return hashCandidate;
    }

    @Override
    public InputStream asInputStream(URI resourceURI) throws IOException {
        URI resourceURI1 = asURI(resourceURI);
        return resourceURI1 == null ? null : resourceURI1.toURL().openStream();
    }
}

