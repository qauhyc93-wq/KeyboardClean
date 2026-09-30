import Cocoa
import ApplicationServices

final class Cleaner: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var titleLabel: NSTextField!
    var infoLabel: NSTextField!
    var action: NSButton!
    var tap: CFMachPort?
    var source: CFRunLoopSource?
    var locked = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 380), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "键盘清洁"
        window.center()
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        let view = window.contentView!
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        let symbol = NSTextField(labelWithString: "⌨")
        symbol.font = .systemFont(ofSize: 64)
        symbol.alignment = .center
        symbol.frame = NSRect(x: 30, y: 250, width: 480, height: 85)
        view.addSubview(symbol)
        titleLabel = NSTextField(labelWithString: "放心擦，按键由我挡住")
        titleLabel.font = .systemFont(ofSize: 25, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: 211, width: 500, height: 35)
        view.addSubview(titleLabel)
        infoLabel = NSTextField(wrappingLabelWithString: "开启后拦截普通键盘输入；电源键、Touch ID 不受控制。\n清洁完可用触控板或鼠标点击解锁。")
        infoLabel.alignment = .center
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.frame = NSRect(x: 30, y: 145, width: 480, height: 55)
        view.addSubview(infoLabel)
        action = NSButton(title: "开始清洁", target: self, action: #selector(toggle))
        action.bezelStyle = .rounded
        action.font = .systemFont(ofSize: 17, weight: .medium)
        action.frame = NSRect(x: 155, y: 88, width: 230, height: 44)
        view.addSubview(action)
        let privacy = NSTextField(labelWithString: "完全本地运行 · 不记录按键 · 不联网")
        privacy.alignment = .center
        privacy.textColor = .tertiaryLabelColor
        privacy.font = .systemFont(ofSize: 12)
        privacy.frame = NSRect(x: 20, y: 32, width: 500, height: 22)
        view.addSubview(privacy)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        // Register the app with macOS privacy settings on first launch.
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }

    @objc func toggle() {
        if locked { unlock(); return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            let alert = NSAlert()
            alert.messageText = "需要辅助功能权限来拦截按键"
            alert.informativeText = "在系统设置 → 隐私与安全性 → 辅助功能中，允许“键盘清洁”。如果列表没有它，可用 + 添加这个应用。授权后回到这里再点开始；必要时退出并重新打开应用。"
            alert.addButton(withTitle: "打开设置")
            alert.addButton(withTitle: "稍后")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            return
        }
        // NX_SYSDEFINED (14) carries media keys and has no named CGEventType case.
        let mask = [CGEventType.keyDown.rawValue, CGEventType.keyUp.rawValue, CGEventType.flagsChanged.rawValue, UInt32(14)].reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let newTap = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let cleaner = Unmanaged<Cleaner>.fromOpaque(context).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                DispatchQueue.main.async { cleaner.unlock(reason: "拦截已中断，键盘已解锁。") }
                return Unmanaged.passUnretained(event)
            }
            return cleaner.locked ? nil : Unmanaged.passUnretained(event)
        }, userInfo: context) else {
            infoLabel.stringValue = "无法建立键盘拦截。请检查辅助功能权限并重新打开应用。"
            return
        }
        guard let newSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0) else {
            CFMachPortInvalidate(newTap)
            return
        }
        tap = newTap
        source = newSource
        locked = true
        CFRunLoopAddSource(CFRunLoopGetMain(), newSource, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
        window.level = .normal
        titleLabel.stringValue = "键盘已锁定，可以清洁了"
        action.title = "清洁完成 · 点击解锁"
        infoLabel.stringValue = "清洁完可用触控板或鼠标点击解锁。"
        infoLabel.frame = NSRect(x: 30, y: 166, width: 480, height: 22)
        // Keep the cleaning window active after installing the global event tap.
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func unlock(reason: String = "键盘已恢复。可以再次开始清洁。") {
        locked = false
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
        guard window != nil else { return }
        window.level = .normal
        titleLabel.stringValue = "清洁完成，键盘已解锁"
        infoLabel.frame = NSRect(x: 30, y: 145, width: 480, height: 55)
        infoLabel.stringValue = reason
        action.title = "再次开始清洁"
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationWillTerminate(_ notification: Notification) { unlock() }
}

let app = NSApplication.shared
let cleaner = Cleaner()
app.delegate = cleaner
app.run()
