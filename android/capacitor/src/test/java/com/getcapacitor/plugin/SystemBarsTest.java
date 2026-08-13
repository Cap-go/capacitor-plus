package com.getcapacitor.plugin;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.view.View;
import android.view.Window;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.Bridge;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import org.junit.Test;
import org.mockito.MockedStatic;

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
    public void hideWithEmptyBarHidesSystemBars() throws Exception {
        WindowInsetsControllerCompat controller = invokeSetHidden(new SystemBars(), true, "");

        verify(controller).hide(WindowInsetsCompat.Type.systemBars());
        verify(controller, never()).hide(WindowInsetsCompat.Type.statusBars());
        verify(controller, never()).hide(WindowInsetsCompat.Type.navigationBars());
    }

    @Test
    public void hideWithStatusBarHidesOnlyStatusBars() throws Exception {
        WindowInsetsControllerCompat controller = invokeSetHidden(new SystemBars(), true, "StatusBar");

        verify(controller).hide(WindowInsetsCompat.Type.statusBars());
        verify(controller, never()).hide(WindowInsetsCompat.Type.systemBars());
        verify(controller, never()).hide(WindowInsetsCompat.Type.navigationBars());
    }

    @Test
    public void togglingNavigationBarTracksNavBarVisible() throws Exception {
        SystemBars plugin = new SystemBars();

        invokeSetHidden(plugin, true, "NavigationBar");
        assertFalse(navBarVisible(plugin));

        invokeSetHidden(plugin, false, "NavigationBar");
        assertTrue(navBarVisible(plugin));
    }

    @Test
    public void togglingAllBarsTracksNavBarVisible() throws Exception {
        SystemBars plugin = new SystemBars();

        invokeSetHidden(plugin, true, "");
        assertFalse(navBarVisible(plugin));

        invokeSetHidden(plugin, false, "");
        assertTrue(navBarVisible(plugin));
    }

    @Test
    public void hidingOnlyStatusBarLeavesNavBarVisible() throws Exception {
        SystemBars plugin = new SystemBars();

        invokeSetHidden(plugin, true, "StatusBar");

        assertTrue(navBarVisible(plugin));
    }

    private boolean navBarVisible(SystemBars plugin) throws Exception {
        Field field = SystemBars.class.getDeclaredField("navBarVisible");
        field.setAccessible(true);
        return field.getBoolean(plugin);
    }

    private WindowInsetsControllerCompat invokeSetHidden(String bar) throws Exception {
        return invokeSetHidden(new SystemBars(), false, bar);
    }

    private WindowInsetsControllerCompat invokeSetHidden(SystemBars plugin, boolean hide, String bar) throws Exception {
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
            setHidden.invoke(plugin, hide, bar);
        }

        return controller;
    }
}
