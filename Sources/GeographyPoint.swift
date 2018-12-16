//
//  PostGISGeographyPoint.swift
//  COpenSSL
//
//  Created by Ryan Coyne on 12/14/18.
//

import Foundation

struct GeographyPoint : CustomStringConvertible, CustomDatabaseTypeConvertible, PostGIS, CustomSelectStringConvertible, Equatable {
    
    func statement(column: String, as: String?=nil) -> String {
        var `as` = `as`
        if `as` == nil { `as` = column }
        return "jsonb_build_object('latitude',ST_X(\(column)::geometry), 'longitude',ST_Y(\(column)::geometry)) as \(`as`!)".function
    }
    
    /// This is the description for the database type.  This is for creating the database table.
    var type: String {
        return "geography(Point,4326)"
    }
    ///  This is the description of the PostGIS Geography Point for creating or inserting the field into the database.
    var description: String {
        if longitude != nil && latitude != nil {
            return "ST_SetSRID(ST_MakePoint(\(longitude!),\(latitude!)),4326)".gisFunction
        } else {
            return "nil"
        }
    }
    
    ///  An easy function to use to get the value from the database into a double value for the geometry field.
    mutating func from(_ value : Any?) {
        if let theData = value as? [String:Any] {
            self.latitude = theData["latitude"].doubleValue
            self.longitude = theData["longitude"].doubleValue
        }
    }
    
    ///  This is the latitude of the geography data point.
    var latitude : Double? = nil
    ///  This is the longitude of the geography data point.
    var longitude : Double? = nil
    
}
