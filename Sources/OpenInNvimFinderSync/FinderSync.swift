import AppKit
import FinderSync
import Foundation

@objc(FinderSync)
final class FinderSync: FIFinderSync {
    private let controller = FIFinderSyncController.default()

    override init() {
        super.init()
        controller.directoryURLs = monitoredDirectories()
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        let item = NSMenuItem(title: "在 nvim 中打开", action: #selector(openInNvim(_:)), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return menu
    }

    @objc private func openInNvim(_ sender: Any?) {
        let selectedURLs = controller.selectedItemURLs() ?? []
        let urls: [URL]

        if selectedURLs.isEmpty, let targetedURL = controller.targetedURL() {
            urls = [targetedURL]
        } else {
            urls = selectedURLs
        }

        guard !urls.isEmpty, let appURL = containingAppURL() else { return }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false

        NSWorkspace.shared.open(urls, withApplicationAt: appURL, configuration: configuration)
    }

    private func monitoredDirectories() -> Set<URL> {
        var urls: Set<URL> = [FileManager.default.homeDirectoryForCurrentUser]

        let volumesURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
        if FileManager.default.fileExists(atPath: volumesURL.path) {
            urls.insert(volumesURL)
        }

        return urls
    }

    private func containingAppURL() -> URL? {
        var url = Bundle.main.bundleURL

        while url.pathExtension != "app" {
            let parent = url.deletingLastPathComponent()
            if parent == url {
                return nil
            }
            url = parent
        }

        return url
    }
}
