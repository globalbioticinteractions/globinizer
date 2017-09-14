package org.globalbioticinteractions;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import org.apache.commons.collections4.CollectionUtils;
import org.eol.globi.service.DatasetFinder;
import org.eol.globi.service.DatasetFinderException;
import org.eol.globi.service.DatasetFinderGitHubArchive;
import org.eol.globi.service.DatasetFinderProxy;
import org.eol.globi.service.DatasetFinderZenodo;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

@Parameters(separators = "= ", commandDescription = "Sync Datasets with Local Repository")
public class CmdUpdate extends CmdDefaultParams {

    @Parameter(description = "namespace1, namespace2, ...")
    private List<String> namespaces = new ArrayList<>();

    @Override
    public void run() {
        DatasetFinder finder = new DatasetFinderProxy(Arrays.asList(new DatasetFinderZenodo(), new DatasetFinderGitHubArchive()));
        try {
            List<String> selectedNamespaces = new ArrayList<>(namespaces);
            if (selectedNamespaces.isEmpty()) {
                selectedNamespaces = new ArrayList<>(finder.findNamespaces());
            }

            for (String namespace : selectedNamespaces) {
                new DatasetFinderCaching(finder, getCacheDir())
                        .datasetFor(namespace);
            }
        } catch (DatasetFinderException e) {
            throw new RuntimeException(e);
        }
    }

}
