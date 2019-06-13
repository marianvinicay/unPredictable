//
//  MVAPopup.swift
//  unPredictable
//
//  Created by Marian Vinicay on 09/12/2017.
//  Copyright © 2017 Marvin. All rights reserved.
//

#if os(iOS)
import UIKit

class MVAPopup: UIAlertController {
    
    class func create(withMessage message: String) -> MVAPopup {
        let dialog = MVAPopup(title: message, message: nil, preferredStyle: .alert)
        dialog.view.tintColor = .white
        let attributedString = NSAttributedString(string: message, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.white
            ])
        dialog.setValue(attributedString, forKey: "attributedTitle")
        
        let subview = (dialog.view.subviews.first?.subviews.first?.subviews.first!)! as UIView
        subview.layer.cornerRadius = 13
        subview.backgroundColor = UIColor(red:0.29, green:0.29, blue:0.29, alpha:1.00)
        
        return dialog
    }
    
    func addAction(withTitle title: String, type: UIAlertAction.Style, action: ((UIAlertAction)->Void)?) {
        self.addAction(UIAlertAction(title: title, style: type, handler: action))
    }
    
    class func createOKPopup(withMessage msg: String) -> MVAPopup {
        let popup = MVAPopup.create(withMessage: msg)
        popup.addAction(withTitle: "OK", type: .default, action: nil)
        
        return popup
    }
    
    func present() {
        DispatchQueue.main.async {
            let win = UIWindow(frame: UIScreen.main.bounds)
            let vc = UIViewController()
            vc.view.backgroundColor = .clear
            win.rootViewController = vc
            win.windowLevel = UIWindow.Level.alert + 1
            win.makeKeyAndVisible()
            vc.present(self, animated: true, completion: nil)
        }
    }
}
#elseif os(macOS)
import AppKit

class MVAPopup: NSAlert {
    class func create(withMessage msg: String) -> MVAPopup {
        let dialog = MVAPopup()
        dialog.messageText = msg
        dialog.informativeText = ""
        dialog.alertStyle = .informational
        
        return dialog
    }
    
    func addAction(withTitle title: String, shouldHighlight highlight: Bool = false) {
        let btt = self.addButton(withTitle: title)
        btt.keyEquivalent = ""
        if highlight {
            btt.keyEquivalent = "\r"
        }
    }
    
    class func createOKPopup(withMessage msg: String) -> MVAPopup {
        let alert = MVAPopup()
        alert.messageText = msg
        alert.informativeText = ""
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        return alert
    }
    
    func present() {
        DispatchQueue.main.async { self.runModal() }
    }
}
#endif
