import Flutter
import WebKit
import Network

enum FanboxLoginBridge {
  private static let resetKey = "fanbox-browser-reset"

  static func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "freepiv/fanbox_login", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "session":
          WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            let session = cookies.first {
              $0.name == "FANBOXSESSID" && $0.path == "/" &&
              ["fanbox.cc", ".fanbox.cc", "www.fanbox.cc", ".www.fanbox.cc"].contains($0.domain) &&
              ($0.expiresDate == nil || $0.expiresDate! > Date())
            }?.value
            result(session.flatMap { !$0.isEmpty && $0.utf8.count <= 8192 ? $0 : nil })
          }
        case "configure":
          let configure = { configureProxy(call.arguments as? String, result: result) }
          if UserDefaults.standard.bool(forKey: resetKey) { clear(completion: configure) }
          else { configure() }
        case "clear":
          UserDefaults.standard.set(true, forKey: resetKey)
          clear { result(nil) }
        default: result(FlutterMethodNotImplemented)
        }
      }
  }

  private static func related(_ domain: String) -> Bool {
    let host = domain.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
    return ["fanbox.cc", "pixiv.net"].contains { host == $0 || host.hasSuffix("." + $0) }
  }

  private static func clear(completion: @escaping () -> Void) {
    let store = WKWebsiteDataStore.default()
    store.httpCookieStore.getAllCookies { cookies in
      let group = DispatchGroup()
      for cookie in cookies where related(cookie.domain) {
        group.enter()
        store.httpCookieStore.delete(cookie) { group.leave() }
      }
      group.notify(queue: .main) {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        store.fetchDataRecords(ofTypes: types) { records in
          store.removeData(ofTypes: types, for: records.filter { related($0.displayName) }) {
            UserDefaults.standard.set(false, forKey: resetKey)
            completion()
          }
        }
      }
    }
  }

  private static func configureProxy(_ proxy: String?, result: @escaping FlutterResult) {
    guard #available(iOS 17.0, *) else {
      result(proxy == nil ? nil : FlutterError(code: "proxyUnsupported", message: "WebView proxy requires iOS 17", details: nil))
      return
    }
    guard let proxy else {
      WKWebsiteDataStore.default().proxyConfigurations = []
      result(nil)
      return
    }
    guard let url = URLComponents(string: proxy), let host = url.host,
      let scheme = url.scheme, ["http", "socks5"].contains(scheme),
      url.user == nil, url.password == nil,
      let port = NWEndpoint.Port(rawValue: UInt16(exactly: url.port ?? (scheme == "http" ? 80 : 1080)) ?? 0),
      port.rawValue != 0 else {
      result(FlutterError(code: "proxyUnsupported", message: "Unsupported WebView proxy", details: nil))
      return
    }
    let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: port)
    let config = scheme == "http" ? ProxyConfiguration(httpCONNECTProxy: endpoint) : ProxyConfiguration(socksv5Proxy: endpoint)
    WKWebsiteDataStore.default().proxyConfigurations = [config]
    result(nil)
  }
}
