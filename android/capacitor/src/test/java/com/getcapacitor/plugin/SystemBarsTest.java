package com.getcapacitor.plugin;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.res.Resources;
import android.util.DisplayMetrics;
import android.view.View;
import android.view.Window;
import android.webkit.WebView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.Bridge;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import org.junit.Assert;
import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;

public class SystemBarsTest {

    @Test
    public void showWithEmptyBarShowsSystemBars() throws Exception {
        WindowInsetsControllerCompat controller = invokeShow("");

        verify(controller).show(WindowInsetsCompat.Type.systemBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.statusBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.navigationBars());
    }

    @Test
    public void showWithStatusBarShowsOnlyStatusBars() throws Exception {
        WindowInsetsControllerCompat controller = invokeShow("StatusBar");

        verify(controller).show(WindowInsetsCompat.Type.statusBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.systemBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.navigationBars());
    }

    @Test
    public void showWithNavigationBarShowsOnlyNavigationBars() throws Exception {
        WindowInsetsControllerCompat controller = invokeShow("NavigationBar");

        verify(controller).show(WindowInsetsCompat.Type.navigationBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.systemBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.statusBars());
    }

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
        insetsHandlingField.set(plugin, "css");

        WindowInsetsCompat insets = mock(WindowInsetsCompat.class);
        when(insets.getInsets(WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.displayCutout())).thenReturn(
            Insets.of(20, 40, 10, 30)
        );
        when(insets.isVisible(WindowInsetsCompat.Type.ime())).thenReturn(false);

        Method injectSafeAreaCSS = SystemBars.class.getDeclaredMethod("injectSafeAreaCSS", WindowInsetsCompat.class, boolean.class);
        injectSafeAreaCSS.setAccessible(true);
        injectSafeAreaCSS.invoke(plugin, insets, false);

        ArgumentCaptor<String> scriptCaptor = ArgumentCaptor.forClass(String.class);
        verify(webView).evaluateJavascript(scriptCaptor.capture(), any());
        String script = scriptCaptor.getValue();
        Assert.assertTrue(script.contains("\"--safe-area-inset-top\", \"20px\""));
        Assert.assertTrue(script.contains("\"--safe-area-inset-left\", \"10px\""));
        Assert.assertTrue(script.contains("\"--safe-area-inset-bottom\", \"15px\""));
        Assert.assertTrue(script.contains("\"--safe-area-inset-right\", \"5px\""));
    }

    private WindowInsetsControllerCompat invokeShow(String bar) throws Exception {
        SystemBars plugin = new SystemBars();
        Bridge bridge = mock(Bridge.class);
        AppCompatActivity activity = mock(AppCompatActivity.class);
        Window window = mock(Window.class);
        View decorView = mock(View.class);
        WindowInsetsControllerCompat controller = mock(WindowInsetsControllerCompat.class);

        when(bridge.getActivity()).thenReturn(activity);
        when(activity.getWindow()).thenReturn(window);
        when(window.getDecorView()).thenReturn(decorView);

        plugin.setBridge(bridge);

        try (MockedStatic<WindowCompat> windowCompat = mockStatic(WindowCompat.class)) {
            windowCompat.when(() -> WindowCompat.getInsetsController(window, decorView)).thenReturn(controller);

            Method setHidden = SystemBars.class.getDeclaredMethod("setHidden", boolean.class, String.class);
            setHidden.setAccessible(true);
            setHidden.invoke(plugin, false, bar);
        }

        return controller;
    }
}
