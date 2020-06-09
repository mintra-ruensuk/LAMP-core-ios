// mindLAMP

import WatchConnectivity

class LMWatchSessionManager: NSObject, WCSessionDelegate {
    
    static let kMessage:String = "StartSensingData"
    
    static let sharedManager = LMWatchSessionManager()
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    private var validSession: WCSession? {
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }
    
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        if session.activationState == .activated {
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive: \(session)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        self.session?.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["request"] as? String == "version" {
            replyHandler(["version" : "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "No version")"])
        }
    }
    
    func startWatchSensors() {
        self.updateApplicationContext()
    }
    
    func updateApplicationContext() {
        let context = [String: AnyObject]()
        do {
            try LMWatchSessionManager.sharedManager.updateApplicationContext(applicationContext: context)
        } catch {
            print("Error updating application context")
        }
    }
}

extension LMWatchSessionManager {
    func updateApplicationContext(applicationContext: [String : AnyObject]) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
            } catch let error {
                throw error
            }
        }
    }
}

extension LMWatchSessionManager {
    private var validReachableSession: WCSession? {
        if let session = validSession, session.isReachable {
            return session
        }
        return nil
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : Any],
                 replyHandler: ([String : AnyObject]) -> Void) {
        LMSensorManager.shared.createSensorObjectsFromWatchData(dataMessage: message)
    }
}
