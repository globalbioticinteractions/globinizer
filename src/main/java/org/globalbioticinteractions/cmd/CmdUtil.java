package org.globalbioticinteractions.cmd;

import org.eol.globi.service.DatasetFinder;
import org.eol.globi.service.DatasetFinderException;

import java.util.ArrayList;
import java.util.List;

class CmdUtil {

    static void handleNamespaces(DatasetFinder finder, NamespaceHandler handler, List<String> namespaces) throws DatasetFinderException {
        List<String> selectedNamespaces = new ArrayList<>(namespaces);
        if (selectedNamespaces.isEmpty()) {
            selectedNamespaces = new ArrayList<>(finder.findNamespaces());
        }

        for (String namespace : selectedNamespaces) {
            try {
                handler.onNamespace(namespace);
            } catch (Exception e) {
                throw new DatasetFinderException("failed to handle [" + namespace + "]", e);
            }
        }
    }
}
