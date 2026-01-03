import Foundation
import Combine
import IOKit.hid

enum TriggerMode: String, CaseIterable, Identifiable {
    case instant
    case flap
    
    var id: String { self.rawValue }
}

class LidAngleMonitor: ObservableObject {
    @Published var currentAngle: Double = 0.0
    @Published var previousAngle: Double = 0.0
    @Published var jumpTriggered: Bool = false
    
    // Settings (Persistent)
    @Published var jumpThreshold: Double {
        didSet { UserDefaults.standard.set(jumpThreshold, forKey: "jumpThreshold") }
    }
    @Published var triggerMode: TriggerMode {
        didSet { UserDefaults.standard.set(triggerMode.rawValue, forKey: "triggerMode") }
    }
    
    // Live Diagnostics
    @Published var currentDelta: Double = 0.0
    
    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    private var timer: Timer?
    
    // Flap Logic State
    private var lastSignificantMoveTime: Date = Date.distantPast
    private var lastSignificantDirection: Int = 0 // 1 = Opening, -1 = Closing
    
    // Throttling
    private var lastTriggerCheckTime: Date = Date()
    private var angleAtLastTriggerCheck: Double = 0.0
    
    init() {
        // Load Defaults
        let savedThreshold = UserDefaults.standard.double(forKey: "jumpThreshold")
        // Default to 4.0 if not set (checking for 0 is safe as threshold needs to be positive)
        self.jumpThreshold = savedThreshold > 0 ? savedThreshold : 4.0
        
        if let savedModeRaw = UserDefaults.standard.string(forKey: "triggerMode"),
           let mode = TriggerMode(rawValue: savedModeRaw) {
            self.triggerMode = mode
        } else {
            self.triggerMode = .flap // Default to Flap
        }
        
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        setupHIDManager()
        // Poll at 60Hz
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateAngle()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        if let device = device {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        if let manager = manager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }
    
    private func setupHIDManager() {
        print("[LidAngleMonitor] Setting up HID Manager...")
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = manager else { 
            print("[LidAngleMonitor] Failed to create HID Manager")
            return 
        }
        
        // Matching Dictionary
        let matchingDict: [String: Any] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDDeviceUsagePageKey: 0x0020,
            kIOHIDDeviceUsageKey: 0x008A
        ]
        
        IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            print("[LidAngleMonitor] No matching devices found")
            return
        }
        
        print("[LidAngleMonitor] Found \(devices.count) potential devices")
        
        // Iterate to find the working one
        for (index, candidate) in devices.enumerated() {
            let res = IOHIDDeviceOpen(candidate, IOOptionBits(kIOHIDOptionsTypeNone))
            if res == kIOReturnSuccess {
                // Test read
                var report = [UInt8](repeating: 0, count: 8)
                var reportLength = CFIndex(report.count)
                
                let readRes = IOHIDDeviceGetReport(candidate, kIOHIDReportTypeFeature, 1, &report, &reportLength)
                
                if readRes == kIOReturnSuccess && reportLength >= 3 {
                    print("[LidAngleMonitor] Device \(index) VALID. Using this sensor.")
                    self.device = candidate
                    // Keep it open
                    return
                } else {
                    print("[LidAngleMonitor] Device \(index) open success but read failed (res: \(readRes)). Closing.")
                    IOHIDDeviceClose(candidate, IOOptionBits(kIOHIDOptionsTypeNone))
                }
            } else {
                print("[LidAngleMonitor] Device \(index) failed to open.")
            }
        }
        
        print("[LidAngleMonitor] ERROR: Could not find a working Lid Angle Sensor among candidates.")
    }
    
    private func updateAngle() {
        guard let device = device else {
            if manager != nil { setupHIDManager() }
            return
        }
        
        var report = [UInt8](repeating: 0, count: 8)
        var reportLength = CFIndex(report.count)
        
        let res = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 1, &report, &reportLength)
        
        if res == kIOReturnSuccess && reportLength >= 3 {
            let rawValue = UInt16(report[1]) | (UInt16(report[2]) << 8)
            let angle = Double(rawValue)
            
            // Initialization Check
            if previousAngle == 0 && currentAngle == 0 {
                previousAngle = angle
                currentAngle = angle
                angleAtLastTriggerCheck = angle
                return
            }
            
            // UI Update (Fast)
            previousAngle = currentAngle
            currentAngle = angle
            
            // Trigger Logic (Throttled - 100ms)
            let now = Date()
            if now.timeIntervalSince(lastTriggerCheckTime) >= 0.1 {
                let delta = angle - angleAtLastTriggerCheck
                currentDelta = delta // Publish for UI
                
                checkTrigger(delta: delta)
                
                angleAtLastTriggerCheck = angle
                lastTriggerCheckTime = now
            }
        }
    }
    
    private func checkTrigger(delta: Double) {
        switch triggerMode {
        case .instant:
            // Absolute delta > threshold
            if abs(delta) > jumpThreshold {
                triggerJump()
            }
            
        case .flap:
            // Need consecutive movements in opposite directions within 500ms
            // Each movement must exceed threshold
            
            let direction = delta > 0 ? 1 : -1
            if abs(delta) > jumpThreshold {
                let now = Date()
                
                // Check if this is a reversal of a recent significant move
                if lastSignificantDirection != 0 && 
                   lastSignificantDirection != direction && 
                   now.timeIntervalSince(lastSignificantMoveTime) < 0.5 {
                    
                    triggerJump()
                    // Reset to avoid double triggering on same flap
                    lastSignificantDirection = 0 
                } else {
                    // Record this move
                    lastSignificantDirection = direction
                    lastSignificantMoveTime = now
                }
            }
        }
    }
    
    private func triggerJump() {
        print("Jump Triggered! Mode: \(triggerMode)")
        jumpTriggered = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.jumpTriggered = false
        }
    }
}
