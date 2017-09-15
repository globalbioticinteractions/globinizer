package org.globalbioticinteractions;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.apache.commons.io.filefilter.FileFileFilter;
import org.apache.commons.io.filefilter.TrueFileFilter;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;
import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetCached;
import org.eol.globi.service.DatasetFactory;
import org.eol.globi.service.DatasetFinder;
import org.eol.globi.service.DatasetFinderException;
import org.eol.globi.service.DatasetFinderGitHubArchive;
import org.eol.globi.service.DatasetImpl;
import org.eol.globi.util.ResourceUtil;
import org.joda.time.DateTimeZone;
import org.joda.time.format.DateTimeFormat;
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
import java.util.Collections;
import java.util.Date;
import java.util.Enumeration;
import java.util.List;
import java.util.TreeSet;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

public class DatasetFinderLocal implements DatasetFinder {
    private final String cacheDir;

    public DatasetFinderLocal(String cacheDir) {
        this.cacheDir = cacheDir;
    }

    @Override
    public Collection<String> findNamespaces() throws DatasetFinderException {
        Collection<File> accessFiles = FileUtils.listFiles(new File(cacheDir), new FileFileFilter() {
            @Override
            public boolean accept(File file) {
                return "access.tsv".endsWith(file.getName());
            }
        }, TrueFileFilter.INSTANCE);

        Collection<String> namespaces = new TreeSet<>();
        for (File accessFile : accessFiles) {
            try {
                String[] rows = IOUtils.toString(accessFile.toURI()).split("\n");
                for (String row : rows) {
                    namespaces.add(row.split("\t")[0]);
                }
            } catch (IOException e) {
                throw new DatasetFinderException("failed to read ", e);
            }
        }

        return namespaces;
    }


    @Override
    public Dataset datasetFor(String namespace) throws DatasetFinderException {
        File accessFile = new File(cacheDir + "/" + namespace + "/access.tsv");
        Dataset dataset = null;

        try {
            String[] rows = IOUtils.toString(accessFile.toURI()).split("\n");
            for (String row : rows) {
                String[] split = row.split("\t");
                if (split.length > 3) {
                    String hashFull = split[2];
                    String hash = hashFull.split(":")[0];
                    URI sourceURI = URI.create(split[1]);
                    File cachedArchiveFile = new File(accessFile.getParent(), hash + ".zip");
                    URI cachedURI = cacheArchive(cachedArchiveFile);

                    Dataset datasetCached = DatasetFactory.datasetFor(namespace, new DatasetFinder() {
                        @Override
                        public Collection<String> findNamespaces() throws DatasetFinderException {
                            return Arrays.asList(namespace);
                        }

                        @Override
                        public Dataset datasetFor(String s) throws DatasetFinderException {
                            return new DatasetImpl(namespace, cachedURI);
                        }
                    });


                    dataset = new DatasetLocal(datasetCached,
                            sourceURI,
                            ISODateTimeFormat.dateTimeParser().withZoneUTC().parseDateTime(split[3]).toDate(),
                            hashFull);

                }
            }
        } catch (IOException e) {
            throw new DatasetFinderException("failed to access [" + accessFile.toURI().toString() + "]", e);
        }

        if (dataset == null) {
            throw new DatasetFinderException("failed to retrieve/cache dataset in namespace [" + namespace + "]");
        }

        return dataset;
    }

    static URI cacheArchive(File archiveCache) throws IOException {
        Enumeration<? extends ZipEntry> entries = new ZipFile(archiveCache).entries();

        String archiveRoot = null;
        while(entries.hasMoreElements()) {
            ZipEntry entry = entries.nextElement();
            if (entry.isDirectory()) {
                archiveRoot = entry.getName();
                break;
            }
        }

        return URI.create("jar:" + archiveCache.toURI() + "!/" + archiveRoot);
    }


}
