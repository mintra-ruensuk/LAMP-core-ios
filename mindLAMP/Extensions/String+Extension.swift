//
//  String+Extension.swift
//  lampv2
//
//  Created by ZCO Engineer on 13/01/20.
//

import Foundation

extension String {
    
    func toData() -> Data {

        return self.data(using: String.Encoding.utf8) ?? Data()
    }

    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
