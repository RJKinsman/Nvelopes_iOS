//
//  NvelopesViewController.swift
//  Nvelopes
//
//  Created by Roland Kinsman on 12/30/18.
//  Copyright © 2018 RJKinsman. All rights reserved.
//

import UIKit
import MSAL

// Variables from MSALiOS - Start
let kClientID = "433dbc19-0293-4796-9012-c2ea57e23637"
let kGraphEndpoint = "https://graph.microsoft.com/"
let kAuthority = "https://login.microsoftonline.com/consumers"
let kRedirectUri = "msauth.com.RJKinsman.Nvelopes://auth"

let kScopes: [String] = ["user.read"]

var accessToken = String()
var applicationContext : MSALPublicClientApplication?
var webViewParamaters : MSALWebviewParameters?

var loggingText: UITextView!
var signOutButton: UIButton!
var callGraphButton: UIButton!
var usernameLabel: UILabel!

var currentAccount: MSALAccount?

// Variables from MSALiOS - End

var nvelopeNames = [String]()
var nvelopeAmounts = [Double]()
var modelController: ModelController!
var nvelopes = modelController?.nvelopes
var reload = false

class NvelopesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var labelMessage: UILabel!
    
    let dispatchGroup = DispatchGroup()

    var modelController: ModelController!
    
    // Gain access to AppDelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(NvelopesViewController.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        
        return refreshControl
    }()


    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Default is 1 if not implemented
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var rows = 0
        if reload {
            rows = nvelopeNames.count
            return rows
        }
        
        if let nvelopes = modelController?.nvelopes {
            rows = nvelopes.nvelopeNames.count
            print("Count: " , rows)
        } else {
            print("Count is nil!")
        }

        return rows

    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let nvelopes = modelController?.nvelopes
        let cellIdentifier = "EnvelopeCell"
        
        // from developer.apple.com table tutorial
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? EnvelopeTableViewCell else {
            fatalError("The dequeued call is not an instance of EnvelopeTableViewCell")
        }

        if reload {
            cell.labelEnvelopeName.text = nvelopeNames[indexPath.row]
        } else {
            cell.labelEnvelopeName.text = nvelopes!.nvelopeNames[indexPath.row]
        }

        var envelopeAmount = 0.0
        if reload {
            envelopeAmount = nvelopeAmounts[indexPath.row]
        } else {
            envelopeAmount = nvelopes!.nvelopeAmounts[indexPath.row]
        }
        
        var amount: String
        if envelopeAmount == 0 {
            cell.labelEnvelopeAmount.text = ""
        } else {
            if reload {
                amount = String(nvelopeAmounts[indexPath.row])
            } else {
                amount = String(nvelopes!.nvelopeAmounts[indexPath.row])

            }
            let amountComponents = amount.components(separatedBy: ".")
            let amountDollar = amountComponents[0]
            var amountCents = amountComponents[1]
            if (amountCents.count) < 2 {
                amountCents = String(amountCents + "0")
            }
            cell.labelEnvelopeAmount.text = String("$" + amountDollar + "." + amountCents)
        }
        
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        initUI()
        
        do {
            try self.initMSAL()
        } catch let error {
            self.updateLogging(text: "Unable to create Application Context \(error)")
        }
        
        self.loadCurrentAccount()
        self.platformViewDidLoadSetup()

        labelMessage.sizeToFit()
        labelMessage.numberOfLines = 0
        
        print("NvelopesViewController.viewDidLoad")
        
        self.tableView.addSubview(self.refreshControl)

        if let nvelopes = self.modelController?.nvelopes {
            print("nvelopes.asofDate:" , nvelopes.asofDate)
            self.labelDate.text = nvelopes.asofDate
            self.labelMessage.text = nvelopes.nvelopesMessage
        } else {
            print("NvelopesViewController.viewDidLoad: nada")
        }

        self.tableView.reloadData()

        return
    }
        
    func platformViewDidLoadSetup() {
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appCameToForeGround(notification:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
        self.loadCurrentAccount()
    }
    
    @objc func appCameToForeGround(notification: Notification) {
        self.loadCurrentAccount()
    }
}
extension NvelopesViewController {

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        
        print("NvelopesViewController.handleRefresh")
        
        /*
         
         To refresh the data, we need to do several things:
         1. Make sure we still have access to the file in dropbox and get serverModified.
            If we do not have access, we we update the as of date, reload the data and return
         
         2. Compare serverModified to serverModifiedSaved.
            If they are equal, again, we update the as of date, reload the data and return
            Otherwise, we download the new file and process it
         
         We do this by calling methods in AppDelegate and ModelController.
         
         Notes about replicated functions:
         I had to replicate the functions checkForDropboxAccess and downloadNvelopes here because I couldn't figure out how to implement dispatchgroups (Apple's GCD) across classes.
         I also had to replicate and modify processNvelopes here from the ModelController because I couldn't figure out how to get the data back into this class.
         
         */

        dispatchGroup.enter()
        checkForDropboxAccess()

        dispatchGroup.notify(queue: .main) {
        
// If we did not get access, just refresh the table and return
            if !self.appDelegate.gotDropboxAccess {
                print("NvelopesViewController: did not get Drobpbox access.  Refreshing Data" )
//                self.processNvelopes()
                self.processNvelopes()
                self.tableView.reloadData()
                refreshControl.endRefreshing()
                return
                }
        
//            let serverModifiedSaved = self.appDelegate.getServerModifiedKey()
        
//            if self.appDelegate.serverModifiedString == serverModifiedSaved {
//            print("NvelopesViewController: no file update.  Refreshing Data" )
//            self.processNvelopes()
//            self.tableView.reloadData()
//            refreshControl.endRefreshing()
            return
        }
            
            /*
               This switch allows the other functions to operate on the proper data depending on whether we are coming in from the ModelController or NvelopesViewController
             */

            reload = true

        print("NvelopesViewController..handleRefresh(): downloading the file")
            
//            self.appDelegate.saveServerModifiedKey()

            self.dispatchGroup.enter()
//            self.downloadNvelopes()

            self.dispatchGroup.notify(queue: .main) {
            
//                self.processNvelopes()
                self.processNvelopes()
                print("NvelopesViewController.handleRefresh: after processNvelopes()")
                print("NvelopesViewController.handleRefresh: nvelopeNames.count: " , nvelopeNames.count as Any)

                print("NvelopesViewController.handleRefresh asofDate:" , asofDate)
                self.labelDate.text = asofDate
                self.labelMessage.text = nvelopesMessage

                print("NvelopesViewController.handleRefresh: executing reloadData")
                self.tableView.reloadData()
                refreshControl.endRefreshing()
                
            }
            
        return
            
        }

    
    func checkForDropboxAccess() {
        
        // Test to see if we are authorized and we can get the file.  If yes, use the regular view, otherwise handle
        
        // Check to see if Nvelopes.csv exists in Dropbox.
//        client!.files.getMetadata(path: "/Nvelopes.csv")
//            .response {response, error in
//                if let (metadata) = response {
//                    self.dispatchGroup.leave()
//                    switch metadata {
//                    case let fileMetadata as Files.FileMetadata:
                        //                            print("AppDelegate: File metadata: \(fileMetadata)")
//                        self.appDelegate.serverModified = fileMetadata.serverModified
//                        self.appDelegate.serverModifiedString = String(describing: self.appDelegate.serverModified)
//                        print("NvelopesViewController.checkForDropboxAccess: File serverModified: \(self.appDelegate.serverModifiedString)!")
                    // folders don't have serverModified
//                    case let folderMetadata as Files.FolderMetadata:
//                        print("Folder metadata: \(folderMetadata)")
//                    // deleted entries don't have serverModified
//                    case let deletedMetadata as Files.DeletedMetadata:
//                        print("Deleted entity's metadata: \(deletedMetadata)")
//                    default:
//                        print("default")
//                    }
//                }
//                if let error = error {
//                    self.dispatchGroup.leave()
                    print("NvelopesViewController.checkForDropboxAccess: We did not get the attributes :(")
//                    print("Error begin:")
//                    print(error.description)
//                    print("Error end")
//                    switch error as CallError {
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
//                                    print("unsupportedContentType")
//                            case .locked:
//                                    print("locked")
//                            }
//                        }
//
//                    case .authError(let authError, let userMessage, let errorSummary, let requestId):
//                        print("authError\(String(describing: authError))]:")
//                        print("userMessage\(String(describing: userMessage))]:")
//                        print("errorSummary\(String(describing: errorSummary))]:")
//                        print("requestID\(String(describing: requestId))]:")
////                        self.appDelegate.gotDropboxAccess = false
//
//                    case .clientError(let clientError):
//                        let errDescription = clientError?.localizedDescription
//                        print("errDescription: \(String(describing: errDescription))")
////                        self.appDelegate.gotDropboxAccess = false
//
//                    default:
//                        print("Unhandled Error, crashing...")
//                        fatalError()
//                    }
//                }
        }
        
//        return
//    }

    func downloadNvelopes() {
        print("NvelopesViewController:downloadNvelopes()")
        
//        let fileManager = FileManager.default
//        let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let destURL = directoryURL.appendingPathComponent("Nvelopes.csv")
//        let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in return destURL}
        
//        client!.files.download(path: "/Nvelopes.csv", overwrite: true, destination: destination)
//            .response { response, error in
//                if let (_) = response {
//                    print("NvelopesViewController.downloadNvelopes: we got a response")
//                    self.appDelegate.gotDownload = true
//                    self.dispatchGroup.leave()
                }
//                if response != nil {
//                } else if let error = error {
//                    print("NvelopesViewController.downloadNvelopes: download Error:")
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
    
    func processNvelopes() {
        
        let fileManager = FileManager.default
        let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destURL = directoryURL.appendingPathComponent("Nvelopes.csv")
        
        print("NvelopesViewController.processNvelopes()")
        nvelopeNames.removeAll()
        nvelopeAmounts.removeAll()
        
        do {
            let data = try Data(contentsOf:destURL)
            let attributedString = try NSAttributedString(data: data, documentAttributes: nil)
            let fullText = attributedString.string
            let readings = fullText.components(separatedBy: CharacterSet.newlines)
            var stringLine: NSString
            stringLine = NSString(string: readings[0])
            print(stringLine)
            // Validate the data in the Nvelopes.ios file.  The first line must start with a string, "Nvelopes iOS"
            if stringLine.length > 11 {
                if stringLine.substring(to: 12) != "Nvelopes iOS" {
                    print (destURL.absoluteString + " Invalid. found " + (stringLine as String))
                    return
                }
            } else {
                print (destURL.absoluteString + " Invalid. found " + (stringLine as String))
                print (stringLine as String)
                return
            }
            /*
             The second line is the message line
             */
            
            stringLine = NSString(string: readings[2])
            print(stringLine)
            nvelopesMessage = String(stringLine)
            //            print("ModelController: nvelopesMessage: \(nvelopesMessage)")
            
            /*
             
             The third line is the "as of" date in the file.

             */
            
            stringLine = NSString(string: readings[4])
            var stringDate : String
            var dotline = 0
            stringDate = stringLine.components(separatedBy: ": ")[1]
            stringLine = NSString(string: stringDate)
            stringDate = stringLine.components(separatedBy: "\"")[0]
            asofDate = ("As of " + stringDate)
            let asofDate_test = stringDate
            print("NvelopesViewController.processNvelopes asofDate:" , asofDate)

            /*
             
             Parse the as of date into a date type and calculate the number of days since today
             
             The date will be in the format of:
             Month (spelled out) Date (zero suppressed) comma year (all digits)
             For example:
                         July 6, 2019
             
             */
            
            let today = Calendar.current
            print("Today's date:" , Date())
            print("asofDate:" , asofDate_test)
            let asofDate_formaatter = DateFormatter()
            asofDate_formaatter.dateFormat = "MMMM d, y"
            
            if let asofDate_date = asofDate_formaatter.date(from: asofDate_test) {
                print("asofDate_date:" , asofDate_date)
                let days = today.dateComponents([.day], from: asofDate_date,
                                                to: Date())
                daysSinceAsof = days.day!
                print("daysSinceAsof:" , daysSinceAsof)
            }
            
            if daysSinceAsof == 0 {
                asofDate = "As of Today"
            } else {
                if daysSinceAsof == 1 {
                    asofDate = "As of Yesterday"
                }
            }

            
            for i in stride(from: 6, to: readings.count-1, by: 2) {
                stringLine = NSString(string: readings[i])
                if stringLine == "." {
                    dotline = i
                    break
                }
                print("stringline:" , stringLine)
                nvelopeNames.append(stringLine.components(separatedBy: ",")[0])
                nvelopeAmounts.append(Double((stringLine.components(separatedBy: ",")[1]))!)
            }
            
            let i = dotline+2
            stringLine = NSString(string: readings[i])
            print("stringline:" , stringLine)
            var emfbal : String
            emfbal = stringLine.components(separatedBy: ": ")[1]
            print("emfbal:" , emfbal)
            nvelopesMessage = String(nvelopesMessage + "\n Emergency Fund $" + emfbal)

            }
            
            
            
        catch {
            print("NvelopesViewController.processNvelopes(): error processing nvelopes.csv:")
            print(error)
        }
        
        
        return
    }
}

// MARK: Initialization

extension NvelopesViewController {
    
    /**
     
     Initialize a MSALPublicClientApplication with a given clientID and authority
     
     - clientId:            The clientID of your application, you should get this from the app portal.
     - redirectUri:         A redirect URI of your application, you should get this from the app portal.
     If nil, MSAL will create one by default. i.e./ msauth.<bundleID>://auth
     - authority:           A URL indicating a directory that MSAL can use to obtain tokens. In Azure AD
     it is of the form https://<instance/<tenant>, where <instance> is the
     directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
     identifier within the directory itself (e.g. a domain associated to the
     tenant, such as contoso.onmicrosoft.com, or the GUID representing the
     TenantID property of the directory)
     - error                The error that occurred creating the application object, if any, if you're
     not interested in the specific error pass in nil.
     */
    func initMSAL() throws {
        
        guard let authorityURL = URL(string: kAuthority) else {
            self.updateLogging(text: "Unable to create authority URL")
            return
        }
        
        let authority = try MSALAADAuthority(url: authorityURL)
        
        let msalConfiguration = MSALPublicClientApplicationConfig(clientId: kClientID,
                                                                  redirectUri: kRedirectUri,
                                                                  authority: authority)
        applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
        self.initWebViewParams()
    }
    
    func initWebViewParams() {
        webViewParamaters = MSALWebviewParameters(authPresentationViewController: self)
    }
}

// MARK: Shared device

extension NvelopesViewController {
    
    @objc func getDeviceMode(_ sender: UIButton) {
        
        if #available(iOS 13.0, *) {
            applicationContext?.getDeviceInformation(with: nil, completionBlock: { (deviceInformation, error) in
                
                guard let deviceInfo = deviceInformation else {
                    self.updateLogging(text: "Device info not returned. Error: \(String(describing: error))")
                    return
                }
                
                let isSharedDevice = deviceInfo.deviceMode == .shared
                let modeString = isSharedDevice ? "shared" : "private"
                self.updateLogging(text: "Received device info. Device is in the \(modeString) mode.")
            })
        } else {
            self.updateLogging(text: "Running on older iOS. GetDeviceInformation API is unavailable.")
        }
    }
}


// MARK: Acquiring and using token

extension NvelopesViewController {
    
    /**
     This will invoke the authorization flow.
     */
    
    @objc func callGraphAPI(_ sender: UIButton) {
        
        self.loadCurrentAccount { (account) in
            
            guard let currentAccount = account else {
                
                // We check to see if we have a current logged in account.
                // If we don't, then we need to sign someone in.
                self.acquireTokenInteractively()
                return
            }
            
            self.acquireTokenSilently(currentAccount)
        }
    }
    
    func acquireTokenInteractively() {
        
        guard let applicationContext = applicationContext else { return }
        guard let webViewParameters = webViewParamaters else { return }

        let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount
        
        applicationContext.acquireToken(with: parameters) { (result, error) in
            
            if let error = error {
                
                self.updateLogging(text: "Could not acquire token: \(error)")
                return
            }
            
            guard let result = result else {
                
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }
            
            accessToken = result.accessToken
            self.updateLogging(text: "Access token is \(accessToken)")
            self.updateCurrentAccount(account: result.account)
            self.getContentWithToken()
        }
    }
    
    func acquireTokenSilently(_ account : MSALAccount!) {
        
        guard let applicationContext = applicationContext else { return }
        
        /**
         
         Acquire a token for an existing account silently
         
         - forScopes:           Permissions you want included in the access token received
         in the result in the completionBlock. Not all scopes are
         guaranteed to be included in the access token returned.
         - account:             An account object that we retrieved from the application object before that the
         authentication flow will be locked down to.
         - completionBlock:     The completion block that will be called when the authentication
         flow completes, or encounters an error.
         */
        
        let parameters = MSALSilentTokenParameters(scopes: kScopes, account: account)
        
        applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
            
            if let error = error {
                
                let nsError = error as NSError
                
                // interactionRequired means we need to ask the user to sign-in. This usually happens
                // when the user's Refresh Token is expired or if the user has changed their password
                // among other possible reasons.
                
                if (nsError.domain == MSALErrorDomain) {
                    
                    if (nsError.code == MSALError.interactionRequired.rawValue) {
                        
                        DispatchQueue.main.async {
                            self.acquireTokenInteractively()
                        }
                        return
                    }
                }
                
                self.updateLogging(text: "Could not acquire token silently: \(error)")
                return
            }
            
            guard let result = result else {
                
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }
            
            accessToken = result.accessToken
            self.updateLogging(text: "Refreshed Access token is \(accessToken)")
            self.updateSignOutButton(enabled: true)
            self.getContentWithToken()
        }
    }
    
    func getGraphEndpoint() -> String {
        return kGraphEndpoint.hasSuffix("/") ? (kGraphEndpoint + "v1.0/me/") : (kGraphEndpoint + "/v1.0/me/");
    }
    
    /**
     This will invoke the call to the Microsoft Graph API. It uses the
     built in URLSession to create a connection.
     */
    
    func getContentWithToken() {
        
        // Specify the Graph API endpoint
        let graphURI = getGraphEndpoint()
        let url = URL(string: graphURI)
        var request = URLRequest(url: url!)
        
        // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                self.updateLogging(text: "Couldn't get graph result: \(error)")
                return
            }
            
            guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) else {
                
                self.updateLogging(text: "Couldn't deserialize result JSON")
                return
            }
            
            self.updateLogging(text: "Result from Graph: \(result))")
            
            }.resume()
    }

}


// MARK: Get account and removing cache

extension NvelopesViewController {
    
    typealias AccountCompletion = (MSALAccount?) -> Void

    func loadCurrentAccount(completion: AccountCompletion? = nil) {
        
        guard let applicationContext = applicationContext else { return }
        
        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main
                
        // Note that this sample showcases an app that signs in a single account at a time
        // If you're building a more complex app that signs in multiple accounts at the same time, you'll need to use a different account retrieval API that specifies account identifier
        // For example, see "accountsFromDeviceForParameters:completionBlock:" - https://azuread.github.io/microsoft-authentication-library-for-objc/Classes/MSALPublicClientApplication.html#/c:objc(cs)MSALPublicClientApplication(im)accountsFromDeviceForParameters:completionBlock:
        applicationContext.getCurrentAccount(with: msalParameters, completionBlock: { (currentAccount, previousAccount, error) in
            
            if let error = error {
                self.updateLogging(text: "Couldn't query current account with error: \(error)")
                return
            }
            
            if let currentAccount = currentAccount {
                
                self.updateLogging(text: "Found a signed in account \(String(describing: currentAccount.username)). Updating data for that account...")
                
                self.updateCurrentAccount(account: currentAccount)
                
                if let completion = completion {
                    completion(currentAccount)
                }
                
                return
            }
            
            self.updateLogging(text: "Account signed out. Updating UX")
            accessToken = ""
            self.updateCurrentAccount(account: nil)
            
            if let completion = completion {
                completion(nil)
            }
        })
    }
    
    /**
     This action will invoke the remove account APIs to clear the token cache
     to sign out a user from this application.
     */
    @objc func signOut(_ sender: UIButton) {
        
        guard let applicationContext = applicationContext else { return }
        
        guard let account = currentAccount else { return }
        
        do {
            
            /**
             Removes all tokens from the cache for this application for the provided account
             
             - account:    The account to remove from the cache
             */
            
            let signoutParameters = MSALSignoutParameters(webviewParameters: webViewParamaters!)
            signoutParameters.signoutFromBrowser = false
            
            applicationContext.signout(with: account, signoutParameters: signoutParameters, completionBlock: {(success, error) in
                
                if let error = error {
                    self.updateLogging(text: "Couldn't sign out account with error: \(error)")
                    return
                }
                
                self.updateLogging(text: "Sign out completed successfully")
                accessToken = ""
                self.updateCurrentAccount(account: nil)
            })
            
        }
    }
}

// MARK: UI Helpers
extension NvelopesViewController {
    
    func initUI() {
        
        usernameLabel = UILabel()
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.text = ""
        usernameLabel.textColor = .darkGray
        usernameLabel.textAlignment = .right
        
        self.view.addSubview(usernameLabel)
        
        usernameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50.0).isActive = true
        usernameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10.0).isActive = true
        usernameLabel.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        usernameLabel.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        // Add call Graph button
        callGraphButton  = UIButton()
        callGraphButton.translatesAutoresizingMaskIntoConstraints = false
        callGraphButton.setTitle("Call Microsoft Graph API", for: .normal)
        callGraphButton.setTitleColor(.blue, for: .normal)
        callGraphButton.addTarget(self, action: #selector(callGraphAPI(_:)), for: .touchUpInside)
        self.view.addSubview(callGraphButton)
        
        callGraphButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        callGraphButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 120.0).isActive = true
        callGraphButton.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        callGraphButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        // Add sign out button
        signOutButton = UIButton()
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.setTitleColor(.blue, for: .normal)
        signOutButton.setTitleColor(.gray, for: .disabled)
        signOutButton.addTarget(self, action: #selector(signOut(_:)), for: .touchUpInside)
        self.view.addSubview(signOutButton)
        
        signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signOutButton.topAnchor.constraint(equalTo: callGraphButton.bottomAnchor, constant: 10.0).isActive = true
        signOutButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        signOutButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        let deviceModeButton = UIButton()
        deviceModeButton.translatesAutoresizingMaskIntoConstraints = false
        deviceModeButton.setTitle("Get device info", for: .normal);
        deviceModeButton.setTitleColor(.blue, for: .normal);
        deviceModeButton.addTarget(self, action: #selector(getDeviceMode(_:)), for: .touchUpInside)
        self.view.addSubview(deviceModeButton)
        
        deviceModeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        deviceModeButton.topAnchor.constraint(equalTo: signOutButton.bottomAnchor, constant: 10.0).isActive = true
        deviceModeButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        deviceModeButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        // Add logging textfield
        loggingText = UITextView()
        loggingText.isUserInteractionEnabled = false
        loggingText.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(loggingText)
        
        loggingText.topAnchor.constraint(equalTo: deviceModeButton.bottomAnchor, constant: 10.0).isActive = true
        loggingText.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10.0).isActive = true
        loggingText.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10.0).isActive = true
        loggingText.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 10.0).isActive = true
    }
    
    func updateLogging(text : String) {
        
        if Thread.isMainThread {
            loggingText.text = text
        } else {
            DispatchQueue.main.async {
                loggingText.text = text
            }
        }
    }
    
    func updateSignOutButton(enabled : Bool) {
        if Thread.isMainThread {
            signOutButton.isEnabled = enabled
        } else {
            DispatchQueue.main.async {
                signOutButton.isEnabled = enabled
            }
        }
    }
    
    func updateAccountLabel() {
        
        guard let currentAccount = currentAccount else {
            usernameLabel.text = "Signed out"
            return
        }
        
        usernameLabel.text = currentAccount.username
    }
    
    func updateCurrentAccount(account: MSALAccount?) {
        currentAccount = account
        self.updateAccountLabel()
        self.updateSignOutButton(enabled: account != nil)
    }
}
