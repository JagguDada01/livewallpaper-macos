import AppKit
import AVFoundation
import Foundation

final class PlayerContainerView: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.addSublayer(playerLayer)
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}

final class LiveWallpaperController {
    private let videoURL: URL
    private var windows: [NSWindow] = []
    private var players: [AVQueuePlayer] = []
    private var loopers: [AVPlayerLooper] = []
    private var screenObserver: NSObjectProtocol?
    private var itemObservers: [NSObjectProtocol] = []

    init(videoURL: URL) {
        self.videoURL = videoURL
    }

    deinit {
        let center = NotificationCenter.default
        if let observer = screenObserver {
            center.removeObserver(observer)
        }
        for observer in itemObservers {
            center.removeObserver(observer)
        }
    }

    func start() {
        buildWindows()
        registerObservers()
    }

    private func registerObservers() {
        guard screenObserver == nil else {
            return
        }
        let center = NotificationCenter.default
        screenObserver = center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildWindows()
        }
    }

    private func rebuildWindows() {
        let center = NotificationCenter.default
        for observer in itemObservers {
            center.removeObserver(observer)
        }
        itemObservers.removeAll()

        for player in players {
            player.pause()
        }
        loopers.removeAll()
        players.removeAll()
        windows.removeAll()
        buildWindows()
    }

    private func buildWindows() {
        let screens = NSScreen.screens
        for screen in screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.hasShadow = false
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

            let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
            window.level = NSWindow.Level(rawValue: desktopLevel + 1)
            window.setFrame(screen.frame, display: true)

            let container = PlayerContainerView(frame: window.contentView?.bounds ?? .zero)
            container.autoresizingMask = [.width, .height]
            window.contentView = container

            let player = AVQueuePlayer()
            player.isMuted = true
            let item = AVPlayerItem(url: videoURL)
            let failedObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: item,
                queue: .main
            ) { note in
                let nsError = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError
                let detail = nsError?.localizedDescription ?? "unknown decoding error"
                fputs("Playback failed: \(detail)\n", stderr)
                NSApplication.shared.terminate(nil)
            }
            let looper = AVPlayerLooper(player: player, templateItem: item)
            container.playerLayer.player = player

            window.orderBack(nil)
            player.play()

            windows.append(window)
            players.append(player)
            loopers.append(looper)
            itemObservers.append(failedObserver)
        }
    }
}

private func parseVideoURL() -> URL {
    let args = Array(CommandLine.arguments.dropFirst())
    guard args.count == 2, args[0] == "--video" else {
        fputs("Usage: livewallpaper-daemon --video <path>\n", stderr)
        exit(1)
    }

    let expanded = NSString(string: args[1]).expandingTildeInPath
    let path = URL(fileURLWithPath: expanded).path
    guard FileManager.default.fileExists(atPath: path) else {
        fputs("Video file does not exist: \(path)\n", stderr)
        exit(1)
    }
    return URL(fileURLWithPath: path)
}

private func installSignalHandlers() {
    signal(SIGINT) { _ in
        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
        }
    }
    signal(SIGTERM) { _ in
        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
        }
    }
}

private func validateVideoIsPlayable(_ url: URL) {
    let asset = AVURLAsset(url: url)
    let semaphore = DispatchSemaphore(value: 0)
    var validationError: String?

    Task {
        do {
            let isPlayable = try await asset.load(.isPlayable)
            let hasProtectedContent = try await asset.load(.hasProtectedContent)
            let videoTracks = try await asset.loadTracks(withMediaType: .video)

            if !isPlayable {
                validationError = "Video is not playable by AVFoundation on this Mac."
            } else if hasProtectedContent {
                validationError = "Video has protected content and cannot be played."
            } else if videoTracks.isEmpty {
                validationError = "No video track found in file."
            }
        } catch {
            validationError = "Unsupported or unreadable video: \(error.localizedDescription)"
        }
        semaphore.signal()
    }

    let waitResult = semaphore.wait(timeout: .now() + 10)
    if waitResult == .timedOut {
        fputs("Timed out while validating video file.\n", stderr)
        exit(1)
    }
    if let validationError {
        fputs("\(validationError)\n", stderr)
        exit(1)
    }
}

let videoURL = parseVideoURL()
validateVideoIsPlayable(videoURL)
installSignalHandlers()

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let controller = LiveWallpaperController(videoURL: videoURL)
controller.start()
app.run()
