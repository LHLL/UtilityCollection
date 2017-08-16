//
//  DeviceStatusMonitor.swift
//  UtilityCollection
//
//  Created by Xu, Jay on 8/15/17.
//  Copyright © 2017 Xu, Jay. All rights reserved.
//

import UIKit
import CoreMotion

enum OrientationStatus{
    case Portrait, Landscape, Locked
}

class DeviceStatusMonitor {
    
    static let shared = DeviceStatusMonitor()
    
    //MARK:Private properties
    var status:OrientationStatus = .Portrait
    private lazy var containerVC:UIViewController? = {
        let root = UIApplication.shared.keyWindow?.rootViewController
        guard let top = root else{return nil}
        guard !(top is UINavigationController) else {
            return (top as! UINavigationController).topViewController
        }
        guard !(top is UITabBarController) else {
            return (top as! UITabBarController).selectedViewController
        }
        return top
    }()
    private let device = UIDevice.current
    private lazy var meter: CMMotionManager = {
        let m = CMMotionManager()
        m.accelerometerUpdateInterval = 0.5
        return m
    }()
    
    //In case some one forgets to use singleton
    private init(){}
    
    //This method should be used in App Delegate applicationDidBecomeActive
    func startMonitoringDeviceOritation(){
        if let s = getSupportedOritation() {
            status = s
        }
        checkRotationLockStatus()
    }
    //This method should be used in App Delegate applicationWillResignActive
    func stopMonitoringDeviceOritation(){
        device.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.UIDeviceOrientationDidChange,
                                                  object: nil)
    }
    
    //MARK:Private Utility methods
    @objc private func orientationHandler(){
        if let s = checkOrientation() {
            status = s
        }
    }
    
    private func checkOrientation()->OrientationStatus?{
        if UIDeviceOrientationIsPortrait(device.orientation) {
            return .Portrait
        }else if UIDeviceOrientationIsLandscape(device.orientation) {
            return .Landscape
        }
        return nil
    }
    
    private func startUpdateingStatus(){
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationHandler),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange,
                                               object: nil)
        device.beginGeneratingDeviceOrientationNotifications()
    }
    
    private func checkRotationLockStatus(){
        meter.startAccelerometerUpdates( to: OperationQueue() ) {[unowned self] angle, _ in
            guard angle != nil else{return}
            guard abs(angle!.acceleration.x) > 0.85 else{return}
            guard let s = self.checkOrientation() else{return}
            if s == self.status {
                self.status = .Locked
                self.handleRotationLocked()
            }else{
                self.startUpdateingStatus()
            }
            self.meter.stopAccelerometerUpdates()
        }
    }
    
    private func handleRotationLocked(){
        guard self.containerVC?.presentedViewController == nil else{
            return
        }
        let alert = UIAlertController(title: "Device Rotation Locked!",
                                      message: "We suggest you to shoot video on landscape mode for better quality, please enable device roation function using switch on top of volum button.",
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK",style: .cancel,handler: nil)
        alert.addAction(cancel)
        DispatchQueue.main.async {
            self.containerVC?.present(alert,animated: true,completion: nil)
        }
    }
    //Reading properties from plist
    private func getSupportedOritation()->OrientationStatus?{
        var myDict: NSDictionary?
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist") else {return nil}
        myDict = NSDictionary(contentsOfFile: path)
        guard let dict = myDict else{return nil}
        guard let orientations = dict["UISupportedInterfaceOrientations"] as? [String] else{return nil}
        return orientations.contains("UIInterfaceOrientationPortrait") ? .Portrait : .Landscape
    }
}
