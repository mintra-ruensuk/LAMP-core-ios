//
//  ScreenSensor.swift
//  com.lamp.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/10/23.
//

import UIKit

struct Constants {
static let lockComplete: [UInt8] = [14, 6, 3, 74, 45, 49, 61, 60, 58, 28, 93, 49, 2, 25, 42, 2, 14, 10, 6, 19, 16, 75, 64, 79, 45, 56, 44, 13, 7, 21, 15, 17, 88, 69]
static let lockState: [UInt8] = [14, 6, 3, 74, 45, 49, 61, 60, 58, 28, 93, 49, 2, 25, 42, 2, 14, 10, 6, 19, 16, 75, 64, 79, 45, 56, 60, 22, 11, 17, 6]
}

extension Notification.Name {
    public static let actionLAMPScreen       = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN)
    public static let actionLAMPScreenStart  = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN_START)
    public static let actionLAMPScreenStop   = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN_STOP)
    public static let actionLampScreenSync   = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN_SYNC)
    public static let actionLampScreenSetLabel = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN_SET_LABEL)
    
    public static let actionLampScreenOn     = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN_ON)
    public static let actionLampScreenOff    = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN_OFF)
    public static let actionLampScreenLocked = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN_LOCKED)
    public static let actionLampScreenUnlocked  = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN_UNLOCKED)
    
    public static let actionLampScreenSyncCompletion  = Notification.Name(ScreenSensor.ACTION_LAMP_SCREEN_SYNC_COMPLETION)
}

public protocol ScreenObserver{
    func onScreenOn()
    func onScreenOff()
    func onScreenLocked()
    func onScreenUnlocked()
    func onScreenBrightnessChanged(data:ScreenBrightnessData)
}

public class ScreenSensor: LampSensorCore {
    
    public static let TAG = "LAMP::Screen"
    
    public static let ACTION_LAMP_SCREEN = "com.lampframework.ios.sensor.screen"
    public static let ACTION_LAMP_SCREEN_START = "com.lampframework.ios.sensor.screen.SENSOR_START"
    public static let ACTION_LAMP_SCREEN_STOP = "com.lampframework.ios.sensor.screen.SENSOR_STOP"
    public static let ACTION_LAMP_SCREEN_SET_LABEL = "com.lampframework.ios.sensor.screen.SET_LABEL"
    public static let EXTRA_LABEL = "label"
    public static let ACTION_LAMP_SCREEN_SYNC = "com.lampframework.ios.sensor.screen.SENSOR_SYNC"
    
    public static let ACTION_LAMP_SCREEN_SYNC_COMPLETION = "com.lampframework.ios.sensor.screeen.SENSOR_SYNC_COMPLETION"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
    public static let EXTRA_OBJECT_TYPE = "objectType"
    public static let EXTRA_TABLE_NAME  = "tableName"
    
    /**
     * Broadcasted event: screen is on
     */
    public static let ACTION_LAMP_SCREEN_ON = "com.lampframework.ios.sensor.screen.ACTION_LAMP_SCREEN_ON"
    
    /**
     * Broadcasted event: screen is off
     */
    public static let ACTION_LAMP_SCREEN_OFF = "com.lampframework.ios.sensor.screen.ACTION_LAMP_SCREEN_OFF"
    
    /**
     * Broadcasted event: screen is locked
     */
    public static let ACTION_LAMP_SCREEN_LOCKED = "com.lampframework.ios.sensor.screen.ACTION_LAMP_SCREEN_LOCKED"
    
    /**
     * Broadcasted event: screen is unlocked
     */
    public static let ACTION_LAMP_SCREEN_UNLOCKED = "com.lampframework.ios.sensor.screen.ACTION_LAMP_SCREEN_UNLOCKED"
    
    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_LAMP_TOUCH_CLICKED = "com.lampframework.ios.sensor.screen.ACTION_LAMP_TOUCH_CLICKED"

    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_LAMP_TOUCH_LONG_CLICKED = "com.lampframework.ios.sensor.screen.ACTION_LAMP_TOUCH_LONG_CLICKED"
    
    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_LAMP_TOUCH_SCROLLED_UP = "com.lampframework.ios.sensor.screen.ACTION_LAMP_TOUCH_SCROLLED_UP"
    
    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_LAMP_TOUCH_SCROLLED_DOWN = "com.lampframework.ios.sensor.screen.ACTION_LAMP_TOUCH_SCROLLED_DOWN"
    
    /**
     * Screen status: OFF = 0
     */
    public static let STATUS_SCREEN_OFF = 0
    
    /**
     * Screen status: ON = 1
     */
    public static let STATUS_SCREEN_ON = 1
    
    /**
     * Screen status: LOCKED = 2
     */
    public static let STATUS_SCREEN_LOCKED = 2
    
    /**
     * Screen status: UNLOCKED = 3
     */
    public static let STATUS_SCREEN_UNLOCKED = 3
    
    var screenBrigthnessObserver:NSObjectProtocol? = nil
    
    var timer:Timer? = nil
    
    var LAST_VALUE:Double = 0
    
    public var CONFIG = Config()
    
    public class Config:SensorConfig {
        public var sensorObserver:ScreenObserver? = nil
        
        public override init(){
            super.init()
            //dbPath = "aware_screen"
        }
        
        public func apply(closure:(_ config: ScreenSensor.Config ) -> Void ) -> Self {
            closure(self)
            return self
        }
    }
    
    public override convenience init() {
        self.init(ScreenSensor.Config())
    }
    
    public init(_ config:ScreenSensor.Config){
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
    }
    
    deinit {
        if let observer = self.screenBrigthnessObserver{
            self.notificationCenter.removeObserver(observer)
        }
    }
    
    var LAST_SCREEN_STATE = false
    
    public override func start() {
        
        let o = StringHelper(salt: "\(AppDelegate.self.description()), \(NSObject.self.description()), \(NSString.self.description()), \(NSArray.self.description())")
        let completekey = o.reveal(key: Constants.lockComplete)
        let statekey = o.reveal(key: Constants.lockState)
        setDeviceLockEventbserver(completekey, statekey)
        self.notificationCenter.post(name: .actionLAMPScreenStart, object: self)
        self.screenBrigthnessObserver = self.notificationCenter.addObserver(
            forName: UIScreen.brightnessDidChangeNotification, object: nil, queue: .main) { (notification) in
             self.screenBrightnessChanged()
                
            if UIScreen.main.brightness == 0.0 {
                if self.LAST_SCREEN_STATE == true {
                    self.screenOff()
                    self.LAST_SCREEN_STATE = false
                }
            }else{
                if self.LAST_SCREEN_STATE == false {
                    self.screenOn()
                    self.LAST_SCREEN_STATE = true
                }
            }
        }
    }
    
    public override func stop() {
        removeDeviceLockEventbserver()
        self.notificationCenter.post(name: .actionLAMPScreenStop,  object: self)
        if let observer = self.screenBrigthnessObserver {
            self.notificationCenter.removeObserver(observer)
            self.screenBrigthnessObserver = nil
        }
    }
    
    public override func sync(force: Bool = false) {
            self.notificationCenter.post(name: .actionLampScreenSync, object: self)
    }
    
    func setDeviceLockEventbserver(_ completekey: String, _ statekey: String) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        Unmanaged.passUnretained(self).toOpaque(),
                                        displayStatusChangedCallback,
                                        completekey as CFString,
                                        nil,
                                        .deliverImmediately)
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        Unmanaged.passUnretained(self).toOpaque(),
                                        displayStatusChangedCallback,
                                        statekey as CFString,
                                        nil,
                                        .deliverImmediately)
    }
    
    func removeDeviceLockEventbserver(){
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque(), nil, nil)
    }
    
    private let displayStatusChangedCallback: CFNotificationCallback = { _, cfObserver, cfName, _, _ in
        guard let lockState = cfName?.rawValue as String? else {
            return
        }
        let catcher = Unmanaged<ScreenSensor>.fromOpaque(UnsafeRawPointer(OpaquePointer(cfObserver)!)).takeUnretainedValue()
        catcher.displayStatusChanged(lockState)
    }
    
    private func displayStatusChanged(_ lockState: String) {
        //print(Date().timeIntervalSince1970, "lockState = \(lockState)")
        let o = StringHelper(salt: "\(AppDelegate.self.description()), \(NSObject.self.description()), \(NSString.self.description()), \(NSArray.self.description())")
        let completekey = o.reveal(key: Constants.lockComplete)
        if (lockState == completekey) {
            self.screenLocked()
        } else {
            self.screenUnlocked()
        }
        self.notificationCenter.post(name: .actionLAMPScreen, object: self)
    }
    var lastEventTimestamp:Double = 0
    func screenLocked(){
        let screenData = ScreenData()
        screenData.screenStatus = ScreenSensor.STATUS_SCREEN_LOCKED
        screenData.label = self.CONFIG.label
        if let engine = self.dbEngine {
            engine.save(screenData)
        }
        if self.CONFIG.debug { print(ScreenSensor.TAG, "locked") }
        if let observer = self.CONFIG.sensorObserver{
            observer.onScreenLocked()
        }
        self.notificationCenter.post(name: .actionLampScreenLocked, object: self)
        // set last event timestamp for ignore a screenUnlock event after a screenLock event
        lastEventTimestamp = Date().timeIntervalSince1970
        if let t = self.timer{
            t.invalidate()
            self.timer = nil
        }
    }
    
    func screenUnlocked(){
        let screenData = ScreenData()
        screenData.label = self.CONFIG.label
        if(lastEventTimestamp + 0.1 < Date().timeIntervalSince1970){
            screenData.screenStatus = ScreenSensor.STATUS_SCREEN_UNLOCKED
            if let engine = self.dbEngine {
                engine.save(screenData)
            }
            if self.CONFIG.debug { print(ScreenSensor.TAG, "unlocked")}
            if let observer = self.CONFIG.sensorObserver{
                observer.onScreenUnlocked()
            }
            self.notificationCenter.post(name: .actionLampScreenUnlocked, object: self)
            if self.timer == nil {
                self.timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true, block: { (timer) in
                    self.screenBrightnessChanged()
                })
                self.screenBrightnessChanged()
            }
        }
    }
    
    func screenOn(){
        let screenData = ScreenData()
        screenData.label = self.CONFIG.label
        screenData.screenStatus = ScreenSensor.STATUS_SCREEN_ON
        if let engine = self.dbEngine {
            engine.save(screenData)
        }
        if self.CONFIG.debug { print(ScreenSensor.TAG, "screen on")}
        if let observer = self.CONFIG.sensorObserver{
            observer.onScreenOn()
        }
        self.notificationCenter.post(name: .actionLampScreenOn, object: self)
    }
    
    func screenOff(){
        let screenData = ScreenData()
        screenData.label = self.CONFIG.label
        screenData.screenStatus = ScreenSensor.STATUS_SCREEN_OFF
        if let engine = self.dbEngine {
            engine.save(screenData)
        }
        if self.CONFIG.debug { print(ScreenSensor.TAG, "screen off")}
        if let observer = self.CONFIG.sensorObserver{
            observer.onScreenOff()
        }
        self.notificationCenter.post(name: .actionLampScreenOff, object: self)
    }
    
    func screenBrightnessChanged(){
        
        let brightness = Double(UIScreen.main.brightness)
        
        // print("gap",fabs(LAST_VALUE - brightness))
        if fabs(LAST_VALUE - brightness) > 0.1 {
            let data = ScreenBrightnessData()
            data.brightness = brightness
            data.label = self.CONFIG.label
            if let engine = self.dbEngine {
                if let observer = self.CONFIG.sensorObserver{
                    observer.onScreenBrightnessChanged(data: data)
                }
                engine.save(data)
            }
            LAST_VALUE = brightness
        }
    }
    
    public override func set(label:String) {
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionLampScreenSetLabel, object: self, userInfo: [ScreenSensor.EXTRA_LABEL:label])
    }
}
