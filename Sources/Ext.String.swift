//
//  Ext.String.swift
//  PostgresStORM
//
//  Created by Ryan Coyne on 12/14/18.
//

import Foundation

public extension String {
    init?(databaseType instance: Any) {
        if instance is CustomDatabaseTypeConvertible {
            self = (instance as! CustomDatabaseTypeConvertible).type
        } else {
            return nil
        }
    }
    init(select instance: Any, column: String, as: String?=nil) {
        if instance is CustomSelectStringConvertible {
            self = (instance as! CustomSelectStringConvertible).statement(column: column, as: `as`)
        } else {
            self = column.lowercased()
        }
    }
    var isGISFunction : Bool {
        return self.contains(string: ":gis_function")
    }
    var isFunction : Bool {
        return self.contains(string: ":function")
    }
    var gisFunction : String {
        return self + ":gis_function"
    }
    var function : String {
        return self + ":function"
    }
    var gisFunctionValue : String? {
        if self.isGISFunction {
            return self.components(separatedBy: "".gisFunction).first
        } else {
            return nil
        }
    }
    var functionValue : String? {
        if self.isFunction {
            return self.components(separatedBy: "".function).first
        } else {
            return nil
        }
    }
}
