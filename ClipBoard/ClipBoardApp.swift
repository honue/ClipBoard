import Cocoa
import SwiftUI

// 定义一个数据模型存储剪贴板项目
struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
}

// SwiftUI视图用于显示剪贴板历史
struct ClipboardHistoryView: View {
    @Binding var clipboardItems: [ClipboardItem]
    @Binding var autoPasteEnabled: Bool
    @Binding var autoPressEnterEnabled: Bool
    
    var body: some View {
        VStack {
            Text("剪贴板历史")
                .font(.title)
                .padding()
            
            VStack(alignment: .leading) {
                Toggle("自动粘贴到编辑焦点", isOn: $autoPasteEnabled)
                Toggle("粘贴后自动按回车键", isOn: $autoPressEnterEnabled)
                    .disabled(!autoPasteEnabled) // 只有当自动粘贴启用时，回车键选项才可用
            }
            .padding(.horizontal)
            
            List {
                ForEach(clipboardItems) { item in
                    VStack(alignment: .leading) {
                        Text(item.content)
                            .lineLimit(2)
                        
                        Text(formatDate(item.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button("复制") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.content, forType: .string)
                        }
                        Button("粘贴") {
                            pasteToCurrentFocus(text: item.content)
                        }
                        Button("粘贴并回车") {
                            pasteToCurrentFocusWithEnter(text: item.content)
                        }
                    }
                }
            }
            
            HStack {
                Button("清除历史") {
                    clipboardItems.removeAll()
                }
                
                Spacer()
                
                Button("检查辅助功能权限") {
                    checkAccessibilityPermissions()
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if accessEnabled {
            let alert = NSAlert()
            alert.messageText = "辅助功能权限已启用"
            alert.informativeText = "自动粘贴功能可以正常工作。"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    private func pasteToCurrentFocus(text: String) {
        // 隐藏应用窗口以保持其他应用的焦点
        NSApplication.shared.windows.first?.orderOut(nil)
        
        // 直接模拟Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateCmdV()
        }
    }
    
    private func pasteToCurrentFocusWithEnter(text: String) {
        // 隐藏应用窗口以保持其他应用的焦点
        NSApplication.shared.windows.first?.orderOut(nil)
        
        // 延迟一点点再模拟Cmd+V，确保窗口已经隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateCmdV()
            
            // 延迟一点点再按回车键
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.simulateEnterKey()
            }
        }
    }
    
    private func simulateCmdV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // 创建按下Command键的事件
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        
        // 创建按下V键的事件
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        // 添加Command修饰键
        vDown?.flags = .maskCommand
        
        // 创建释放V键的事件
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        
        // 创建释放Command键的事件
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        // 发送事件
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
    
    private func simulateEnterKey() {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // 回车键的虚拟键代码是36
        let enterDown = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true)
        let enterUp = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false)
        
        // 发送事件
        enterDown?.post(tap: .cghidEventTap)
        enterUp?.post(tap: .cghidEventTap)
    }
}

// 简化的剪贴板历史视图
struct SimpleClipboardView: View {
    @Binding var clipboardItems: [ClipboardItem]
    @Binding var autoPasteEnabled: Bool
    @Binding var autoPressEnterEnabled: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(clipboardItems) { item in
                    HStack(alignment: .center, spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.content)
                                .lineLimit(1)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                            Text(item.timestamp.formatted(.dateTime.month().day().hour().minute().second()))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 40)
                        .background(Color(NSColor(white: 0.95, alpha: 0.95)))
                        .onTapGesture(count: 2) {
                            pasteToCurrentFocus(text: item.content)
                        }
                        .contextMenu {
                            Button("复制") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(item.content, forType: .string)
                            }
                            Button("粘贴") {
                                pasteToCurrentFocus(text: item.content)
                            }
                            Button("粘贴并回车") {
                                pasteToCurrentFocusWithEnter(text: item.content)
                            }
                        }
                    }
                    
                    if item.id != clipboardItems.last?.id {
                        Divider()
                            .padding(.horizontal, 8)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 300, height: 380)
        .background(Color(NSColor(white: 0.95, alpha: 0.95)))
    }
    
    private func pasteToCurrentFocus(text: String) {
        // 直接模拟Cmd+V
        simulateCmdV()
    }
    
    private func pasteToCurrentFocusWithEnter(text: String) {
        // 模拟Cmd+V
        simulateCmdV()
        
        // 延迟一点点再按回车键
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            simulateEnterKey()
        }
    }
    
    private func simulateCmdV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // 创建按下Command键的事件
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        
        // 创建按下V键的事件
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        // 添加Command修饰键
        vDown?.flags = .maskCommand
        
        // 创建释放V键的事件
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        
        // 创建释放Command键的事件
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        // 发送事件
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
    
    private func simulateEnterKey() {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // 回车键的虚拟键代码是36
        let enterDown = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true)
        let enterUp = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false)
        
        // 发送事件
        enterDown?.post(tap: .cghidEventTap)
        enterUp?.post(tap: .cghidEventTap)
    }
}

// 主应用
@main
struct ClipBoardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于剪贴板监控") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "剪贴板监控",
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0",
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "一个监控剪贴板并自动粘贴的应用"
                            )
                        ]
                    )
                }
            }
            
            CommandGroup(after: .newItem) {
                Button("显示悬浮窗 (⌘⇧V)") {
                    appDelegate.showFloatingPanel()
                }
                .keyboardShortcut("V", modifiers: [.command, .shift])
            }
        }
    }
}

// 内容视图
struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    
    var body: some View {
        ClipboardHistoryView(
            clipboardItems: $appDelegate.clipboardItems,
            autoPasteEnabled: $appDelegate.autoPasteEnabled,
            autoPressEnterEnabled: $appDelegate.autoPressEnterEnabled
        )
        .onAppear {
            // 应用启动时检查辅助功能权限
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
    }
}

// 应用代理
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    @Published var autoPasteEnabled: Bool = false
    @Published var autoPressEnterEnabled: Bool = false
    
    private var floatingPanel: NSPanel?
    private var hotKeyMonitor: Any?
    
    // 存储设置
    private let userDefaults = UserDefaults.standard
    private let autoPasteKey = "autoPasteEnabled"
    private let autoPressEnterKey = "autoPressEnterEnabled"
    
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 设置应用不在程序坞显示
        NSApp.setActivationPolicy(.accessory)
        
        // 加载设置
        autoPasteEnabled = userDefaults.bool(forKey: autoPasteKey)
        autoPressEnterEnabled = userDefaults.bool(forKey: autoPressEnterKey)
        
        // 初始化lastChangeCount
        lastChangeCount = NSPasteboard.general.changeCount
        
        // 设置一个定时器来检查剪贴板变化
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self,
                             selector: #selector(checkForPasteboardChanges),
                             userInfo: nil, repeats: true)
        
        // 注册全局快捷键
        registerHotKey()
        
        // 检查并设置登录项
        if !LoginItemManager.shared.isLoginItemEnabled() {
            _ = LoginItemManager.shared.enableLoginItem()
        }
    }
    
    private func registerHotKey() {
        // 移除之前的监控器
        if let monitor = hotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // 创建新的全局监控器
        hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 { // 9 是 V 键的 keyCode
                DispatchQueue.main.async {
                    if let panel = self?.floatingPanel, panel.isVisible {
                        self?.closeFloatingPanel()
                    } else {
                        self?.showFloatingPanel()
                    }
                }
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 保存设置
        userDefaults.set(autoPasteEnabled, forKey: autoPasteKey)
        userDefaults.set(autoPressEnterEnabled, forKey: autoPressEnterKey)
        timer?.invalidate()
        
        // 移除快捷键监控器
        if let monitor = hotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    @objc func checkForPasteboardChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            if let copiedString = pasteboard.string(forType: .string) {
                DispatchQueue.main.async {
                    // 添加到UI更新需要在主线程
                    print("剪贴板内容已更改为: \(copiedString)")
                    
                    // 创建新的剪贴板项目并添加到列表开头
                    let newItem = ClipboardItem(content: copiedString, timestamp: Date())
                    self.clipboardItems.insert(newItem, at: 0)
                    
                    // 限制历史记录数量，最多保留100条
                    if self.clipboardItems.count > 100 {
                        self.clipboardItems.removeLast()
                    }
                    
                    // 如果启用了自动粘贴，则执行粘贴操作
                    if self.autoPasteEnabled {
                        if self.autoPressEnterEnabled {
                            self.pasteToCurrentFocusWithEnter(text: copiedString)
                        } else {
                            self.pasteToCurrentFocus(text: copiedString)
                        }
                    }
                    
                    // 更新悬浮窗内容
                    self.updateFloatingPanelContent()
                }
            }
        }
    }
    
    private func updateFloatingPanelContent() {
        guard let panel = floatingPanel, panel.isVisible else { return }
        
        // 重新创建内容视图
        let contentView = SimpleClipboardView(
            clipboardItems: Binding(
                get: { self.clipboardItems },
                set: { self.clipboardItems = $0 }
            ),
            autoPasteEnabled: Binding(
                get: { self.autoPasteEnabled },
                set: { self.autoPasteEnabled = $0 }
            ),
            autoPressEnterEnabled: Binding(
                get: { self.autoPressEnterEnabled },
                set: { self.autoPressEnterEnabled = $0 }
            )
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 380)
        
        // 更新容器视图的内容
        if let containerView = panel.contentView {
            // 移除旧的 hostingView
            containerView.subviews.first?.removeFromSuperview()
            // 添加新的 hostingView
            containerView.addSubview(hostingView, positioned: .below, relativeTo: nil)
        }
    }
    
    private func pasteToCurrentFocus(text: String) {
        // 隐藏应用窗口以保持其他应用的焦点
        NSApplication.shared.windows.first?.orderOut(nil)
        
        // 直接模拟Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateCmdV()
        }
    }
    
    private func pasteToCurrentFocusWithEnter(text: String) {
        // 隐藏应用窗口以保持其他应用的焦点
        NSApplication.shared.windows.first?.orderOut(nil)
        
        // 延迟一点点再模拟Cmd+V，确保窗口已经隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateCmdV()
            
            // 延迟一点点再按回车键
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.simulateEnterKey()
            }
        }
    }
    
    private func simulateCmdV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // 创建按下Command键的事件
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        
        // 创建按下V键的事件
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        // 添加Command修饰键
        vDown?.flags = .maskCommand
        
        // 创建释放V键的事件
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        
        // 创建释放Command键的事件
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        // 发送事件
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
    
    private func simulateEnterKey() {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // 回车键的虚拟键代码是36
        let enterDown = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true)
        let enterUp = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false)
        
        // 发送事件
        enterDown?.post(tap: .cghidEventTap)
        enterUp?.post(tap: .cghidEventTap)
    }
    
    func showFloatingPanel() {
        if floatingPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.isMovableByWindowBackground = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            // 创建内容视图
            let contentView = SimpleClipboardView(
                clipboardItems: Binding(
                    get: { self.clipboardItems },
                    set: { self.clipboardItems = $0 }
                ),
                autoPasteEnabled: Binding(
                    get: { self.autoPasteEnabled },
                    set: { self.autoPasteEnabled = $0 }
                ),
                autoPressEnterEnabled: Binding(
                    get: { self.autoPressEnterEnabled },
                    set: { self.autoPressEnterEnabled = $0 }
                )
            )
            
            let hostingView = NSHostingView(rootView: contentView)
            hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 380)
            
            // 创建容器视图
            let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
            containerView.wantsLayer = true
            containerView.layer?.backgroundColor = NSColor(white: 0.95, alpha: 0.95).cgColor
            containerView.layer?.cornerRadius = 10
            
            // 添加拖拽区域
            let dragView = NSView(frame: NSRect(x: 0, y: 380, width: 300, height: 20))
            dragView.wantsLayer = true
            dragView.layer?.backgroundColor = NSColor(white: 0.9, alpha: 0.95).cgColor
            dragView.layer?.cornerRadius = 10
            
            // 添加关闭按钮
            let closeButton = NSButton(frame: NSRect(x: 5, y: 375, width: 20, height: 20))
            closeButton.bezelStyle = .circular
            closeButton.title = "×"
            closeButton.font = NSFont.systemFont(ofSize: 16, weight: .bold)
            closeButton.target = self
            closeButton.action = #selector(closeFloatingPanel)
            
            // 添加视图到容器
            containerView.addSubview(hostingView)
            containerView.addSubview(dragView)
            containerView.addSubview(closeButton)
            
            // 设置拖拽区域可以移动窗口
            let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            dragView.addGestureRecognizer(panGesture)
            
            panel.contentView = containerView
            floatingPanel = panel
        }
        
        if let panel = floatingPanel {
            // 将窗口位置设置在鼠标位置右下角
            let mouseLocation = NSEvent.mouseLocation
            let screenFrame = NSScreen.main?.frame ?? .zero
            let windowFrame = panel.frame
            let x = mouseLocation.x
            let y = mouseLocation.y - windowFrame.height // 从鼠标位置向下偏移窗口高度
            
            // 确保窗口不会超出屏幕边界
            let finalX = min(x, screenFrame.maxX - windowFrame.width)
            let finalY = max(y, screenFrame.minY)
            
            panel.setFrameOrigin(NSPoint(x: finalX, y: finalY))
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func closeFloatingPanel() {
        floatingPanel?.orderOut(nil)
    }
    
    @objc private func handlePanGesture(_ gesture: NSPanGestureRecognizer) {
        guard let window = floatingPanel else { return }
        
        let translation = gesture.translation(in: window.contentView)
        var newOrigin = window.frame.origin
        newOrigin.x += translation.x
        newOrigin.y -= translation.y // 注意：y坐标是反的
        
        window.setFrameOrigin(newOrigin)
        gesture.setTranslation(.zero, in: window.contentView)
    }
}
