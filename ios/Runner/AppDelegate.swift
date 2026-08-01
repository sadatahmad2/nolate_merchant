import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle deep links for OAuth (Google Sign-In callback)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Pass the URL to Flutter so Supabase can handle the OAuth callback
    if let flutterViewController = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "supabase_auth_callback",
        binaryMessenger: flutterViewController.binaryMessenger
      )
      channel.invokeMethod("handleDeepLink", arguments: url.absoluteString)
    }
    // Also let the super handle it (for other plugins)
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
