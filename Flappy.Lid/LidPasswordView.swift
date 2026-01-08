import SwiftUI

struct LidPasswordView: View {
    @ObservedObject var gameEngine: GameViewModel
    @ObservedObject var lidMonitor: LidAngleMonitor
    @StateObject var passwordManager = LidPasswordManager.shared
    @State private var isEditingPassword = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                // Top Bar
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
                
                // Title
                Text("LID PASSWORD")
                    .font(.flappy(size: 40))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                Spacer()
                
                // Main Visualization
                ZStack {
                    // Border Ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 250, height: 250)
                    
                    // State Logic
                    if passwordManager.state == .monitoring {
                         Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 230, height: 230)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                    .scaleEffect(1.1)
                                    .opacity(0.5)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: passwordManager.state)
                            )
                    }
                    
                    VStack(spacing: 15) {
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
                
                Spacer()
                
                // Configuration
                Button(action: { isEditingPassword = true }) {
                    HStack {
                        Image(systemName: "asterisk.rectangle")
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
                        SecureField("Password", text: $passwordManager.targetPassword)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                        
                        Divider()
                        
                        Stepper("Trigger Count: \(passwordManager.requiredCount)", value: $passwordManager.requiredCount, in: 1...10)
                            .frame(width: 200)
                        
                        Button("Done") { isEditingPassword = false }
                    }
                    .padding()
                }
                
               Text("Instructions:\n1. Close lid below \(Int(passwordManager.maxActivationAngle))°.\n2. Quickly open/close \(passwordManager.requiredCount) times within 3s.\n(Open > 4° delta)")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            passwordManager.startMonitoring(lidMonitor: lidMonitor)
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
