package org.globalbioticinteractions.cmd;

import com.beust.jcommander.Parameters;
import org.eol.globi.service.DatasetFinder;
import org.eol.globi.service.DatasetFinderException;
import org.eol.globi.service.DatasetFinderGitHubArchive;
import org.eol.globi.service.DatasetFinderProxy;
import org.eol.globi.service.DatasetFinderZenodo;
import org.globalbioticinteractions.DatasetFinderCaching;

import java.util.Arrays;

@Parameters(separators = "= ", commandDescription = "Sync Datasets with Local Repository")
public class CmdUpdate extends CmdDefaultParams {

    @Override
    public void run() {
        DatasetFinder finder = new DatasetFinderProxy(Arrays.asList(new DatasetFinderZenodo(), new DatasetFinderGitHubArchive()));
        try {
            NamespaceHandler handler = namespace -> new DatasetFinderCaching(finder, getCacheDir())
                    .datasetFor(namespace);
            CmdUtil.handleNamespaces(finder, handler, getNamespaces());
        } catch (DatasetFinderException e) {
            throw new RuntimeException(e);
        }
    }

}
