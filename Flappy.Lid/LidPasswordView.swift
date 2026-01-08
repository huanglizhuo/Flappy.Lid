import SwiftUI

struct LidPasswordView: View {
    @ObservedObject var gameEngine: GameViewModel
    @ObservedObject var lidMonitor: LidAngleMonitor
    @StateObject var passwordManager = LidPasswordManager.shared
    @State private var isEditingPassword = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Top Header
                ZStack {
                    // Centered Title
                    Text("LID PASSWORD")
                        .font(.flappy(size: 40))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                        
                    // Buttons
                    HStack {
                        Button(action: {
                            withAnimation {
                                gameEngine.appMode = .selecting
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .padding()
                }
                .padding(.top, 20)
                
                // Main Visualization
                ZStack {
                    // Border Ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 180, height: 160)
                    
                    // State Logic
                    if passwordManager.state == .monitoring {
                         Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                    .scaleEffect(1.1)
                                    .opacity(0.5)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: passwordManager.state)
                            )
                    }
                    
                    VStack(spacing: 16) {
                        Image(systemName: "lock.laptopcomputer")
                            .font(.system(size: 80))
                            .foregroundColor(statusColor)
                        
                        Text(statusText)
                            .font(.flappy(size: 24))
                            .foregroundColor(statusColor)
                        
                        if passwordManager.state == .monitoring {
                            Text("Open Count: \(passwordManager.openCount)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Active monitor
                Text("Current Angle: \(Int(lidMonitor.currentAngle))°")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top)
                // Configuration
                LidPasswordSettingsButton(passwordManager: passwordManager)
                
                // Minimize Button
                Button(action: {
                    StatusBarManager.shared.minimizeToMenuBar()
                }) {
                    HStack {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                        Text("MINIMIZE TO MENU BAR")
                    }
                    .font(.flappy(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(10)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 10)
                Spacer()
                Text("Instructions: Close lid below \(Int(passwordManager.maxActivationAngle))°. -> Quickly open/close \(passwordManager.requiredCount) times within 3s")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.all, 10)
            }
        }
        .onAppear {
            passwordManager.startMonitoring(lidMonitor: lidMonitor)
        }
        .onDisappear {
            passwordManager.stopMonitoring()
        }
    }
    
    var statusColor: Color {
        switch passwordManager.state {
        case .idle: return .gray
        case .monitoring: return .blue
        case .success: return .green
        }
    }
    
    var statusText: String {
        switch passwordManager.state {
        case .idle: return "WAITING..."
        case .monitoring: return "LISTENING"
        case .success: return "UNLOCKED!"
        }
    }
}

struct LidPasswordSettingsButton: View {
    @ObservedObject var passwordManager: LidPasswordManager
    @State private var isEditingPassword = false
    
    var body: some View {
        Button(action: { isEditingPassword = true }) {
            HStack {
                Image(systemName: "lock.rectangle")
                Text(passwordManager.targetPassword.isEmpty ? "SET PASSWORD" : "CHANGE PASSWORD")
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isEditingPassword) {
            VStack(spacing: 20) {
                Text("Enter Unlock Password")
                    .font(.headline)
                Text("(ASCII Characters Only)")
                    .font(.caption)
                    .foregroundColor(.gray)
                SecureField("Password", text: $passwordManager.targetPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                Divider()
                
                Stepper("Trigger Count: \(passwordManager.requiredCount)", value: $passwordManager.requiredCount, in: 1...10)
                    .frame(width: 200)
                
                Divider()
                
                Toggle("Auto Press Enter", isOn: $passwordManager.isAutoEnterEnabled)
                    .toggleStyle(.switch)
                     .frame(width: 200)
                
                Button("Done") { isEditingPassword = false }
            }
            .padding()
        }
    }
}

#Preview {
    LidPasswordView(
        gameEngine: GameViewModel(),
        lidMonitor: LidAngleMonitor()
    )
    .background(Color(red: 0.1, green: 0.1, blue: 0.2))
}
