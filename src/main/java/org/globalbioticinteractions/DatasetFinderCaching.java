package org.globalbioticinteractions;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetFinder;
import org.eol.globi.service.DatasetFinderException;
import org.eol.globi.service.DatasetImpl;
import org.eol.globi.util.ResourceUtil;
import org.joda.time.format.ISODateTimeFormat;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.Collection;
import java.util.Date;
import java.util.List;

public class DatasetFinderCaching implements DatasetFinder {
    private final static Log LOG = LogFactory.getLog(org.eol.globi.service.DatasetFinderCaching.class);
    public static final String SHA_256 = "SHA-256";

    private final DatasetFinder finder;
    private final String cacheDir;

    public DatasetFinderCaching(DatasetFinder finder) {
        this(finder, "target/cache/datasets");
    }

    public DatasetFinderCaching(DatasetFinder finder, String cacheDir) {
        this.finder = finder;
        this.cacheDir = cacheDir;
    }


    @Override
    public Collection<String> findNamespaces() throws DatasetFinderException {
        return this.finder.findNamespaces();
    }


    @Override
    public Dataset datasetFor(String namespace) throws DatasetFinderException {
        try {
            Dataset dataset = finder.datasetFor(namespace);
            return cacheAndLog(namespace, dataset);
        } catch (IOException e) {
            throw new DatasetFinderException("failed to retrieve/cache dataset in namespace [" + namespace + "]", e);
        }
    }

    private Dataset cacheAndLog(String namespace, Dataset dataset) throws IOException {
        File cache = cache(dataset, cacheDir, dataset.getArchiveURI());
        Date accessedAt = new Date();
        File cacheDirFile = cacheDirForDataset(dataset, new File(cacheDir));
        String sha256 = cache.getName().replace(".zip", "");
        appendAccessLog(namespace, dataset.getArchiveURI().toString(), sha256, accessedAt, cacheDirFile);
        return new DatasetLocal(new DatasetImpl(namespace, DatasetFinderUtil.getLocalDatasetURIRoot(cache)), dataset.getArchiveURI(), accessedAt, toContentHash(sha256));
    }

    private void appendAccessLog(String namespace, String sourceURI, String sha256, Date accessedAt, File cacheDirFile) throws IOException {
        List<String> accessLogEntry = compileLogEntries(namespace, sourceURI, sha256, accessedAt);
        File accessLog = new File(cacheDirFile, "access.tsv");
        String prefix = accessLog.exists() ? "\n" : "";
        String accessLogLine = StringUtils.join(accessLogEntry, '\t');
        FileUtils.writeStringToFile(accessLog, prefix + accessLogLine, true);
    }

    static List<String> compileLogEntries(String namespace, String sourceURI, String sha256, Date accessedAt) {
        return Arrays.asList(namespace
                , sourceURI
                , toContentHash(sha256)
                , ISODateTimeFormat.dateTimeNoMillis().withZoneUTC().print(accessedAt.getTime()));
    }

    private static String toContentHash(String sha256) {
        return sha256 + ":" + SHA_256;
    }


    static File cache(Dataset dataset, String cachePath, URI sourceURI) throws IOException {
        File cacheDir = new File(cachePath);
        FileUtils.forceMkdir(cacheDir);
        File directory = cacheDirForDataset(dataset, cacheDir);

        InputStream sourceStream = ResourceUtil.asInputStream(sourceURI, null);

        File destinationFile = new File(directory, "archive.tmp");
        String msg = "caching [" + sourceURI + "]";
        LOG.info(msg + " started...");
        try {
            MessageDigest md = MessageDigest.getInstance(SHA_256);
            DigestInputStream digestInputStream = new DigestInputStream(sourceStream, md);
            FileUtils.copyInputStreamToFile(digestInputStream, destinationFile);
            IOUtils.closeQuietly(digestInputStream);
            String sha256 = String.format("%064x", new java.math.BigInteger(1, md.digest()));
            File destFile = new File(directory, sha256 + ".zip");
            FileUtils.deleteQuietly(destFile);
            FileUtils.moveFile(destinationFile, destFile);
            LOG.info(msg + " cached at [" + destFile.toURI().toString() + "]...");
            LOG.info(msg + " complete.");
            return destFile;
        } catch (NoSuchAlgorithmException e) {
            LOG.error("failed to access hash/digest algorithm", e);
            throw new IOException("failed to cache dataset [" + dataset.getArchiveURI().toString() + "]");
        }
    }

    private static File cacheDirForDataset(Dataset dataset, File cacheDir) throws IOException {
        File directory = new File(cacheDir, dataset.getNamespace());
        FileUtils.forceMkdir(directory);
        return directory;
    }
}
