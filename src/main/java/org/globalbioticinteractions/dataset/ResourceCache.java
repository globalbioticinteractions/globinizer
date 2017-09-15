package org.globalbioticinteractions.dataset;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;

public interface ResourceCache {
    URI asURI(URI resourceURI) throws IOException;

    URIMeta asMeta(URI resourceURI);

    InputStream asInputStream(URI resourceURI) throws IOException;
}
