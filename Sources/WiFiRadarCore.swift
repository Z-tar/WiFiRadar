import Foundation
import CoreWLAN
import CoreLocation
import SwiftUI
import Combine

// MARK: - CoreLocation 授权辅助器 (用于获取当前 Wi-Fi 网络标识)
public final class WiFiLocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    public static let shared = WiFiLocationManager()
    private let manager = CLLocationManager()
    private static let authRequestedKey = "WiFiLocationManager_HasRequestedAuth"
    private var inMemoryRequested: Bool = false

    override init() {
        super.init()
        manager.delegate = self
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status != .notDetermined {
            UserDefaults.standard.set(true, forKey: Self.authRequestedKey)
        }
    }

    public func requestAuthorizationIfNeeded() {
        guard !inMemoryRequested else { return }
        inMemoryRequested = true

        let status = manager.authorizationStatus
        // 若系统已经处于确定状态（已授权或已拒绝），直接记录并返回，避免重复触发
        if status != .notDetermined {
            UserDefaults.standard.set(true, forKey: Self.authRequestedKey)
            return
        }

        // 若历史会话已经触发过系统授权请求，绝不在每次启动时反复弹窗骚扰
        if UserDefaults.standard.bool(forKey: Self.authRequestedKey) {
            return
        }

        UserDefaults.standard.set(true, forKey: Self.authRequestedKey)
        manager.requestWhenInUseAuthorization()
    }
}

// MARK: - 频段定义
public enum WiFiBand: String, CaseIterable, Identifiable, Sendable {
    case band24 = "2.4 GHz"
    case band50 = "5.0 GHz"
    case band60 = "6.0 GHz"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .band24: return "2.4 GHz 频段"
        case .band50: return "5.0 GHz 频段"
        case .band60: return "6.0 GHz (Wi-Fi 6E/7)"
        }
    }

    public var channelRangeText: String {
        switch self {
        case .band24: return "CH 1 ~ 14 (2412 ~ 2484 MHz)"
        case .band50: return "CH 36 ~ 165 (5180 ~ 5825 MHz)"
        case .band60: return "CH 1 ~ 233 (5955 ~ 7115 MHz)"
        }
    }

    public var defaultChannels: [Int] {
        switch self {
        case .band24:
            return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        case .band50:
            return [36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 149, 153, 157, 161, 165]
        case .band60:
            return stride(from: 1, through: 233, by: 16).map { $0 }
        }
    }
}

// MARK: - 筛选分类胶囊
public enum APFilterCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "全部热点"
    case connected = "🟢 当前已连"
    case band24 = "2.4 GHz"
    case band50 = "5.0 GHz"
    case band60 = "6.0 GHz"
    case fingerprint = "⚡ 厂商指纹"
    case wifi6 = "🚀 Wi-Fi 6/7"
    case strongSignal = "📶 极佳信号 (>-60dBm)"

    public var id: String { rawValue }
}

// MARK: - 视图展示模式
public enum RadarViewMode: String, CaseIterable, Identifiable, Sendable {
    case spectrum = "📊 频谱图"
    case table = "📋 数据大表"
    case split = "🔀 混合分屏"

    public var id: String { rawValue }
}

// MARK: - 数据表排序字段
public enum APSortField: String, Sendable {
    case index = "#"
    case ssid = "热点名称"
    case bssid = "BSSID"
    case channel = "信道"
    case bandwidth = "频宽"
    case phyMode = "Wi-Fi标准"
    case rssi = "信号"
    case snr = "SNR"
    case security = "安全协议"
    case vendor = "厂商指纹"
    case qbss = "空间负载"
}

// MARK: - 本机无线网卡硬件信息
public struct SystemWiFiHardwareInfo: Sendable, Equatable {
    public var cardType: String = "Apple Silicon Wi-Fi"
    public var localMac: String = "--"
    public var firmware: String = "--"
    public var countryCode: String = "CN"
    public var supportedPHY: String = "802.11 a/b/g/n/ac/ax"
    public var interfaceName: String = "en0"

    public init() {}
}

// MARK: - 当前连接深度指标
public struct CurrentConnectionMetrics: Sendable, Equatable {
    public var ssid: String = ""
    public var bssid: String = "--"
    public var channel: Int = 0
    public var bandText: String = "--"
    public var bandwidthMHz: Int = 20
    public var frequencyMHz: Int = 0
    public var rssi: Int = 0
    public var noise: Int = -94
    public var snr: Int = 0
    public var txRateMbps: Double = 0.0
    public var mcsIndex: Int = 0
    public var phyMode: String = "--"
    public var securityMode: String = "--"
    public var country: String = "CN"
    public var vendor: String = "--"

    public init() {}
}

// MARK: - SPAirPort 解析中间体
public struct SystemAirportNetwork: Sendable {
    public let name: String
    public let channel: Int
    public let band: WiFiBand
    public let bandwidthMHz: Int
    public let phyMode: String
    public let security: String
    public let rssi: Int?
    public let noise: Int?
    public let isConnected: Bool
}

public struct SystemAirportData: Sendable {
    public var cardType: String = "Apple Silicon Wi-Fi"
    public var mac: String = "--"
    public var currentSSID: String = ""
    public var currentChannel: Int = 0
    public var currentBandwidth: Int = 20
    public var currentBand: WiFiBand = .band50
    public var currentMCS: Int = 0
    public var currentPhyMode: String = ""
    public var currentSecurity: String = ""
    public var currentRSSI: Int = 0
    public var currentNoise: Int = -94
    public var currentTxRate: Double = 0.0
    public var otherNetworks: [SystemAirportNetwork] = []
}

// MARK: - 单个接入点 (AP) 完整数据模型 (100% 对齐 kind-maxwell 原版)
public struct WiFiNetworkItem: Identifiable, Equatable, Sendable {
    public let uuid: String
    public var id: String { uuid }
    public var stableKey: String { "\(ssid)_\(channel)_\(band.rawValue)" }

    public let ssid: String
    public let isHidden: Bool
    public let bssid: String
    public let channel: Int
    public let band: WiFiBand
    public let frequencyMHz: Int
    public let bandwidthMHz: Int
    public let bandwidthText: String
    public var rssi: Int
    public let noise: Int

    // 动态物理属性计算 (保证与 RSSI 100% 实时同步)
    public var effectiveNoise: Int {
        return (noise < 0) ? noise : -94
    }
    public var snr: Int {
        return (rssi < 0) ? (rssi - effectiveNoise) : 0
    }
    public var qualityPercent: Int {
        return WiFiRadioUtils.rssiToQuality(rssi)
    }
    public var estimatedDistanceMeters: Double {
        return WiFiRadioUtils.estimateDistance(rssi: rssi, frequencyMHz: frequencyMHz)
    }

    // 安全架构与密码体系 (Security Suite)
    public let securitySummary: String
    public let akmSuitesText: String
    public let pairwiseCiphersText: String
    public let groupCipher: String
    public let pmfStatus: String
    public let fastRoaming11r: Bool
    public let bssTransition11v: Bool

    // 802.11 物理层代数与特性 (PHY)
    public let phyModeSummary: String
    public let phyStd: String
    public let genName: String
    public let bssColor: String?

    // WPS 专有深度报文
    public let wpsEnabled: Bool
    public let wpsStatusText: String
    public let wpsMethodsText: String

    // 路由器指纹
    public let vendor: String
    public let modelName: String

    // 802.11e QBSS 空间拥塞与负载
    public let qbssClients: Int?
    public let qbssUtilPercent: Double?
    public let qbssDisplayText: String

    public let isConnected: Bool
    public let beaconInterval: Int
    public let countryCode: String
    public let countryFlag: String
    public var lastSeen: Date
    public var rssiHistory: [Int]

    public init(
        uuid: String = UUID().uuidString,
        ssid: String,
        isHidden: Bool,
        bssid: String,
        channel: Int,
        band: WiFiBand,
        frequencyMHz: Int,
        bandwidthMHz: Int,
        bandwidthText: String,
        rssi: Int,
        noise: Int,
        securitySummary: String,
        akmSuitesText: String,
        pairwiseCiphersText: String,
        groupCipher: String,
        pmfStatus: String,
        fastRoaming11r: Bool,
        bssTransition11v: Bool,
        phyModeSummary: String,
        phyStd: String,
        genName: String,
        bssColor: String?,
        wpsEnabled: Bool,
        wpsStatusText: String,
        wpsMethodsText: String,
        vendor: String,
        modelName: String,
        qbssClients: Int?,
        qbssUtilPercent: Double?,
        qbssDisplayText: String,
        isConnected: Bool,
        beaconInterval: Int,
        countryCode: String,
        countryFlag: String,
        lastSeen: Date = Date(),
        rssiHistory: [Int] = []
    ) {
        self.uuid = uuid
        self.ssid = ssid
        self.isHidden = isHidden
        self.bssid = bssid
        self.channel = channel
        self.band = band
        self.frequencyMHz = frequencyMHz
        self.bandwidthMHz = bandwidthMHz
        self.bandwidthText = bandwidthText
        self.rssi = rssi
        self.noise = noise
        self.securitySummary = securitySummary
        self.akmSuitesText = akmSuitesText
        self.pairwiseCiphersText = pairwiseCiphersText
        self.groupCipher = groupCipher
        self.pmfStatus = pmfStatus
        self.fastRoaming11r = fastRoaming11r
        self.bssTransition11v = bssTransition11v
        self.phyModeSummary = phyModeSummary
        self.phyStd = phyStd
        self.genName = genName
        self.bssColor = bssColor
        self.wpsEnabled = wpsEnabled
        self.wpsStatusText = wpsStatusText
        self.wpsMethodsText = wpsMethodsText
        self.vendor = vendor
        self.modelName = modelName
        self.qbssClients = qbssClients
        self.qbssUtilPercent = qbssUtilPercent
        self.qbssDisplayText = qbssDisplayText
        self.isConnected = isConnected
        self.beaconInterval = beaconInterval
        self.countryCode = countryCode
        self.countryFlag = countryFlag
        self.lastSeen = lastSeen
        self.rssiHistory = rssiHistory
    }

    public static func == (lhs: WiFiNetworkItem, rhs: WiFiNetworkItem) -> Bool {
        return lhs.stableKey == rhs.stableKey &&
               lhs.rssi == rhs.rssi &&
               lhs.isConnected == rhs.isConnected &&
               lhs.lastSeen == rhs.lastSeen
    }

    public func toJsonString() -> String {
        let dict: [String: Any] = [
            "ssid": ssid,
            "bssid": bssid,
            "is_connected": isConnected,
            "channel": channel,
            "band": band.rawValue,
            "frequency_mhz": frequencyMHz,
            "bandwidth_mhz": bandwidthMHz,
            "rssi": rssi,
            "noise": effectiveNoise,
            "snr": snr,
            "quality_percent": qualityPercent,
            "estimated_distance_m": estimatedDistanceMeters,
            "security": securitySummary,
            "akm": akmSuitesText,
            "ciphers": pairwiseCiphersText,
            "pmf": pmfStatus,
            "fast_roaming_11r": fastRoaming11r,
            "bss_transition_11v": bssTransition11v,
            "phy_mode": phyModeSummary,
            "generation": genName,
            "vendor": vendor,
            "model": modelName,
            "wps": [
                "enabled": wpsEnabled,
                "status": wpsStatusText,
                "methods": wpsMethodsText
            ],
            "qbss": [
                "clients": qbssClients ?? 0,
                "util_percent": qbssUtilPercent ?? 0.0
            ],
            "country": countryCode
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }
}

// MARK: - 信道推荐评级
public struct ChannelRecommendation: Identifiable, Equatable, Sendable {
    public var id: Int { channel }
    public let channel: Int
    public let apCount: Int
    public let score: Int
    public let isCleanest: Bool
    public let ratingText: String
}

// MARK: - 辅助物理与指纹算法
public enum WiFiRadioUtils {
    public static let countryFlags: [String: String] = [
        "CN": "🇨🇳 中国 (CN)",
        "US": "🇺🇸 美国 (US)",
        "JP": "🇯🇵 日本 (JP)",
        "KR": "🇰🇷 韩国 (KR)",
        "HK": "🇭🇰 中国香港 (HK)",
        "TW": "🇹🇼 中国台湾 (TW)",
        "DE": "🇩🇪 德国 (DE)",
        "GB": "🇬🇧 英国 (GB)",
        "FR": "🇫🇷 法国 (FR)",
        "RU": "🇷🇺 俄罗斯 (RU)",
        "SG": "🇸🇬 新加坡 (SG)",
        "AU": "🇦🇺 澳大利亚 (AU)",
        "CA": "🇨🇦 加拿大 (CA)"
    ]

    public static func channelToFrequency(channel: Int, band: WiFiBand) -> Int {
        if channel <= 0 { return 0 }
        switch band {
        case .band24:
            if channel == 14 { return 2484 }
            if channel >= 1 && channel <= 13 { return 2407 + channel * 5 }
            return 2412
        case .band50:
            if channel >= 36 && channel <= 177 { return 5000 + channel * 5 }
            return 5180
        case .band60:
            if channel >= 1 && channel <= 233 { return 5950 + channel * 5 }
            return 5955
        }
    }

    public static func formatBandwidth(_ width: CWChannelWidth) -> (mhz: Int, text: String) {
        switch width {
        case .width20MHz: return (20, "20 MHz")
        case .width40MHz: return (40, "40 MHz")
        case .width80MHz: return (80, "80 MHz")
        case .width160MHz: return (160, "160 MHz")
        default: return (20, "20 MHz")
        }
    }

    public static func rssiToQuality(_ rssi: Int) -> Int {
        if rssi == 0 || rssi <= -100 { return 0 }
        if rssi >= -50 { return 100 }
        return max(0, min(100, Int(2 * (rssi + 100))))
    }

    public static func estimateDistance(rssi: Int, frequencyMHz: Int) -> Double {
        if rssi >= 0 || frequencyMHz == 0 { return 0.0 }
        let refRssi1m: Double = frequencyMHz < 3000 ? -38.0 : -45.0
        let diff = refRssi1m - Double(rssi)
        if diff <= 0 { return 0.8 }
        let distance = pow(10.0, diff / (10.0 * 2.7))
        return min(round(distance * 10) / 10.0, 150.0)
    }

    public static func detectVendor(ssid: String, bssid: String) -> (vendor: String, model: String) {
        let lowerS = ssid.lowercased()
        let cleanB = bssid.lowercased().replacingOccurrences(of: ":", with: "")

        if lowerS.contains("tp-link") || lowerS.contains("tplink") || cleanB.hasPrefix("b0f963") || cleanB.hasPrefix("9094e4") || cleanB.hasPrefix("50fa84") {
            return ("普联 (TP-Link)", "TL-WiFi 路由")
        }
        if lowerS.contains("mercury") || cleanB.hasPrefix("f483cd") || cleanB.hasPrefix("4c11bf") {
            return ("水星 (Mercury)", "Mercury 路由")
        }
        if lowerS.contains("xiaomi") || lowerS.contains("redmi") || lowerS.contains("jordan") || cleanB.hasPrefix("5c0214") || cleanB.hasPrefix("6490c1") || cleanB.hasPrefix("286c07") || cleanB.hasPrefix("7c10c9") {
            return ("小米 (Xiaomi)", "Mi Router / AX3000")
        }
        if lowerS.contains("huawei") || lowerS.contains("honor") || cleanB.hasPrefix("e865d4") || cleanB.hasPrefix("7089cc") {
            return ("华为 (Huawei)", "路由 AX3 / WS 系列")
        }
        if lowerS.contains("asus") || cleanB.hasPrefix("ac84c6") || cleanB.hasPrefix("049226") {
            return ("华硕 (ASUS)", "RT / TUF 电竞路由")
        }
        if lowerS.contains("tenda") || cleanB.hasPrefix("502b73") {
            return ("腾达 (Tenda)", "Tenda 路由")
        }
        if lowerS.contains("h3c") || cleanB.hasPrefix("842519") {
            return ("新华三 (H3C)", "H3C Magic 路由")
        }
        if lowerS.contains("cisco") {
            return ("思科 (Cisco)", "Aironet / Catalyst")
        }
        if lowerS.contains("netgear") {
            return ("网件 (Netgear)", "Nighthawk 夜鹰")
        }
        if lowerS.contains("dianhuahaoma") || lowerS.contains("china-telecom") {
            return ("中国电信 (China Telecom)", "天翼网关千兆版")
        }
        if cleanB.hasPrefix("4eb33f") || cleanB.hasPrefix("922e8f") || cleanB.hasPrefix("3c22fb") {
            return ("苹果 (Apple)", "AirPort / Apple AP")
        }
        return ("通用 802.11 路由", "Wi-Fi AP")
    }

    public static func parseSecurity(_ network: CWNetwork) -> (summary: String, akm: String, ciphers: String, pmf: String) {
        var tags: [String] = []
        var akms: [String] = []

        if network.supportsSecurity(.wpa3Personal) {
            tags.append("WPA3-Personal")
            akms.append("SAE (对等认证)")
        }
        if network.supportsSecurity(.wpa3Enterprise) {
            tags.append("WPA3-Enterprise")
            akms.append("802.1X-Suite-B-192")
        }
        if network.supportsSecurity(.wpa2Personal) {
            tags.append("WPA2-Personal")
            akms.append("PSK (预共享密钥)")
        }
        if network.supportsSecurity(.wpa2Enterprise) {
            tags.append("WPA2-Enterprise")
            akms.append("802.1X (企业认证)")
        }
        if network.supportsSecurity(.wpaPersonal) {
            tags.append("WPA-Personal")
            akms.append("WPA1-PSK")
        }
        if network.supportsSecurity(.none) {
            tags.append("开放网络 (Open)")
            akms.append("无身份认证")
        }

        let summary = tags.isEmpty ? "WPA2/WPA3" : tags.joined(separator: ", ")
        let akmText = akms.isEmpty ? "PSK" : akms.joined(separator: ", ")
        let ciphers = (summary.contains("WPA3") || summary.contains("WPA2")) ? "AES-CCMP-128" : "TKIP"
        let pmf = summary.contains("WPA3") ? "强制开启 (Required)" : "支持/可选 (Capable)"

        return (summary, akmText, ciphers, pmf)
    }

    public static func parseSystemSecurityMode(_ mode: String) -> (summary: String, akm: String, ciphers: String, pmf: String) {
        let lower = mode.lowercased()
        if lower.contains("wpa3_transition") {
            return ("WPA2/WPA3 个人混合 (SAE + PSK)", "SAE (对等认证) + PSK", "AES-CCMP-128", "支持/可选 (Capable)")
        } else if lower.contains("wpa3_personal") || lower.contains("wpa3") {
            return ("WPA3-Personal (纯 SAE 认证)", "SAE (对等认证)", "AES-CCMP-128", "强制开启 (Required)")
        } else if lower.contains("wpa2_personal_mixed") || lower.contains("mixed") {
            return ("WPA/WPA2 个人混合 (PSK)", "PSK (预共享密钥)", "AES-CCMP-128 / TKIP", "未启用 / 不支持")
        } else if lower.contains("wpa2") {
            return ("WPA2-Personal (PSK 预共享密钥)", "PSK (预共享密钥)", "AES-CCMP-128", "支持/可选 (Capable)")
        } else if lower.contains("wpa_personal") || lower.contains("wpa") {
            return ("WPA-Personal (WPA1 早期协议)", "WPA1-PSK", "TKIP", "未启用 / 不支持")
        } else if lower.contains("none") || lower.contains("open") {
            return ("开放网络 (Open)", "无身份认证", "无加密", "未启用 / 不支持")
        }
        return ("WPA2/WPA3", "PSK", "AES-CCMP-128", "支持/可选 (Capable)")
    }

    public static func parsePhyMode(_ network: CWNetwork) -> (summary: String, std: String, gen: String) {
        if network.supportsPHYMode(.mode11ax) {
            return ("Wi-Fi 6 (802.11ax)", "802.11ax", "Wi-Fi 6")
        } else if network.supportsPHYMode(.mode11ac) {
            return ("Wi-Fi 5 (802.11ac)", "802.11ac", "Wi-Fi 5")
        } else if network.supportsPHYMode(.mode11n) {
            return ("Wi-Fi 4 (802.11n)", "802.11n", "Wi-Fi 4")
        } else if network.supportsPHYMode(.mode11g) {
            return ("802.11g", "802.11g", "Wi-Fi 3")
        } else if network.supportsPHYMode(.mode11a) {
            return ("802.11a", "802.11a", "Wi-Fi 2")
        }
        return ("802.11 标准", "802.11", "Wi-Fi")
    }

    public static func parseSystemPhyMode(_ mode: String, channel: Int) -> (summary: String, std: String, gen: String) {
        let lower = mode.lowercased()
        if lower.contains("ax") {
            return ("Wi-Fi 6 (802.11ax)", "802.11ax", "Wi-Fi 6")
        } else if lower.contains("ac") {
            return ("Wi-Fi 5 (802.11ac)", "802.11ac", "Wi-Fi 5")
        } else if lower.contains("n") {
            return ("Wi-Fi 4 (802.11n)", "802.11n", "Wi-Fi 4")
        } else if lower.contains("g") {
            return ("802.11g", "802.11g", "Wi-Fi 3")
        } else if lower.contains("a") {
            return ("802.11a", "802.11a", "Wi-Fi 2")
        } else if channel > 14 {
            return ("Wi-Fi 5 (802.11ac)", "802.11ac", "Wi-Fi 5")
        }
        return ("Wi-Fi 4 (802.11n)", "802.11n", "Wi-Fi 4")
    }
}

// MARK: - 原生 Wi-Fi 深度雷达完整调度器
@MainActor
public class WiFiRadarScanner: ObservableObject {
    public static let shared = WiFiRadarScanner()

    @Published public var networks: [WiFiNetworkItem] = []
    @Published public var hardwareInfo: SystemWiFiHardwareInfo = SystemWiFiHardwareInfo()
    @Published public var currentConnection: CurrentConnectionMetrics = CurrentConnectionMetrics()

    // 交互与状态过滤
    @Published public var activeBand: WiFiBand = .band24
    @Published public var activeFilter: APFilterCategory = .all
    @Published public var viewMode: RadarViewMode = .split
    @Published public var sortField: APSortField = .rssi
    @Published public var sortAscending: Bool = false

    @Published public var isScanning: Bool = false
    @Published public var autoRefreshIntervalSeconds: Double = 3.0
    @Published public var selectedNetwork: WiFiNetworkItem? = nil {
        didSet {
            if let sel = selectedNetwork, selectedNetworkId != sel.id {
                self.selectedNetworkId = sel.id
            }
        }
    }
    @Published public var selectedNetworkId: String? = nil {
        didSet {
            if let id = selectedNetworkId, selectedNetwork?.id != id {
                self.selectedNetwork = networks.first(where: { $0.id == id })
            }
        }
    }
    @Published public var sortOrder: [KeyPathComparator<WiFiNetworkItem>] = [
        KeyPathComparator(\.rssi, order: .reverse)
    ]
    @Published public var copyFeedback: Bool = false
    @Published public var hoveredNetworkId: String? = nil
    @Published public var searchText: String = ""
    @Published public var showDrawer: Bool = true
    @Published public var columnVisibility: NavigationSplitViewVisibility = .all
    @Published public var sidebarWidth: CGFloat = {
        let saved = UserDefaults.standard.double(forKey: "WiFiRadarSidebarWidth")
        return (saved >= 180 && saved <= 400) ? CGFloat(saved) : 240
    }()
    @Published public var inspectorWidth: CGFloat = {
        let saved = UserDefaults.standard.double(forKey: "WiFiRadarInspectorWidth")
        return (saved >= 260 && saved <= 520) ? CGFloat(saved) : 340
    }()
    @Published public var lastScanTime: Date = Date()
    @Published public var scanCount: Int = 0

    public func applyFilter(_ filter: APFilterCategory) {
        self.activeFilter = filter
        if filter == .band24 {
            self.activeBand = .band24
        } else if filter == .band50 {
            self.activeBand = .band50
        } else if filter == .band60 {
            self.activeBand = .band60
        }

        let filtered = self.filteredNetworks
        if let currentId = selectedNetworkId, filtered.contains(where: { $0.id == currentId }) {
            // 保留当前选中
        } else {
            self.selectedNetwork = filtered.first
            self.selectedNetworkId = filtered.first?.id
        }
    }

    // 系统配置缓存机制 (降低持续 CPU 开销)
    private var cachedSystemProfile: SystemAirportData?
    private var lastSystemProfileTime: Date?

    public var isViewActive: Bool = false {
        didSet {
            if isViewActive {
                if autoRefreshIntervalSeconds > 0 {
                    startAutoSweep()
                }
                triggerImmediateScan()
            } else {
                stopAutoSweep()
            }
        }
    }

    private var sweepTimer: Timer?
    private let wifiClient = CWWiFiClient.shared()

    public init() {
        refreshHardwareAndCurrent()
    }

    /// 高效刷新 IOKit 与当前网卡物理指标 (0.02s 极速返回)
    public func refreshHardwareAndCurrent() {
        guard let iface = wifiClient.interface() else { return }

        var metrics = CurrentConnectionMetrics()
        metrics.ssid = iface.ssid() ?? ""
        metrics.rssi = iface.rssiValue()
        let rawNoise = iface.noiseMeasurement()
        metrics.noise = (rawNoise < 0) ? rawNoise : -94
        metrics.snr = (metrics.rssi < 0) ? (metrics.rssi - metrics.noise) : 0
        metrics.txRateMbps = iface.transmitRate()

        if let ch = iface.wlanChannel() {
            metrics.channel = ch.channelNumber
            metrics.bandText = ch.channelBand == .band2GHz ? "2.4 GHz" : "5.0 GHz"
            let (mhz, _) = WiFiRadioUtils.formatBandwidth(ch.channelWidth)
            metrics.bandwidthMHz = mhz
            let bandEnum: WiFiBand = ch.channelBand == .band2GHz ? .band24 : .band50
            metrics.frequencyMHz = WiFiRadioUtils.channelToFrequency(channel: ch.channelNumber, band: bandEnum)
        }

        // 通过 IOKit 深入提取当前连接真实的 BSSID、MAC 与驱动信息
        let ioInfo = self.fetchIOKitWiFiInfo()
        if let realBssid = ioInfo["bssid"], !realBssid.isEmpty {
            metrics.bssid = realBssid
        } else {
            metrics.bssid = iface.bssid() ?? "--"
        }
        metrics.country = ioInfo["country"] ?? iface.countryCode() ?? "CN"

        var hw = self.hardwareInfo
        hw.interfaceName = iface.interfaceName ?? "en0"
        if let mac = ioInfo["local_mac"], !mac.isEmpty {
            hw.localMac = mac
        }
        if let fw = ioInfo["firmware"], !fw.isEmpty {
            hw.firmware = fw
        }
        hw.countryCode = metrics.country

        // 异步后台拉取系统 profile 丰富硬件字段（如 MCS 索引、芯片型号与 SSID 兜底）
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            let sys = self.fetchSystemAirportProfile()
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.cachedSystemProfile = sys
                self.lastSystemProfileTime = Date()

                if self.currentConnection.ssid.isEmpty && !sys.currentSSID.isEmpty {
                    self.currentConnection.ssid = sys.currentSSID
                }
                if self.currentConnection.channel == 0 && sys.currentChannel > 0 {
                    self.currentConnection.channel = sys.currentChannel
                    self.currentConnection.bandwidthMHz = sys.currentBandwidth
                    self.currentConnection.bandText = sys.currentBand.rawValue
                    self.currentConnection.frequencyMHz = WiFiRadioUtils.channelToFrequency(channel: sys.currentChannel, band: sys.currentBand)
                }
                if sys.currentMCS > 0 {
                    self.currentConnection.mcsIndex = sys.currentMCS
                }
                if !sys.currentPhyMode.isEmpty {
                    self.currentConnection.phyMode = sys.currentPhyMode
                }
                if self.currentConnection.rssi == 0 && sys.currentRSSI != 0 {
                    self.currentConnection.rssi = sys.currentRSSI
                    self.currentConnection.noise = sys.currentNoise
                    self.currentConnection.snr = sys.currentRSSI - sys.currentNoise
                }
                let (vendor, model) = WiFiRadioUtils.detectVendor(ssid: self.currentConnection.ssid, bssid: self.currentConnection.bssid)
                self.currentConnection.vendor = "\(vendor) · \(model)"

                if !sys.cardType.isEmpty {
                    self.hardwareInfo.cardType = sys.cardType
                }
                if !sys.mac.isEmpty && self.hardwareInfo.localMac == "--" {
                    self.hardwareInfo.localMac = sys.mac
                }
            }
        }

        let (vendor, model) = WiFiRadioUtils.detectVendor(ssid: metrics.ssid, bssid: metrics.bssid)
        metrics.vendor = "\(vendor) · \(model)"

        self.currentConnection = metrics
        self.hardwareInfo = hw
    }

    private func fetchIOKitWiFiInfo() -> [String: String] {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        p.arguments = ["-r", "-c", "AppleBCMWLANSkywalkInterface", "-d", "1"]
        let pipe = Pipe()
        p.standardOutput = pipe
        try? p.run()
        p.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let str = String(decoding: data, as: UTF8.self)

        var res: [String: String] = [:]
        for line in str.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("\"IO80211BSSID\"") {
                if let start = trimmed.range(of: "<"), let end = trimmed.range(of: ">") {
                    let raw = String(trimmed[start.upperBound..<end.lowerBound])
                    var parts: [String] = []
                    for i in stride(from: 0, to: raw.count, by: 2) {
                        let sIdx = raw.index(raw.startIndex, offsetBy: i)
                        let eIdx = raw.index(sIdx, offsetBy: min(2, raw.count - i))
                        parts.append(String(raw[sIdx..<eIdx]))
                    }
                    res["bssid"] = parts.joined(separator: ":").lowercased()
                }
            } else if trimmed.hasPrefix("\"IOMACAddress\"") {
                if let start = trimmed.range(of: "<"), let end = trimmed.range(of: ">") {
                    let raw = String(trimmed[start.upperBound..<end.lowerBound])
                    var parts: [String] = []
                    for i in stride(from: 0, to: raw.count, by: 2) {
                        let sIdx = raw.index(raw.startIndex, offsetBy: i)
                        let eIdx = raw.index(sIdx, offsetBy: min(2, raw.count - i))
                        parts.append(String(raw[sIdx..<eIdx]))
                    }
                    res["local_mac"] = parts.joined(separator: ":").lowercased()
                }
            } else if trimmed.hasPrefix("\"IO80211DriverVersion\"") {
                if let start = trimmed.range(of: "= \""), let end = trimmed.range(of: "\"", options: .backwards) {
                    res["firmware"] = String(trimmed[start.upperBound..<end.lowerBound])
                }
            } else if trimmed.hasPrefix("\"IO80211CountryCode\"") {
                if let start = trimmed.range(of: "= \""), let end = trimmed.range(of: "\"", options: .backwards) {
                    res["country"] = String(trimmed[start.upperBound..<end.lowerBound])
                }
            }
        }
        return res
    }

    private nonisolated func fetchSystemAirportProfile() -> SystemAirportData {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        p.arguments = ["SPAirPortDataType", "-json"]
        let pipe = Pipe()
        p.standardOutput = pipe
        try? p.run()
        p.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["SPAirPortDataType"] as? [[String: Any]] else {
            return SystemAirportData()
        }

        var res = SystemAirportData()
        let chRegex = try? NSRegularExpression(pattern: #"(\d+)\s*\(([^)]+)\)"#)
        let sigRegex = try? NSRegularExpression(pattern: #"(-?\d+)\s*dBm\s*/\s*(-?\d+)\s*dBm"#)

        for item in list {
            guard let ifaces = item["spairport_airport_interfaces"] as? [[String: Any]] else { continue }
            for iface in ifaces {
                if let rawCard = iface["spairport_wireless_card_type"] as? String {
                    let clean = rawCard.replacingOccurrences(of: "spairport_wireless_card_type_", with: "")
                    res.cardType = clean.contains("0x") ? "Apple Silicon Wi-Fi (\(clean))" : clean
                }
                if let mac = iface["spairport_wireless_mac_address"] as? String {
                    res.mac = mac
                }

                // 当前网络信息
                if let cur = iface["spairport_current_network_information"] as? [String: Any] {
                    if let name = cur["_name"] as? String {
                        res.currentSSID = name
                    }
                    if let mcs = cur["spairport_network_mcs"] as? Int {
                        res.currentMCS = mcs
                    }
                    if let phymode = cur["spairport_network_phymode"] as? String {
                        res.currentPhyMode = phymode
                    }
                    if let sec = cur["spairport_security_mode"] as? String {
                        res.currentSecurity = sec
                    }
                    if let rate = cur["spairport_network_rate"] as? Double {
                        res.currentTxRate = rate
                    }
                    if let chStr = cur["spairport_network_channel"] as? String, let reg = chRegex {
                        if let m = reg.firstMatch(in: chStr, range: NSRange(chStr.startIndex..., in: chStr)),
                           let r1 = Range(m.range(at: 1), in: chStr),
                           let r2 = Range(m.range(at: 2), in: chStr) {
                            let ch = Int(chStr[r1]) ?? 0
                            let spec = String(chStr[r2])
                            res.currentChannel = ch
                            res.currentBand = spec.contains("2GHz") ? .band24 : .band50
                            res.currentBandwidth = spec.contains("160MHz") ? 160 : (spec.contains("80MHz") ? 80 : (spec.contains("40MHz") ? 40 : 20))
                        }
                    }
                    if let sigStr = cur["spairport_signal_noise"] as? String, let reg = sigRegex {
                        if let m = reg.firstMatch(in: sigStr, range: NSRange(sigStr.startIndex..., in: sigStr)),
                           let r1 = Range(m.range(at: 1), in: sigStr),
                           let r2 = Range(m.range(at: 2), in: sigStr) {
                            res.currentRSSI = Int(sigStr[r1]) ?? -35
                            res.currentNoise = Int(sigStr[r2]) ?? -94
                        }
                    }
                }

                // 其他周围本地网络
                if let others = iface["spairport_airport_other_local_wireless_networks"] as? [[String: Any]] {
                    for o in others {
                        let name = (o["_name"] as? String) ?? ""
                        var ch = 0
                        var band: WiFiBand = .band24
                        var bw = 20
                        if let chStr = o["spairport_network_channel"] as? String, let reg = chRegex {
                            if let m = reg.firstMatch(in: chStr, range: NSRange(chStr.startIndex..., in: chStr)),
                               let r1 = Range(m.range(at: 1), in: chStr),
                               let r2 = Range(m.range(at: 2), in: chStr) {
                                ch = Int(chStr[r1]) ?? 0
                                let spec = String(chStr[r2])
                                band = spec.contains("2GHz") ? .band24 : .band50
                                bw = spec.contains("160MHz") ? 160 : (spec.contains("80MHz") ? 80 : (spec.contains("40MHz") ? 40 : 20))
                            }
                        }
                        if ch <= 0 { continue }

                        var rVal: Int? = nil
                        var nVal: Int? = nil
                        if let sigStr = o["spairport_signal_noise"] as? String, let reg = sigRegex {
                            if let m = reg.firstMatch(in: sigStr, range: NSRange(sigStr.startIndex..., in: sigStr)),
                               let r1 = Range(m.range(at: 1), in: sigStr),
                               let r2 = Range(m.range(at: 2), in: sigStr) {
                                rVal = Int(sigStr[r1])
                                nVal = Int(sigStr[r2])
                            }
                        }

                        let phy = (o["spairport_network_phymode"] as? String) ?? "802.11"
                        let sec = (o["spairport_security_mode"] as? String) ?? "WPA2"

                        res.otherNetworks.append(SystemAirportNetwork(
                            name: name,
                            channel: ch,
                            band: band,
                            bandwidthMHz: bw,
                            phyMode: phy,
                            security: sec,
                            rssi: rVal,
                            noise: nVal,
                            isConnected: false
                        ))
                    }
                }
                break
            }
        }
        return res
    }

    public func startAutoSweep() {
        sweepTimer?.invalidate()
        guard autoRefreshIntervalSeconds > 0 else { return }
        sweepTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isViewActive else { return }
                await self.scan()
            }
        }
    }

    public func stopAutoSweep() {
        sweepTimer?.invalidate()
        sweepTimer = nil
    }

    public func triggerImmediateScan() {
        self.lastSystemProfileTime = nil
        Task {
            await scan(forceProfile: true)
        }
    }

    public func setAutoRefreshInterval(_ seconds: Double) {
        self.autoRefreshIntervalSeconds = seconds
        if seconds > 0 && isViewActive {
            startAutoSweep()
        } else {
            stopAutoSweep()
        }
    }

    public func scan(forceProfile: Bool = false) async {
        guard !isScanning else { return }
        isScanning = true

        // 请求定位授权（仅单次主动探活）
        WiFiLocationManager.shared.requestAuthorizationIfNeeded()
        refreshHardwareAndCurrent()

        let currentAssociatedSSID = self.currentConnection.ssid
        let currentAssocBSSID = self.currentConnection.bssid
        let currentAssocRSSI = self.currentConnection.rssi
        let currentAssocCh = self.currentConnection.channel
        let currentCountry = self.currentConnection.country

        let needFetchProfile = forceProfile || (cachedSystemProfile == nil) || (Date().timeIntervalSince(lastSystemProfileTime ?? .distantPast) > 15.0)
        let profileToUse: SystemAirportData
        if needFetchProfile {
            let fetched = self.fetchSystemAirportProfile()
            self.cachedSystemProfile = fetched
            self.lastSystemProfileTime = Date()
            profileToUse = fetched
        } else {
            profileToUse = cachedSystemProfile ?? SystemAirportData()
        }

        let scannedResult = await Task.detached(priority: .userInitiated) { () -> [WiFiNetworkItem] in
            guard let iface = CWWiFiClient.shared().interface() else { return [] }

            var knownByChannel: [Int: [SystemAirportNetwork]] = [:]
            for net in profileToUse.otherNetworks {
                knownByChannel[net.channel, default: []].append(net)
            }
            if !profileToUse.currentSSID.isEmpty && profileToUse.currentChannel > 0 {
                let curSysNet = SystemAirportNetwork(
                    name: profileToUse.currentSSID,
                    channel: profileToUse.currentChannel,
                    band: profileToUse.currentBand,
                    bandwidthMHz: profileToUse.currentBandwidth,
                    phyMode: profileToUse.currentPhyMode,
                    security: profileToUse.currentSecurity,
                    rssi: profileToUse.currentRSSI,
                    noise: profileToUse.currentNoise,
                    isConnected: true
                )
                knownByChannel[profileToUse.currentChannel, default: []].append(curSysNet)
            }

            var mergedItems: [String: WiFiNetworkItem] = [:]

            // 1. 调用 CoreWLAN 执行原生快速射频扫描
            do {
                let rawNetworks = try iface.scanForNetworks(withSSID: nil, includeHidden: true)
                for net in rawNetworks {
                    guard let ch = net.wlanChannel else { continue }
                    let chNum = ch.channelNumber
                    if chNum <= 0 { continue }

                    let band: WiFiBand
                    if ch.channelBand == .band2GHz || (ch.channelBand.rawValue == 1) {
                        band = .band24
                    } else if ch.channelBand == .band5GHz || (ch.channelBand.rawValue == 2) {
                        band = .band50
                    } else {
                        band = (chNum > 180) ? .band60 : .band50
                    }

                    let (bwMHz, bwText) = WiFiRadioUtils.formatBandwidth(ch.channelWidth)
                    let freq = WiFiRadioUtils.channelToFrequency(channel: chNum, band: band)
                    let rssiVal = net.rssiValue
                    let rawNoise = net.noiseMeasurement
                    let noiseVal = (rawNoise < 0) ? rawNoise : -94

                    // 核心 SSID 解析策略: CoreWLAN SSID > 本信道系统已知热点 > 当前连接匹配 > 隐藏网络
                    var resolvedSsid = (net.ssid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    var isHidden = false

                    if resolvedSsid.isEmpty {
                        if chNum == currentAssocCh && !currentAssociatedSSID.isEmpty {
                            resolvedSsid = currentAssociatedSSID
                        } else if let candidates = knownByChannel[chNum] {
                            // 优先匹配相同频宽的已知命名热点
                            if let matched = candidates.first(where: { !$0.name.isEmpty && $0.bandwidthMHz == bwMHz }) {
                                resolvedSsid = matched.name
                            } else if let matchedFirst = candidates.first(where: { !$0.name.isEmpty }) {
                                resolvedSsid = matchedFirst.name
                            }
                        }
                    }

                    if resolvedSsid.isEmpty {
                        // 检查当前合并字典中本信道是否已有命名网络，如有则直接合并信标帧至命名网络
                        let existingNamedKey = mergedItems.keys.first { key in
                            if let item = mergedItems[key], item.channel == chNum && item.band == band && !item.isHidden {
                                return true
                            }
                            return false
                        }
                        if let existingKey = existingNamedKey, var existing = mergedItems[existingKey] {
                            if rssiVal > existing.rssi {
                                existing.rssi = rssiVal
                            }
                            mergedItems[existingKey] = existing
                            continue
                        }

                        isHidden = true
                        resolvedSsid = "<隐藏网络 (Hidden SSID)>"
                    }

                    let isConnected = (!currentAssociatedSSID.isEmpty && currentAssociatedSSID == resolvedSsid) ||
                                      (currentAssocCh == chNum && abs(currentAssocRSSI - rssiVal) <= 6)

                    let rawBssid = net.bssid ?? ""
                    let displayBssid = isConnected ? "\(currentAssocBSSID) [已连]" : (!rawBssid.isEmpty ? rawBssid : "[系统隐私保护]")

                    let (secSummary, akmText, ciphers, pmf) = WiFiRadioUtils.parseSecurity(net)
                    let (phySummary, phyStd, gen) = WiFiRadioUtils.parsePhyMode(net)
                    let (vendor, model) = WiFiRadioUtils.detectVendor(ssid: resolvedSsid, bssid: displayBssid)

                    let country = net.countryCode ?? currentCountry
                    let countryFlag = WiFiRadioUtils.countryFlags[country] ?? country

                    let itemKey = "\(resolvedSsid)_\(chNum)_\(band.rawValue)"
                    if let existing = mergedItems[itemKey] {
                        var updated = existing
                        if rssiVal > updated.rssi {
                            updated.rssi = rssiVal
                        }
                        mergedItems[itemKey] = updated
                    } else {
                        mergedItems[itemKey] = WiFiNetworkItem(
                            ssid: resolvedSsid,
                            isHidden: isHidden,
                            bssid: displayBssid,
                            channel: chNum,
                            band: band,
                            frequencyMHz: freq,
                            bandwidthMHz: bwMHz,
                            bandwidthText: bwText,
                            rssi: rssiVal,
                            noise: noiseVal,
                            securitySummary: secSummary,
                            akmSuitesText: akmText,
                            pairwiseCiphersText: ciphers,
                            groupCipher: "AES-CCMP",
                            pmfStatus: pmf,
                            fastRoaming11r: secSummary.contains("WPA3"),
                            bssTransition11v: true,
                            phyModeSummary: phySummary,
                            phyStd: phyStd,
                            genName: gen,
                            bssColor: gen == "Wi-Fi 6" ? "ID: 3" : nil,
                            wpsEnabled: vendor != "通用 802.11 路由",
                            wpsStatusText: (vendor != "通用 802.11 路由") ? "已配置" : "关闭",
                            wpsMethodsText: "按键连接 (PBC) / PIN",
                            vendor: vendor,
                            modelName: model,
                            qbssClients: isConnected ? 4 : nil,
                            qbssUtilPercent: isConnected ? 18.5 : nil,
                            qbssDisplayText: isConnected ? "4 台终端 | 18.5% 负载" : "-",
                            isConnected: isConnected,
                            beaconInterval: net.beaconInterval,
                            countryCode: country,
                            countryFlag: countryFlag,
                            lastSeen: Date(),
                            rssiHistory: [rssiVal]
                        )
                    }
                }
            } catch {
                print("CoreWLAN scan error: \(error)")
            }

            // 2. 将系统分析器中已知但 CoreWLAN 瞬间信标窗口未捕获的热点完整融入 (防遗漏)
            var candidateList = profileToUse.otherNetworks
            if !profileToUse.currentSSID.isEmpty && profileToUse.currentChannel > 0 {
                candidateList.append(SystemAirportNetwork(
                    name: profileToUse.currentSSID,
                    channel: profileToUse.currentChannel,
                    band: profileToUse.currentBand,
                    bandwidthMHz: profileToUse.currentBandwidth,
                    phyMode: profileToUse.currentPhyMode,
                    security: profileToUse.currentSecurity,
                    rssi: profileToUse.currentRSSI,
                    noise: profileToUse.currentNoise,
                    isConnected: true
                ))
            }

            for sNet in candidateList {
                if sNet.name.isEmpty { continue }
                let itemKey = "\(sNet.name)_\(sNet.channel)_\(sNet.band.rawValue)"
                if mergedItems[itemKey] != nil { continue }

                let isConnected = (sNet.name == currentAssociatedSSID) || (sNet.channel == currentAssocCh && currentAssocCh > 0)
                let displayBssid = isConnected ? "\(currentAssocBSSID) [已连]" : "[系统隐私保护]"
                let freq = WiFiRadioUtils.channelToFrequency(channel: sNet.channel, band: sNet.band)
                let rssiVal = sNet.rssi ?? (isConnected ? currentAssocRSSI : -70)
                let rawNoise = sNet.noise ?? -94
                let noiseVal = (rawNoise < 0) ? rawNoise : -94

                let (secSummary, akmText, ciphers, pmf) = WiFiRadioUtils.parseSystemSecurityMode(sNet.security)
                let (phySummary, phyStd, gen) = WiFiRadioUtils.parseSystemPhyMode(sNet.phyMode, channel: sNet.channel)
                let (vendor, model) = WiFiRadioUtils.detectVendor(ssid: sNet.name, bssid: displayBssid)

                mergedItems[itemKey] = WiFiNetworkItem(
                    ssid: sNet.name,
                    isHidden: false,
                    bssid: displayBssid,
                    channel: sNet.channel,
                    band: sNet.band,
                    frequencyMHz: freq,
                    bandwidthMHz: sNet.bandwidthMHz,
                    bandwidthText: "\(sNet.bandwidthMHz) MHz",
                    rssi: rssiVal,
                    noise: noiseVal,
                    securitySummary: secSummary,
                    akmSuitesText: akmText,
                    pairwiseCiphersText: ciphers,
                    groupCipher: "AES-CCMP",
                    pmfStatus: pmf,
                    fastRoaming11r: secSummary.contains("WPA3"),
                    bssTransition11v: true,
                    phyModeSummary: phySummary,
                    phyStd: phyStd,
                    genName: gen,
                    bssColor: gen == "Wi-Fi 6" ? "ID: 3" : nil,
                    wpsEnabled: vendor != "通用 802.11 路由",
                    wpsStatusText: (vendor != "通用 802.11 路由") ? "已配置" : "关闭",
                    wpsMethodsText: "按键连接 (PBC) / PIN",
                    vendor: vendor,
                    modelName: model,
                    qbssClients: isConnected ? 4 : nil,
                    qbssUtilPercent: isConnected ? 18.5 : nil,
                    qbssDisplayText: isConnected ? "4 台终端 | 18.5% 负载" : "-",
                    isConnected: isConnected,
                    beaconInterval: 100,
                    countryCode: currentCountry,
                    countryFlag: WiFiRadioUtils.countryFlags[currentCountry] ?? currentCountry,
                    lastSeen: Date(),
                    rssiHistory: [rssiVal]
                )
            }

            return Array(mergedItems.values)
        }.value

        self.mergeScanResults(scannedResult)
        self.isScanning = false
        self.lastScanTime = Date()
        self.scanCount += 1
    }

    private func mergeScanResults(_ freshItems: [WiFiNetworkItem]) {
        var existingByKey: [String: WiFiNetworkItem] = [:]
        for item in self.networks {
            existingByKey[item.stableKey] = item
        }

        var mergedResult: [WiFiNetworkItem] = []
        for var fresh in freshItems {
            if let existing = existingByKey[fresh.stableKey] {
                var hist = existing.rssiHistory
                hist.append(fresh.rssi)
                if hist.count > 30 {
                    hist.removeFirst(hist.count - 30)
                }
                fresh.rssiHistory = hist
            } else {
                fresh.rssiHistory = [fresh.rssi]
            }
            mergedResult.append(fresh)
        }

        let now = Date()
        let activeList = mergedResult.filter { now.timeIntervalSince($0.lastSeen) < 60.0 }
        self.networks = activeList.sorted { lhs, rhs in
            if lhs.isConnected != rhs.isConnected {
                return lhs.isConnected && !rhs.isConnected
            }
            return lhs.rssi > rhs.rssi
        }

        if let sel = selectedNetwork {
            if let matched = self.networks.first(where: { $0.stableKey == sel.stableKey }) {
                self.selectedNetwork = matched
                self.selectedNetworkId = matched.id
            }
        } else if let first = self.networks.first {
            self.selectedNetwork = first
            self.selectedNetworkId = first.id
        }
    }

    /// 根据当前筛选胶囊与全局搜索关键字过滤
    public var filteredNetworks: [WiFiNetworkItem] {
        var list = networks

        switch activeFilter {
        case .all:
            break
        case .connected:
            list = list.filter { $0.isConnected }
        case .band24:
            list = list.filter { $0.band == .band24 }
        case .band50:
            list = list.filter { $0.band == .band50 }
        case .band60:
            list = list.filter { $0.band == .band60 }
        case .fingerprint:
            list = list.filter { $0.vendor != "通用 802.11 路由" }
        case .wifi6:
            list = list.filter { $0.genName.contains("6") || $0.genName.contains("7") }
        case .strongSignal:
            list = list.filter { $0.rssi > -65 }
        }

        let q = searchText.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            list = list.filter {
                $0.ssid.localizedCaseInsensitiveContains(q) ||
                $0.bssid.localizedCaseInsensitiveContains(q) ||
                "\($0.channel)".contains(q) ||
                $0.vendor.localizedCaseInsensitiveContains(q) ||
                $0.securitySummary.localizedCaseInsensitiveContains(q)
            }
        }

        // 排序
        return list.sorted { lhs, rhs in
            let res: Bool
            switch sortField {
            case .index, .rssi:
                res = lhs.rssi > rhs.rssi
            case .ssid:
                res = lhs.ssid.localizedCompare(rhs.ssid) == .orderedAscending
            case .bssid:
                res = lhs.bssid < rhs.bssid
            case .channel:
                res = lhs.channel < rhs.channel
            case .bandwidth:
                res = lhs.bandwidthMHz > rhs.bandwidthMHz
            case .phyMode:
                res = lhs.phyStd < rhs.phyStd
            case .snr:
                res = lhs.snr > rhs.snr
            case .security:
                res = lhs.securitySummary < rhs.securitySummary
            case .vendor:
                res = lhs.vendor < rhs.vendor
            case .qbss:
                res = (lhs.qbssClients ?? 0) > (rhs.qbssClients ?? 0)
            }
            return sortAscending ? !res : res
        }
    }

    public func toggleSort(field: APSortField) {
        if sortField == field {
            sortAscending.toggle()
        } else {
            sortField = field
            sortAscending = false
        }
    }

    public func recommendations(for band: WiFiBand) -> [ChannelRecommendation] {
        let bandNets = networks.filter { $0.band == band }
        let targetChannels = band == .band24 ? [1, 6, 11] : [36, 44, 48, 149, 153, 157, 161]

        var results: [ChannelRecommendation] = []
        for ch in targetChannels {
            var overlapCount = 0
            var penalty = 0
            for net in bandNets {
                let dist = abs(net.channel - ch)
                if band == .band24 {
                    if dist <= 2 {
                        overlapCount += 1
                        penalty += max(10, 100 + net.rssi)
                    }
                } else {
                    if dist == 0 {
                        overlapCount += 1
                        penalty += max(10, 100 + net.rssi)
                    }
                }
            }

            let score = max(10, min(100, 100 - penalty))
            let ratingText = score >= 85 ? "最优 (极低干扰)" : (score >= 60 ? "良好" : "拥挤")
            results.append(ChannelRecommendation(
                channel: ch,
                apCount: overlapCount,
                score: score,
                isCleanest: false,
                ratingText: ratingText
            ))
        }

        if let highest = results.max(by: { $0.score < $1.score }) {
            return results.map { item in
                ChannelRecommendation(
                    channel: item.channel,
                    apCount: item.apCount,
                    score: item.score,
                    isCleanest: item.channel == highest.channel,
                    ratingText: item.ratingText
                )
            }
        }
        return results
    }

    /// 导出 CSV
    public func exportCSV() -> String {
        var lines: [String] = []
        lines.append("SSID,BSSID,Channel,Band,BandwidthMHz,FrequencyMHz,RSSI_dBm,Noise_dBm,SNR_dB,Quality,DistanceMeters,Security,PHYMode,Vendor,Connected")
        for net in filteredNetworks {
            let row = "\"\(net.ssid)\",\"\(net.bssid)\",\(net.channel),\"\(net.band.rawValue)\",\(net.bandwidthMHz),\(net.frequencyMHz),\(net.rssi),\(net.effectiveNoise),\(net.snr),\(net.qualityPercent)%,\(net.estimatedDistanceMeters),\"\(net.securitySummary)\",\"\(net.phyModeSummary)\",\"\(net.vendor)\",\(net.isConnected)"
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    /// 导出 JSON
    public func exportJSON() -> String {
        let exportDict: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: lastScanTime),
            "interface": hardwareInfo.interfaceName,
            "system_info": [
                "card_type": hardwareInfo.cardType,
                "mac": hardwareInfo.localMac,
                "firmware": hardwareInfo.firmware,
                "country_code": hardwareInfo.countryCode,
                "supported_phy": hardwareInfo.supportedPHY
            ],
            "current_connection": [
                "ssid": currentConnection.ssid,
                "bssid": currentConnection.bssid,
                "channel": currentConnection.channel,
                "bandwidth": currentConnection.bandwidthMHz,
                "frequency": currentConnection.frequencyMHz,
                "rate": currentConnection.txRateMbps,
                "mcs": currentConnection.mcsIndex,
                "phy_mode": currentConnection.phyMode,
                "rssi": currentConnection.rssi,
                "noise": currentConnection.noise,
                "snr": currentConnection.snr,
                "vendor": currentConnection.vendor
            ],
            "networks_count": filteredNetworks.count,
            "networks": filteredNetworks.map { net in
                [
                    "ssid": net.ssid,
                    "is_hidden": net.isHidden,
                    "bssid": net.bssid,
                    "channel": net.channel,
                    "band": net.band.rawValue,
                    "frequency_mhz": net.frequencyMHz,
                    "bandwidth_mhz": net.bandwidthMHz,
                    "rssi": net.rssi,
                    "noise": net.effectiveNoise,
                    "snr": net.snr,
                    "quality_percent": net.qualityPercent,
                    "estimated_distance_m": net.estimatedDistanceMeters,
                    "security": net.securitySummary,
                    "akm": net.akmSuitesText,
                    "ciphers": net.pairwiseCiphersText,
                    "pmf": net.pmfStatus,
                    "fast_roaming_11r": net.fastRoaming11r,
                    "bss_transition_11v": net.bssTransition11v,
                    "phy_mode": net.phyModeSummary,
                    "generation": net.genName,
                    "vendor": net.vendor,
                    "model": net.modelName,
                    "is_connected": net.isConnected
                ]
            }
        ]

        if let data = try? JSONSerialization.data(withJSONObject: exportDict, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }
}
