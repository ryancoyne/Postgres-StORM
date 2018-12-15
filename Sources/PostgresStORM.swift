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

    /// Optional Support - Set value to nil, add it to null update, otherwise it will not save correctly.
    private var _columnsThatNeedNullOnSave : Set<String> = []
    var nullColumns : Set<String> {
        get { return self._columnsThatNeedNullOnSave }
        set { self._columnsThatNeedNullOnSave = newValue }
    }
    
	/// Table that the child object relates to in the database.
	/// Defined as "open" as it is meant to be overridden by the child class.
	open func table() -> String {
		let m = Mirror(reflecting: self)
		return ("\(m.subjectType)").lowercased()
	}
    
    open func sequence() -> String {
        return "\(table())_id_seq"
    }

	/// Empty initializer
    required override public init() {
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

	
    /// This function saves, either inserting or updating depending on the key.  This also automatically inserts the createdby or modifiedby column user id.
    ///
    /// - Parameter auditUserId: This is the id of the user, typically a string if using PerfectAuthentication
    /// - Throws: gives a StORMError error.
    func save(auditUserId: Any, didSet: ((_ id: Any)->Void)?=nil) throws {
        do {
            var data = asData(1)
            if keyIsEmpty() {
                
                if let index = data.index(where: { (dic) -> Bool in
                    return dic.0 == "createdby"
                }) {
                    data[index].1 = String(describing: auditUserId)
                } else {
                    data.append(("createdby", String(describing: auditUserId)))
                }
                
                let id = try insert(data)
                didSet?(id)
            } else {
                let (idname, idval) = firstAsKey()
                
                if let index = data.index(where: { (dic) -> Bool in
                    return dic.0 == "modifiedby"
                }) {
                    data[index].1 = String(describing: auditUserId)
                } else {
                    data.append(("modifiedby", String(describing: auditUserId)))
                }
                try update(data: data, idName: idname, idValue: idval)
            }
        } catch {
            LogFile.error("Error: \(error)", logFile: "./StORMlog.txt")
            throw StORMError.error("\(error)")
        }
    }
    
    /// Standard "Save" function.
    /// Designed as "open" so it can be overriden and customized.
    /// If an ID has been defined, save() will perform an updae, otherwise a new document is created.
    /// On error can throw a StORMError error.
    
    open func save() throws {
        do {
            var data = asData(1)
            if keyIsEmpty() {
                try insert(data)
            } else {
                let (idname, idval) = firstAsKey()
                // If the values were back to nil they wont show in the asData function. Here we need to add the column/null value:
                if !self.nullColumns.isEmpty {
                    for column in self.nullColumns {
                        data.append((column, "null"))
                    }
                }
                try update(data: data, idName: idname, idValue: idval)
                self._columnsThatNeedNullOnSave.removeAll()
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
            var data = asData(1)
            if keyIsEmpty() {
                let setId = try insert(data)
                set(setId)
            } else {
                let (idname, idval) = firstAsKey()
                if !self.nullColumns.isEmpty {
                    for column in self.nullColumns {
                        data.append((column, "null"))
                    }
                }
                try update(data: data, idName: idname, idValue: idval)
                self._columnsThatNeedNullOnSave.removeAll()
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
    
    
    /// This create function automatically sets in the createdby userid & completes the create function.
    ///
    /// - Parameter auditUserId: This is the user id for your user auditing this table.
    /// - Throws: This throws a StORMError Error.
    func create(auditUserId: Any) throws {
        do {
            var data = asData()
            data.append(("createdby", String(describing: auditUserId)))
            try insert(data)
        } catch {
            LogFile.error("Error: \(error)", logFile: "./StORMlog.txt")
            throw StORMError.error("\(error)")
        }
    }

    // Table Exists??
    open func doesTableExist(inSchema : String="public") throws -> Bool {
        let sql = "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name='\(table())' AND table_schema='\(inSchema)');"
        if let result = try sqlRows(sql, params: []).first {
            return (result.data["exists"] as? String) == "true"
        } else {
            return false
        }
    }
    
    open func doesColumnExist(inSchema : String, column: String) throws -> Bool {
        let sql = "SELECT EXISTS (SELECT FROM information_schema.columns where table_schema='\(inSchema)' AND table_name='\(table())' AND column_name='\(column)');"
        if let result = try sqlRows(sql, params: []).first {
            return (result.data["exists"] as? String) == "true"
        } else {
            return false
        }
    }
    
    open func doesSequenceExist(inSchema : String) throws -> Bool {
        let sql = "SELECT EXISTS (SELECT FROM information_schema.sequences where sequence_schema='\(inSchema)' AND sequence_name='\(sequence())');"
        if let result = try sqlRows(sql, params: []).first {
            return (result.data["exists"] as? Bool) == true
        } else {
            return false
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
    ///   - inSchema:  This lets you set the schema for setting up the table.
    ///   - autoIncrementPK: This makes it so if your primary key is an integer, it sets up a sequence for automatically setting your id on save().
    /// - Throws: Throws a StORM error with the description of the error.
    open func setup(_ str: String = "", inSchema : String="public", autoIncrementPK : Bool = false) throws {
		LogFile.info("Running setup: \(table())", logFile: "./StORMlog.txt")
        
        // First lets check if the table exists already or not, then we know we may need to do some modifications to the table:
        if try self.doesTableExist(inSchema: inSchema) {
            // Table exists.. lets go and update the table!
            // We are assuming the sequence has been created.  We are going and checking for updates to column names or a new column itself here:
            var updateStatement = str
            for child in self.allChildren(includingNilValues: true, primaryKey: self.primaryKeyLabel()) {
                // Make sure we have a label for the value:
                guard let key = child.label else { continue }
                
                if !key.hasPrefix("internal_") && !key.hasPrefix("_"), try self.doesColumnExist(inSchema: inSchema, column: key) {
                    // Okay the column does exist.  We need to check for changes.
                } else {
                    // Okay the column does NOT exist.  Lets add this as an update to the table.. but first we need to get the data type:
                    var data_type = ""
                    var constraint = ""
                    
                    // If the user adds a default, than we will add a default here under the constraint.
                    let valIsNil = (String(describing: child.value) == "nil")
                    if let dbType = String(databaseType: child.value) {
                        data_type = dbType
                    } else {
                        switch type(of: child.value) {
                        case is Int?.Type, is Int.Type:
                            // It is in an integer:
                            data_type = "int8"
                            if !valIsNil {
                                constraint = " NOT NULL DEFAULT \(child.value as! Int) "
                            }
                        case is Bool.Type, is Bool?.Type:
                            data_type = "bool"
                        case is String.Type, is String?.Type, is [Int]?.Type, is [Int].Type, is [String].Type, is [String]?.Type, is [Any].Type, is [Any]?.Type:
                            data_type = "text"
                        case is [String:Any].Type, is [String:Any]?.Type:
                            data_type = "jsonb"
                        case is UInt.Type, is UInt8.Type, is UInt16.Type, is UInt32.Type, is UInt64.Type, is UInt?.Type, is UInt8?.Type, is UInt16?.Type, is UInt32?.Type, is UInt64?.Type:
                            data_type = "bytea"
                        case is Double.Type, is Double?.Type, is Float.Type, is Float?.Type:
                            data_type = "float8"
                        default: break
                        }
                    }
                    
                    updateStatement.append("ALTER TABLE \(inSchema).\(table()) ADD COLUMN \(key) \(data_type) \(constraint)")
                }
            }
            
        } else {
            // Go and create the NEW table:
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
                        // Take care of the custom data types:
                        if let dbType = String(databaseType: child.value) {
                            verbage += dbType
                        } else {
                            switch type(of: child.value) {
                            case is Int?.Type, is Int.Type:
                                if autoIncrementPK && opt.count == 0, try !self.doesSequenceExist(inSchema: inSchema) {
                                    
                                    verbage += "integer NOT NULL DEFAULT nextval('\(inSchema).\(sequence())'::regclass)"
                                    // Lets go and create the sequence:
                                    var addsequence = "CREATE SEQUENCE \(inSchema).\(sequence()) "
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
                                    verbage += "serial"
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
                        }
                        
                        if opt.count == 0 && !autoIncrementPK {
                            verbage += " NOT NULL"
                            keyName = key
                        }
                        opt.append(verbage)
                    }
                }
                
                var keyComponent = ""
                if !autoIncrementPK  {
                    keyComponent =  ", CONSTRAINT \(table())_key PRIMARY KEY (\(keyName)) NOT DEFERRABLE INITIALLY IMMEDIATE"
                }
                
                createStatement = "CREATE TABLE IF NOT EXISTS \(inSchema).\(table()) (\(opt.joined(separator: ", "))\(keyComponent));"
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

}
