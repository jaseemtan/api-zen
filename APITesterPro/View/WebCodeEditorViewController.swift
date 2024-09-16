//
//  WebCodeEditorViewController.swift
//  APITesterPro
//
//  Created by Jaseem V V on 15/09/24.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import Foundation
import UIKit
import WebKit

extension Notification.Name {
    static let editorTextDidChange = Notification.Name("editor-text-did-change")
}

enum EditorTheme {
    case light
    case dark
}

class WebCodeEditorViewController: UIViewController {
    var text: String?  // Editor content
    var mode: PostRequestBodyMode = .json
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var doneBtn: UIButton!
    private let nc = NotificationCenter.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.debug("webeditor: view did load")
        self.initUI()
        self.initEvents()
    }
    
    func initUI() {
        
    }
    
    func initEvents() {
        if #available(iOS 17.0, *) {
            self.registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { (self: Self, previousTraitCollection: UITraitCollection) in
                Log.debug("register for trait changes")
                if self.traitCollection.userInterfaceStyle == .light {
                    // Code to execute in light mode
                    print("App switched to light mode")
                } else {
                    // Code to execute in dark mode
                    print("App switched to dark mode")
                }
            })
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        Log.debug("trait collection did change")
    }
    
    func initWebView() {
        
    }
    
    func initMessageHandler() {
        
    }
    
    func getUserScript() {
        
    }
    
    func getEditorText(complete: () -> String) {
        
    }
    
    func executeJavaScriptFn(fnName: String, params: Dictionary<String, Any>, completion: () -> Void) {
        
    }
    
    func getCurrentEditorTheme() -> EditorTheme {
        return .light
    }
    
    func updateEditorText(_ text: String) {
        
    }
    
    func updateEditorMode(_ mode: String) {
        
    }
    
    func updateTheme(_ theme: EditorTheme) {
        
    }
    
    @IBAction func cancelBtnDidTap(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}
