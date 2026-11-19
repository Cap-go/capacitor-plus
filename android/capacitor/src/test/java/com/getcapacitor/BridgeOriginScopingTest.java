package com.getcapacitor;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import android.net.Uri;
import org.junit.Test;

public class BridgeOriginScopingTest {

    @Test
    public void shouldBlockHttpInterceptorNavigationOnMatchingAppOrigin() {
        Uri appOrigin = Uri.parse("https://localhost:8100");
        assertTrue(
            Bridge.shouldBlockHttpInterceptorNavigation(
                Uri.parse("https://localhost:8100" + Bridge.CAPACITOR_HTTP_INTERCEPTOR_START + "?u=https://example.com"),
                appOrigin
            )
        );
    }

    @Test
    public void shouldNotBlockHttpInterceptorNavigationOnDifferentPort() {
        Uri appOrigin = Uri.parse("https://localhost:8100");
        assertFalse(
            Bridge.shouldBlockHttpInterceptorNavigation(
                Uri.parse("https://localhost:3000" + Bridge.CAPACITOR_HTTP_INTERCEPTOR_START + "/page"),
                appOrigin
            )
        );
    }

    @Test
    public void shouldNotBlockHttpInterceptorNavigationOnExternalHost() {
        Uri appOrigin = Uri.parse("https://localhost");
        assertFalse(
            Bridge.shouldBlockHttpInterceptorNavigation(
                Uri.parse("https://example.com" + Bridge.CAPACITOR_HTTP_INTERCEPTOR_START + "/x"),
                appOrigin
            )
        );
    }
}
