package com.getcapacitor;

import android.net.Uri;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import androidx.webkit.JavaScriptReplyProxy;
import androidx.webkit.WebViewCompat;
import androidx.webkit.WebViewFeature;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Set;
import java.util.function.Predicate;

/**
 * MessageHandler handles messages from the WebView, dispatching them
 * to plugins.
 */
public class MessageHandler {

    @FunctionalInterface
    public interface Interceptor {
        void intercept(JSObject object);
    }

    public static final class WebMessagePolicy {

        private final Set<String> originRules;
        private final Predicate<Uri> acceptsOrigin;

        public WebMessagePolicy(Set<String> originRules, Predicate<Uri> acceptsOrigin) {
            this.originRules = Collections.unmodifiableSet(new LinkedHashSet<>(Objects.requireNonNull(originRules)));
            this.acceptsOrigin = Objects.requireNonNull(acceptsOrigin);
        }

        public Set<String> originRules() {
            return originRules;
        }

        public Predicate<Uri> acceptsOrigin() {
            return acceptsOrigin;
        }
    }

    private Bridge bridge;
    private WebView webView;
    private JavaScriptReplyProxy javaScriptReplyProxy;
    private final boolean scopedWebMessages;

    public MessageHandler(Bridge bridge, WebView webView) {
        this(bridge, webView, null);
    }

    MessageHandler(Bridge bridge, WebView webView, WebMessagePolicy policy) {
        this.bridge = bridge;
        this.webView = webView;
        this.scopedWebMessages = policy != null;

        Set<String> originRules = scopedWebMessages ? policy.originRules() : bridge.getAllowedOriginRules();
        if (scopedWebMessages && originRules.isEmpty()) {
            return;
        }

        if (
            WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER) &&
            (scopedWebMessages || !bridge.getConfig().isUsingLegacyBridge())
        ) {
            WebViewCompat.WebMessageListener capListener = (view, message, sourceOrigin, isMainFrame, replyProxy) -> {
                if (!isMainFrame) {
                    Logger.warn("Plugin execution is allowed in Main Frame only");
                    return;
                }
                if (!scopedWebMessages || (sourceOrigin != null && policy.acceptsOrigin().test(sourceOrigin))) {
                    javaScriptReplyProxy = replyProxy;
                    postMessage(message.getData());
                }
            };
            try {
                WebViewCompat.addWebMessageListener(webView, "androidBridge", originRules, capListener);
                return;
            } catch (Exception ex) {
                if (scopedWebMessages) {
                    Logger.error("Unable to register scoped Android bridge", ex);
                    return;
                }
                webView.addJavascriptInterface(this, "androidBridge");
            }
        } else if (scopedWebMessages) {
            Logger.warn("Scoped Android bridge unavailable on this WebView");
        } else {
            webView.addJavascriptInterface(this, "androidBridge");
        }
    }

    /**
     * The main message handler that will be called from JavaScript
     * to send a message to the native bridge.
     * @param jsonStr
     */
    @JavascriptInterface
    @SuppressWarnings("unused")
    public void postMessage(String jsonStr) {
        try {
            JSObject postData = new JSObject(jsonStr);

            String type = postData.getString("type");

            if (type == null) type = "message";

            Interceptor interceptor = bridge.getCallInterceptor(type);
            if (interceptor != null) {
                interceptor.intercept(postData);
            }
        } catch (Exception ex) {
            Logger.error("Post message error:", ex);
        }
    }

    public void sendResponseMessage(PluginCall call, PluginResult successResult, PluginResult errorResult) {
        try {
            PluginResult data = new PluginResult();
            data.put("save", call.isKeptAlive());
            data.put("callbackId", call.getCallbackId());
            data.put("pluginId", call.getPluginId());
            data.put("methodName", call.getMethodName());

            boolean pluginResultInError = errorResult != null;
            if (pluginResultInError) {
                data.put("success", false);
                data.put("error", errorResult);
                Logger.debug("Sending plugin error: " + data.toString());
            } else {
                data.put("success", true);
                if (successResult != null) {
                    data.put("data", successResult);
                }
            }

            boolean isValidCallbackId = !call.getCallbackId().equals(PluginCall.CALLBACK_ID_DANGLING);
            if (isValidCallbackId) {
                if (!scopedWebMessages && bridge.getConfig().isUsingLegacyBridge()) {
                    legacySendResponseMessage(data);
                } else if (WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER) && javaScriptReplyProxy != null) {
                    javaScriptReplyProxy.postMessage(data.toString());
                } else if (!scopedWebMessages) {
                    legacySendResponseMessage(data);
                }
            } else {
                bridge.getApp().fireRestoredResult(data);
            }
        } catch (Exception ex) {
            Logger.error("sendResponseMessage: error: " + ex);
        }
        if (!call.isKeptAlive()) {
            call.release(bridge);
        }
    }

    private void legacySendResponseMessage(PluginResult data) {
        final String runScript = "window.Capacitor.fromNative(" + data.toString() + ")";
        final WebView webView = this.webView;
        webView.post(() -> webView.evaluateJavascript(runScript, null));
    }
}