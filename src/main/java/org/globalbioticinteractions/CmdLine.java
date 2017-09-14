package org.globalbioticinteractions;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameters;

import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;

public class CmdLine {

    @Parameters(commandDescription = "List Dataset (Taxon) Names")
    private class CommandNames {

    }

    public class CommandMain implements Runnable {

        @Override
        public void run() {
            // ignore
        }
    }

    public JCommander buildCommander() {
        return JCommander.newBuilder()
                .addObject(new CommandMain())
                .addCommand("list", new CmdList())
                .addCommand("update", new CmdUpdate())
                .addCommand("names", new CommandNames())
                .addCommand("check", new CmdCheck())
                .build();
    }


}