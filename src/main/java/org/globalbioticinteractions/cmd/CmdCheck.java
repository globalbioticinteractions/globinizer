package org.globalbioticinteractions.cmd;

import com.beust.jcommander.Parameters;
import org.eol.globi.tool.GitHubRepoCheck;

@Parameters(separators = "= ", commandDescription = "Check Dataset Accessibility")
public class CmdCheck extends CmdDefaultParams {

    @Override
    public void run() {
        try {
            GitHubRepoCheck.main(getNamespaces().toArray(new String[getNamespaces().size()]));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
