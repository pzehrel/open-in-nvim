import AppKit
import Foundation

struct AppConfig {
    var terminal: String = "auto"
    var nvimPath: String = "/opt/homebrew/bin/nvim"
    var server: String = ""
}

final class ConfigStore {
    static let shared = ConfigStore()

    let configURL: URL

    private init() {
        configURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".config/open-in-nvim/config")
    }

    func load() -> AppConfig {
        var config = AppConfig()

        guard let content = try? String(contentsOf: configURL, encoding: .utf8) else {
            if let nvim = findExecutable("nvim") {
                config.nvimPath = nvim
            }
            return config
        }

        for rawLine in content.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#"), let equalsIndex = line.firstIndex(of: "=") else {
                continue
            }

            let key = String(line[..<equalsIndex])
            var value = String(line[line.index(after: equalsIndex)...])
            value = value.trimmingCharacters(in: .whitespaces)
            value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

            switch key {
            case "OPEN_IN_NVIM_TERMINAL":
                config.terminal = value
            case "OPEN_IN_NVIM_NVIM":
                config.nvimPath = value
            case "OPEN_IN_NVIM_SERVER":
                config.server = value
            default:
                continue
            }
        }

        return config
    }

    func save(_ config: AppConfig) throws {
        try FileManager.default.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let lines = [
            "# 由“在 nvim 中打开”设置界面生成",
            "OPEN_IN_NVIM_TERMINAL=\(shellQuote(config.terminal))",
            "OPEN_IN_NVIM_NVIM=\(shellQuote(config.nvimPath))",
            config.server.isEmpty ? nil : "OPEN_IN_NVIM_SERVER=\(shellQuote(config.server))"
        ].compactMap { $0 }

        try (lines.joined(separator: "\n") + "\n").write(to: configURL, atomically: true, encoding: .utf8)
    }

    private func findExecutable(_ name: String) -> String? {
        let paths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
            "/bin/\(name)"
        ]

        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

final class OpenInNvimRunner {
    private let scriptPath: String

    init() {
        if let resourcePath = Bundle.main.resourcePath {
            self.scriptPath = (resourcePath as NSString).appendingPathComponent("open-in-nvim.sh")
        } else {
            self.scriptPath = "./open-in-nvim.sh"
        }
    }

    func open(_ urls: [URL], completion: ((String?) -> Void)? = nil) {
        guard !urls.isEmpty else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [scriptPath] + urls.map { $0.path }

        let errorPipe = Pipe()
        process.standardError = errorPipe

        process.terminationHandler = { process in
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            DispatchQueue.main.async {
                if process.terminationStatus == 0 {
                    completion?(nil)
                } else {
                    completion?(errorText?.isEmpty == false ? errorText : "打开失败，脚本没有返回错误信息。")
                }
            }
        }

        do {
            try process.run()
        } catch {
            completion?(error.localizedDescription)
        }
    }
}

final class SettingsWindowController: NSWindowController {
    private let terminalPopup = NSPopUpButton()
    private let customTerminalField = NSTextField()
    private let nvimPathField = NSTextField()
    private let serverField = NSTextField()
    private let statusLabel = NSTextField(labelWithString: "")
    private let configStore = ConfigStore.shared
    private let runner: OpenInNvimRunner

    private let terminalOptions: [(title: String, value: String)] = [
        ("自动选择", "auto"),
        ("Ghostty", "ghostty"),
        ("iTerm2", "iterm"),
        ("Terminal.app", "terminal"),
        ("自定义 App 名称", "custom")
    ]

    init(runner: OpenInNvimRunner) {
        self.runner = runner

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 350),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "在 nvim 中打开"
        window.center()

        super.init(window: window)
        buildUI()
        loadConfig()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        let titleLabel = NSTextField(labelWithString: "打开方式设置")
        titleLabel.font = .boldSystemFont(ofSize: 20)

        terminalPopup.addItems(withTitles: terminalOptions.map(\.title))
        terminalPopup.target = self
        terminalPopup.action = #selector(terminalChanged)

        customTerminalField.placeholderString = "例如 WezTerm、Alacritty"
        nvimPathField.placeholderString = "/opt/homebrew/bin/nvim"
        serverField.placeholderString = "可选，例如 /tmp/my-nvim.sock"

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byWordWrapping

        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveConfig))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        let testButton = NSButton(title: "测试打开个人目录", target: self, action: #selector(testOpenHome))
        testButton.bezelStyle = .rounded

        let buttonStack = NSStackView(views: [testButton, saveButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .centerY
        buttonStack.distribution = .gravityAreas

        let form = NSGridView(views: [
            [label("终端"), terminalPopup],
            [label("自定义终端"), customTerminalField],
            [label("nvim 路径"), nvimPathField],
            [label("固定 server"), serverField]
        ])
        form.rowSpacing = 12
        form.columnSpacing = 12
        form.column(at: 0).xPlacement = .trailing
        form.column(at: 1).width = 360

        let stack = NSStackView(views: [titleLabel, form, statusLabel, buttonStack])
        stack.orientation = .vertical
        stack.spacing = 18
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
            statusLabel.widthAnchor.constraint(equalTo: form.widthAnchor),
            buttonStack.widthAnchor.constraint(equalTo: form.widthAnchor)
        ])
    }

    private func label(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.textColor = .secondaryLabelColor
        return field
    }

    private func loadConfig() {
        let config = configStore.load()
        let knownIndex = terminalOptions.firstIndex { $0.value == config.terminal && $0.value != "custom" }

        if let knownIndex {
            terminalPopup.selectItem(at: knownIndex)
            customTerminalField.stringValue = ""
        } else {
            terminalPopup.selectItem(withTitle: "自定义 App 名称")
            customTerminalField.stringValue = config.terminal
        }

        nvimPathField.stringValue = config.nvimPath
        serverField.stringValue = config.server
        terminalChanged()
        statusLabel.stringValue = "配置文件：\(configStore.configURL.path)"
    }

    @objc private func terminalChanged() {
        let isCustom = selectedTerminalValue() == "custom"
        customTerminalField.isEnabled = isCustom
        customTerminalField.alphaValue = isCustom ? 1 : 0.45
    }

    @objc private func saveConfig() {
        do {
            try configStore.save(currentConfig())
            statusLabel.stringValue = "已保存：\(configStore.configURL.path)"
        } catch {
            showError("保存失败", error.localizedDescription)
        }
    }

    @objc private func testOpenHome() {
        do {
            try configStore.save(currentConfig())
            statusLabel.stringValue = "正在测试打开个人目录..."
            runner.open([FileManager.default.homeDirectoryForCurrentUser]) { [weak self] error in
                if let error {
                    self?.showError("测试失败", error)
                } else {
                    self?.statusLabel.stringValue = "测试命令已发送。"
                }
            }
        } catch {
            showError("保存失败", error.localizedDescription)
        }
    }

    private func currentConfig() -> AppConfig {
        let selected = selectedTerminalValue()
        let terminal = selected == "custom"
            ? customTerminalField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            : selected

        return AppConfig(
            terminal: terminal.isEmpty ? "auto" : terminal,
            nvimPath: nvimPathField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            server: serverField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func selectedTerminalValue() -> String {
        let index = terminalPopup.indexOfSelectedItem
        guard terminalOptions.indices.contains(index) else { return "auto" }
        return terminalOptions[index].value
    }

    private func showError(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
        statusLabel.stringValue = message
    }
}

final class ServiceProvider: NSObject {
    private let runner: OpenInNvimRunner
    private let didStartOpening: () -> Void

    init(runner: OpenInNvimRunner, didStartOpening: @escaping () -> Void) {
        self.runner = runner
        self.didStartOpening = didStartOpening
    }

    @objc func openInNvim(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = Self.urls(from: pasteboard)

        if urls.isEmpty {
            error.pointee = "没有从 Finder 收到文件或文件夹路径。"
            return
        }

        didStartOpening()
        runner.open(urls) { error in
            if let error {
                let alert = NSAlert()
                alert.messageText = "打开失败"
                alert.informativeText = error
                alert.alertStyle = .warning
                alert.runModal()
            }
            NSApp.terminate(nil)
        }
    }

    private static func urls(from pasteboard: NSPasteboard) -> [URL] {
        var urls: [URL] = []

        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            urls.append(contentsOf: fileURLs)
        }

        if urls.isEmpty, let filenames = pasteboard.propertyList(forType: .fileURL) as? [String] {
            urls.append(contentsOf: filenames.compactMap(URL.init(string:)))
        }

        if urls.isEmpty, let filenames = pasteboard.propertyList(forType: .init("NSFilenamesPboardType")) as? [String] {
            urls.append(contentsOf: filenames.map { URL(fileURLWithPath: $0) })
        }

        return Array(Set(urls)).sorted { $0.path < $1.path }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let runner = OpenInNvimRunner()
    private var serviceProvider: ServiceProvider?
    private var settingsWindowController: SettingsWindowController?
    private var didHandleExternalOpen = false
    private var didShowSettings = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let provider = ServiceProvider(runner: runner) { [weak self] in
            self?.didHandleExternalOpen = true
        }
        serviceProvider = provider
        NSApp.servicesProvider = provider
        NSUpdateDynamicServices()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        didHandleExternalOpen = true
        runner.open(urls) { error in
            if let error {
                let alert = NSAlert()
                alert.messageText = "打开失败"
                alert.informativeText = error
                alert.alertStyle = .warning
                alert.runModal()
            }
            application.terminate(nil)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self, !self.didHandleExternalOpen, !self.didShowSettings else { return }
            self.showSettings()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showSettings()
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func showSettings() {
        didShowSettings = true

        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(runner: runner)
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
