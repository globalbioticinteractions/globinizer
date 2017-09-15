package org.globalbioticinteractions.cmd;

import com.beust.jcommander.Parameter;

import java.util.ArrayList;
import java.util.List;

public abstract class CmdDefaultParams implements Runnable {
    @Parameter(names = {"--cache-dir", "-c"}, description = "cache directory")
    private String cacheDir = "./datasets";

    public String getCacheDir() {
        return cacheDir;
    }

    @Parameter(description = "namespace1, namespace2, ...")
    private List<String> namespaces = new ArrayList<>();


    public List<String> getNamespaces() {
        return namespaces;
    }
}