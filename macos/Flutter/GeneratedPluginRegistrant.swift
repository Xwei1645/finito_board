//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import quill_native_bridge_macos
import screen_retriever
import url_launcher_macos
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  QuillNativeBridgePlugin.register(with: registry.registrar(forPlugin: "QuillNativeBridgePlugin"))
  ScreenRetrieverPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverPlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
