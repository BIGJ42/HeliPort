import SwiftUI
import Charts

struct SignalData: Identifiable {
    let id = UUID()
    let time: Date
    let value: Int
}

class NetworkDetailsViewModel: ObservableObject {
    @Published var ssid: String = ""
    @Published var ipAddress: String = ""
    @Published var router: String = ""
    @Published var signal: Int = 0
    @Published var noise: Int = 0
    @Published var txRate: String = ""
    @Published var channel: String = ""
    @Published var phyMode: String = ""
    @Published var bssid: String = ""
    @Published var signalHistory: [SignalData] = (0..<30).map { index in
        SignalData(time: Date().addingTimeInterval(Double(-index * 2)), value: Int.random(in: -70...(-60)))
    }

    func update(with info: StatusMenuBase.StationInfo) {
        self.ssid = info.ssid ?? ""
        self.ipAddress = info.ipAddr
        self.router = info.routerAddr
        self.signal = info.rssiValue
        self.noise = Int(info.noise.replacingOccurrences(of: " dBm", with: "")) ?? 0
        self.txRate = info.txRate
        self.channel = info.channel
        self.phyMode = info.phyMode
        self.bssid = info.bssid

        let newData = SignalData(time: Date(), value: info.rssiValue)
        signalHistory.insert(newData, at: 0)
        if signalHistory.count > 30 {
            signalHistory.removeLast()
        }
    }
}

struct NetworkDetailsDashboard: View {
    @ObservedObject var viewModel: NetworkDetailsViewModel
    
    private var signalDisplay: String {
        if UserDefaults.standard.bool(forKey: String.DefaultsKey.showSignalAsPercentage) {
            let percentage = max(min(viewModel.signal + 100, 70), 0) * 100 / 70
            return "\(percentage)%"
        }
        return "\(viewModel.signal) dBm"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            HStack(spacing: 12) {
                // Icon with subtle glow
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: HeliPortUI.Dashboard.iconSize, height: HeliPortUI.Dashboard.iconSize)
                    
                    Image(systemName: "wifi")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.ssid)
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
                    Text(viewModel.txRate.replacingOccurrences(of: " Mbps", with: ""))
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
                    ForEach(viewModel.signalHistory) { data in
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
                .frame(height: 40)
            }
            .padding(.bottom, 16)
            
            Divider().opacity(0.5)
                .padding(.bottom, 12)
            
            // Technical Details Grid
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                GridRow {
                    DetailItem(label: "IP Address", value: viewModel.ipAddress)
                    DetailItem(label: "Router", value: viewModel.router)
                }
                GridRow {
                    DetailItem(label: "Channel", value: viewModel.channel)
                    DetailItem(label: "PHY Mode", value: viewModel.phyMode)
                }
                GridRow {
                    DetailItem(label: "BSSID", value: viewModel.bssid.uppercased())
                    DetailItem(label: "Noise", value: "\(viewModel.noise) dBm")
                }
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: HeliPortUI.Radius.medium, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
                
                RoundedRectangle(cornerRadius: HeliPortUI.Radius.medium, style: .continuous)
                    .fill(HeliPortUI.Dashboard.premiumGradient)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: HeliPortUI.Radius.medium, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .padding(.horizontal, HeliPortUI.Spacing.small + 2)
        .padding(.vertical, HeliPortUI.Spacing.small)
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
