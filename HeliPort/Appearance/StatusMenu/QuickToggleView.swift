import SwiftUI

struct QuickToggleView: View {
    @Binding var isOn: Bool
    let title: String
    var onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .labelsHidden()
                .scaleEffect(0.8)
                .onChange(of: isOn) { newValue in
                    onToggle(newValue)
                }
        }
        .modernMenuItem()
    }
}

class ModernToggleMenuItem: NSMenuItem {
    init(title: String, isOn: Binding<Bool>, onToggle: @escaping (Bool) -> Void) {
        super.init(title: title, action: nil, keyEquivalent: "")
        let view = QuickToggleView(isOn: isOn, title: title, onToggle: onToggle)
        self.view = NSHostingView(rootView: view)
        self.view?.frame = NSRect(x: 0, y: 0, width: 300, height: 44)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
