//
//  ModelController.swift
//  Nvelopes
//
//  Created by Roland Kinsman on 1/19/19.
//  Copyright © 2019 RJKinsman. All rights reserved.
//

import Foundation

var asofDate = ""
var nvelopesMessage = ""
var daysSinceAsof = 0

let fileManager = FileManager.default
let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
let destURL = directoryURL.appendingPathComponent("Nvelopes.csv")

class ModelController {

    var nvelopes = Nvelopes(
        nvelopeNames: nvelopeNames,
        nvelopeAmounts: nvelopeAmounts,
        asofDate: asofDate,
        nvelopesMessage: nvelopesMessage
    )
    
    init() {
        
        print("ModelController.init() start")
        
        self.processNvelopes()
        
        print("ModelController.init() finish")

    }
    
    func processNvelopes() {

/*
         IMPORTANT: This code is repeated in NvelopesViewController.  Any changes made here must be done there as well
 */
        print("ModelController.processNvelopes()")
        nvelopeNames.removeAll()
        nvelopeAmounts.removeAll()
                
        do {
            let data = try Data(contentsOf:destURL)
            let attributedString = try NSAttributedString(data: data, documentAttributes: nil)
            let fullText = attributedString.string
            let readings = fullText.components(separatedBy: CharacterSet.newlines)
            var stringLine: NSString
            stringLine = NSString(string: readings[0])
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
            nvelopes.nvelopesMessage = String(stringLine)
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
            nvelopes.asofDate = ("As of " + stringDate)
            let asofDate_test = stringDate
            print("ModelController.processNvelopes asofDate:" , nvelopes.asofDate)

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
                nvelopes.asofDate = "As of Today"
            } else {
                if daysSinceAsof == 1 {
                    nvelopes.asofDate = "As of Yesterday"
                }
            }
 
            for i in stride(from: 6, to: readings.count-1, by: 2) {
                stringLine = NSString(string: readings[i])
                if stringLine == "." {
                    dotline = i
                    break
                }
                print("stringline:" , stringLine)
                nvelopes.nvelopeNames.append(stringLine.components(separatedBy: ",")[0])
                nvelopes.nvelopeAmounts.append(Double((stringLine.components(separatedBy: ",")[1]))!)
            }
            
            let i = dotline+2
            stringLine = NSString(string: readings[i])
            print("stringline:" , stringLine)
            var emfbal : String
            emfbal = stringLine.components(separatedBy: ": ")[1]
            print("emfbal:" , emfbal)
            nvelopes.nvelopesMessage = String(nvelopes.nvelopesMessage + "\n Emergency Fund $" + emfbal)

        }
        catch {
            print("ModelController: error processing nvelopes.csv:")
            print(error)
        }


        return
    }
    
}
