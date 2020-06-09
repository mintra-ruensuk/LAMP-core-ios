// mindLAMPWatch Extension

import Foundation
import CoreMotion
import WatchKit
import os.log

let kAccelerometerDataIdentifier: String = "AccelerometerData"
let kGravityDataIdentifier: String = "GravityData"
let kRotationDataIdentifier: String = "RotationData"
let kAttitudeDataIdentifier: String = "AttitudeData"

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}

class LMWatchSensorManager {
    
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    let sampleInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)
    
    var gravityStr = ""
    var rotationRateStr = ""
    var userAccelStr = ""
    var attitudeStr = ""
    
    var recentDetection = false
    
    var garvityDataBuffer:Array<GravityData>  = Array<GravityData>()
    var accelerometerDataBuffer:Array<AccelerometerData>  = Array<AccelerometerData>()
    var rotationDataBuffer:Array<RotationData>  = Array<RotationData>()
    var attitudeDataBuffer:Array<AttitudeData>  = Array<AttitudeData>()
    
    init() {
        queue.maxConcurrentOperationCount = 1
        queue.name = "LMWatchSensorManagerQueue"
    }
    
    func startUpdates() {
        if !motionManager.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return
        }
        
        os_log("Start Updates");
        
        motionManager.deviceMotionUpdateInterval = sampleInterval
        motionManager.startDeviceMotionUpdates(to: queue) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }
            
            if deviceMotion != nil {
                self.processDeviceMotion(deviceMotion!)
            }
        }
    }
    
    func stopUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
        self.sendLatestDataToPhone()
    }
    
    func processDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        
        let currentTime:Double = Date().timeIntervalSince1970
        
        let userAccelData = AccelerometerData()
        userAccelData.timestamp = Int64(currentTime*1000)
        userAccelData.x = deviceMotion.userAcceleration.x
        userAccelData.y = deviceMotion.userAcceleration.y
        userAccelData.z = deviceMotion.userAcceleration.z
        userAccelData.eventTimestamp = Int64(currentTime*1000)
        accelerometerDataBuffer.append(userAccelData)
        
        let gravityData = GravityData()
        gravityData.timestamp = Int64(currentTime*1000)
        gravityData.x = deviceMotion.userAcceleration.x
        gravityData.y = deviceMotion.userAcceleration.y
        gravityData.z = deviceMotion.userAcceleration.z
        gravityData.eventTimestamp = Int64(currentTime*1000)
        garvityDataBuffer.append(gravityData)
        
        let rotationData = RotationData()
        rotationData.timestamp = Int64(currentTime*1000)
        rotationData.x = deviceMotion.userAcceleration.x
        rotationData.y = deviceMotion.userAcceleration.y
        rotationData.z = deviceMotion.userAcceleration.z
        rotationData.eventTimestamp = Int64(currentTime*1000)
        rotationDataBuffer.append(rotationData)
        
        let attitudeData = AttitudeData()
        attitudeData.timestamp = Int64(currentTime*1000)
        attitudeData.x = deviceMotion.userAcceleration.x
        attitudeData.y = deviceMotion.userAcceleration.y
        attitudeData.z = deviceMotion.userAcceleration.z
        attitudeData.eventTimestamp = Int64(currentTime*1000)
        attitudeDataBuffer.append(attitudeData)
        
        /*
         gravityStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
         deviceMotion.gravity.x,
         deviceMotion.gravity.y,
         deviceMotion.gravity.z)
         
         userAccelStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
         deviceMotion.userAcceleration.x,
         deviceMotion.userAcceleration.y,
         deviceMotion.userAcceleration.z)
         
         rotationRateStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
         deviceMotion.rotationRate.x,
         deviceMotion.rotationRate.y,
         deviceMotion.rotationRate.z)
         
         attitudeStr = String(format: "r: %.1f p: %.1f y: %.1f" ,
         deviceMotion.attitude.roll,
         deviceMotion.attitude.pitch,
         deviceMotion.attitude.yaw)
         
         let timestamp = Date().millisecondsSince1970
         ( os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@",
         String(timestamp),
         String(deviceMotion.gravity.x),
         String(deviceMotion.gravity.y),
         String(deviceMotion.gravity.z),
         String(deviceMotion.userAcceleration.x),
         String(deviceMotion.userAcceleration.y),
         String(deviceMotion.userAcceleration.z),
         String(deviceMotion.rotationRate.x),
         String(deviceMotion.rotationRate.y),
         String(deviceMotion.rotationRate.z),
         String(deviceMotion.attitude.roll),
         String(deviceMotion.attitude.pitch),
         String(deviceMotion.attitude.yaw)) */
        
    }
    
    public func sendLatestDataToPhone() {
        var acclDict = accelerometerDataBuffer.last?.toDictionary()
        acclDict?["Identifier"] = kAccelerometerDataIdentifier
        if let messageDict =  acclDict {
            LMPhoneSessionManager.sharedManager.sendMessage(message: messageDict)
        }
        
        var gravityDict = garvityDataBuffer.last?.toDictionary()
        gravityDict?["Identifier"] = kGravityDataIdentifier
        if let messageDict =  gravityDict {
            LMPhoneSessionManager.sharedManager.sendMessage(message: messageDict)
        }
        
        var rotationDict = rotationDataBuffer.last?.toDictionary()
        rotationDict?["Identifier"] = kRotationDataIdentifier
        if let messageDict =  rotationDict {
            LMPhoneSessionManager.sharedManager.sendMessage(message: messageDict)
        }
        
        var attitudeDict = attitudeDataBuffer.last?.toDictionary()
        attitudeDict?["Identifier"] = kAttitudeDataIdentifier
        if let messageDict =  rotationDict {
            LMPhoneSessionManager.sharedManager.sendMessage(message: messageDict)
        }
    }
}
