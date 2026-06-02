import Cocoa
import FlutterMacOS
import MediaPlayer

class MainFlutterWindow: NSWindow {
  private var mediaController: MediaController?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Canal para teclas multimedia + "Now Playing" del sistema.
    let channel = FlutterMethodChannel(
      name: "sonora/media",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    mediaController = MediaController(channel: channel)

    super.awakeFromNib()
  }
}

/// Conecta las teclas multimedia (Play/Pause, Next, Previous, Stop) y el panel
/// "Now Playing" del sistema con el reproductor de Flutter.
class MediaController {
  private let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    setupRemoteCommands()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call)
      result(nil)
    }
  }

  // Comandos del centro de control / teclas multimedia -> Flutter.
  private func setupRemoteCommands() {
    let c = MPRemoteCommandCenter.shared()

    c.playCommand.isEnabled = true
    c.playCommand.addTarget { [weak self] _ in self?.send("play"); return .success }

    c.pauseCommand.isEnabled = true
    c.pauseCommand.addTarget { [weak self] _ in self?.send("pause"); return .success }

    c.togglePlayPauseCommand.isEnabled = true
    c.togglePlayPauseCommand.addTarget { [weak self] _ in self?.send("playpause"); return .success }

    c.nextTrackCommand.isEnabled = true
    c.nextTrackCommand.addTarget { [weak self] _ in self?.send("next"); return .success }

    c.previousTrackCommand.isEnabled = true
    c.previousTrackCommand.addTarget { [weak self] _ in self?.send("previous"); return .success }

    c.stopCommand.isEnabled = true
    c.stopCommand.addTarget { [weak self] _ in self?.send("stop"); return .success }
  }

  private func send(_ method: String) {
    DispatchQueue.main.async { self.channel.invokeMethod(method, arguments: nil) }
  }

  // Llamadas desde Flutter para actualizar la info de "Now Playing".
  private func handle(_ call: FlutterMethodCall) {
    let center = MPNowPlayingInfoCenter.default()
    switch call.method {
    case "updateNowPlaying":
      guard let a = call.arguments as? [String: Any] else { return }
      var info: [String: Any] = [:]
      info[MPMediaItemPropertyTitle] = a["title"] as? String ?? ""
      info[MPMediaItemPropertyArtist] = a["artist"] as? String ?? ""
      let durMs = (a["durationMs"] as? Int) ?? 0
      let posMs = (a["positionMs"] as? Int) ?? 0
      let playing = (a["isPlaying"] as? Bool) ?? false
      info[MPMediaItemPropertyPlaybackDuration] = Double(durMs) / 1000.0
      info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(posMs) / 1000.0
      info[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
      if let path = a["artworkPath"] as? String, !path.isEmpty,
         let img = NSImage(contentsOfFile: path) {
        info[MPMediaItemPropertyArtwork] =
          MPMediaItemArtwork(boundsSize: img.size) { _ in img }
      }
      center.nowPlayingInfo = info
      center.playbackState = playing ? .playing : .paused

    case "updatePlaybackState":
      guard let a = call.arguments as? [String: Any] else { return }
      let playing = (a["isPlaying"] as? Bool) ?? false
      let posMs = (a["positionMs"] as? Int) ?? 0
      var info = center.nowPlayingInfo ?? [:]
      info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(posMs) / 1000.0
      info[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
      center.nowPlayingInfo = info
      center.playbackState = playing ? .playing : .paused

    case "clear":
      center.nowPlayingInfo = nil
      center.playbackState = .stopped

    default:
      break
    }
  }
}
