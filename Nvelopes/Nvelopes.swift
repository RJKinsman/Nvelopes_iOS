//
//  Nvelopes.swift
//  Nvelopes
//
//  Created by Roland Kinsman on 1/19/19.
//  Copyright © 2019 RJKinsman. All rights reserved.
//

import Foundation

struct Nvelopes:Codable {
    var nvelopeNames: [String]
    var nvelopeAmounts: [Double]
    var asofDate: String
    var nvelopesMessage: String
}
