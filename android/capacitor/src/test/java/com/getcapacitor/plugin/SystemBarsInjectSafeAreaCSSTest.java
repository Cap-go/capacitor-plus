package com.getcapacitor.plugin;

import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.res.Resources;
import android.util.DisplayMetrics;
import android.webkit.WebView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.WindowInsetsCompat;
import com.getcapacitor.Bridge;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = 35, manifest = Config.NONE)
public class SystemBarsInjectSafeAreaCSSTest {

    @Test
    public void injectSafeAreaCSSUsesOriginalSystemBarInsets() throws Exception {
        SystemBars plugin = new SystemBars();
        Bridge bridge = mock(Bridge.class);
        AppCompatActivity activity = mock(AppCompatActivity.class);
        Resources resources = mock(Resources.class);
        DisplayMetrics displayMetrics = new DisplayMetrics();
        displayMetrics.density = 2.0f;
        WebView webView = mock(WebView.class);

        when(bridge.getActivity()).thenReturn(activity);
        when(activity.getResources()).thenReturn(resources);
        when(resources.getDisplayMetrics()).thenReturn(displayMetrics);
        when(bridge.getWebView()).thenReturn(webView);
        doAnswer((invocation) -> {
            ((Runnable) invocation.getArgument(0)).run();
            return null;
        })
            .when(bridge)
            .executeOnMainThread(any(Runnable.class));

        plugin.setBridge(bridge);

        Field insetsHandlingField = SystemBars.class.getDeclaredField("insetsHandling");
        insetsHandlingField.setAccessible(true);
        insetsHandlingField.set(plugin, SystemBars.INSETS_HANDLING_CSS);

        WindowInsetsCompat insets = new WindowInsetsCompat.Builder()
            .setInsets(WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.displayCutout(), Insets.of(10, 20, 5, 15))
            .build();

        Method injectSafeAreaCSS = SystemBars.class.getDeclaredMethod("injectSafeAreaCSS", WindowInsetsCompat.class);
        injectSafeAreaCSS.setAccessible(true);
        injectSafeAreaCSS.invoke(plugin, insets);

        ArgumentCaptor<String> scriptCaptor = ArgumentCaptor.forClass(String.class);
        verify(webView).evaluateJavascript(scriptCaptor.capture(), any());
        String script = scriptCaptor.getValue();
        assertTrue(script.contains("\"--safe-area-inset-top\", \"10px\""));
        assertTrue(script.contains("\"--safe-area-inset-left\", \"5px\""));
        assertTrue(script.contains("\"--safe-area-inset-bottom\", \"7px\""));
        assertTrue(script.contains("\"--safe-area-inset-right\", \"2px\""));
    }
}