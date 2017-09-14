package org.globalbioticinteractions;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import org.apache.commons.lang.StringUtils;
import org.eol.globi.service.DatasetFinder;
import org.eol.globi.service.DatasetFinderException;
import org.eol.globi.service.DatasetFinderGitHubArchive;
import org.eol.globi.service.DatasetFinderProxy;
import org.eol.globi.service.DatasetFinderZenodo;
import org.eol.globi.tool.GitHubRepoCheck;
import org.junit.Assert;
import org.junit.Test;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.core.StringContains.containsString;
import static org.junit.Assert.assertThat;

public class CmdLineTest {

    @Parameters(commandDescription = "List Available Datasets")
    private class CommandList implements Runnable {

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

    @Parameters(separators = "= ", commandDescription = "Sync Datasets with Local Repository")
    private class CommandUpdate extends CommandDefaultParams {

        @Override
        public void run() {
            DatasetFinder finder = new DatasetFinderProxy(Arrays.asList(new DatasetFinderZenodo(), new DatasetFinderGitHubArchive()));
            try {
                Collection<String> namespaces = finder.findNamespaces();
                for (String namespace : namespaces) {
                    new DatasetRepository(finder, getCacheDir())
                            .datasetFor(namespace);

                }
            } catch (DatasetFinderException e) {
                throw new RuntimeException(e);
            }
        }

    }

    @Parameters(commandDescription = "Normalize (or Enrich) Dataset Terms")
    private class CommandNormalize {

    }

    @Parameters(commandDescription = "Import Dataset")
    private class CommandImport {

    }

    @Parameters(separators = "=", commandDescription = "Export Dataset")
    private class CommandExport {

    }

    @Parameters(separators = "= ", commandDescription = "Test Dataset Accessibility")
    private class CommandTest extends CommandDefaultParams {
        @Parameter
        private List<String> namespaces = Arrays.asList();

        @Override
        public void run() {
            try {
                GitHubRepoCheck.main(namespaces.toArray(new String[namespaces.size()]));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public abstract class CommandDefaultParams implements Runnable {
        @Parameter(names = "--filter", description = "only include namespaces that match regex")
        private String regex = ".*";

        @Parameter(names = {"--cache-dir", "-c"}, description = "cache directory")
        private String cacheDir = "./datasets";

        public String getCacheDir() {
            return cacheDir;
        }

    }

    public class CommandMain implements Runnable {
        @Override
        public void run() {
            // ignore
        }
    }

    @Test
    public void usage() {
        JCommander jc = buildCommander();
        StringBuilder usageString = new StringBuilder();
        jc.usage(usageString);
        System.out.println(usageString.toString());
        assertThat(usageString.toString(), containsString("Usage"));
    }

    @Test
    public void list() {
        JCommander jc = buildCommander();

        jc.parse("list");

        Assert.assertEquals(jc.getParsedCommand(), "list");

        JCommander actual = jc.getCommands().get(jc.getParsedCommand());
        Assert.assertEquals(actual.getObjects().size(), 1);
        Assert.assertEquals(actual.getObjects().get(0).getClass(), CommandList.class);

        if (actual.getObjects().get(0) instanceof Runnable) {
            ((Runnable) actual.getObjects().get(0)).run();
        }
    }

    @Test
    public void update() {
        JCommander jc = buildCommander();
        jc.parse("update", "--cache-dir=./bla");
        assertUpdateCmd(jc);

        jc = buildCommander();
        jc.parse("update", "-c", "./bla");
        assertUpdateCmd(jc);

        jc = buildCommander();
        jc.parse("-c", "./bla", "update");
        assertUpdateCmd(jc);
    }

    @Test
    public void updateRun() {
        JCommander jc = buildCommander();
        jc.parse("update", "--cache-dir=./target/tmp-dataset");

        JCommander actual = jc.getCommands().get(jc.getParsedCommand());
        Assert.assertEquals(actual.getObjects().size(), 1);
        Assert.assertEquals(actual.getObjects().get(0).getClass(), CommandUpdate.class);

        if (actual.getObjects().get(0) instanceof Runnable) {
            ((Runnable) actual.getObjects().get(0)).run();
        }

    }

    @Test
    public void testRun() {
        JCommander jc = buildCommander();
        jc.parse("test", "--cache-dir=./target/tmp-dataset", "globalbioticinteractions/template-dataset");

        JCommander actual = jc.getCommands().get(jc.getParsedCommand());
        Assert.assertEquals(actual.getObjects().size(), 1);
        Assert.assertEquals(actual.getObjects().get(0).getClass(), CommandTest.class);

        if (actual.getObjects().get(0) instanceof Runnable) {
            ((Runnable) actual.getObjects().get(0)).run();
        }

    }

    public void assertUpdateCmd(JCommander jc) {
        Assert.assertEquals(jc.getParsedCommand(), "update");

        JCommander actual = jc.getCommands().get(jc.getParsedCommand());
        Assert.assertEquals(actual.getObjects().size(), 1);
        Object cmd = actual.getObjects().get(0);
        Assert.assertEquals(cmd.getClass(), CommandUpdate.class);
        assertThat(((CommandUpdate) cmd).getCacheDir(), is("./bla"));
    }

    public JCommander buildCommander() {
        CommandMain cmdMain = new CommandMain();
        return JCommander.newBuilder()
                .addObject(cmdMain)
                .addCommand("list", new CommandList())
                .addCommand("update", new CommandUpdate())
                .addCommand("test", new CommandTest())
                .addCommand("import", new CommandImport())
                .addCommand("normalize", new CommandNormalize())
                .addCommand("export", new CommandExport())
                .build();
    }


}