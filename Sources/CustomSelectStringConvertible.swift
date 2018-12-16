//
//  CustomSelectStringConvertible.swift
//  PostgresStORM
//
//  Created by Ryan Coyne on 12/16/18.
//

protocol CustomSelectStringConvertible {
    func statement(column: String, as: String?) -> String 
}
