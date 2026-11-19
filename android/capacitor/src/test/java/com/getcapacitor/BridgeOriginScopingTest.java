package com.getcapacitor;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

import android.net.Uri;
import java.net.URI;
import java.net.URISyntaxException;
import org.junit.Test;
import org.mockito.MockedStatic;

public class BridgeOriginScopingTest {

    @Test
    public void shouldBlockHttpInterceptorNavigationOnMatchingAppOrigin() {
        withParsedUris(() -> {
            Uri appOrigin = Uri.parse("https://localhost:8100");
            assertTrue(
                Bridge.shouldBlockHttpInterceptorNavigation(
                    Uri.parse("https://localhost:8100" + Bridge.CAPACITOR_HTTP_INTERCEPTOR_START + "?u=https://example.com"),
                    appOrigin
                )
            );
        });
    }

    @Test
    public void shouldNotBlockHttpInterceptorNavigationOnDifferentPort() {
        withParsedUris(() -> {
            Uri appOrigin = Uri.parse("https://localhost:8100");
            assertFalse(
                Bridge.shouldBlockHttpInterceptorNavigation(
                    Uri.parse("https://localhost:3000" + Bridge.CAPACITOR_HTTP_INTERCEPTOR_START + "/page"),
                    appOrigin
                )
            );
        });
    }

    @Test
    public void shouldNotBlockHttpInterceptorNavigationOnExternalHost() {
        withParsedUris(() -> {
            Uri appOrigin = Uri.parse("https://localhost");
            assertFalse(
                Bridge.shouldBlockHttpInterceptorNavigation(
                    Uri.parse("https://example.com" + Bridge.CAPACITOR_HTTP_INTERCEPTOR_START + "/x"),
                    appOrigin
                )
            );
        });
    }

    private static void withParsedUris(Runnable block) {
        try (MockedStatic<Uri> uriStatic = mockStatic(Uri.class)) {
            uriStatic.when(() -> Uri.parse(anyString())).thenAnswer((inv) -> parseUri(inv.getArgument(0)));
            block.run();
        }
    }

    private static Uri parseUri(String url) throws URISyntaxException {
        URI parsed = new URI(url);
        Uri uri = mock(Uri.class);
        when(uri.getScheme()).thenReturn(parsed.getScheme());
        when(uri.getHost()).thenReturn(parsed.getHost());
        when(uri.getPort()).thenReturn(parsed.getPort());
        when(uri.getPath()).thenReturn(parsed.getPath());
        return uri;
    }
}
