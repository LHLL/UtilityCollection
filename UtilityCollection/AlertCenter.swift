//
//  AlertCenter.swift
//
//
//  Created by Xu, Jay on 8/15/17.
//  Copyright © 2017 Wells Fargo. All rights reserved.
//

import UIKit

struct AlertCenter {
    
    static var containerVC:UIViewController? = {
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
    static private var errors = [String]()
    static private var titles = [String]()
    static private var completions = [(()->Void)]()
    static private var existingAlert:UIAlertController? {
        didSet {
            guard existingAlert == nil else {
                return
            }
            throwAlerts(titles: titles, messages: errors, completions: completions)
        }
    }
    
    static func throwAnAlert(title:String,
                             message: String,
                             completion:(()->Void)?) {
        if existingAlert == nil {
            existingAlert = containerVC?.presentedViewController as? UIAlertController
        }
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            completion?()
            if self.existingAlert != nil {
                self.existingAlert = nil
            }
        })
        errors.append(message)
        titles.append(title)
        alertVC.addAction(action)
        guard existingAlert == nil else{return}
        existingAlert = alertVC
        guard errors.count <= 1 else {return}
        DispatchQueue.main.async {
            containerVC?.present(alertVC, animated: true, completion: nil)
            self.errors.removeFirst()
            self.titles.removeFirst()
        }
    }
    
    static func throwAlerts(titles:[String],
                            messages: [String],
                            completions:[(()->Void)]?) {
        errors = messages
        self.titles = titles
        if completions != nil {
            self.completions = completions!
        }
        if let error = messages.first {
            let alertVC = UIAlertController(title: titles.first, message: error, preferredStyle: .alert)
            var next:UIAlertAction?
            guard messages.count != 1 else {
                next = UIAlertAction(title: "OK", style: .cancel, handler: {(action) in
                    if self.completions.count > 0 {
                        self.completions.last!()
                    }
                })
                alertVC.addAction(next!)
                containerVC?.present(alertVC, animated: true, completion: nil)
                self.titles.removeAll()
                self.errors.removeAll()
                self.completions.removeAll()
                return
            }
            next = UIAlertAction(title: "Next",style: .default,handler: { (action) in
                if self.completions.count > 0 {
                    let result = self.completions.removeFirst()
                    result()
                }
                self.errors.removeFirst()
                self.titles.removeFirst()
                
                DispatchQueue.main.async {
                    self.throwAlerts(titles: self.titles,
                                     messages: self.errors,
                                     completions: self.completions)
                }
            })
            alertVC.addAction(next!)
            DispatchQueue.main.async {
                containerVC?.present(alertVC,
                                     animated: true,
                                     completion: nil)
            }
        }
    }
}
