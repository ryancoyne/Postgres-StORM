# Postgres-StORM

Postgres-StORM is the PostgreSQL module for StORM - a Swift ORM.

It aims to be easy to use, but flexible. Drawing on previous experiences, whether they be good, bad or ugly, of other ORM's, I have tried to build a system that allows you write great code without worrying about the details of how to interact with the database.

Other database wrappers will be available shortly. They will all use the StORM base, and provide as much consistency between datasources as possible.

StORM is built on top of [Perfect](https://github.com/PerfectlySoft/Perfect) - the most mature of the Server Side Swift platforms.

### What does it do?

* Abstracts the database layer from your code.
* Provides a way of adding save, delete, find to your Swift classes
* Gives you access to more powerful select, insert, update, delete, and raw SQL querying.
* Maps result sets to your classes


### What does it not do?

Right now there are a few things missing, but the basics are there. 

On the "TODO" list are:

* complete joins
* complete having
* complete group by
* upsert
* documentation
* complete test coverage

# Latest Update:

- Adds support to setup a table with an auto-incrementing integer primary key.
- Adds support for optional declared variables in PostgresStORM models.
- Adds support for automatic created/modified fields as integer date values on your create() or save(), as well as a new written function for create/save that you can pass an auditUserId to automatically set the createdby or modifiedby field.
- Adds support for subclassing PostgresStORM models (Say a class just for AuditFields created, createdby, modified, modifiedby.
- Adds support for updating values going from oldValue != nil to being equal to nil & adds an update SQL statement to set it back to NULL/DEFAULT.

## Examples:

### Setup a table with an auto-incrementing integer primary key:
Suppose we have the following models.  
```
class AuditFields: PostgresStORM {
    
    /// This is when the table row has been created.
    var created : Int?           = nil
    /// This is the id of the user that has created the row.
    var createdby : String?  = nil
    /// This is when the table row has been modified.
    var modified : Int?          = nil
    /// This is the id of the user that has modified the row.
    var modifiedby : String? = nil
    
    // This is needed when created a subclass containing other fields to re-use for other models.
    override init() {
        super.init()
        self.didInitializeSuperclass()
    }
}

// The outer most class does not need to override init & call didInitializeSuperclass.  This helps with identifying the id in the model.
class TestUser2: AuditFields {
    // Notice we now do not need to put id at the top.  However, this is backwards compatable, meaning if you do not want to subclass, or if someone updates & has the same models as configured before, they do not need to add any extra code to set the primaryKeyLabel.
    var firstname : String?          = nil {
        didSet {
            if oldValue != nil && firstname == nil {
                self.nullColumns.insert("firstname")
            } else if firstname != nil {
                self.nullColumns.remove("firstname")
            }
        }
    }
    var lastname : String?          = nil {
        didSet {
            if oldValue != nil && lastname == nil {
                self.nullColumns.insert("lastname")
            } else if firstname != nil {
                self.nullColumns.remove("lastname")
            }
        }
    }
    var phonenumber : String? = nil {
        didSet {
            if oldValue != nil && phonenumber == nil {
                self.nullColumns.insert("phonenumber")
            } else if firstname != nil {
                self.nullColumns.remove("phonenumber")
            }
        }
    }
    var id : Int?                             = nil
    
    override open func table() -> String {
        return "testuser2"
    }
    
    // This is only needed if the id for the table is outside the scope of this class.  This also gives us the flexibilty of having the primary key placed anywhere in the model.
    override open func primaryKeyLabel() -> String? {
        return "id"
    }
    
    override func to(_ this: StORMRow) {
        
        // Audit fields:
        id                = this.data["id"] as? Int
        created     = this.data["created"] as? Int
        createdby     = this.data["createdby"] as? String
        modified     = this.data["modified"] as? Int
        modifiedby     = this.data["modifiedby"] as? String
        
        firstname        = this.data["firstname"] as? String
        lastname        = this.data["lastname"] as? String
        phonenumber            = this.data["phonenumber"] as? String
        
    }
    
    func rows() -> [TestUser2] {
        var rows = [TestUser2]()
        for i in 0..<self.results.rows.count {
            let row = TestUser2()
            row.to(self.results.rows[i])
            rows.append(row)
        }
        return rows
    }
    
}
```
To create this table with an auto-incrementing integer, you would do the following:
```
let createTable = TestUser2()
createTable.setup(autoIncrementingPK: true)
```
To create that table WITHOUT the auto-incrementing integer key, you would just call setup like normal:
```
let createTable = TestUser2()
createTable.setup()
```

### Primary Key Easability:
Notice in the TestUser2 model we are able to have the id for the user down below the firstname or the lastname variables.  You will only be able to do this if you implement the override function for primaryKeyLabel & specify the label of the primary key.  This also gives you the ability to put the id in the AuditFields class, however you will need to still specify in the top class what your id label is.  

Notice you also have to implement an override function for your initializer for AuditFields, indicating that you have initialized a superclass for your main PostgresStORM class.

However, you do NOT need to override the primaryKeyLabel if you have the id as your first variable in your top class.

### Automatic created/modified & createdby/modifiedby:
You may either declare these variables as optional, or have a default and deal without optionals.  Either way, if you have a fieldname of created or modified, it will automatically set in the INTEGER epoch value.

Updating the createdby & modifiedby will be at the PostgresStORM database level.  You will pass in the auditUserId as follows on your create or save function:
```
func handleSomeEndpoint() -> RequestHandler {
    request, response in 
    
    guard let session = request.session else { response.notLoggedIn() }
    let user = TestUser()
    user.firstname = "First"
    user.lastname  = "Last"
    // This wont have an id so we would insert, automatically setting the created integer epoch value.  
    // Saving specifying the auditUserId will automatically fill either createdby or modifiedby fields.
    try? user.save(auditUserId: session.userid)
    //OR 
    // This will still automatically set created or modified integer date.
    try? user.save()
}

```
