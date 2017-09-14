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
import org.joda.time.DateTimeZone;
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
import java.util.Enumeration;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

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
            File cache = cache(dataset, cacheDir);
            URI archiveCacheURI = getArchiveCacheURI(cache);
            Date accessedAt = new Date();
            DatasetLocal datasetCached = new DatasetLocal(new DatasetImpl(namespace, archiveCacheURI), dataset.getArchiveURI(), accessedAt);
            File cacheDirFile = cacheDirForDataset(dataset, new File(cacheDir));
            String sha256 = cache.getName().replace(".zip", "");
            List<String> accessLogEntry = accessLogEntries(accessedAt, dataset, sha256);
            File accessLog = new File(cacheDirFile, "access.tsv");
            String prefix = accessLog.exists() ? "\n" : "";
            String accessLogLine = StringUtils.join(accessLogEntry, '\t');
            FileUtils.writeStringToFile(accessLog, prefix + accessLogLine, true);
            return datasetCached;
        } catch (IOException e) {
            throw new DatasetFinderException("failed to retrieve/cache dataset in namespace [" + namespace + "]", e);
        }
    }

    static List<String> accessLogEntries(Date accessedAt, Dataset datasetCached, String sha256) {
        return Arrays.asList(datasetCached.getNamespace()
                , datasetCached.getArchiveURI().toString()
                , sha256 + ":" + SHA_256
                , ISODateTimeFormat.dateTimeNoMillis().withZone(DateTimeZone.UTC).print(accessedAt.getTime()));
    }

    static URI getArchiveCacheURI(File archiveCache) throws IOException {
        Enumeration<? extends ZipEntry> entries = new ZipFile(archiveCache).entries();

        String archiveRoot = null;
        while (entries.hasMoreElements()) {
            ZipEntry entry = entries.nextElement();
            if (entry.isDirectory()) {
                archiveRoot = entry.getName();
                break;
            }
        }

        return URI.create("jar:" + archiveCache.toURI() + "!/" + archiveRoot);
    }

    static File cache(Dataset dataset, String pathname) throws IOException {
        File cacheDir = new File(pathname);
        FileUtils.forceMkdir(cacheDir);
        URI sourceURI = dataset.getArchiveURI();
        InputStream sourceStream = ResourceUtil.asInputStream(sourceURI, null);
        File directory = cacheDirForDataset(dataset, cacheDir);

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
