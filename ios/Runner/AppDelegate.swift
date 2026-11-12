import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, AVAudioPlayerDelegate {
  private var player: AVAudioPlayer?
  private var loadedPart: Int?
  private var preview: FlutterMethodChannel?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BuukAudioPreview") else { return }
    let channel = FlutterMethodChannel(name: "buuk_store/preview", binaryMessenger: registrar.messenger())
    preview = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        switch call.method {
        case "play":
          guard let arguments = call.arguments as? [String: Any],
                let part = arguments["part"] as? Int,
                let rate = arguments["rate"] as? Double else {
            throw CocoaError(.fileReadCorruptFile)
          }
          if self.loadedPart != part {
            self.player?.stop()
            let asset = registrar.lookupKey(forAsset: "assets/audio/part-\(part).mp3")
            guard let url = Bundle.main.url(forResource: asset, withExtension: nil) else {
              throw CocoaError(.fileNoSuchFile)
            }
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.enableRate = true
            self.player = player
            self.loadedPart = part
          }
          self.player?.rate = Float(rate)
          self.player?.play()
        case "pause":
          self.player?.pause()
        case "stop":
          self.player?.stop()
          self.player = nil
          self.loadedPart = nil
        case "rate":
          if let rate = call.arguments as? Double { self.player?.rate = Float(rate) }
        default:
          result(FlutterMethodNotImplemented)
          return
        }
        result(nil)
      } catch {
        self.player = nil
        self.loadedPart = nil
        result(FlutterError(code: "preview_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    self.player = nil
    self.loadedPart = nil
    preview?.invokeMethod("complete", arguments: nil)
  }
}
