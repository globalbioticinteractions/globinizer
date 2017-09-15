package org.globalbioticinteractions;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.List;

public class ResourceCacheProxy implements ResourceCache {

    private List<ResourceCache> resourceCaches;

    public ResourceCacheProxy(List<ResourceCache> resourceCaches) {
        this.resourceCaches = resourceCaches;
    }

    @Override
    public URI asURI(URI resourceURI) throws IOException {
        URI uri = null;
        for (ResourceCache resourceCache : resourceCaches) {
                uri = uri == null ? resourceCache.asURI(resourceURI) : uri;
        }
        return uri;
    }

    @Override
    public URIMeta asMeta(URI resourceURI) {
        URIMeta meta = null;
        for (ResourceCache resourceCache : resourceCaches) {
            meta = meta == null ? resourceCache.asMeta(resourceURI) : meta;
        }
        return meta;
    }

    @Override
    public InputStream asInputStream(URI resourceURI) throws IOException {
        InputStream is = null;
        for (ResourceCache resourceCache : resourceCaches) {
            is = is == null ? resourceCache.asInputStream(resourceURI) : is;
        }
        return is;
    }
}

