import SQLite3
import Foundation

class DatabaseManager {
    var db: OpaquePointer?
    let databasePath = "database.sqlite"
    let directoryPath = "/Users/hungtran/Desktop/LifeGuardProject/LifeGuard/Database"
    
    init() {
        getDatabase()
        getTable()
    }
    
    // Open or create the database
    func getDatabase() {
        do {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: directoryPath) {
                try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            }
            let filePath = "\(directoryPath)/\(databasePath)"
            print("Database path: \(filePath)")
            if sqlite3_open(filePath,&db) != SQLITE_OK {
                print("Error opening database at \(filePath)")
                db = nil
            } else {
                print("Database successfully opened/ created at \(filePath) ")
            }
        } catch {
            print("Error creating database file URL: \(error.localizedDescription)")
        }
    }
    
    
    // Create the Users table if it doesn't exist
    func getTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT,
            username TEXT UNIQUE,
            password TEXT,
            email TEXT UNIQUE,
            phone_number TEXT UNIQUE
        );
        """
        
        guard db != nil else {
            print("Database connection is not available.")
            return
        }
        
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error creating database table: \(errorMessage)")
        } else {
            print("Table 'Users' created or already exists.")
        }
    }
    
    // Insert a user into the Users table
    func insertUser(username: String, password: String, phone_number: String, email: String, full_name: String) -> Bool {
        let insertQuery = """
        INSERT INTO Users (full_name, username, password, phone_number, email) 
        VALUES (?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        
        let full_name_converted = full_name as NSString
        let username_converted = username as NSString
        let password_converted = password as NSString
        let phone_number_converted = phone_number as NSString
        let email_converted = email as NSString
        
        // Construct the actual query for logging purposes
        let actualQuery = """
        INSERT INTO Users (full_name, username, password, phone_number, email) 
        VALUES ('\(full_name)', '\(username)', '\(password)', '\(phone_number)', '\(email)');
        """
        print("Actual Query: \(actualQuery)") // Log the real query

        // Prepare the query
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            // Bind the parameters
            sqlite3_bind_text(statement, 1, full_name_converted.utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, username_converted.utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, password_converted.utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, phone_number_converted.utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, email_converted.utf8String, -1, nil)
            

            // Execute the statement
            if sqlite3_step(statement) == SQLITE_DONE {
                print("User inserted successfully.")
                sqlite3_finalize(statement)
                return true
            } else {
                print("Failed to insert user.")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error preparing insert: \(errorMessage)")
        }

        // Finalize the statement
        sqlite3_finalize(statement)
        return false
    }

    
    // Authenticate a user by username and password
    func authenticate(username: String, password: String) -> Bool {
        let query = "SELECT * FROM Users WHERE username = ? AND password = ?;"
        var statement: OpaquePointer?
        
        guard db != nil else {
            print("Database connection is not available.")
            return false
        }
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            print("Error preparing query: \(String(cString: sqlite3_errmsg(db)))")
            return false
        }
        
        let username_converted = username as NSString
        let password_converted = password as NSString
        
        sqlite3_bind_text(statement, 1, username_converted.utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, password_converted.utf8String, -1, nil)
        
        let result = sqlite3_step(statement)
        sqlite3_finalize(statement)
        
        return result == SQLITE_ROW
    }
    
    func fetchUserInfo(username: String) -> (full_name: String, phone_number: String, email: String)? {
            let query = "SELECT full_name, phone_number, email FROM Users WHERE username = ?"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing select statement")
                return nil
            }
        let username_converted = username as NSString
            // Bind the username parameter
        sqlite3_bind_text(statement, 1, username_converted.utf8String, -1, nil)
        
            // Execute the query and fetch the result
            if sqlite3_step(statement) == SQLITE_ROW {
                let fullName = String(cString: sqlite3_column_text(statement, 0))
                let phoneNumber = String(cString: sqlite3_column_text(statement, 1))
                let email = String(cString: sqlite3_column_text(statement, 2))
                sqlite3_finalize(statement)
                return (fullName, phoneNumber, email)
            }else{
                print("Failed to fetch user data")
            }
        
        
            sqlite3_finalize(statement)
            return nil
        }
}
