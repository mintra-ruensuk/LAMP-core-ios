// mindLAMPWatch Extension

import Foundation
import HealthKit

class LMWatchWorkoutManager {
    
    let motionManager = LMWatchSensorManager()
    let healthStore = HKHealthStore()
    
    var session: HKWorkoutSession?
    
    init() {
    }
    
    func startWorkout() {
        if (session != nil) {
            return
        }
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .running
        workoutConfiguration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        if #available(watchOS 6.0, *) {
            session?.startActivity(with: Date())
        } else {
            healthStore.start(session!)
        }
        motionManager.startUpdates()
        
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(stopSensors), userInfo: nil, repeats: false)
    }
    
    @objc func stopSensors() {
        self.stopWorkout()
    }
    
    func stopWorkout() {
        
        if (session == nil) {
            return
        }
        
        motionManager.stopUpdates()
        
        if #available(watchOS 6.0, *) {
            session?.stopActivity(with: Date())
        } else {
            healthStore.end(session!)
        }
        session = nil
    }
}
