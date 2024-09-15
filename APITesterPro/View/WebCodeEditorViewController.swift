//
//  WebCodeEditorViewController.swift
//  APITesterPro
//
//  Created by Jaseem V V on 15/09/24.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import Foundation
import UIKit

class WebCodeEditorViewController: UIViewController {
    var text: String?
    var mode: String?
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var doneBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.debug("webeditor: view did load")
        self.initUI()
        self.initEvents()
    }
    
    func initUI() {
        
    }
    
    func initEvents() {
        
    }
    
    @IBAction func cancelBtnDidTap(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
