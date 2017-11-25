//
//  PostgreStORM.swift
//  PostgresSTORM
//
//  Created by Jonathan Guthrie on 2016-10-03.
//
//

import StORM
import PerfectPostgreSQL
import PerfectLogger

/// PostgresConnector sets the connection parameters for the PostgreSQL Server access
/// Usage:
/// PostgresConnector.host = "XXXXXX"
/// PostgresConnector.username = "XXXXXX"
/// PostgresConnector.password = "XXXXXX"
/// PostgresConnector.port = 5432
public struct PostgresConnector {

	public static var host: String		= ""
	public static var username: String	= ""
	public static var password: String	= ""
	public static var database: String	= ""
	public static var port: Int			= 5432

	public static var quiet: Bool		= false

	private init(){}

}

/// SuperClass that inherits from the foundation "StORM" class.
/// Provides PosgreSQL-specific ORM functionality to child classes
open class PostgresStORM: StORM, StORMProtocol {

	/// Table that the child object relates to in the database.
	/// Defined as "open" as it is meant to be overridden by the child class.
	open func table() -> String {
		let m = Mirror(reflecting: self)
		return ("\(m.subjectType)").lowercased()
	}

	/// Empty initializer
	override public init() {
		super.init()
	}

	private func printDebug(_ statement: String, _ params: [String]) {
		if StORMdebug { LogFile.debug("StORM Debug: \(statement) : \(params.joined(separator: ", "))", logFile: "./StORMlog.txt") }
	}

	// Internal function which executes statements, with parameter binding
	// Returns raw result
	@discardableResult
	func exec(_ statement: String, params: [String]) throws -> PGResult {
		let thisConnection = PostgresConnect(
			host:		PostgresConnector.host,
			username:	PostgresConnector.username,
			password:	PostgresConnector.password,
			database:	PostgresConnector.database,
			port:		PostgresConnector.port
		)

		thisConnection.open()
		if thisConnection.state == .bad {
			error = .connectionError
			throw StORMError.error("Connection Error")
		}
		thisConnection.statement = statement

		printDebug(statement, params)
		let result = thisConnection.server.exec(statement: statement, params: params)

		// set exec message
		errorMsg = thisConnection.server.errorMessage().trimmingCharacters(in: .whitespacesAndNewlines)
		if StORMdebug { LogFile.info("Error msg: \(errorMsg)", logFile: "./StORMlog.txt") }
		if isError() {
			thisConnection.server.close()
			throw StORMError.error(errorMsg)
		}
		thisConnection.server.close()
		return result
	}

	// Internal function which executes statements, with parameter binding
	// Returns a processed row set
	@discardableResult
	func execRows(_ statement: String, params: [String]) throws -> [StORMRow] {
		let thisConnection = PostgresConnect(
			host:		PostgresConnector.host,
			username:	PostgresConnector.username,
			password:	PostgresConnector.password,
			database:	PostgresConnector.database,
			port:		PostgresConnector.port
		)

		thisConnection.open()
		if thisConnection.state == .bad {
			error = .connectionError
			throw StORMError.error("Connection Error")
		}
		thisConnection.statement = statement

		printDebug(statement, params)
		let result = thisConnection.server.exec(statement: statement, params: params)

		// set exec message
		errorMsg = thisConnection.server.errorMessage().trimmingCharacters(in: .whitespacesAndNewlines)
		if StORMdebug { LogFile.info("Error msg: \(errorMsg)", logFile: "./StORMlog.txt") }
		if isError() {
			thisConnection.server.close()
			throw StORMError.error(errorMsg)
		}

		let resultRows = parseRows(result)
		//		result.clear()
		thisConnection.server.close()
		return resultRows
	}


	func isError() -> Bool {
		if errorMsg.contains(string: "ERROR"), !PostgresConnector.quiet {
			print(errorMsg)
			return true
		}
		return false
	}


	/// Generic "to" function
	/// Defined as "open" as it is meant to be overridden by the child class.
	///
	/// Sample usage:
	///		id				= this.data["id"] as? Int ?? 0
	///		firstname		= this.data["firstname"] as? String ?? ""
	///		lastname		= this.data["lastname"] as? String ?? ""
	///		email			= this.data["email"] as? String ?? ""
	open func to(_ this: StORMRow) {
	}

	/// Generic "makeRow" function
	/// Defined as "open" as it is meant to be overridden by the child class.
	open func makeRow() {
		guard self.results.rows.count > 0 else {
			return
		}
		self.to(self.results.rows[0])
	}

	/// Standard "Save" function.
	/// Designed as "open" so it can be overriden and customized.
	/// If an ID has been defined, save() will perform an updae, otherwise a new document is created.
	/// On error can throw a StORMError error.

	open func save() throws {
		do {
			if keyIsEmpty() {
				try insert(asData(1))
			} else {
				let (idname, idval) = firstAsKey()
				try update(data: asData(1), idName: idname, idValue: idval)
			}
		} catch {
			LogFile.error("Error: \(error)", logFile: "./StORMlog.txt")
			throw StORMError.error("\(error)")
		}
	}

	/// Alternate "Save" function.
	/// This save method will use the supplied "set" to assign or otherwise process the returned id.
	/// Designed as "open" so it can be overriden and customized.
	/// If an ID has been defined, save() will perform an updae, otherwise a new document is created.
	/// On error can throw a StORMError error.

	open func save(set: (_ id: Any)->Void) throws {
		do {
			if keyIsEmpty() {
				let setId = try insert(asData(1))
				set(setId)
			} else {
				let (idname, idval) = firstAsKey()
				try update(data: asData(1), idName: idname, idValue: idval)
			}
		} catch {
			LogFile.error("Error: \(error)", logFile: "./StORMlog.txt")
			throw StORMError.error("\(error)")
		}
	}

	/// Unlike the save() methods, create() mandates the addition of a new document, regardless of whether an ID has been set or specified.

	override open func create() throws {
		do {
			try insert(asData())
		} catch {
			LogFile.error("Error: \(error)", logFile: "./StORMlog.txt")
			throw StORMError.error("\(error)")
		}
	}


	/// Table Creation (alias for setup)

	open func setupTable(_ str: String = "") throws {
		try setup(str)
	}
    
    /// Table creation
    /// Requires the connection to be configured, as well as a valid "table" property to have been set in the class
    ///
    /// - Parameters:
    ///   - str: This makes it so you can run your own SQL string to setup your table.
    ///   - autoIncrementPK: This makes it so if your primary key is an integer, it sets up a sequence for automatically setting your id on save().
    /// - Throws: Throws a StORM error with the description of the error.
    open func setup(_ str: String = "", autoIncrementPK : Bool = false) throws {
		LogFile.info("Running setup: \(table())", logFile: "./StORMlog.txt")
		var createStatement = str
		if str.count == 0 {
			var opt = [String]()
			var keyName = ""
			for child in self.allChildren(includingNilValues: true, primaryKey: self.primaryKeyLabel()) {
				var verbage = ""
                guard let key = child.label else {
                    continue
                }
				if !key.hasPrefix("internal_") && !key.hasPrefix("_") {
					verbage = "\(key.lowercased()) "
                    switch type(of: child.value) {
                    case is Int?.Type, is Int.Type:
                        if autoIncrementPK && opt.count == 0 {
                            verbage += "integer NOT NULL DEFAULT nextval('\(table())_id_seq'::regclass)"
                            // Lets go and create the sequence:
                            var addsequence = "CREATE SEQUENCE public.\(table())_id_seq "
                            addsequence.append("INCREMENT 1 ")
                            addsequence.append("START 1 ")
                            addsequence.append("MINVALUE 1 ")
                            addsequence.append("MAXVALUE 9223372036854775807 ")
                            addsequence.append("CACHE 1;")
                            
                            do {
                                try sql(addsequence, params: [])
                            } catch {
                                LogFile.error("Error msg: \(error)", logFile: "./StORMlog.txt")
                                throw StORMError.error("\(error)")
                            }
                            
                        } else if opt.count == 0 {
                            verbage += "serial NOT NULL"
                        } else {
                            verbage += "int8"
                        }
                    case is Bool.Type, is Bool?.Type:
                        verbage += "bool"
                    case is String.Type, is String?.Type, is [Int]?.Type, is [Int].Type, is [String].Type, is [String]?.Type, is [Any].Type, is [Any]?.Type:
                        verbage += "text"
                    case is [String:Any].Type, is [String:Any]?.Type:
                        verbage += "jsonb"
                    case is UInt.Type, is UInt8.Type, is UInt16.Type, is UInt32.Type, is UInt64.Type, is UInt?.Type, is UInt8?.Type, is UInt16?.Type, is UInt32?.Type, is UInt64?.Type:
                        verbage += "bytea"
                    case is Double.Type, is Double?.Type, is Float.Type, is Float?.Type:
                        verbage += "float8"
                    default:
                        verbage += "text"
                    }
                    if opt.count == 0 && !autoIncrementPK {
                        verbage += " NOT NULL"
                        keyName = key
                    }
                }
                opt.append(verbage)
            }
            
            var keyComponent = ""
            if !autoIncrementPK  {
                keyComponent =  ", CONSTRAINT \(table())_key PRIMARY KEY (\(keyName)) NOT DEFERRABLE INITIALLY IMMEDIATE"
            }
            
            createStatement = "CREATE TABLE IF NOT EXISTS \(table()) (\(opt.joined(separator: ", "))\(keyComponent));"
            if StORMdebug { LogFile.info("createStatement: \(createStatement)", logFile: "./StORMlog.txt") }
            
        }
        
		do {
			try sql(createStatement, params: [])
		} catch {
			LogFile.error("Error msg: \(error)", logFile: "./StORMlog.txt")
			throw StORMError.error("\(error)")
		}
	}

}
