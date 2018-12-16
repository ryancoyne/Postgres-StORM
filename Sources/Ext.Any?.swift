//
//  Ext.Any?.swift
//  COpenSSL
//
//  Created by Ryan Coyne on 12/16/18.
//

import Foundation

extension Optional where Wrapped == Any {
    var doubleValue : Double? {
        if self == nil {
            return nil
        }
        switch self {
        case is Int, is Int?:
            return Double(exactly: self as! Int)
        case is Float, is Float?:
            return Double(exactly: self as! Float)
        case is Double, is Double?:
            return self as? Double
        case is String, is String?:
            return Double(self as! String)
        default:
            return nil
        }
    }
}
