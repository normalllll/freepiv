package io.github.normalllll.freepiv

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.webkit.CookieManager
import android.webkit.WebStorage
import androidx.webkit.ProxyConfig
import androidx.webkit.ProxyController
import androidx.webkit.WebViewFeature
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

/** Native reads include HttpOnly; only the fixed FANBOX session is returned. */
object FanboxLoginBridge {
    private val hosts = listOf("fanbox.cc", "www.fanbox.cc", "api.fanbox.cc", "pixiv.net", "www.pixiv.net", "accounts.pixiv.net")
    private val main = Handler(Looper.getMainLooper())
    private val executor = Executor { main.post(it) }

    fun attach(context: Context, messenger: BinaryMessenger) {
        val preferences = context.getSharedPreferences("fanbox-login", Context.MODE_PRIVATE)
        MethodChannel(messenger, "freepiv/fanbox_login").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "session" -> {
                        val header = CookieManager.getInstance().getCookie("https://www.fanbox.cc/").orEmpty()
                        val session = header.split(';').firstOrNull { it.trim().startsWith("FANBOXSESSID=") }
                            ?.trim()?.substringAfter('=')?.takeIf { it.isNotEmpty() && it.length <= 8192 }
                        result.success(session)
                    }
                    "configure" -> {
                        val configure = { configureProxy(call.arguments as? String, result) }
                        if (preferences.getBoolean("reset", false)) {
                            clear { success ->
                                if (success) {
                                    preferences.edit().putBoolean("reset", false).commit()
                                    configure()
                                } else result.error("cleanupFailed", "Browser cleanup failed", null)
                            }
                        } else configure()
                    }
                    "clear" -> {
                        preferences.edit().putBoolean("reset", true).commit()
                        clear { success ->
                            if (success) {
                                preferences.edit().putBoolean("reset", false).commit()
                                result.success(null)
                            } else result.error("cleanupFailed", "Browser cleanup failed", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) {
                result.error(if (call.method == "clear") "cleanupFailed" else "unavailable", "FANBOX browser operation failed", null)
            }
        }
    }

    private fun configureProxy(proxy: String?, result: MethodChannel.Result) {
        if (!WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE)) {
            if (proxy == null) result.success(null)
            else result.error("proxyUnsupported", "WebView proxy override unavailable", null)
            return
        }
        if (proxy == null) {
            ProxyController.getInstance().clearProxyOverride(executor) { result.success(null) }
            return
        }
        val uri = Uri.parse(proxy)
        if (uri.scheme !in listOf("http", "socks5") || uri.host.isNullOrEmpty() || uri.userInfo != null) {
            result.error("proxyUnsupported", "Unsupported WebView proxy", null)
            return
        }
        try {
            val config = ProxyConfig.Builder().addProxyRule(proxy).build()
            ProxyController.getInstance().setProxyOverride(config, executor) { result.success(null) }
        } catch (_: IllegalArgumentException) {
            result.error("proxyUnsupported", "Unsupported WebView proxy", null)
        }
    }

    private fun clear(done: (Boolean) -> Unit) {
        val manager = CookieManager.getInstance()
        // Android cannot enumerate cookie metadata. Expire the authentication
        // cookies at known auth roots, without clearing other WebView accounts.
        val mutations = mutableListOf<Pair<String, String>>()
        for (host in hosts) {
            val url = "https://$host/"
            val names = manager.getCookie(url).orEmpty().split(';').mapNotNull {
                it.trim().substringBefore('=', "").takeIf { name -> name.isNotEmpty() }
            }.toSet() + "FANBOXSESSID"
            for (name in names) {
                val root = if (host.endsWith("fanbox.cc")) "fanbox.cc" else "pixiv.net"
                for (domain in setOf("", "; Domain=$host", "; Domain=.$root", "; Domain=.$host")) {
                    mutations += url to "$name=; Path=/; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Secure; HttpOnly$domain"
                }
            }
            WebStorage.getInstance().deleteOrigin(url.removeSuffix("/"))
        }
        var remaining = mutations.size
        if (remaining == 0) { done(true); return }
        for ((url, cookie) in mutations) {
            manager.setCookie(url, cookie) {
                remaining--
                if (remaining == 0) {
                    manager.flush()
                    val clean = hosts.all { host ->
                        manager.getCookie("https://$host/").orEmpty().split(';').none {
                            val name = it.trim().substringBefore('=')
                            name in setOf("FANBOXSESSID", "PHPSESSID") && it.substringAfter('=', "").isNotEmpty()
                        }
                    }
                    done(clean)
                }
            }
        }
    }
}
