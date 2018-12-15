//
//  Ext.String.swift
//  PostgresStORM
//
//  Created by Ryan Coyne on 12/14/18.
//

import Foundation

extension String {
    init?(databaseType instance: Any) {
        if instance is CustomDatabaseTypeConvertible {
            self = (instance as! CustomDatabaseTypeConvertible).type
        } else {
            return nil
        }
    }
}
