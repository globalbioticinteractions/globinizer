package org.globalbioticinteractions;

import com.beust.jcommander.JCommander;
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

        if (actual.getObjects().get(0) instanceof Runnable) {
            ((Runnable) actual.getObjects().get(0)).run();
        }
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

        if (actual.getObjects().get(0) instanceof Runnable) {
            ((Runnable) actual.getObjects().get(0)).run();
        }
    }

    @Test
    public void runCheck() {
        JCommander jc = new CmdLine().buildCommander();
        jc.parse("check", "--cache-dir=./target/tmp-dataset", "globalbioticinteractions/template-dataset");

        JCommander actual = jc.getCommands().get(jc.getParsedCommand());
        Assert.assertEquals(actual.getObjects().size(), 1);
        Assert.assertEquals(actual.getObjects().get(0).getClass(), CmdCheck.class);

        if (actual.getObjects().get(0) instanceof Runnable) {
            ((Runnable) actual.getObjects().get(0)).run();
        }
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