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

enum EditorTheme: String {
    case light
    case dark
}

class WebCodeEditorViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    var text: String?  // Editor content
    var mode: PostRequestBodyMode = .json
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var navbarView: UIView!
    private let nc = NotificationCenter.default
    private let app = App.shared
    private var webView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.debug("webeditor: view did load")
        self.initUI()
        self.initEvents()
    }
    
    func initUI() {
        UI.disableDynamicFont(self.view)
        self.initWebView()
    }
    
    func initEvents() {
        if #available(iOS 17.0, *) {
            self.registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { (self: Self, previousTraitCollection: UITraitCollection) in
                Log.debug("register for trait changes")
                if self.traitCollection.userInterfaceStyle == .dark {
                    Log.debug("App switched to dark mode")
                    self.updateTheme(.dark)
                } else {
                    Log.debug("App switched to light mode")
                    self.updateTheme(.light)
                }
            })
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        Log.debug("trait collection did change")
        if (previousTraitCollection?.userInterfaceStyle == .dark) {
            Log.debug("App switched to dark mode --")
            self.updateTheme(.dark)
        } else {
            Log.debug("App switched to light mode --")
            self.updateTheme(.light)
        }
    }
    
    func initWebView() {
        self.updateTheme(self.app.getCurrentUIStyle() == .dark ? .dark : .light)
        self.webView = WKWebView(frame: .zero, configuration: self.initMessageHandler())
        if let webView = self.webView {
            webView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(webView)
            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
                webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
                webView.topAnchor.constraint(equalTo: self.navbarView.bottomAnchor, constant: 0),
                webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
            ])
        }
        self.webView?.navigationDelegate = self
        if let editorFile = Bundle.main.path(forResource: "editor", ofType: "html") {
            let htmlURL = URL(fileURLWithPath: editorFile)
            let baseURL = URL(fileURLWithPath: Bundle.main.bundlePath)
            self.webView?.loadFileURL(htmlURL, allowingReadAccessTo: baseURL)
        }
    }
    
    func initMessageHandler() -> WKWebViewConfiguration {
        let script = self.getUserScript()
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        let controller = WKUserContentController()
        controller.addUserScript(userScript)
        controller.add(self, name: "ob")
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        return config
    }
    
    func getUserScript() -> String {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "userscript", withExtension: "js") else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
    
    func setText(_ text: String) {
        self.text = text
        self.updateEditorText(text)
    }
    
    func setMode(_ mode: PostRequestBodyMode) {
        self.mode = mode
        self.updateEditorMode(mode)
    }
    
    func getEditorText(complete: @escaping (String) -> Void) {
        self.executeJavaScriptFn(fnName: "ob.getText", params: [:]) { res, err in
            if let err = err {
                Log.error(err)
                return
            }
            if let text = res as? String {
                self.nc.post(name: .editorTextDidChange, object: nil, userInfo: ["text": text, "mode": self.mode.rawValue])
                complete(text)
            }
            
        }
    }
    
    func executeJavaScriptFn(fnName: String, params: [String: Any], completion: ((Any?, Error?) -> Void)? = nil) {
        var fnWithArgs: String = ""
        if let jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) {
            if let args = String(data: jsonData, encoding: .utf8) {
                fnWithArgs = "\(fnName)(\(args))"
            }
        } else {
            fnWithArgs = "\(fnName)"
        }
        self.webView?.evaluateJavaScript(fnWithArgs, completionHandler: completion)
    }
    
    func getCurrentEditorTheme() -> EditorTheme {
        return self.app.getCurrentUIStyle() == .dark ? .dark : .light
    }
    
    func updateEditorText(_ text: String) {
        self.executeJavaScriptFn(fnName: "ob.updateText", params: ["text": text])
    }
    
    func updateEditorMode(_ mode: PostRequestBodyMode) {
        self.executeJavaScriptFn(fnName: "ob.updateMode", params: ["mode": mode.rawValue])
    }
    
    func updateTheme(_ theme: EditorTheme) {
        self.executeJavaScriptFn(fnName: "ob.updateTheme", params: ["mode": theme.rawValue])
    }
    
    @IBAction func cancelBtnDidTap(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func doneBtnDidTap(_ sender: Any) {
        Log.debug("done btn did tap")
        self.getEditorText { _ in
            self.dismiss(animated: true)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.updateTheme(self.getCurrentEditorTheme())
        self.setText(self.text ?? "")
        self.updateEditorMode(self.mode)
        self.executeJavaScriptFn(fnName: "ob.test", params: [:]) { res, err in
            Log.debug("result: \(String(describing: res))")
        }
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Log.debug("wk script message received: \(message.body)")
    }
    
}
