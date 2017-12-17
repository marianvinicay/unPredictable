//
//  MVAPopup.swift
//  unPredictable
//
//  Created by Majo on 09/12/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

#if os(iOS)
import PopupDialog

class MVAPopup {
    class func customiseAppeareance() {
        // Customize dialog appearance
        let pv = PopupDialogDefaultView.appearance()
        pv.titleFont    = UIFont.boldSystemFont(ofSize: 25.0)
        pv.titleColor   = .white
        pv.messageFont  = UIFont.systemFont(ofSize: 0.0)
        
        // Customize the container view appearance
        let pcv = PopupDialogContainerView.appearance()
        pcv.backgroundColor = UIColor(red:0.29, green:0.29, blue:0.29, alpha:1.00)//UIColor(red:0.16, green:0.17, blue:0.21, alpha:1.00)
        pcv.cornerRadius    = 13
        pcv.shadowEnabled   = false
        
        // Customize cancel button appearance
        let cb = PopupDialogButton.appearance()//CancelButton.appearance()
        cb.titleFont = UIFont.systemFont(ofSize: 24.0)
        cb.titleColor     = .white
        cb.buttonColor    = UIColor(red:0.29, green:0.29, blue:0.29, alpha:1.00)
        cb.buttonHeight   = 300
        cb.separatorColor = .lightText
    }
    
    class func create(withTitle title: String, andMessage message: String?) -> PopupDialog {
        let dialog = PopupDialog(title: title, message: message, image: nil, buttonAlignment: .horizontal, transitionStyle: .bounceDown, preferredWidth: 340, gestureDismissal: false, hideStatusBar: true, completion: nil)
        
        return dialog
    }
    
    class func addAction(toPopup dialog: PopupDialog, withTitle title: String, _ action: @escaping ()->Void) {
        let btt = PopupDialogButton(title: title, action: action)
        dialog.addButton(btt)
    }
}
#elseif os(macOS)
    import AppKit
    
    class MVAPopup {
        class func create(withTitle title: String, andMessage message: String?) -> NSAlert {
            let dialog = NSAlert()
            dialog.messageText = title
            dialog.informativeText = message ?? ""
            dialog.alertStyle = .informational
            
            return dialog
        }
        
        class func addAction(toPopup dialog: NSAlert, withTitle title: String, shouldHighlight highlight: Bool = false) {
            let btt = dialog.addButton(withTitle: title)
            btt.keyEquivalent = ""
            if highlight {
                btt.keyEquivalent = "\r"
            }
        }
    }
#endif
