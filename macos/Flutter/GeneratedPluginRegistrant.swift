//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import app_links
import device_info_plus
import file_picker
import package_info_plus
import pasteboard
import url_launcher_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AppLinksMacosPlugin.register(with: registry.registrar(forPlugin: "AppLinksMacosPlugin"))
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  PasteboardPlugin.register(with: registry.registrar(forPlugin: "PasteboardPlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
}
