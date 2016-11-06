//
//  CuochDB.swift
//  PerfectCouchDB
//
//  Created by Jonatha Guthrie on 2016-10-24.
//	Copyright (C) 2016 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectCURL
import cURL

/// This enum type indicates an exception when dealing with a CouchDB database
public enum CouchDBError : Error {
	/// A CouchDB error code and message.
	case Error(code: Int, msg: String)

	/*
		401 - Session authentication failed
	
		1001 - Events error: Feed must be one of longpoll, continuous, or eventsource
	*/
}

public enum HTTPMethod : String {
	case get		= "GET"
	case post		= "POST"
	case head		= "HEAD"
	case put		= "PUT"
	case delete		= "DELETE"
	case copy		= "COPY"
}


class CouchDB {

	var debug: Bool		= false
    var database		= ""
	var connector		= CouchDBConnector()			// defaults have been defined in connector
	var authentication	= CouchDBAuthentication()		// default is for none

	public init() {}

	/// Define a CouchDB database
	/// - parameter db: String path to CouchDB database
	public init(_ db: String) {
		database = db
	}
	public init(_ c: CouchDBConnector) {
		connector = c
	}


	/*
		SESSION AUTHENTICATION
	*/
	public func getToken() throws -> Bool {
		guard let _ = authentication.username, let _ = authentication.password else {
			throw CouchDBError.Error(code: 401, msg: "Please supply a username or password.")
		}
		let body = authentication.sessionJSON()
		let (code, _, _, _) = makeRequest(.post, "/_session", body: body)
//		let (code, response, raw, header) = makeRequest(.post, "/_session", body: body)
		// need to handle code options...
		print(code)
		return true
	}



	/*
		SERVER API FUNCTIONS
	*/


	/// Server Info
	public func serverInfo() -> (CouchDBResponse, [String:Any]) {
		let (code, response, _, _) = makeRequest(.get, "/")
		return (code, response)
	}

	/// Server Active Tasks
	public func serverActiveTasks() -> (CouchDBResponse, [String:Any]) {
		let (code, response, _, _) = makeRequest(.get, "/_active_tasks")
		return (code, response)
	}

	/// Server - List all databases
	public func listDatabases() -> (CouchDBResponse, [String:Any]) {
		let (code, response, _, _) = makeRequest(.get, "/_all_dbs")
		return (code, response)
	}

	/// Server - List all database events
	///	Query Parameters:
	//	- feed (string) –
	//		- longpoll: Closes the connection after the first event.
	//		- continuous: Send a line of JSON per event. Keeps the socket open until timeout.
	//		- eventsource: Like, continuous, but sends the events in EventSource format.
	//	- timeout (number) – Number of seconds until CouchDB closes the connection. Default is 60.
	//	- heartbeat (boolean) – Whether CouchDB will send a newline character (\n) on timeout. Default is true.

	public func listDatabaseEvents(feed: String = "longpoll", timeout: Int = 60, heartbeat: Bool = true) throws -> (CouchDBResponse, [String:Any]) {
		let allowableFeed = ["longpoll", "continuous", "eventsource"]
		if !allowableFeed.contains(feed) {
			throw CouchDBError.Error(code: 1001, msg: "Feed must be one of longpoll, continuous, or eventsource.")
		}
		let options = "?feed=\(feed)&timeout=\(timeout)&heartbeat=\(heartbeat)"
		let (code, response, _, _) = makeRequest(.get, "/_db_updates\(options)")
		return (code, response)
	}

	/// Server - List node membership
	/// Displays the nodes that are part of the cluster as cluster_nodes. The field all_nodes displays all nodes this node knows about, including the ones that are part of the cluster. The endpoint is useful when setting up a cluster, see Node Management
	public func listNodeMembership() -> (CouchDBResponse, [String:Any]) {
		let (code, response, _, _) = makeRequest(.get, "/_membership")
		return (code, response)
	}

	/// Server - Retrieve Server log
	/// Gets the CouchDB log, equivalent to accessing the local log file of the corresponding CouchDB instance.
	public func log(bytes: Int = 1000, offset: Int = 0) throws -> (CouchDBResponse, [String:Any]) {
		let options = "?bytes=\(bytes)&offset=\(offset)"
		let (code, response, _, _) = makeRequest(.get, "/_log\(options)")
		return (code, response)
	}



/*
	10.2.6. /_log
	10.2.7. /_replicate
	Replication Operation
	Specifying the Source and Target Database
	Single Replication
	Continuous Replication
	Canceling Continuous Replication
	10.2.8. /_restart
	10.2.9. /_stats
	couchdb
	httpd_request_methods
	httpd_status_codes
	httpd
	10.2.10. /_utils
	10.2.11. /_uuids

*/


	/*
	DATABASE API FUNCTIONS
		HEAD /{db}
			Returns the HTTP Headers containing a minimal amount of information about the specified database. Since the response body is empty, using the HEAD method is a lightweight way to check if the database exists already or not.

		GET /{db}
			Gets information about the specified database.

		PUT /{db}
			Creates a new database

		DELETE /{db}
			Deletes the specified database, and all the documents and attachments contained within it
	*/

	/// Check if Database Exists
	// Returns true / false
	public func databaseExists(_ name: String) -> Bool {
		let (code, _, _, _) = makeRequest(.head, "/\(name)")
		if code == .ok { return true }
		return false
	}

	/// Create Database
	/// - sets current database to new database
	public func databaseCreate(_ name: String) -> CouchDBResponse {
		// TODO: do db name check

		let (code, data, raw, http) = makeRequest(.put, "/\(name)")
		if debug {
			print("[DEBUG] Code: \(code)")
			print("[DEBUG] Data: \(data)")
			print("[DEBUG] Raw: \(raw)")
			print("[DEBUG] http: \(http.variables)")
		}
		if code == .created { database = name }
		if debug { print("[DEBUG] Database set to: \(database)") }
		return code
	}
	
	/// Delete Database
	@discardableResult
	public func databaseDelete(_ name: String = "") -> CouchDBResponse {
		// TODO: do db name check
		if !name.isEmpty { database = name }
		if database.isEmpty { return (.notAcceptable) }

		let (code, _, _, _) = makeRequest(.delete, "/\(database)")
		database = ""
		return code
	}
	
	/// Get Database Info
	///	- committed_update_seq (number) – The number of committed update.
	///	- compact_running (boolean) – Set to true if the database compaction routine is operating on this database.
	///	- db_name (string) – The name of the database.
	///	- disk_format_version (number) – The version of the physical format used for the data when it is stored on disk.
	///	- data_size (number) – The number of bytes of live data inside the database file.
	///	- disk_size (number) – The length of the database file on disk. Views indexes are not included in the calculation.
	///	- doc_count (number) – A count of the documents in the specified database.
	///	- doc_del_count (number) – Number of deleted documents
	///	- instance_start_time (string) – Timestamp of when the database was opened, expressed in microseconds since the epoch.
	///	- purge_seq (number) – The number of purge operations on the database.
	///	- update_seq (number) – The current number of updates to the database.
	/// 	Status Codes - 200 OK; 404 Not Found – Requested database not found
	public func databaseInfo(_ name: String = "") -> (CouchDBResponse, [String:Any]) {
		// TODO: do db name check
		if !name.isEmpty { database = name }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		let (code, response, _, _) = makeRequest(.get, "/\(database)")
		return (code, response)
	}

	public func addDoc(_ name: String = "", doc: [String: Any], id: String = "") throws -> (CouchDBResponse, [String:Any]) {
		// TODO: do db name check
		if !name.isEmpty { database = name }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		var docStore: String?

//		if let str = doc as? String {
//			do {
//				docStore = try str.jsonEncodedString()
//			} catch {
//				print(error)
//				throw CouchDBError.Error(code: 201, msg: "Invalid String as JSON")
//			}
//		} else
//			if let str = doc as? [String: Any] {
			do {
				docStore = try doc.jsonEncodedString()
				print("Encoded: \(docStore!)")
			} catch {
				print(error)
				throw CouchDBError.Error(code: 201, msg: "Invalid [String:Any] as JSON")
			}
//		}
//			else if let str = doc as? [Any] {
//			do {
//				docStore = try str.jsonEncodedString()
//			} catch {
//				print(error)
//				throw CouchDBError.Error(code: 201, msg: "Invalid [Any] as JSON")
//			}
//		}

//		guard let docStoreOK = docStore else {
//			throw CouchDBError.Error(code: 201, msg: "Invalid Input as JSON")
//		}
		print(docStore!)
		let (code, response, _, _) = makeRequest(.post, "/\(database)/", body: docStore!)
		return (code, response)
	}

}








