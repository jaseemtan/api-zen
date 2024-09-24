//
//  GenesisViewController.swift
//  APITesterPro
//
//  Created by Jaseem V V on 24.09.2024.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class GenesisViewController: UIViewController {
    private var webView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.debug("genesis view did load")
        self.initUI()
    }
    
    func initUI() {
        self.webView = WKWebView(frame: .zero, configuration: self.getWebviewConfig())
        if let webView = self.webView {
            webView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(webView)
            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
                webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
                webView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
                webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
            ])
        }
        self.webView?.navigationDelegate = self
        self.webView?.scrollView.bounces = false  // disables overscroll
        if let htmlFile = Bundle.main.path(forResource: "genesis", ofType: "html") {
            let htmlURL = URL(fileURLWithPath: htmlFile)
            let baseURL = URL(fileURLWithPath: Bundle.main.bundlePath)
            self.webView?.loadFileURL(htmlURL, allowingReadAccessTo: baseURL)
        }
    }
    
    func getWebviewConfig() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        return config
    }
}

extension GenesisViewController: WKNavigationDelegate {
    
}
