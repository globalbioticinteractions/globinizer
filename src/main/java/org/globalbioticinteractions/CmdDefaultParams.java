package org.globalbioticinteractions;

import com.beust.jcommander.Parameter;

public abstract class CmdDefaultParams implements Runnable {
    @Parameter(names = "--filter", description = "only include namespaces that match regex")
    private String regex = ".*";

    @Parameter(names = {"--cache-dir", "-c"}, description = "cache directory")
    private String cacheDir = "./datasets";

    public String getCacheDir() {
        return cacheDir;
    }

}
