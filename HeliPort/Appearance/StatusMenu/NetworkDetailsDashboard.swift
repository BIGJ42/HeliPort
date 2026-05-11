import SwiftUI
import Charts

struct SignalData: Identifiable {
    let id = UUID()
    let time: Date
    let value: Int
}

struct NetworkDetailsDashboard: View {
    let ssid: String
    let ipAddress: String
    let router: String
    let signal: Int
    let noise: Int
    let txRate: String
    let channel: String
    let phyMode: String
    let bssid: String
    
    private var signalDisplay: String {
        if UserDefaults.standard.bool(forKey: String.DefaultsKey.showSignalAsPercentage) {
            let percentage = max(min(signal + 100, 70), 0) * 100 / 70
            return "\(percentage)%"
        }
        return "\(signal) dBm"
    }
    
    @State private var signalHistory: [SignalData] = (0..<30).map { i in
        SignalData(time: Date().addingTimeInterval(Double(-i * 2)), value: Int.random(in: -70...(-40)))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            HStack(spacing: 12) {
                // Icon with subtle glow
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: "wifi")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(ssid)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Connected • Stable")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Real-time Rate Badge
                VStack(alignment: .trailing, spacing: 0) {
                    Text(txRate.replacingOccurrences(of: " Mbps", with: ""))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                    Text("Mbps")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(8)
            }
            .padding(.bottom, 16)
            
            // Chart Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("SIGNAL STRENGTH")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(signalDisplay)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                }
                
                Chart {
                    ForEach(signalHistory) { data in
                        AreaMark(
                            x: .value("Time", data.time),
                            y: .value("Signal", data.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Time", data.time),
                            y: .value("Signal", data.value)
                        )
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: -90...(-30))
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 50)
            }
            .padding(.bottom, 16)
            
            Divider().opacity(0.5)
                .padding(.bottom, 12)
            
            // Technical Details Grid
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                GridRow {
                    DetailItem(label: "IP Address", value: ipAddress)
                    DetailItem(label: "Router", value: router)
                }
                GridRow {
                    DetailItem(label: "Channel", value: channel)
                    DetailItem(label: "PHY Mode", value: phyMode)
                }
                GridRow {
                    DetailItem(label: "BSSID", value: bssid.uppercased())
                    DetailItem(label: "Noise", value: "\(noise) dBm")
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
                
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.03), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.secondary.opacity(0.7))
                .tracking(0.5)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

class ModernDashboardMenuItem: NSMenuItem {
    init(ssid: String, ipAddress: String, router: String, signal: Int, noise: Int, txRate: String, channel: String, phyMode: String, bssid: String) {
        super.init(title: "Dashboard", action: nil, keyEquivalent: "")
        let view = NetworkDetailsDashboard(
            ssid: ssid,
            ipAddress: ipAddress,
            router: router,
            signal: signal,
            noise: noise,
            txRate: txRate,
            channel: channel,
            phyMode: phyMode,
            bssid: bssid
        )
        self.view = NSHostingView(rootView: view)
        self.view?.frame = NSRect(x: 0, y: 0, width: 320, height: 280)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

