package org.globalbioticinteractions;

import com.beust.jcommander.Parameters;
import org.apache.commons.lang.StringUtils;
import org.eol.globi.service.DatasetFinderException;
import org.eol.globi.service.DatasetFinderGitHubArchive;
import org.eol.globi.service.DatasetFinderProxy;
import org.eol.globi.service.DatasetFinderZenodo;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Parameters(commandDescription = "List Available Datasets")
public class CmdList implements Runnable {

    @Override
    public void run() {
        DatasetFinderProxy finder = new DatasetFinderProxy(Arrays.asList(new DatasetFinderZenodo(), new DatasetFinderGitHubArchive()));
        try {
            List<String> namespaces = finder.findNamespaces()
                    .stream()
                    .filter(StringUtils::isNotEmpty)
                    .distinct()
                    .sorted()
                    .collect(Collectors.toList());
            System.out.println(StringUtils.join(namespaces, "\n"));
        } catch (DatasetFinderException e) {
            throw new RuntimeException(e);
        }
    }
}
