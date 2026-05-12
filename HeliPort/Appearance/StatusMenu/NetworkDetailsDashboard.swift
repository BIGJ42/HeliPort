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
    @Published var snr: Int = 0
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
        self.snr = self.signal - self.noise

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
    
    private var signalColor: Color {
        let rssi = viewModel.signal
        if rssi > -60 { return .green }
        if rssi > -75 { return Color(red: 1, green: 0.6, blue: 0) }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(signalColor.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: "wifi", variableValue: Double(max(0, viewModel.signal + 100)) / 100.0)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(signalColor)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.ssid)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(signalColor)
                            .frame(width: 5, height: 5)
                        Text("Connected")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(signalColor.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Tx Rate Badge
                VStack(alignment: .trailing, spacing: -1) {
                    Text(viewModel.txRate.replacingOccurrences(of: " Mbps", with: ""))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Mbps")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.regularMaterial)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
            }
            .padding(.bottom, 12)
            
            // Signal Chart
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("SIGNAL STRENGTH")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.secondary.opacity(0.7))
                        .tracking(0.8)
                    Spacer()
                    Text(signalDisplay)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(signalColor)
                }
                
                Chart {
                    ForEach(viewModel.signalHistory) { data in
                        AreaMark(
                            x: .value("Time", data.time),
                            y: .value("Signal", data.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [signalColor.opacity(0.25), signalColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Time", data.time),
                            y: .value("Signal", data.value)
                        )
                        .foregroundStyle(signalColor.opacity(0.9))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: -90...(-30))
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 32)
            }
            .padding(.bottom, 12)
            
            Divider().opacity(0.15)
                .padding(.bottom, 10)
            
            // Details Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                DetailItem(label: "IP Address", value: viewModel.ipAddress, icon: "network")
                DetailItem(label: "Router", value: viewModel.router, icon: "router")
                DetailItem(label: "Channel", value: viewModel.channel, icon: "antenna.radiowaves.left.and.right")
                DetailItem(label: "PHY Mode", value: viewModel.phyMode, icon: "bolt.fill")
                DetailItem(label: "BSSID", value: viewModel.bssid.uppercased(), icon: "macpro.gen3")
                DetailItem(label: "Noise", value: "\(viewModel.noise) dBm", icon: "ear.and.waveform")
                DetailItem(label: "SNR", value: "\(viewModel.snr) dB", icon: "equal.circle")
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: HeliPortUI.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HeliPortUI.Radius.medium, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.accentColor.opacity(0.7))
                .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundColor(.secondary.opacity(0.55))
                    .tracking(0.6)
                Text(value)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
            
            // Simple visual feedback could be added here if needed, 
            // but for lightweight apps, a silent copy is often preferred 
            // or a small haptic if available.
        }
    }
}

