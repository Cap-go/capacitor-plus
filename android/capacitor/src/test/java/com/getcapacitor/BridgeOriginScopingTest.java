package com.getcapacitor;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.net.Uri;
import org.junit.Test;

public class BridgeOriginScopingTest {

    @Test
    public void shouldBlockHttpInterceptorNavigationOnMatchingAppOrigin() {
        Uri appOrigin = mock(Uri.class);
        when(appOrigin.getHost()).thenReturn("localhost");
        when(appOrigin.getScheme()).thenReturn("https");
        when(appOrigin.getPort()).thenReturn(8100);

        Uri url = mock(Uri.class);
        when(url.getPath()).thenReturn(Bridge.CAPACITOR_HTTP_INTERCEPTOR_START + "?u=https://example.com");
        when(url.getHost()).thenReturn("localhost");
        when(url.getScheme()).thenReturn("https");
        when(url.getPort()).thenReturn(8100);

        assertTrue(Bridge.shouldBlockHttpInterceptorNavigation(url, appOrigin));
    }

    @Test
    public void shouldNotBlockHttpInterceptorNavigationOnDifferentPort() {
        Uri appOrigin = mock(Uri.class);
        when(appOrigin.getHost()).thenReturn("localhost");
        when(appOrigin.getScheme()).thenReturn("https");
        when(appOrigin.getPort()).thenReturn(8100);

        Uri url = mock(Uri.class);
        when(url.getPath()).thenReturn(Bridge.CAPACITOR_HTTP_INTERCEPTOR_START + "/page");
        when(url.getHost()).thenReturn("localhost");
        when(url.getScheme()).thenReturn("https");
        when(url.getPort()).thenReturn(3000);

        assertFalse(Bridge.shouldBlockHttpInterceptorNavigation(url, appOrigin));
    }

    @Test
    public void shouldNotBlockHttpInterceptorNavigationOnExternalHost() {
        Uri appOrigin = mock(Uri.class);
        when(appOrigin.getHost()).thenReturn("localhost");
        when(appOrigin.getScheme()).thenReturn("https");
        when(appOrigin.getPort()).thenReturn(-1);

        Uri url = mock(Uri.class);
        when(url.getPath()).thenReturn(Bridge.CAPACITOR_HTTP_INTERCEPTOR_START + "/x");
        when(url.getHost()).thenReturn("example.com");
        when(url.getScheme()).thenReturn("https");
        when(url.getPort()).thenReturn(-1);

        assertFalse(Bridge.shouldBlockHttpInterceptorNavigation(url, appOrigin));
    }
}
