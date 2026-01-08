import SwiftUI

struct LidPasswordView: View {
    @ObservedObject var gameEngine: GameViewModel
    @ObservedObject var lidMonitor: LidAngleMonitor
    @StateObject var passwordManager = LidPasswordManager.shared
    @State private var isEditingPassword = false
    
    var body: some View {

        GeometryReader { geometry in
            let minDim = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                VStack(spacing: 0) {
                    // 1. Header
                    ZStack {
                        // Centered Title
                        Text("LID PASSWORD")
                            .font(.flappy(size: minDim * 0.08))
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
                                    .font(.system(size: minDim * 0.06))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .frame(height: geometry.size.height * 0.15)
                    
                    Spacer()
                    
                    // 2. Main Visualization
                    VStack(spacing: 16) {
                        ZStack {
                            // Border Ring
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                .frame(width: minDim * 0.4, height: minDim * 0.4)
                            
                            // State Logic
                            if passwordManager.state == .monitoring {
                                 Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: minDim * 0.25, height: minDim * 0.25)
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
                                    .font(.system(size: minDim * 0.15))
                                    .foregroundColor(statusColor)
                                
                                Text(statusText)
                                    .font(.flappy(size: minDim * 0.05))
                                    .foregroundColor(statusColor)
                                
                                if passwordManager.state == .monitoring {
                                    Text("Open Count: \(passwordManager.openCount)")
                                        .font(.system(size: minDim * 0.03))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Active monitor
                        Text("Current Angle: \(Int(lidMonitor.currentAngle))°")
                            .font(.system(size: minDim * 0.03))
                            .foregroundColor(.gray)
                        
                        // Configuration
                        LidPasswordSettingsButton(passwordManager: passwordManager)
                            .scaleEffect(minDim * 0.002) // Slight scaling for controls
                    }
                    
                    Spacer()
                    
                    // 3. Minimize Button
                    Button(action: {
                        StatusBarManager.shared.minimizeToMenuBar()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                            Text("MINIMIZE TO MENU BAR")
                        }
                        .font(.flappy(size: minDim * 0.03))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 10)
                    
                    // 4. Instructions
                    Text("Instructions: Close lid below \(Int(passwordManager.maxActivationAngle))°. -> Quickly open/close \(passwordManager.requiredCount) times within 3s")
                        .font(.system(size: minDim * 0.025))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                        .padding(.horizontal)
                }
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
