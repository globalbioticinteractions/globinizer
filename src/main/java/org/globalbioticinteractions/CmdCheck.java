package org.globalbioticinteractions;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import org.eol.globi.tool.GitHubRepoCheck;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Parameters(separators = "= ", commandDescription = "Check Dataset Accessibility")
public class CmdCheck extends CmdDefaultParams {

    @Parameter(description = "namespace1, namespace2, ...")
    private List<String> namespaces = new ArrayList<>();

    @Override
    public void run() {
        try {
            GitHubRepoCheck.main(namespaces.toArray(new String[namespaces.size()]));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
