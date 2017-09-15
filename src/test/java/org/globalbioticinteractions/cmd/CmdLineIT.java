package org.globalbioticinteractions.cmd;

import com.beust.jcommander.JCommander;
import org.apache.commons.io.FileUtils;
import org.globalbioticinteractions.cmd.CmdCheck;
import org.globalbioticinteractions.cmd.CmdLine;
import org.globalbioticinteractions.cmd.CmdList;
import org.globalbioticinteractions.cmd.CmdUpdate;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.File;

import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;

public class CmdLineIT {

    @Before
    public void emptyCache() {
        FileUtils.deleteQuietly(new File("target/tmp-dataset"));
    }

    @Test
    public void list() {
        JCommander jc = new CmdLine().buildCommander();
        jc.parse("list");

        Assert.assertEquals(jc.getParsedCommand(), "list");

        JCommander actual = jc.getCommands().get(jc.getParsedCommand());
        Assert.assertEquals(actual.getObjects().size(), 1);
        Assert.assertEquals(actual.getObjects().get(0).getClass(), CmdList.class);

        CmdLine.run(actual);
    }

    @Test
    public void runCheck() {
        JCommander jc = new CmdLine().buildCommander();
        jc.parse("check", "--cache-dir=./target/tmp-dataset", "globalbioticinteractions/template-dataset");

        JCommander actual = jc.getCommands().get(jc.getParsedCommand());
        Assert.assertEquals(actual.getObjects().size(), 1);
        Assert.assertEquals(actual.getObjects().get(0).getClass(), CmdCheck.class);

        CmdLine.run(actual);
    }
}