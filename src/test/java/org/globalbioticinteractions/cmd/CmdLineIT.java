package org.globalbioticinteractions.cmd;

import com.beust.jcommander.JCommander;
import org.globalbioticinteractions.cmd.CmdCheck;
import org.globalbioticinteractions.cmd.CmdLine;
import org.globalbioticinteractions.cmd.CmdList;
import org.globalbioticinteractions.cmd.CmdUpdate;
import org.junit.Assert;
import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;

public class CmdLineIT {

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
    public void update() {
        JCommander jc = new CmdLine().buildCommander();
        jc.parse("update", "--cache-dir=./bla");
        assertUpdateCmd(jc);

        jc = new CmdLine().buildCommander();
        jc.parse("update", "-c", "./bla");
        assertUpdateCmd(jc);
    }

    @Test
    public void runUpdate() {
        JCommander jc = new CmdLine().buildCommander();
        jc.parse("update", "--cache-dir=./target/tmp-dataset", "globalbioticinteractions/template-dataset");

        JCommander actual = jc.getCommands().get(jc.getParsedCommand());
        Assert.assertEquals(actual.getObjects().size(), 1);
        Assert.assertEquals(actual.getObjects().get(0).getClass(), CmdUpdate.class);

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

    private void assertUpdateCmd(JCommander jc) {
        Assert.assertEquals(jc.getParsedCommand(), "update");

        JCommander actual = jc.getCommands().get(jc.getParsedCommand());
        Assert.assertEquals(actual.getObjects().size(), 1);
        Object cmd = actual.getObjects().get(0);
        Assert.assertEquals(cmd.getClass(), CmdUpdate.class);
        assertThat(((CmdUpdate) cmd).getCacheDir(), is("./bla"));
    }
}