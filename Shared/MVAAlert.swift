//
//  MVAAlert.swift
//  unPredictable
//
//  Created by Majo on 20/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//
#if os(iOS) || os(tvOS)
    import UIKit

    class MVAAlert {
        class func new(withTitle title: String?, andMessage msg: String?) -> UIAlertController {
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            return alert
        }
    
        class func present(_ alert: UIAlertController, inViewController vc: UIViewController? = nil) {
            if vc != nil {
                vc!.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
#elseif os(macOS)
    import AppKit
    
    class MVAAlert {
        class func new(withTitle title: String?, andMessage msg: String?) -> NSAlert {
            let alert = NSAlert()
            alert.messageText = title ?? ""
            alert.informativeText = msg ?? ""
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: "OK")
            return alert
        }
        
        class func present(_ alert: NSAlert) {
            DispatchQueue.main.async {
                alert.beginSheetModal(for: NSApplication.shared.mainWindow!, completionHandler: nil)
            }
        }
    }
#endif
