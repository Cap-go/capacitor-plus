package com.getcapacitor.plugin;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.res.Resources;
import android.util.DisplayMetrics;
import android.view.View;
import android.view.Window;
import android.webkit.WebView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.Bridge;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import org.junit.Test;
import org.mockito.ArgumentCaptor;

public class SystemBarsTest {

    @Test
    public void showWithEmptyBarShowsSystemBars() throws Exception {
        WindowInsetsControllerCompat controller = invokeSetHidden("");

        verify(controller).show(WindowInsetsCompat.Type.systemBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.statusBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.navigationBars());
    }

    @Test
    public void showWithStatusBarShowsOnlyStatusBars() throws Exception {
        WindowInsetsControllerCompat controller = invokeSetHidden("StatusBar");

        verify(controller).show(WindowInsetsCompat.Type.statusBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.systemBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.navigationBars());
    }

    @Test
    public void showWithNavigationBarShowsOnlyNavigationBars() throws Exception {
        WindowInsetsControllerCompat controller = invokeSetHidden("NavigationBar");

        verify(controller).show(WindowInsetsCompat.Type.navigationBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.systemBars());
        verify(controller, never()).show(WindowInsetsCompat.Type.statusBars());
    }

    @Test
    public void getSystemBarInsetsForCssUsesSystemBarsAndDisplayCutoutNotIme() {
        WindowInsetsCompat insets = mock(WindowInsetsCompat.class);
        Insets systemBarInsets = Insets.of(10, 20, 5, 15);
        when(insets.getInsets(anyInt())).thenReturn(systemBarInsets);

        int expectedMask = WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.displayCutout();
        int imeMask = WindowInsetsCompat.Type.ime();

        SystemBars plugin = new SystemBars();
        Insets result = plugin.getSystemBarInsetsForCss(insets);

        ArgumentCaptor<Integer> maskCaptor = ArgumentCaptor.forClass(Integer.class);
        verify(insets).getInsets(maskCaptor.capture());
        int mask = maskCaptor.getValue();
        assertEquals(expectedMask, mask);
        assertEquals(0, mask & imeMask);
        assertEquals(systemBarInsets, result);
    }

    @Test
    public void injectSafeAreaCSSUsesOriginalSystemBarInsets() throws Exception {
        SystemBars plugin = spy(new SystemBars());
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

        doReturn(Insets.of(10, 20, 5, 15)).when(plugin).getSystemBarInsetsForCss(any());

        Method injectSafeAreaCSS = SystemBars.class.getDeclaredMethod("injectSafeAreaCSS", WindowInsetsCompat.class);
        injectSafeAreaCSS.setAccessible(true);
        injectSafeAreaCSS.invoke(plugin, new Object[] { null });

        ArgumentCaptor<String> scriptCaptor = ArgumentCaptor.forClass(String.class);
        verify(webView).evaluateJavascript(scriptCaptor.capture(), any());
        String script = scriptCaptor.getValue();
        assertTrue(script.contains("\"--safe-area-inset-top\", \"10px\""));
        assertTrue(script.contains("\"--safe-area-inset-left\", \"5px\""));
        assertTrue(script.contains("\"--safe-area-inset-bottom\", \"7px\""));
        assertTrue(script.contains("\"--safe-area-inset-right\", \"2px\""));
    }

    @Test
    public void bottomInsetIsNavigationBarWhenKeyboardHidden() throws Exception {
        assertEquals(126, invokeGetBottomInset(126, 0, false));
    }

    @Test
    public void bottomInsetIsZeroWhenDockedKeyboardCoversNavigationBar() throws Exception {
        assertEquals(0, invokeGetBottomInset(126, 883, true));
    }

    @Test
    public void bottomInsetIsZeroWhenKeyboardInsetEqualsNavigationBar() throws Exception {
        assertEquals(0, invokeGetBottomInset(126, 126, true));
    }

    @Test
    public void bottomInsetIsUncoveredPartWhenKeyboardPartiallyCoversNavigationBar() throws Exception {
        assertEquals(76, invokeGetBottomInset(126, 50, true));
    }

    @Test
    public void bottomInsetIsNavigationBarWhenFloatingKeyboardCoversNothing() throws Exception {
        assertEquals(63, invokeGetBottomInset(63, 0, true));
    }

    @Test
    public void webViewMajorVersionIsParsedFromReleaseVersionName() {
        assertEquals(140, SystemBars.parseWebViewMajorVersion("140.0.7339.207"));
    }

    @Test
    public void webViewMajorVersionIsZeroForDeveloperBuild() {
        assertEquals(0, SystemBars.parseWebViewMajorVersion("Developer Build"));
    }

    @Test
    public void webViewMajorVersionIsZeroForEmptyVersionName() {
        assertEquals(0, SystemBars.parseWebViewMajorVersion(""));
    }

    @Test
    public void webViewMajorVersionIsZeroForDotOnlyVersionName() {
        assertEquals(0, SystemBars.parseWebViewMajorVersion("."));
    }

    @Test
    public void webViewMajorVersionIgnoresLeadingWhitespace() {
        assertEquals(140, SystemBars.parseWebViewMajorVersion(" 140.0.7339.207"));
    }

    @Test
    public void webViewMajorVersionIsZeroWhenNumberOverflows() {
        assertEquals(0, SystemBars.parseWebViewMajorVersion("99999999999.0"));
    }

    @Test
    public void webViewMajorVersionIsZeroForNullVersionName() {
        assertEquals(0, SystemBars.parseWebViewMajorVersion(null));
    }

    private int invokeGetBottomInset(int navigationBarBottom, int imeBottom, boolean keyboardVisible) throws Exception {
        Method getBottomInset = SystemBars.class.getDeclaredMethod("getBottomInset", Insets.class, Insets.class, boolean.class);
        getBottomInset.setAccessible(true);
        return (int) getBottomInset.invoke(
            new SystemBars(),
            Insets.of(0, 0, 0, navigationBarBottom),
            Insets.of(0, 0, 0, imeBottom),
            keyboardVisible
        );
    }

    private WindowInsetsControllerCompat invokeSetHidden(String bar) throws Exception {
        SystemBars plugin = spy(new SystemBars());
        Bridge bridge = mock(Bridge.class);
        AppCompatActivity activity = mock(AppCompatActivity.class);
        Window window = mock(Window.class);
        View decorView = mock(View.class);
        WindowInsetsControllerCompat controller = mock(WindowInsetsControllerCompat.class);

        when(bridge.getActivity()).thenReturn(activity);
        when(activity.getWindow()).thenReturn(window);
        when(window.getDecorView()).thenReturn(decorView);
        doReturn(controller).when(plugin).getInsetsController(window, decorView);

        plugin.setBridge(bridge);

        Method setHidden = SystemBars.class.getDeclaredMethod("setHidden", boolean.class, String.class);
        setHidden.setAccessible(true);
        setHidden.invoke(plugin, false, bar);

        return controller;
    }
}
