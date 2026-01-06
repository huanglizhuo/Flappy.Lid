import SwiftUI
import ApplicationServices

struct KeySimulatorView: View {
    @ObservedObject var keySimulator = KeySimulator.shared
    @ObservedObject var lidMonitor: LidAngleMonitor
    @State private var isListeningForKey = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("KEY SIMULATOR MODE")
                .font(.flappy(size: 40))
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            // Visual Indicator
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
                
                if let lastTrig = keySimulator.lastTriggerTime, 
                   Date().timeIntervalSince(lastTrig) < 0.2 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 180, height: 180)
                        .transition(.scale)
                }
                
                VStack {
                    Image(systemName: "keyboard")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text(keyCodeToName(keySimulator.targetKeyCode))
                        .font(.flappy(size: 30))
                        .foregroundColor(.yellow)
                        .padding(.top, 10)
                }
            }
            .padding(.vertical, 20)
            
            // Current Trigger Info
            Text("TRIGGER: \(lidMonitor.triggerMode.rawValue.uppercased())")
                .font(.flappy(size: 20))
                .foregroundColor(.white.opacity(0.8))
            
            // Permissions Warning
            if !keySimulator.checkPermissions() {
                VStack {
                    Text("Accessibility Permission Required")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("Grant permission in System Settings to control other apps.")
                        .font(.caption)
                        .foregroundColor(.white)
                    Button("Open Settings") {
                        // Prompt again which opens settings
                        _ = keySimulator.checkPermissions() 
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
            }
            
            // Key Binding Config
            Button(action: {
                isListeningForKey = true
            }) {
                Text(isListeningForKey ? "PRESS A KEY..." : "CHANGE KEY BINDING")
                    .padding()
                    .background(isListeningForKey ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.flappy(size: 18))
            }
            .buttonStyle(.plain)
            .background(KeyReaderView(active: $isListeningForKey) { newKeyCode in
                keySimulator.targetKeyCode = newKeyCode
                isListeningForKey = false
            })
            
            Text("Use Settings to configure Sensitivity and Trigger Mode.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 20)
        }
    }
    
    func keyCodeToName(_ code: CGKeyCode) -> String {
        switch code {
        case 49: return "SPACE"
        case 36: return "ENTER"
        case 123: return "LEFT"
        case 124: return "RIGHT"
        case 126: return "UP"
        case 125: return "DOWN"
        default: return "CODE: \(code)"
        }
    }
}

// Invisible view to capture key input
struct KeyReaderView: NSViewRepresentable {
    @Binding var active: Bool
    var onKey: (CGKeyCode) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyInputNSView()
        view.onKey = onKey
        view.activeBinding = $active
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? KeyInputNSView else { return }
        view.activeBinding = $active
        if active {
            DispatchQueue.main.async {
                view.window?.makeFirstResponder(view)
            }
        }
    }
    
    class KeyInputNSView: NSView {
        var onKey: ((CGKeyCode) -> Void)?
        var activeBinding: Binding<Bool>?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            guard let active = activeBinding?.wrappedValue, active else {
                super.keyDown(with: event)
                return
            }
            onKey?(event.keyCode)
        }
    }
}
