//
//  ConnectToDropboxViewController.swift
//  Nvelopes
//
//  Created by Roland Kinsman on 1/5/19.
//  Copyright © 2019 RJKinsman. All rights reserved.
//

import UIKit
import SwiftyDropbox

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    DropboxClientsManager.setupWithAppKey("fawy4f14021rypr")
    print("ConnectToDropboxViewController did setupWithAppKey")
    return true
}

class ConnectToDropboxViewController: UIViewController {

    @IBAction func connectToDropboxButtonTapped(_ sender: Any) {
        // Begin the Dropbopx authorization flow
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self, openURL: { (url: URL) -> Void in UIApplication.shared.open(url, options: [:], completionHandler: nil) })

    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewDidAppear(_ animated: Bool) {
    }

}
