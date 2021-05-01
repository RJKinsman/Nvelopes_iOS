//
//  NvelopesViewController.swift
//  Nvelopes
//
//  Created by Roland Kinsman on 12/30/18.
//  Copyright © 2018 RJKinsman. All rights reserved.
//

import UIKit
//import SwiftyDropbox

var nvelopeNames = [String]()
var nvelopeAmounts = [Double]()
//let client = DropboxClientsManager.authorizedClient
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
        // Do any additional setup after loading the view, typically from a nib.
    
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
                processNvelopes()
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
                processNvelopes()
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

//}
