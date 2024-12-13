//
//  History.swift
//  LifeGuard
//
//  Created by Đại Việt Hưng Trần on 12/2/24.
//
import SwiftUI
import SQLite3

class History_database {
    var db: OpaquePointer?
    let databasePath = "historydatabase.sqlite"
    let directoryPath = "/Users/hungtran/Desktop/LifeGuardProject/LifeGuard/Database"
    init() {
        getHistoryDatabase()
        getHistoryTable()
    }
    func getHistoryDatabase() {
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
    func getHistoryTable(){
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS History (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            history_content TEXT,
            username TEXT,
            time TEXT,
            address TEXT
        );
        """
        guard db != nil else {
            print("History database is not available")
            return
        }
        
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error creating database table: \(errorMessage)")
        }
        else{
            print("Table 'Users' created or already exists.")
        }
    }
    func insertHistory(history_content: String, username: String,time: String, address: String)-> Bool{
        let insertQuery = """
        INSERT INTO History (history_content, username, time, address)
        VALUES (?,?,?,?)
        """
        var statement : OpaquePointer?
        
        let histroy_content_converted = history_content as NSString
        let username_converted = username as NSString
        let time_converted = time as NSString
        let address_converted = address as NSString
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, histroy_content_converted.utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, username_converted.utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, time_converted.utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, address_converted.utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("History inserted successfully.")
                sqlite3_finalize(statement)
                return true
            }
            else {
                print("Failed to insert user.")
            }
        }else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error: \(errorMessage)")
        }
        sqlite3_finalize(statement)
        return false
    }
    func fetchAllHistory() -> [String] {
        let query = "SELECT history_content FROM History ORDER BY id ASC;"
        var statement: OpaquePointer?
        var historyData: [String] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            print("Error preparing select statement")
            return []
        }
        while sqlite3_step(statement) == SQLITE_ROW{
            if let contentCStr = sqlite3_column_text(statement, 0){
                let historyContent = String(cString: contentCStr)
                historyData.append(historyContent)
            }
        }
        sqlite3_finalize(statement)
        return historyData
    }
    func fetchAllTime() -> [String] {
        let query =  "SELECT time FROM History ORDER BY id ASC;"
        var statement: OpaquePointer?
        var timeData: [String] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            print("Error preparing select statement")
            return []
        }
        while sqlite3_step(statement) == SQLITE_ROW {
            if let contentCStr = sqlite3_column_text(statement, 0){
                let timeContent = String(cString: contentCStr)
                timeData.append(timeContent)
            }
        }
        sqlite3_finalize(statement)
        return timeData
    }
    func fetchAllAddress()-> [String] {
        let query = "SELECT address FROM History ORDER BY id ASC;"
        var statement: OpaquePointer?
        var addressData: [String] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            print("Error preparing select statment")
            return []
        }
        while sqlite3_step(statement) == SQLITE_ROW {
            if let contentCStr = sqlite3_column_text(statement, 0){
                let addressContent = String(cString: contentCStr)
                addressData.append(addressContent)
            }
        }
        sqlite3_finalize(statement)
        return addressData
    }
    func getLatestHistory() -> (content: String, address: String)? {
        let query = "SELECT history_content, address FROM History ORDER BY id DESC LIMIT 1;"
        var statement: OpaquePointer?
        var content: String?
        var address: String?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            print("Error preparing select statement")
            return nil
        }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            if let contentCStr = sqlite3_column_text(statement, 0),
               let addressCStr = sqlite3_column_text(statement, 1) {
                content = String(cString: contentCStr)
                address = String(cString: addressCStr)
            }
        }
        
        sqlite3_finalize(statement)
        
        if let content = content, let address = address {
            return (content: content, address: address)
        }
        return nil
    }
}

struct HistoryView: View {
    @State private var historyData: [String] = []
    @State private var timeData: [String] = []
    @State private var addressData : [String] = []
    
    let historyDatabase = History_database()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Iterate through reversed indices
                    ForEach(historyData.indices.reversed(), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 30)
                            .frame(width: 380, height: 200)
                            .foregroundColor(.blue)
                            .overlay(
                                VStack(alignment: .leading, spacing: 10) {
                                    if index < timeData.count { // Prevent out-of-bounds access
                                        Text("Time: \(timeData[index])")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    if index < addressData.count {
                                        Text("Location: \(addressData[index])")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    Text(historyData[index])
                                        .foregroundColor(.white)
                                        .font(.body)
                                        .lineLimit(nil)
                                }
                                .padding()
                            )
                    }
                }
                .padding()
            }
            .navigationTitle("History")
            .onAppear {
                loadHistoryData()
                loadTimeData()
                loadAddressData()// Call to load time data
            }
        }
    }

    func loadHistoryData() {
        historyData = historyDatabase.fetchAllHistory()
    }

    func loadTimeData() {
        timeData = historyDatabase.fetchAllTime() 
    }
    func loadAddressData() {
        addressData = historyDatabase.fetchAllAddress()
    }
}




#Preview{
    HistoryView()
}
