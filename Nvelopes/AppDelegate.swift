//
//  AppDelegate.swift
//  Nvelopes
//
//  Created by Roland Kinsman on 12/30/18.
//  Copyright © 2018 RJKinsman. All rights reserved.
//

import UIKit
import OneDriveSDK
import MSAL

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let dispatchGroup = DispatchGroup()
    let serverModifiedKey = "serverModified"

    var window: UIWindow?
    var window1: UIWindow?
    var gotDropboxAccess = true
    var needAuth = false
    var isClientError = false
    var gotDownload = false
    var serverModified: Date? = nil
    var serverModifiedString: String = ""
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.window1 = UIWindow(frame: UIScreen.main.bounds)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

// Display the wait screen
        self.window1?.rootViewController = mainStoryboard.instantiateViewController(withIdentifier: "sbNvelopesWait") as UIViewController
        self.window1?.makeKeyAndVisible()

//        DropboxClientsManager.setupWithAppKey("fawy4f14021rypr")

        print("AppDelegate: about to check for authorized client")

//        if DropboxClientsManager.authorizedClient != nil {
//            print("AppDelegate: We have an authorized client.  Now let's see if we can get the file attributes")
//
//            dispatchGroup.enter()
//
//            checkForDropboxAccess()
//        } else {
//            print("AppDelegate: we do not have an authorized client.  Displaying sbLinkToDropbox" )
//            needAuth = true
//            displaysbLinkToDropbox()
//            return true
//
//        }
                
        dispatchGroup.notify(queue: .main) {

// If we did not get access, then display the link to dropbox screen and return
            if !self.gotDropboxAccess {
                print("AppDelegate: did not get Drobpbox access.  Displaying sbLinkToDropbox" )
//                self.displaysbLinkToDropbox()
                return
                }
            
            /*
             Now that we have Dropbox access, we need to determine if we need to download the file.  We do this by comparing the newly retrieved serverModified to the one
             saved before.  If they are equal, then we are done.  We simply display the sbNvelopes screen and return.  Otherwise, we go ahead and download the file.
             */
            
            if self.isClientError {
                print("AppDelegate.applicationDidFinishLaunching(): client error")
//                self.displaysbNvelopes()
                return
                }
            
//            let serverModifiedSaved = self.getServerModifiedKey()

//            if self.serverModifiedString == serverModifiedSaved {
//                print("AppDelegate.applicationDidFinishLaunchingWithOptions: No file update")
//                self.displaysbNvelopes()
//                return
//            }
            
// Save serverModified and Download the file
            print("AppDelegate: downloading the file")
            
//            self.saveServerModifiedKey()
            
            self.dispatchGroup.enter()

//            self.downloadNvelopes()
            
            self.dispatchGroup.notify(queue: .main) {
                
            // Display the regular ViewController
//            self.displaysbNvelopes()
                
            }
        }
        return true
    }
    
    func checkForDropboxAccess() {
        
        // Test to see if we are authorized and we can get the file.
        
        // Check to see if Nvelopes.csv exists in Dropbox.
//        client!.files.getMetadata(path: "/Nvelopes.csv")
//            .response {response, error in
//              if let (metadata) = response {
//                if let (_) = response {
//                    self.dispatchGroup.leave()
//                    switch metadata {
//                    case let fileMetadata as Files.FileMetadata:
//                        self.serverModified = fileMetadata.serverModified
//                        self.serverModifiedString = String(describing: self.serverModified)
//                        print("AppDelegate.checkForDropboxAccess: File serverModified: \(self.serverModifiedString)!")
//
//                    // folders don't have serverModified
//                    case let folderMetadata as Files.FolderMetadata:
//                        print("Folder metadata: \(folderMetadata)")
//
//                    // deleted entries don't have serverModified
//                    case let deletedMetadata as Files.DeletedMetadata:
//                        print("Deleted entity's metadata: \(deletedMetadata)")
//
//                    default:
//                        print("default")
//                    }
                }
//                if let error = error {
//                    print("AppDelegate.checkForDropboxAccess(): We did not get the attributes :(")
//                    self.dispatchGroup.leave()
//                    switch error as CallError {
//
//                    case .routeError(let boxed, _, _, let requestId):
//                        print("RouteError[\(String(describing: requestId))]:")
//
//                        switch boxed.unboxed as Files.GetMetadataError {
//                        case .path(let lookupError):
//                            switch lookupError {
//                            case .notFound:
//                                print("File Not Found")
//                            case .other:
//                                print("Other error")
//                            case .malformedPath(_):
//                                print("MalformedPath")
//                            case .notFile:
//                                print("notFile")
//                            case .notFolder:
//                                print("notFolder")
//                            case .restrictedContent:
//                                print("restrictedContent")
//                            case .unsupportedContentType:
//                                print("unsupportedContentType")
//                            case .locked:
//                                print("locked")
//                            }
//                        }
                        
//                    case .authError(let authError, let userMessage, let errorSummary, let requestId):
//                        print("authError\(String(describing: authError))]:")
//                        print("userMessage\(String(describing: userMessage))]:")
//                        print("errorSummary\(String(describing: errorSummary))]:")
//                        print("requestID\(String(describing: requestId))]:")
//                        self.gotDropboxAccess = false
//                        _ = DropboxOAuthManager.sharedOAuthManager.clearStoredAccessTokens()
//
//                    case .clientError(let clientError):
//                        let errDescription = clientError?.localizedDescription
//                        print("clientError - errDescription: \(String(describing: errDescription))")
//                        self.isClientError = true
//
//                    default:
//                        print("Unhandled Error, crashing...")
//                        fatalError()
//                    }
//                }
//        }
        
//        return
    }
    
//    func downloadNvelopes() {
//        print("AppDelegate:downloadNvelopes()")
//
//        let fileManager = FileManager.default
//        let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let destURL = directoryURL.appendingPathComponent("Nvelopes.csv")
//        let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in return destURL}
//
//        client!.files.download(path: "/Nvelopes.csv", overwrite: true, destination: destination)
//            .response { response, error in
//                if let (_) = response {
//                    print("AppDelegate.downloadNvelopes: we got a response")
//                    self.gotDownload = true
//                    self.dispatchGroup.leave()
//                }
//                if response != nil {
//                } else if let error = error {
//                    print("AppDelegate.downloadNvelopes: download Error:")
//                    print(error.description)
//                    self.dispatchGroup.leave()
//                }
//            }
//            .progress { progressData in
//                print(progressData)
//        }
//
//        return
//    }
//
//    func displaysbNvelopes() {
//        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        self.window?.rootViewController = mainStoryboard.instantiateViewController(withIdentifier: "sbNvelopes") as UIViewController
//        if let nvelopesViewController = window?.rootViewController as? NvelopesViewController {
//            nvelopesViewController.modelController = ModelController()
//        }
//
//        self.window?.makeKeyAndVisible()
//        return
//    }
//
//    func displaysbLinkToDropbox() {
//        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        self.window?.rootViewController = mainStoryboard.instantiateViewController(withIdentifier: "sbLinkToDropbox") as UIViewController
//        self.window?.makeKeyAndVisible()
//        return
//    }
//
//    func getServerModifiedKey() -> String? {
//        let serverModifiedSaved = UserDefaults.standard.string(forKey: serverModifiedKey)
//
//        return serverModifiedSaved
//    }
//
//    func saveServerModifiedKey() {
//        UserDefaults.standard.set(self.serverModifiedString, forKey: self.serverModifiedKey)
//        return
//    }
//
//
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//
//        self.window = UIWindow(frame: UIScreen.main.bounds)
        
//        let _: DropboxOAuthCompletion = {
//            if let authResult = $0 {
//                switch authResult {
//
//            case .success(let token):
//                print("AppDelegate (authResult): Success! User is logged into Dropbox with token: \(token)")
//
//                if self.needAuth {
//
//                    self.dispatchGroup.enter()
//
//                    self.checkForDropboxAccess()
//
//                    self.dispatchGroup.notify(queue: .main) {
//
//                        // If we did not get access, then display the link to dropbox screen and return
//                        if !self.gotDropboxAccess {
//                            print("AppDelegate: did not get Drobpbox access.  Displaying sbLinkToDropbox" )
//                            self.displaysbLinkToDropbox()
//                            return
//                        }
//
//                        /*
//                         Now that we have Dropbox access, we need to determine if we need to download the file.  We do this by comparing the newly retrieved serverModified to the one
//                         saved before.  If they are equal, then we are done.  We simply display the sbNvelopes screen and return.  Otherwise, we go ahead and download the file.
//                         */
//
//                        if self.isClientError {
//                            print("AppDelegate.applicationDidFinishLaunching(): client error")
//                            self.displaysbNvelopes()
//                            return
//                        }
//
//                        let serverModifiedSaved = self.getServerModifiedKey()
//
//                        if self.serverModifiedString == serverModifiedSaved {
//                            print("AppDelegate.applicationDidFinishLaunchingWithOptions: No file update")
//                            self.displaysbNvelopes()
//                            return
//                        }
//
//                        // Save serverModified and Download the file
//                        print("AppDelegate: downloading the file")
//
//                        self.saveServerModifiedKey()
//
//                        self.dispatchGroup.enter()
//
//                        self.downloadNvelopes()
//
//                        self.dispatchGroup.notify(queue: .main) {
//
//                            // Display the regular ViewController
//                            self.displaysbNvelopes()
//
//                        }
//                    }
//
//                } else {
//                // Display the regular ViewController
//                    displaysbNvelopes()
//                    self.displaysbNvelopes()
//                }
//
//            case .cancel:
//                print("AppDelegate (authResult): Authorization flow was manually canceled by user!")
//                print("Crashing")
//                fatalError()
//            case .error(_, let description):
//                print("AppDelegate (authResult): Auth flow Error: \(String(describing: description))")
//                print("Crashing")
//                fatalError()
//            }
//        }
//        return true
//    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
//        return true
//        return

//}
//
//}
