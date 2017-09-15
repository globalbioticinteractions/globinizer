package org.globalbioticinteractions.cmd;

import com.beust.jcommander.Parameters;
import org.eol.globi.data.NodeFactoryException;
import org.eol.globi.data.ParserFactoryLocal;
import org.eol.globi.data.StudyImporter;
import org.eol.globi.data.StudyImporterForGitHubData;
import org.eol.globi.domain.Interaction;
import org.eol.globi.domain.Specimen;
import org.eol.globi.domain.Study;
import org.eol.globi.domain.Taxon;
import org.eol.globi.service.Dataset;
import org.eol.globi.service.DatasetFactory;
import org.eol.globi.service.DatasetFinderException;
import org.eol.globi.service.GitHubImporterFactory;
import org.globalbioticinteractions.DatasetFinderLocal;

import java.util.stream.Collectors;
import java.util.stream.Stream;

@Parameters(separators = "= ", commandDescription = "List Dataset (Taxon) Names For Local Datasets")
public class CmdNames extends CmdDefaultParams {

    @Override
    public void run() {
        DatasetFinderLocal finder = new DatasetFinderLocal(getCacheDir());

        ParserFactoryLocal parserFactory = new ParserFactoryLocal();
        NodeFactoryNull nodeFactory = new NodeFactoryNull() {

            Dataset dataset;

            @Override
            public Dataset getOrCreateDataset(Dataset dataset) {
                this.dataset = dataset;
                return super.getOrCreateDataset(dataset);
            }

            @Override
            public Specimen createSpecimen(Interaction interaction, Taxon taxon) throws NodeFactoryException {
                logTaxon(taxon);
                return super.createSpecimen(interaction, taxon);
            }

            private void logTaxon(Taxon taxon) {
                Stream<String> taxonInfo = Stream.of(taxon.getName(),
                        taxon.getRank(),
                        taxon.getExternalId(),
                        taxon.getPath(),
                        taxon.getPathIds(),
                        taxon.getPathNames(),
                        dataset.getNamespace(),
                        dataset.getArchiveURI().toString(),
                        dataset.getOrDefault("accessedAt", ""),
                        dataset.getOrDefault("contentHash", ""));
                String row = taxonInfo
                        .map(term -> null == term ? "" : term)
                        .map(term -> term.replaceAll("[\\t\\n\\r]", " "))
                        .collect(Collectors.joining("\t"));
                System.out.println(row);
            }

            @Override
            public Specimen createSpecimen(Study study, Taxon taxon) throws NodeFactoryException {
                logTaxon(taxon);
                return super.createSpecimen(study, taxon);
            }
        };

        try {
            CmdUtil.handleNamespaces(finder, namespace -> {
                Dataset dataset = DatasetFactory.datasetFor(namespace, finder);
                nodeFactory.getOrCreateDataset(dataset);
                new GitHubImporterFactory()
                        .createImporter(dataset, nodeFactory)
                        .importStudy();
            }, getNamespaces());
        } catch (DatasetFinderException e) {
            throw new RuntimeException(e);
        }

    }
}


