# WiFi Radar

> **English** | [中文](#中文)

A native macOS Wi-Fi scanner and channel spectrum analyzer built with Swift, SwiftUI, and CoreWLAN.

---

## English

### Features

- **Channel Spectrum Visualization**: Real-time signal strength (RSSI) curves across 2.4 GHz, 5 GHz, and 6 GHz (Wi-Fi 6E / Wi-Fi 7) bands.
- **Safari-Style Unified Toolbar**: Native macOS toolbar integration with view mode switcher (Spectrum, List, Split View), search filter, and inspector toggle.
- **Detailed Network Telemetry**: Inspect SSID, BSSID, RSSI, noise floor, signal-to-noise ratio (SNR), channel width (20 / 40 / 80 / 160 MHz), Wi-Fi generation (802.11n / ac / ax / be), and security suites (WPA2, WPA3-SAE).
- **Data Export**: Export scan results to standard CSV or structured JSON.
- **Window & Layout Persistence**: Automatically saves and restores window dimensions and sidebar widths.
- **Lightweight & Native**: Written in 100% Swift 6 with zero third-party dependencies.

### Installation

#### Download Pre-built App
Download the latest **`WiFiRadar.dmg`** from the [Releases](https://github.com/Z-tar/WiFiRadar/releases) page, open the disk image, and drag `WiFiRadar.app` to your `Applications` folder.

#### Build from Source
**Requirements:** macOS 13.0 or later, Xcode 15+ or Swift 6 toolchain.

```bash
git clone https://github.com/Z-tar/WiFiRadar.git
cd WiFiRadar
./build.sh
```

The script compiles the release binary, creates `/Applications/WiFiRadar.app`, and packages `WiFiRadar.dmg` and `WiFiRadar.zip` into `~/Downloads/`.

### Project Structure

```text
WiFiRadar/
├── Package.swift                  # Swift Package Manager manifest
├── build.sh                       # Build & DMG packaging script
├── make_icon.swift                # App icon generator
├── Resources/
│   ├── AppIcon.icns               # Application icon
│   ├── icon_1024.png              # 1024x1024 master icon
│   └── Info.plist                 # Bundle metadata & permissions
└── Sources/
    ├── main.swift                 # App lifecycle entry point
    ├── WiFiRadarCore.swift        # CoreWLAN hardware scanning & RF model
    └── WiFiRadarView.swift        # SwiftUI views & toolbar coordinator
```

### License

Released under the [MIT License](LICENSE).

---

## 中文

基于 Swift、SwiftUI 与 CoreWLAN 构建的 macOS 原生 Wi-Fi 扫描与信道频谱分析工具。

### 功能特性

- **信道频谱可视化**：实时展示 2.4 GHz、5 GHz 与 6 GHz (Wi-Fi 6E / Wi-Fi 7) 频段的信道占用与信号强度 (RSSI) 曲线。
- **Safari 风格统一工具栏**：遵循 macOS 原生设计规范，支持视图切换（频谱图、数据列表、混合分屏）、网络搜索过滤与参数检查器抽屉。
- **详细网络信息**：查看 SSID、BSSID、信号强度 (RSSI)、环境噪声、信噪比 (SNR)、信道频宽 (20 / 40 / 80 / 160 MHz)、Wi-Fi 标准代际 (Wi-Fi 4 / 5 / 6 / 6E / 7) 与安全协议 (WPA2 / WPA3-SAE)。
- **数据导出**：支持一键导出标准 CSV 格式与完整 JSON 报文。
- **布局记忆**：自动保存并恢复窗口位置、大小以及侧边栏分栏宽度。
- **原生轻量**：采用纯 Swift 6 与 SwiftUI 编写，零第三方依赖。

### 安装与运行

#### 下载预编译版本
前往 [Releases](https://github.com/Z-tar/WiFiRadar/releases) 页面下载 **`WiFiRadar.dmg`**，打开镜像后将 `WiFiRadar.app` 拖入「应用程序」目录即可。

#### 源码编译
**环境要求**：macOS 13.0 或更高版本，Xcode 15+ 或 Swift 6 工具链。

```bash
git clone https://github.com/Z-tar/WiFiRadar.git
cd WiFiRadar
./build.sh
```

构建脚本将自动完成 Release 编译，安装应用至 `/Applications/WiFiRadar.app`，并在 `~/Downloads/` 目录下生成 `WiFiRadar.dmg` 与 `WiFiRadar.zip`。

### 开源许可证

本项目采用 [MIT License](LICENSE) 许可证。
