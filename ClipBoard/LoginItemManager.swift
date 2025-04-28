import Foundation
import ServiceManagement

class LoginItemManager {
    static let shared = LoginItemManager()
    private let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.yourcompany.ClipBoard"
    private var loginItem: SMAppService?
    
    private init() {
        loginItem = SMAppService.loginItem(identifier: bundleIdentifier)
    }
    
    func enableLoginItem() -> Bool {
        do {
            try loginItem?.register()
            return true
        } catch {
            print("Failed to enable login item: \(error)")
            return false
        }
    }
    
    func disableLoginItem() -> Bool {
        do {
            try loginItem?.unregister()
            return true
        } catch {
            print("Failed to disable login item: \(error)")
            return false
        }
    }
    
    func isLoginItemEnabled() -> Bool {
        return loginItem?.status == .enabled
    }
} 
