// mindLAMPWatch Extension

import UIKit
import WatchConnectivity

protocol SessionManagerDelegate: class {
    func updateUI(messgae: String)
}

class LMPhoneSessionManager: NSObject {
    static let sharedManager = LMPhoneSessionManager()
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    
    weak var delegate: SessionManagerDelegate?
    
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
}

extension LMPhoneSessionManager: WCSessionDelegate {
    
    func sessionReachabilityDidChange(_ session: WCSession) {
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        LMWatchWorkoutManager().startWorkout()
    }
}


extension LMPhoneSessionManager {
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
       DispatchQueue.main.async {
            LMWatchWorkoutManager().startWorkout()
        }
    }
}

extension LMPhoneSessionManager {
    
    private var validReachableSession: WCSession? {
        if let session = session, session.isReachable {
            return session
        }
        return nil
    }
    
    func sendMessage(message: [String : Any], replyHandler: (([String : Any]) -> Void)? = nil,
                     errorHandler: ((Error) -> Void)? = nil) {
        validReachableSession?.sendMessage(message, replyHandler: { (response) in
        }, errorHandler: { (error) in
            print("Error sending message: %@", error)
        })
    }
}
