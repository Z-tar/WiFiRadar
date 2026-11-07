import SwiftUI
import CoreWLAN
import AppKit

// MARK: - Safari 像素级工具栏按钮样式规范 (Safari Pill & Square Button Styles)
public struct SafariToolbarPillButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.12) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
    }
}

public struct SafariToolbarSquareButtonStyle: ButtonStyle {
    var isActive: Bool = false
    public init(isActive: Bool = false) {
        self.isActive = isActive
    }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isActive ? Color.primary.opacity(0.10) : (configuration.isPressed ? Color.primary.opacity(0.12) : Color.primary.opacity(0.03)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isActive ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 0.5)
            )
    }
}

// MARK: - Safari 像素级 1:1 原生侧边栏药丸开关 (Safari Sidebar Toggle Pill)
public struct SafariSidebarToggleView: View {
    @ObservedObject var scanner = WiFiRadarScanner.shared

    public init() {}

    public var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                if scanner.columnVisibility == .detailOnly {
                    scanner.columnVisibility = .all
                } else {
                    scanner.columnVisibility = .detailOnly
                }
            }
        }) {
            HStack(spacing: 3) {
                Image(systemName: "sidebar.leading")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary.opacity(0.85))
                Image(systemName: "chevron.down")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.85))
            }
            .frame(width: 44, height: 26)
            .contentShape(RoundedRectangle(cornerRadius: 6.5, style: .continuous))
        }
        .buttonStyle(SafariToolbarPillButtonStyle())
        .help("展开/折叠侧边栏 (右键快速切换频段)")
        .contextMenu {
            Button(scanner.columnVisibility == .detailOnly ? "展开侧边栏" : "折叠侧边栏") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    if scanner.columnVisibility == .detailOnly {
                        scanner.columnVisibility = .all
                    } else {
                        scanner.columnVisibility = .detailOnly
                    }
                }
            }
            Divider()
            Button("全部网络") { scanner.applyFilter(.all) }
            Button("2.4 GHz 频段") { scanner.applyFilter(.band24) }
            Button("5.0 GHz 频段") { scanner.applyFilter(.band50) }
            Button("6.0 GHz 频段") { scanner.applyFilter(.band60) }
            Divider()
            Button("强信号优先 (>-65dBm)") { scanner.applyFilter(.strongSignal) }
            Button("Wi-Fi 6 / 7 极速") { scanner.applyFilter(.wifi6) }
        }
    }
}

// MARK: - 页面与菜单用户调整宽度持久化偏好键 (Width Persistence Preference Keys)
public struct SidebarWidthPreferenceKey: PreferenceKey {
    public static let defaultValue: CGFloat = 240
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct InspectorWidthPreferenceKey: PreferenceKey {
    public static let defaultValue: CGFloat = 340
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Safari 经典纯白大圆角胶囊搜索栏 (Safari Signature Pure White Capsule Search Field)
public struct SafariCenterCapsuleBar: View {
    @ObservedObject var scanner = WiFiRadarScanner.shared
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    private var capsuleBg: Color {
        colorScheme == .dark ? Color(nsColor: .controlBackgroundColor) : Color.white
    }

    private var capsuleBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var capsuleShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.04)
    }

    public var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(.secondary.opacity(0.65))

            TextField("搜寻热点名称、物理地址、信道或厂商...", text: $scanner.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))

            if !scanner.searchText.isEmpty {
                Button(action: { scanner.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(width: 520, height: 28)
        .background(
            Capsule()
                .fill(capsuleBg)
        )
        .overlay(
            Capsule()
                .stroke(capsuleBorder, lineWidth: 0.5)
        )
        .shadow(color: capsuleShadow, radius: 2.5, x: 0, y: 1)
        .frame(height: 28)
    }
}

// MARK: - Safari 风格右侧独立操作按钮组 (Safari Independent Action Icons)
public struct SafariRightActionGroup: View {
    @ObservedObject var scanner = WiFiRadarScanner.shared

    public init() {}

    public var body: some View {
        HStack(spacing: 6) {
            // 按钮 0: 暂停 / 恢复扫描 (停止/启动切换)
            Button(action: {
                if scanner.isViewActive {
                    scanner.isViewActive = false
                    scanner.stopAutoSweep()
                } else {
                    scanner.isViewActive = true
                    scanner.triggerImmediateScan()
                }
            }) {
                Image(systemName: scanner.isViewActive ? "pause.fill" : "play.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(scanner.isViewActive ? .orange : .green)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(SafariToolbarSquareButtonStyle())
            .help(scanner.isViewActive ? "暂停/停止扫描" : "恢复自动扫描")

            // 按钮 1: 扫描与自动刷新 (点击立即扫描，右键/长按弹出刷新频率)
            Button(action: {
                scanner.triggerImmediateScan()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary.opacity(0.85))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(SafariToolbarSquareButtonStyle())
            .help("立即扫描 (右键选择自动刷新频率)")
            .contextMenu {
                Button("立即扫描") { scanner.triggerImmediateScan() }
                Divider()
                Button("停止自动刷新") { scanner.setAutoRefreshInterval(0) }
                Button("每 3 秒刷新 (推荐)") { scanner.setAutoRefreshInterval(3) }
                Button("每 5 秒刷新") { scanner.setAutoRefreshInterval(5) }
                Button("每 10 秒刷新") { scanner.setAutoRefreshInterval(10) }
            }

            // 按钮 2: 导出分享菜单 (Safari 经典 分享按钮 [ ⎋ ])
            Menu {
                Button("导出为 CSV 表格...") {
                    RadarWindowManager.shared.exportToFile(type: "csv")
                }
                Button("导出为 JSON 报文...") {
                    RadarWindowManager.shared.exportToFile(type: "json")
                }
                Divider()
                Button("复制 CSV 到剪贴板") {
                    RadarToolbarCoordinator.shared.copyCSVAction()
                }
                Button("复制 JSON 到剪贴板") {
                    RadarToolbarCoordinator.shared.copyJSONAction()
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("导出与分享数据")

            // 按钮 3: 参数检查器抽屉开关 (Safari 经典 检查器/总览按钮 [ ◨ ])
            Button(action: {
                withAnimation(.easeInOut(duration: 0.22)) {
                    scanner.showDrawer.toggle()
                }
            }) {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(scanner.showDrawer ? .accentColor : .primary.opacity(0.85))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(SafariToolbarSquareButtonStyle(isActive: scanner.showDrawer))
            .help("显示/隐藏参数检查器")
        }
        .frame(height: 28)
    }
}

// MARK: - 官方原生 NSToolbar 桥接协调器 (Official Apple Native NSToolbar Architecture)
@MainActor
public class RadarToolbarCoordinator: NSObject, NSToolbarDelegate {
    public static let shared = RadarToolbarCoordinator()

    public let sidebarToggleId = NSToolbarItem.Identifier("SafariSidebarToggle")
    public let segId = NSToolbarItem.Identifier("RadarModeSegment")
    public let centerGroupId = NSToolbarItem.Identifier("SafariCenterGroup")
    public let rightGroupId = NSToolbarItem.Identifier("SafariRightGroup")

    public weak var segmentedControl: NSSegmentedControl?

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [sidebarToggleId, segId, .flexibleSpace, centerGroupId, rightGroupId]
    }

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [sidebarToggleId, segId, .flexibleSpace, centerGroupId, .flexibleSpace, rightGroupId]
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == sidebarToggleId {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            let hosting = NSHostingView(rootView: SafariSidebarToggleView())
            hosting.frame = NSRect(x: 0, y: 0, width: 44, height: 28)
            item.view = hosting
            item.label = "侧边栏"
            return item
        } else if itemIdentifier == segId {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            let seg = NSSegmentedControl(
                labels: ["频谱图", "数据列表", "混合分屏"],
                trackingMode: .selectOne,
                target: self,
                action: #selector(onSegmentChanged(_:))
            )
            seg.segmentStyle = .capsule
            seg.controlSize = .regular
            seg.selectedSegment = {
                switch WiFiRadarScanner.shared.viewMode {
                case .spectrum: return 0
                case .table: return 1
                case .split: return 2
                }
            }()
            self.segmentedControl = seg
            seg.frame = NSRect(x: 0, y: 0, width: 220, height: 28)
            item.view = seg
            item.label = "展示模式"
            return item
        } else if itemIdentifier == centerGroupId {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            let hosting = NSHostingView(rootView: SafariCenterCapsuleBar())
            hosting.frame = NSRect(x: 0, y: 0, width: 520, height: 28)
            item.view = hosting
            item.label = "全局搜索"
            return item
        } else if itemIdentifier == rightGroupId {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            let hosting = NSHostingView(rootView: SafariRightActionGroup())
            hosting.frame = NSRect(x: 0, y: 0, width: 132, height: 28)
            item.view = hosting
            item.label = "操作面板"
            return item
        }
        return nil
    }

    @objc private func onSegmentChanged(_ sender: NSSegmentedControl) {
        let modes: [RadarViewMode] = [.spectrum, .table, .split]
        guard sender.selectedSegment >= 0 && sender.selectedSegment < modes.count else { return }
        let targetMode = modes[sender.selectedSegment]
        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            WiFiRadarScanner.shared.viewMode = targetMode
        }
    }

    public func copyCSVAction() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(WiFiRadarScanner.shared.exportCSV(), forType: .string)
    }

    public func copyJSONAction() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(WiFiRadarScanner.shared.exportJSON(), forType: .string)
    }
}

// MARK: - 独立雷达窗口管理器 (Safari-Class macOS Window Manager)
@MainActor
public class RadarWindowManager: NSObject, NSWindowDelegate {
    public static let shared = RadarWindowManager()
    public private(set) var window: NSWindow?

    public func openWindow() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            WiFiRadarScanner.shared.isViewActive = true
            WiFiRadarScanner.shared.triggerImmediateScan()
            return
        }

        // 1. 读取用户记忆的窗口尺寸 (记忆页面调整后的宽度)
        let savedWidth = UserDefaults.standard.double(forKey: "WiFiRadarWindowWidth")
        let savedHeight = UserDefaults.standard.double(forKey: "WiFiRadarWindowHeight")
        let winW: CGFloat = savedWidth >= 800 ? CGFloat(savedWidth) : 1320
        let winH: CGFloat = savedHeight >= 500 ? CGFloat(savedHeight) : 840

        let newWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: winW, height: winH),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "WiFi Radar"
        newWindow.titleVisibility = .hidden
        newWindow.toolbarStyle = .unified
        newWindow.setFrameAutosaveName("WiFiRadarMainWindowFrame")

        let toolbar = NSToolbar(identifier: "SafariStyleRadarToolbar")
        toolbar.delegate = RadarToolbarCoordinator.shared
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        newWindow.toolbar = toolbar

        newWindow.minSize = NSSize(width: 860, height: 560)
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.contentView = NSHostingView(rootView: WiFiRadarView())

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        WiFiRadarScanner.shared.isViewActive = true
        WiFiRadarScanner.shared.triggerImmediateScan()
    }

    @objc public func windowDidResize(_ notification: Notification) {
        guard let w = window else { return }
        UserDefaults.standard.set(Double(w.frame.width), forKey: "WiFiRadarWindowWidth")
        UserDefaults.standard.set(Double(w.frame.height), forKey: "WiFiRadarWindowHeight")
    }

    @objc public func windowWillClose(_ notification: Notification) {
        WiFiRadarScanner.shared.isViewActive = false
    }

    public func exportToFile(type: String) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        let dateStr = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")

        if type == "csv" {
            panel.title = "导出 Wi-Fi 扫描结果 (CSV)"
            panel.nameFieldStringValue = "WiFi_Scan_\(dateStr).csv"
            panel.allowedContentTypes = [.commaSeparatedText]
            if panel.runModal() == .OK, let url = panel.url {
                try? WiFiRadarScanner.shared.exportCSV().write(to: url, atomically: true, encoding: .utf8)
            }
        } else {
            panel.title = "导出 Wi-Fi 扫描结果 (JSON)"
            panel.nameFieldStringValue = "WiFi_Telemetry_\(dateStr).json"
            panel.allowedContentTypes = [.json]
            if panel.runModal() == .OK, let url = panel.url {
                try? WiFiRadarScanner.shared.exportJSON().write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: - Apple Liquid Glass 官方规范质感修饰器
public struct AppleLiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 8
    var isProminent: Bool = false

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 1. Apple 系统原生动态模糊材质 (GPU 实时高斯模糊透射)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isProminent ? .ultraThickMaterial : .thinMaterial)

                    // 2. 液体高光折射微光层 (模拟顶部漫反射物理光泽)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isProminent ? 0.35 : 0.22),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // 3. 苹果玻璃微边缘倒角反射 (Specular Glass Rim)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.75),
                                Color.white.opacity(0.25),
                                Color.black.opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 2.5, x: 0, y: 1.5)
    }
}

public struct AppleLiquidGlassCapsuleModifier: ViewModifier {
    var isProminent: Bool = false

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Capsule()
                        .fill(isProminent ? .ultraThickMaterial : .thinMaterial)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isProminent ? 0.35 : 0.22),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.75),
                                Color.white.opacity(0.25),
                                Color.black.opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1.5)
    }
}

public extension View {
    func appleLiquidGlass(cornerRadius: CGFloat = 8, isProminent: Bool = false) -> some View {
        modifier(AppleLiquidGlassModifier(cornerRadius: cornerRadius, isProminent: isProminent))
    }

    func appleLiquidGlassCapsule(isProminent: Bool = false) -> some View {
        modifier(AppleLiquidGlassCapsuleModifier(isProminent: isProminent))
    }
}

// MARK: - 主视图 (Safari-Class macOS 27 UI Architecture)
public struct WiFiRadarView: View {
    @ObservedObject var scanner = WiFiRadarScanner.shared
    @Namespace private var sidebarAnimationNamespace

    public init() {}

    public var body: some View {
        NavigationSplitView(columnVisibility: $scanner.columnVisibility) {
            safariSidebar
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: SidebarWidthPreferenceKey.self, value: proxy.size.width)
                    }
                )
                .onPreferenceChange(SidebarWidthPreferenceKey.self) { newWidth in
                    if newWidth >= 160 && newWidth <= 420 && abs(newWidth - scanner.sidebarWidth) > 1 {
                        scanner.sidebarWidth = newWidth
                        UserDefaults.standard.set(Double(newWidth), forKey: "WiFiRadarSidebarWidth")
                    }
                }
                .navigationSplitViewColumnWidth(min: 180, ideal: scanner.sidebarWidth, max: 360)
        } detail: {
            HSplitView {
                mainStageArea
                    .frame(minWidth: 500)

                if scanner.showDrawer {
                    safariInspector
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: InspectorWidthPreferenceKey.self, value: proxy.size.width)
                            }
                        )
                        .onPreferenceChange(InspectorWidthPreferenceKey.self) { newWidth in
                            if newWidth >= 220 && newWidth <= 550 && abs(newWidth - scanner.inspectorWidth) > 1 {
                                scanner.inspectorWidth = newWidth
                                UserDefaults.standard.set(Double(newWidth), forKey: "WiFiRadarInspectorWidth")
                            }
                        }
                        .frame(minWidth: 260, idealWidth: scanner.inspectorWidth, maxWidth: 500)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: scanner.showDrawer)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
        }
        .onAppear {
            scanner.isViewActive = true
        }
        .onDisappear {
            scanner.isViewActive = false
        }
    }

    // MARK: - 1. Safari 风格侧边栏 (Floating Card Selection)
    private var safariSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // 顶部品牌区 (呼应 Safari 起始页风格)
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 24, height: 24)
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("无线频谱雷达")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                // 分组 1: 频段概览
                VStack(alignment: .leading, spacing: 4) {
                    Text("频段")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)

                    safariSidebarItem(title: "全部网络", icon: "wifi", count: scanner.networks.count, isSelected: scanner.activeFilter == .all) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            scanner.applyFilter(.all)
                        }
                    }
                    safariSidebarItem(title: "2.4 GHz 频段", icon: "wave.3.left", count: scanner.networks.filter { $0.band == .band24 }.count, isSelected: scanner.activeFilter == .band24) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            scanner.applyFilter(.band24)
                        }
                    }
                    safariSidebarItem(title: "5.0 GHz 频段", icon: "wave.3.right", count: scanner.networks.filter { $0.band == .band50 }.count, isSelected: scanner.activeFilter == .band50) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            scanner.applyFilter(.band50)
                        }
                    }
                    safariSidebarItem(title: "6.0 GHz (6E/7)", icon: "bolt.horizontal.wave.fill", count: scanner.networks.filter { $0.band == .band60 }.count, isSelected: scanner.activeFilter == .band60) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            scanner.applyFilter(.band60)
                        }
                    }
                }

                // 分组 2: 快捷分类
                VStack(alignment: .leading, spacing: 4) {
                    Text("智能分类")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)

                    safariSidebarItem(title: "当前已连接", icon: "checkmark.circle.fill", count: scanner.networks.filter { $0.isConnected }.count, isSelected: scanner.activeFilter == .connected) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            scanner.applyFilter(.connected)
                        }
                    }
                    safariSidebarItem(title: "Wi-Fi 6 / 7 极速", icon: "sparkle", count: scanner.networks.filter { $0.genName.contains("6") || $0.genName.contains("7") }.count, isSelected: scanner.activeFilter == .wifi6) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            scanner.applyFilter(.wifi6)
                        }
                    }
                    safariSidebarItem(title: "强信号 (>-65dBm)", icon: "antenna.radiowaves.left.and.right", count: scanner.networks.filter { $0.rssi > -65 }.count, isSelected: scanner.activeFilter == .strongSignal) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            scanner.applyFilter(.strongSignal)
                        }
                    }
                    safariSidebarItem(title: "路由器指纹", icon: "network", count: scanner.networks.filter { $0.vendor != "通用 802.11 路由" }.count, isSelected: scanner.activeFilter == .fingerprint) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            scanner.applyFilter(.fingerprint)
                        }
                    }
                }

                // 分组 3: 信道健康度
                VStack(alignment: .leading, spacing: 5) {
                    Text("信道健康评估")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)

                    let recs = scanner.recommendations(for: scanner.activeBand)
                    VStack(spacing: 3) {
                        ForEach(recs) { rec in
                            HStack {
                                Text("CH \(rec.channel)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                Spacer()
                                if rec.isCleanest {
                                    Text("★ 最优")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.green)
                                } else {
                                    Text("\(rec.ratingText) (\(rec.apCount))")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(6)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.horizontal, 10)
                }

                // 分组 4: 本机硬件网卡
                VStack(alignment: .leading, spacing: 4) {
                    Text("本机射频硬件")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)

                    VStack(spacing: 4) {
                        let cleanChip = scanner.hardwareInfo.cardType.replacingOccurrences(of: " (wifi (en0))", with: "").replacingOccurrences(of: "(wifi (en0))", with: "").trimmingCharacters(in: .whitespaces)
                        sidebarHardwareRow("芯片", cleanChip.isEmpty ? "Apple Silicon Wi-Fi" : cleanChip)
                        sidebarHardwareRow("国家", scanner.hardwareInfo.countryCode)
                        sidebarHardwareRow("MAC", scanner.hardwareInfo.localMac)
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.horizontal, 10)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 4)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // Safari 风格悬浮卡片条目 (参照 Safari 侧边栏「起始页面」纯白悬浮药丸卡片)
    private func safariSidebarItem(title: String, icon: String, count: Int?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)

                Spacer()

                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Group {
                    if isSelected {
                        Color.white
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                            )
                            .matchedGeometryEffect(id: "sidebar_active_pill", in: sidebarAnimationNamespace)
                    } else {
                        Color(nsColor: .controlBackgroundColor).opacity(0.001)
                    }
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    private func sidebarHardwareRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .lineLimit(1)
        }
    }

    private func modeIcon(for mode: RadarViewMode) -> String {
        switch mode {
        case .spectrum: return "waveform.path.ecg"
        case .table: return "tablecells"
        case .split: return "rectangle.split.2x1"
        }
    }

    private func modeTitle(for mode: RadarViewMode) -> String {
        switch mode {
        case .spectrum: return "频谱图"
        case .table: return "数据列表"
        case .split: return "混合分屏"
        }
    }

    // MARK: - 3. 主舞台区域 (Apple 原生连续空间形变一镜到底舞台，彻底消除 GeometryReader 抖动)
    private var mainStageArea: some View {
        VStack(spacing: 0) {
            // Safari 风格当前活跃连接卡片 (Active Network Hero 视觉恒定锚点)
            if let active = scanner.networks.first(where: { $0.isConnected }) ?? (scanner.currentConnection.ssid.isEmpty ? nil : nil) {
                safariActiveNetworkHero(active)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
            }

            VStack(spacing: 0) {
                // 板块 1: 120Hz 频谱分析仪 (自适应空间高度连续形变)
                if scanner.viewMode != .table {
                    VStack(spacing: 6) {
                        bandPickerToolbar
                        spectrumCanvasView
                    }
                    .padding(scanner.viewMode == .split ? 10 : 12)
                    .frame(maxHeight: scanner.viewMode == .spectrum ? .infinity : 280)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                }

                // 混合分屏模式下的精致微细分割条
                if scanner.viewMode == .split {
                    Divider()
                        .padding(.horizontal, 10)
                        .transition(.opacity)
                }

                // 板块 2: macOS 原生数据列表 (自适应空间高度连续形变)
                if scanner.viewMode != .spectrum {
                    nativeTableView
                        .frame(maxHeight: .infinity)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            )
                        )
                }
            }
            .clipped()
            .animation(.spring(response: 0.36, dampingFraction: 0.84), value: scanner.viewMode)
        }
    }

    // 仿 Safari 收藏夹卡片风格的当前连接 Hero
    private func safariActiveNetworkHero(_ net: WiFiNetworkItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "wifi")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(net.ssid)
                        .font(.system(size: 14, weight: .bold))
                    Text("ONLINE")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                Text("CH \(net.channel) (\(net.band.rawValue)) · \(net.bandwidthText) · \(net.bssid)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Text("\(net.rssi) dBm")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                Text("\(net.qualityPercent)%")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.06), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    // 频段切换原生分段控件
    private var bandPickerToolbar: some View {
        HStack {
            Picker("频段", selection: $scanner.activeBand) {
                ForEach(WiFiBand.allCases) { band in
                    let count = scanner.networks.filter { $0.band == band }.count
                    Text("\(band.rawValue) (\(count))").tag(band)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 280)

            Spacer()

            Text(scanner.activeBand.channelRangeText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 4. 120Hz ProMotion 频谱分析仪
    private var spectrumCanvasView: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            guard width > 100, height > 80 else { return }

            let padLeft: CGFloat = 36
            let padRight: CGFloat = 20
            let padTop: CGFloat = 20
            let padBottom: CGFloat = 24

            let plotW = width - padLeft - padRight
            let plotH = height - padTop - padBottom

            let band = scanner.activeBand
            let channels: [Int] = {
                switch band {
                case .band24: return Array(1...14)
                case .band50: return [36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 149, 153, 157, 161, 165]
                case .band60: return [1, 5, 9, 13, 17, 21, 25, 29, 33, 37, 41, 45, 49, 53, 57, 61, 65, 69, 73, 77, 81, 85, 89, 93]
                }
            }()

            func getX(for ch: Int) -> CGFloat {
                guard let idx = channels.firstIndex(of: ch) else {
                    let minCh = channels.first ?? 1
                    let maxCh = channels.last ?? 14
                    let ratio = CGFloat(ch - minCh) / CGFloat(max(1, maxCh - minCh))
                    return padLeft + plotW * max(0.0, min(1.0, ratio))
                }
                let step = plotW / CGFloat(max(1, channels.count - 1))
                return padLeft + CGFloat(idx) * step
            }

            // 1. 水平刻度线 (-30, -50, -70, -90 dBm)
            let rssiTicks = [-30, -50, -70, -90]
            for tick in rssiTicks {
                let ratio = CGFloat(tick - (-100)) / 80.0
                let y = padTop + plotH * (1.0 - ratio)

                var path = Path()
                path.move(to: CGPoint(x: padLeft, y: y))
                path.addLine(to: CGPoint(x: width - padRight, y: y))
                context.stroke(path, with: .color(Color.primary.opacity(0.1)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                let text = Text("\(tick) dBm")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                context.draw(text, at: CGPoint(x: padLeft - 6, y: y), anchor: .trailing)
            }

            // 2. 垂直信道网格线与标签
            for ch in channels {
                let x = getX(for: ch)
                var line = Path()
                line.move(to: CGPoint(x: x, y: padTop))
                line.addLine(to: CGPoint(x: x, y: height - padBottom))
                context.stroke(line, with: .color(Color.primary.opacity(0.06)), lineWidth: 1)

                let isCleanChannel = (ch == 1 || ch == 6 || ch == 11 || ch == 36 || ch == 149)
                let chText = Text("\(ch)")
                    .font(.system(size: 9, weight: isCleanChannel ? .bold : .regular, design: .monospaced))
                    .foregroundColor(isCleanChannel ? Color.accentColor : .secondary)
                context.draw(chText, at: CGPoint(x: x, y: height - padBottom + 12), anchor: .center)
            }

            // 3. 抛物线绘制
            let apPalette: [Color] = [.cyan, .blue, .purple, .orange, .pink, .green]
            let targetNets = scanner.filteredNetworks.filter { $0.band == band }
            let hasSelection = scanner.selectedNetwork != nil || scanner.hoveredNetworkId != nil

            for (idx, net) in targetNets.enumerated() {
                let clampedRssi = max(-100, min(-20, net.rssi))
                let ratio = CGFloat(clampedRssi - (-100)) / 80.0
                let peakY = padTop + plotH * (1.0 - ratio)
                let baseX = getX(for: net.channel)

                let spanChannels: CGFloat = {
                    switch net.bandwidthMHz {
                    case 40: return band == .band24 ? 6.0 : 4.0
                    case 80: return 8.0
                    case 160: return 16.0
                    default: return band == .band24 ? 4.0 : 2.0
                    }
                }()

                let stepX = plotW / CGFloat(max(1, channels.count - 1))
                let halfW = max(18.0, (spanChannels / 2.0) * stepX * 0.95)
                let x0 = max(padLeft, baseX - halfW)
                let x1 = min(width - padRight, baseX + halfW)
                let baseY = height - padBottom

                let baseColor = apPalette[idx % apPalette.count]
                let isFocused = (net.id == scanner.selectedNetwork?.id) || (net.id == scanner.hoveredNetworkId)

                var curve = Path()
                curve.move(to: CGPoint(x: x0, y: baseY))
                curve.addQuadCurve(to: CGPoint(x: x1, y: baseY), control: CGPoint(x: baseX, y: peakY))

                // 半透明填充
                var fillPath = curve
                fillPath.addLine(to: CGPoint(x: x1, y: baseY))
                fillPath.addLine(to: CGPoint(x: x0, y: baseY))
                fillPath.closeSubpath()

                let fillOpacity: Double = isFocused ? 0.35 : (hasSelection ? 0.08 : (net.isConnected ? 0.3 : 0.15))
                context.fill(fillPath, with: .color(baseColor.opacity(fillOpacity)))

                // 描边
                let strokeOpacity: Double = isFocused ? 1.0 : (hasSelection ? 0.3 : (net.isConnected ? 0.95 : 0.65))
                let strokeColor = isFocused ? Color.primary : baseColor.opacity(strokeOpacity)
                let lineWidth: CGFloat = isFocused ? 2.6 : (net.isConnected ? 2.2 : 1.4)
                context.stroke(curve, with: .color(strokeColor), lineWidth: lineWidth)

                // 顶点光点
                var peakDot = Path()
                peakDot.addEllipse(in: CGRect(x: baseX - 3, y: peakY - 3, width: 6, height: 6))
                context.fill(peakDot, with: .color(isFocused ? Color.primary : baseColor))

                // 标签
                if isFocused || net.isConnected || !hasSelection {
                    let prefix = net.isConnected ? "🟢 " : ""
                    let labelText = Text("\(prefix)\(net.ssid) (\(net.rssi)dBm)")
                        .font(.system(size: 9, weight: (net.isConnected || isFocused) ? .bold : .medium))
                        .foregroundColor(isFocused ? .primary : (net.isConnected ? .green : baseColor))

                    let labelY = max(padTop + 8, peakY - 9)
                    context.draw(labelText, at: CGPoint(x: baseX, y: labelY), anchor: .center)
                }
            }
        }
        .frame(minHeight: 220)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 5. 纯原生 macOS Table (NSTableView)
    private var nativeTableView: some View {
        Table(scanner.filteredNetworks.sorted(using: scanner.sortOrder), selection: $scanner.selectedNetworkId, sortOrder: $scanner.sortOrder) {
            // 列 1: 序号
            TableColumn("#") { net in
                let idx = (scanner.filteredNetworks.firstIndex(of: net) ?? 0) + 1
                Text("\(idx)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 30, ideal: 36, max: 46)

            // 列 2: SSID (热点名称)
            TableColumn("热点名称 (SSID)", value: \.ssid) { net in
                HStack(spacing: 6) {
                    if net.isConnected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    } else if net.isHidden {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "network")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Text(net.ssid)
                        .font(.system(size: 12, weight: net.isConnected ? .semibold : .regular))
                        .foregroundColor(net.isConnected ? .green : (net.isHidden ? .secondary : .primary))
                        .lineLimit(1)
                }
            }
            .width(min: 140, ideal: 190)

            // 列 3: BSSID (物理地址)
            TableColumn("物理地址 (BSSID)", value: \.bssid) { net in
                Text(net.bssid)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(net.isConnected ? .green : .secondary)
                    .lineLimit(1)
            }
            .width(min: 145, ideal: 180)

            // 列 4: 频段/信道
            TableColumn("信道", value: \.channel) { net in
                Text("CH \(net.channel) (\(net.band.rawValue))")
                    .font(.system(size: 11, design: .monospaced))
            }
            .width(min: 85, ideal: 105)

            // 列 5: 频率/频宽
            TableColumn("频宽/频率", value: \.bandwidthMHz) { net in
                Text("\(net.frequencyMHz)M / \(net.bandwidthText)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 100, ideal: 125)

            // 列 6: Wi-Fi 标准 (动态感知选中态，避免选区高亮时出现白底白字空胶囊)
            TableColumn("Wi-Fi 标准", value: \.genName) { net in
                let isSelected = scanner.selectedNetworkId == net.id
                Text(net.genName)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .foregroundColor(isSelected ? .white : .primary)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.22) : Color.primary.opacity(0.06))
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.white.opacity(0.4) : Color.black.opacity(0.08), lineWidth: 0.5)
                    )
            }
            .width(min: 75, ideal: 85)

            // 列 7: 信号强度 (RSSI) - Apple HIG 原生动态波束
            TableColumn("信号 (RSSI)", value: \.rssi) { net in
                HStack(spacing: 6) {
                    Image(systemName: "wifi", variableValue: max(0.15, Double(net.qualityPercent) / 100.0))
                        .font(.system(size: 12))
                        .foregroundColor(net.rssi > -65 ? .green : (net.rssi > -78 ? .primary : .secondary))

                    Text("\(net.rssi) dBm")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))

                    Text("\(net.qualityPercent)%")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .width(min: 125, ideal: 145)

            // 列 8: 底噪与信噪比
            TableColumn("底噪/SNR", value: \.snr) { net in
                Text("\(net.effectiveNoise) / \(net.snr)dB")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 80, ideal: 95)

            // 列 9: 安全认证与管理帧保护
            TableColumn("安全与管理帧", value: \.securitySummary) { net in
                HStack(spacing: 5) {
                    Image(systemName: net.securitySummary.contains("开放") ? "lock.open" : "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(net.securitySummary.contains("开放") ? .secondary : .accentColor)
                    let pmfBrief = net.pmfStatus.split(separator: " ").first ?? ""
                    let secText = pmfBrief.isEmpty ? net.securitySummary : "\(net.securitySummary) · \(pmfBrief)"
                    Text(secText)
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
            }
            .width(min: 130, ideal: 170)

            // 列 10: 路由器厂商指纹
            TableColumn("路由器指纹", value: \.vendor) { net in
                Text(net.vendor)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            .width(min: 110, ideal: 140)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .id(scanner.activeFilter)
    }

    // MARK: - 6. Safari 风格原生属性检查器 (Grouped Form Inspector)
    private var safariInspector: some View {
        let selected = scanner.selectedNetwork ?? scanner.filteredNetworks.first
        return VStack(spacing: 0) {
            HStack {
                Label("参数检查器", systemImage: "info.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        scanner.showDrawer = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.6))
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider().opacity(0.4)

            Form {
                if let net = selected {
                Section("接入点概览") {
                    LabeledContent("热点名称 (SSID)", value: net.ssid)
                    if net.isConnected {
                        LabeledContent("连接状态", value: "已连接 (Active)")
                    }
                    LabeledContent("物理地址 (BSSID)", value: net.bssid)
                    LabeledContent("信号强度 (RSSI)", value: "\(net.rssi) dBm (\(net.qualityPercent)%)")
                    LabeledContent("直线经验估算距离", value: String(format: "约 %.1f 米", net.estimatedDistanceMeters))
                }

                Section("射频与物理层 (PHY)") {
                    LabeledContent("物理信道", value: "CH \(net.channel) (\(net.band.rawValue))")
                    LabeledContent("中心物理频率", value: "\(net.frequencyMHz) MHz")
                    LabeledContent("实际频宽", value: net.bandwidthText)
                    LabeledContent("Wi-Fi 标准代数", value: "\(net.genName) (\(net.phyModeSummary))")
                    if let bssColor = net.bssColor {
                        LabeledContent("Wi-Fi 6 BSS 着色", value: "ID: \(bssColor)")
                    }
                    LabeledContent("环境底噪 / 信噪比", value: "\(net.effectiveNoise) dBm / \(net.snr) dB")
                    LabeledContent("信标周期 (Beacon)", value: "\(net.beaconInterval) TU (\(String(format: "%.1f", Double(net.beaconInterval) * 1.024)) ms)")
                }

                Section("安全架构与认证") {
                    LabeledContent("安全体系", value: net.securitySummary)
                    LabeledContent("密钥协商 (AKM)", value: net.akmSuitesText.isEmpty ? "公开未加密" : net.akmSuitesText)
                    LabeledContent("单播加密", value: net.pairwiseCiphersText.isEmpty ? "无" : net.pairwiseCiphersText)
                    LabeledContent("管理帧保护 (PMF)", value: net.pmfStatus)
                    LabeledContent("快速漫游 (802.11r)", value: net.fastRoaming11r ? "支持" : "未开启")
                    LabeledContent("BSS 转换 (802.11v)", value: net.bssTransition11v ? "支持" : "未开启")
                }

                Section("设备指纹与 WPS") {
                    LabeledContent("路由器厂商", value: net.vendor)
                    if !net.modelName.isEmpty {
                        LabeledContent("硬件型号", value: net.modelName)
                    }
                    LabeledContent("WPS 状态", value: net.wpsEnabled ? "开启 (\(net.wpsStatusText))" : "关闭")
                    if !net.countryCode.isEmpty {
                        LabeledContent("所属区域", value: "\(flagEmoji(for: net.countryCode)) \(net.countryCode)")
                    }
                }

                if net.qbssClients != nil || net.qbssUtilPercent != nil {
                    Section("空间负载与拥塞 (QBSS)") {
                        if let c = net.qbssClients {
                            LabeledContent("关联设备数", value: "\(c) 台")
                        }
                        if let u = net.qbssUtilPercent {
                            LabeledContent("信道实际占用率", value: String(format: "%.1f%%", u))
                        }
                    }
                }

                Section("报文导出与调试") {
                    Button(action: {
                        copyToClipboard(net.toJsonString())
                        scanner.copyFeedback = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            scanner.copyFeedback = false
                        }
                    }) {
                        HStack {
                            Image(systemName: scanner.copyFeedback ? "checkmark" : "doc.on.doc")
                            Text(scanner.copyFeedback ? "已复制 JSON" : "复制完整原始 JSON 报文")
                        }
                    }
                }
            } else {
                Text("请在左侧列表中选择一个热点以查看详细报文属性")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .formStyle(.grouped)
    }
    .background(Color(nsColor: .windowBackgroundColor))
}

    private func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var s = ""
        for v in countryCode.uppercased().unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return s.isEmpty ? "🌐" : s
    }

    // MARK: - 剪贴板与导出逻辑
    private func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    private func exportToFile(type: String) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        let dateStr = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")

        if type == "csv" {
            panel.title = "导出 Wi-Fi 扫描结果 (CSV)"
            panel.nameFieldStringValue = "WiFi_Scan_\(dateStr).csv"
            panel.allowedContentTypes = [.commaSeparatedText]
            if panel.runModal() == .OK, let url = panel.url {
                try? scanner.exportCSV().write(to: url, atomically: true, encoding: .utf8)
            }
        } else {
            panel.title = "导出 Wi-Fi 扫描结果 (JSON)"
            panel.nameFieldStringValue = "WiFi_Telemetry_\(dateStr).json"
            panel.allowedContentTypes = [.json]
            if panel.runModal() == .OK, let url = panel.url {
                try? scanner.exportJSON().write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}
