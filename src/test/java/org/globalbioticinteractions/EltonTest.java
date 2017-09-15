package org.globalbioticinteractions;

import org.junit.Test;

public class EltonTest {

    @Test
    public void check() {
        Elton.main(new String[] {"check", "globalbioticinteractions/template-dataset"});
    }

    @Test
    public void invalidCommand() {
        Elton.main(new String[] {"bla", "globalbioticinteractions/template-dataset"});
    }
}