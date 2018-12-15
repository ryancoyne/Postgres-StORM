//
//  PostGISGeographyPoint.swift
//  COpenSSL
//
//  Created by Ryan Coyne on 12/14/18.
//

import Foundation

struct PostGISGeographyPoint : CustomStringConvertible, CustomDatabaseTypeConvertible {
    
    /// This is the description for the database type.  This is for creating the database table.
    var type: String {
        return "geography(Point,4326)"
    }
    ///  This is the description of the PostGIS Geography Point for creating or inserting the field into the database.
    var description: String {
        return "ST_SetSRID(ST_MakePoint(\(longitude),\(latitude)),4326)"
    }
    
    var latitude : Double = 0.0
    var longitude : Double = 0.0
}
