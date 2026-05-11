import SwiftUI

struct NetworkItemView: View {
    let ssid: String
    let signalStrength: Int
    let isConnected: Bool
    let isSecure: Bool
    var onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: HeliPortUI.Spacing.medium) {
            // Signal Strength Icon
            ZStack {
                Circle()
                    .fill(isConnected ? Color.accentColor : Color.primary.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: signalIconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isConnected ? .white : .primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ssid)
                    .font(.system(size: 13, weight: isConnected ? .bold : .medium))
                    .foregroundColor(.primary)
                
                if isConnected {
                    Text("Connected")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSecure {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .modernMenuItem()
        .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
    
    private var signalIconName: String {
        if signalStrength > -50 { return "wifi" }
        if signalStrength > -70 { return "wifi" }
        if signalStrength > -90 { return "wifi" }
        return "wifi.exclamationmark"
    }
}

// Helper for hosting in NSMenu
class ModernNetworkMenuItem: NSMenuItem {
    init(ssid: String, signalStrength: Int, isConnected: Bool, isSecure: Bool, onSelect: @escaping () -> Void) {
        super.init(title: ssid, action: nil, keyEquivalent: "")
        let view = NetworkItemView(ssid: ssid, signalStrength: signalStrength, isConnected: isConnected, isSecure: isSecure, onSelect: onSelect)
        self.view = NSHostingView(rootView: view)
        // Adjust frame to fit menu
        self.view?.frame = NSRect(x: 0, y: 0, width: 300, height: 40)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
