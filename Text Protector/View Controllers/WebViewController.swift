//
//  WebViewController.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/30/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    var fileName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.loadFileURL(Bundle.main.url(forResource: fileName!, withExtension: "html")!, allowingReadAccessTo: Bundle.main.url(forResource: fileName!, withExtension: "html")!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
