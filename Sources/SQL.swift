//
//  SQL.swift
//  PerfectPostgresCRUD
//
//  Created by Jonathan Guthrie on 2016-09-24.
//
//

import Foundation
import StORM
import PostgreSQL

extension PostgresConnect {

	/// Execute Raw SQL (with parameter binding)
	/// Returns PGResult
	public func sql(_ statement: String, params: [String]) -> PGResult {
		return exec(statement, params: params)
	}


}