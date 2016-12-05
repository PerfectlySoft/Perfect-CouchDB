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
	/// 401 - Session authentication failed
	/// 1001 - Events error: Feed must be one of longpoll, continuous, or eventsource
	case Error(code: Int, msg: String)
}

/// Defines the allowable HTTP Methods for CouchDB interaction
public enum HTTPMethod : String {
	case get		= "GET"
	case post		= "POST"
	case head		= "HEAD"
	case put		= "PUT"
	case delete		= "DELETE"
	case copy		= "COPY"
}


/// Main CouchDB Class
public class CouchDB {

	/// Boolean switch for enabling/disabling debug mode
	public var debug: Bool		= false
    public var database		= ""
	public var connector		= CouchDBConnector()			// defaults have been defined in connector
	public var authentication	= CouchDBAuthentication()		// default is for none

	public init() {}

	/// Define a CouchDB database
	/// - parameter db: String path to CouchDB database
	public init(_ db: String) {
		database = db
	}

	/// Define a CouchDB instance with a connector
	/// - parameter c: CouchDBConnector object
	public init(_ c: CouchDBConnector) {
		connector = c
	}


	/* ===============================================================================================
		SESSION AUTHENTICATION
	
		Disabled for now.
	=============================================================================================== */
//	public func getToken() throws -> Bool {
//		guard let _ = authentication.username, let _ = authentication.password else {
//			throw CouchDBError.Error(code: 401, msg: "Please supply a username or password.")
//		}
//		let body = authentication.sessionJSON()
//		let (code, response, raw, header) = makeRequest(.post, "/_session", body: body)
////		let (code, response, raw, header) = makeRequest(.post, "/_session", body: body)
//		// need to handle code options...
//		print(code)
//		print(response)
//		print(raw)
//		print(header)
//		return true
//	}



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
	///	- feed (string) –
	///		- longpoll: Closes the connection after the first event.
	///		- continuous: Send a line of JSON per event. Keeps the socket open until timeout.
	///		- eventsource: Like, continuous, but sends the events in EventSource format.
	///	- timeout (number) – Number of seconds until CouchDB closes the connection. Default is 60.
	///	- heartbeat (boolean) – Whether CouchDB will send a newline character (\n) on timeout. Default is true.
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
	/// Returns true / false
	public func databaseExists(_ db: String) -> Bool {
		let (code, _, _, _) = makeRequest(.head, "/\(db)")
		if code == .ok { return true }
		return false
	}

	/// Create Database
	/// - sets current database to new database
	public func databaseCreate(_ db: String) -> CouchDBResponse {
		// TODO: do db name check

		let (code, data, raw, http) = makeRequest(.put, "/\(db)")
		if debug {
			print("[DEBUG] Code: \(code)")
			print("[DEBUG] Data: \(data)")
			print("[DEBUG] Raw: \(raw)")
			print("[DEBUG] http: \(http.variables)")
		}
		if code == .created { database = db }
		if debug { print("[DEBUG] Database set to: \(database)") }
		return code
	}
	
	/// Delete Database
	@discardableResult
	public func databaseDelete(_ db: String = "") -> CouchDBResponse {
		// TODO: do db name check
		if !db.isEmpty { database = db }
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


	///	Creates a new document in the specified database, using the supplied JSON document structure.
	///	If the JSON structure includes the _id field, then the document will be created with the specified document ID.
	///	If the _id field is not specified, a new unique ID will be generated, following whatever UUID algorithm is configured for that server.
	/// Parameters:
	/// - db: The database name
	/// - doc: The document to be stored.
	/// The stored document can be supplied as a JSON encoded string, or as a [String: Any] type.
	/// Returns a tuple of CouchDBResponse and the returned JSON as [String:Any]
	public func addDoc(_ db: String = "", doc: Any) throws -> (CouchDBResponse, [String:Any]) {
		
		if !db.isEmpty { database = db }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		var docStore: String?

		if let str = doc as? String {
			// Presuming this is an already JSON encoded string.
			docStore = str
		} else
			if let str = doc as? [String: Any] {
			do {
				docStore = try str.jsonEncodedString()
			} catch {
				print(error)
				throw CouchDBError.Error(code: 201, msg: "Invalid [String:Any] as JSON")
			}
		}
		else if let str = doc as? [Any] {
			do {
				docStore = try str.jsonEncodedString()
			} catch {
				print(error)
				throw CouchDBError.Error(code: 201, msg: "Invalid [Any] as JSON")
			}
		}

		guard docStore != nil else {
			throw CouchDBError.Error(code: 201, msg: "Invalid Input as JSON")
		}
//		print(docStore!)
		let (code, response, _, _) = makeRequest(.post, "/\(database)/", body: docStore!)
		return (code, response)
	}


	// get all docs
	// http://127.0.0.1:5984/testdb/_all_docs
	//	{"total_rows":1,"offset":0,"rows":[
	//	{"id":"c14bf647a2ff6585437b779b9e00042c","key":"c14bf647a2ff6585437b779b9e00042c","value":{"rev":"1-6f5fa1d234523785d4bfd92b1df25707"}}
	//	]}
	// GET /{db}/_all_docs
	// http://127.0.0.1:5984/_utils/docs/api/database/bulk-api.html#get--db-_all_docs

	/// Returns a JSON structure of all of the documents in a given database. The information is returned as a JSON structure containing meta information about the return structure, including a list of all documents and basic contents, consisting the ID, revision and key. The key is the from the document’s _id.
	/// Uses the CouchDB _all_docs route
	///
	/// Parameters:
	/// db – Database name
	/// queryParams - CouchDBQuery type.
	///
	///	Response JSON Object:
	///	offset (number) – Offset where the document list started
	///	rows (array) – Array of view row objects. By default the information returned contains only the document ID and revision.
	///	total_rows (number) – Number of documents in the database/view. Note that this is not the number of rows returned in the actual query.
	///	update_seq (number) – Current update sequence for the database
	public func filter(_ db: String = "", queryParams: CouchDBQuery) throws -> (CouchDBResponse, [String:Any]) {

		if !db.isEmpty { database = db }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		let queryParamJSON = queryParams.json()
		
		let (code, response, _, _) = makeRequest(.post, "/\(database)/_all_docs", body: queryParamJSON)
		return (code, response)
	}

	// http://127.0.0.1:5984/_utils/docs/api/database/find.html
	/// Find documents using a declarative JSON querying syntax. Queries can use the built-in _all_docs index or custom indices, specified using the _index endpoint.
	///
	///	Query Parameters:
		///	selector (json) – JSON object describing criteria used to select documents. More information provided in the section on selector syntax.
		///	limit (number) – Maximum number of results returned. Default is 25. Optional
		///	skip (number) – Skip the first ‘n’ results, where ‘n’ is the value specified. Optional
		///	sort (json) – JSON array following sort syntax. Optional
		///	fields (json) – JSON array specifying which fields of each object should be returned. If it is omitted, the entire object is returned. More information provided in the section on filtering fields. Optional
		///	use_index (json) – Instruct a query to use a specific index. Specified either as "<design_document>" or ["<design_document>", "<index_name>"]. Optional
	/// Response JSON Object:
		///	docs (object) – Documents matching the selector
	///	Status Codes:
	///	200 OK – Request completed successfully
	///	400 Bad Request – Invalid request
	///	401 Unauthorized – Read permission required
	///	500 Internal Server Error – Query execution error

	public func find(_ db: String = "", queryParams: CouchDBQuery) throws -> (CouchDBResponse, [String:Any]) {
		if !db.isEmpty { database = db }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		let queryParamJSON = queryParams.jsonfind()

		let (code, response, _, _) = makeRequest(.post, "/\(database)/_find", body: queryParamJSON)
		return (code, response)
	}

	// http://127.0.0.1:5984/_utils/docs/api/database/find.html#db-explain
	/// Query parameters are the same as find.
	///
	///	Response JSON Object:
		///	dbname (string) – Name of database
		///	index (object) – Index used to fullfil the query
		///	selector (object) – Query selector used
		///	opts (object) – Query options used
		///	limit (number) – Limit parameter used
		///	skip (number) – Skip parameter used
		///	fields (object) – Fields to be returned by the query
		///	range (object) – Range parameters passed to the underlying view
	///
	///	Status Codes:
	///	200 OK – Request completed successfully
	///	400 Bad Request – Invalid request
	///	401 Unauthorized – Read permission required
	///	500 Internal Server Error – Execution error
	public func explain(_ db: String = "", queryParams: CouchDBQuery) throws -> (CouchDBResponse, [String:Any]) {
		if !db.isEmpty { database = db }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		let queryParamJSON = queryParams.jsonfind()

		let (code, response, _, _) = makeRequest(.post, "/\(database)/_explain", body: queryParamJSON)
		return (code, response)
	}




	// http://127.0.0.1:5984/_utils/docs/api/document/common.html#get--db-docid
	///	Returns document by the specified docid from the specified db. Unless you request a specific revision, the latest revision of the document will always be returned.
	///
	///	Parameters:
		///	db – Database name
		///	docid – Document ID
	///
	///	Query Parameters:
		///	attachments (boolean) – Includes attachments bodies in response. Default is false
		///	att_encoding_info (boolean) – Includes encoding information in attachment stubs if the particular attachment is compressed. Default is false.
		///	atts_since (array) – Includes attachments only since specified revisions. Doesn’t includes attachments for specified revisions. Optional
		///	conflicts (boolean) – Includes information about conflicts in document. Default is false
		///	deleted_conflicts (boolean) – Includes information about deleted conflicted revisions. Default is false
		///	latest (boolean) – Forces retrieving latest “leaf” revision, no matter what rev was requested. Default is false
		///	local_seq (boolean) – Includes last update sequence for the document. Default is false
		///	meta (boolean) – Acts same as specifying all conflicts, deleted_conflicts and open_revs query parameters. Default is false
		///	open_revs (array) – Retrieves documents of specified leaf revisions. Additionally, it accepts value as all to return all leaf revisions. Optional
		///	rev (string) – Retrieves document of specified revision. Optional
		///	revs (boolean) – Includes list of all known document revisions. Default is false
		///	revs_info (boolean) – Includes detailed information for all known document revisions. Default is false
	///
	///	Response JSON Object:
		///	_id (string) – Document ID
		///	_rev (string) – Revision MVCC token
		///	_deleted (boolean) – Deletion flag. Available if document was removed
		///	_attachments (object) – Attachment’s stubs. Available if document has any attachments
		///	_conflicts (array) – List of conflicted revisions. Available if requested with conflicts=true query parameter
		///	_deleted_conflicts (array) – List of deleted conflicted revisions. Available if requested with deleted_conflicts=true query parameter
		///	_local_seq (string) – Document’s update sequence in current database. Available if requested with local_seq=true query parameter
		///	_revs_info (array) – List of objects with information about local revisions and their status. Available if requested with open_revs query parameter
		///	_revisions (object) – List of local revision tokens without. Available if requested with revs=true query parameter
	///
	///	Status Codes:
		///	200 OK – Request completed successfully
		///	304 Not Modified – Document wasn’t modified since specified revision
		///	400 Bad Request – The format of the request or revision was invalid
		///	401 Unauthorized – Read privilege required
		///	404 Not Found – Document not found
	public func get(
		_ db: String = "",
		docid: String,
		attachments: Bool = false,
		att_encoding_info: Bool = false,
		atts_since: [String] = [String](),
		conflicts: Bool = false,
		deleted_conflicts: Bool = false,
		latest: Bool = false,
		local_seq: Bool = false,
		meta: Bool = false,
		open_revs: [String] = [String](),
		rev: String = "",
		revs: Bool = false,
		revs_info: Bool = false
	) throws -> (CouchDBResponse, [String:Any]) {
		if !db.isEmpty { database = db }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		if docid.isEmpty { return (.notAcceptable, [String:Any]()) }

		// assemble JSON
		var queryParams = [String:Any]()
		queryParams["attachments"] = attachments
		queryParams["att_encoding_info"] = att_encoding_info
		if atts_since.count > 0 { queryParams["atts_since"] = atts_since }
		queryParams["conflicts"] = conflicts
		queryParams["deleted_conflicts"] = deleted_conflicts
		queryParams["latest"] = latest
		queryParams["local_seq"] = local_seq
		queryParams["meta"] = meta
		if open_revs.count > 0 { queryParams["open_revs"] = open_revs }
		if rev.characters.count > 0 { queryParams["rev"] = rev }
		queryParams["revs"] = revs
		queryParams["revs_info"] = revs_info

		do {
			let queryParamJSON = try queryParams.jsonEncodedString()
			let (code, response, _, _) = makeRequest(.get, "/\(database)/\(docid)", body: queryParamJSON)
			return (code, response)
		} catch {
			print(error)
			throw CouchDBError.Error(code: 201, msg: "Invalid [String:Any] as JSON")
		}

	}


	// http://127.0.0.1:5984/_utils/docs/api/document/common.html#put--db-docid
	/// Creates a new named document, or creates a new revision of the existing document. Unlike the POST /{db}, you must specify the document ID in the request URL.
	///	Parameters:
		///	db – Database name
		///	docid – Document ID
		/// doc - [String: Any] object to be stored as JSON
	///
	///	Query Parameters:
		///	batch (string) – Stores document in batch mode. Possible values: ok. Optional
		///	new_edits (boolean) – Prevents insertion of a conflicting document. Possible values: true (default) and false. If false, a well-formed _rev must be included in the document. new_edits=false is used by the replicator to insert documents into the target database even if that leads to the creation of conflicts. Optional
	///
	///	Response JSON Object:
		///	id (string) – Document ID
		///	ok (boolean) – Operation status
		///	rev (string) – Revision MVCC token
	///
	///	Status Codes:
		///	201 Created – Document created and stored on disk
		///	202 Accepted – Document data accepted, but not yet stored on disk
		///	400 Bad Request – Invalid request body or parameters
		///	401 Unauthorized – Write privileges required
		///	404 Not Found – Specified database or document ID doesn’t exists
		///	409 Conflict – Document with the specified ID already exists or specified revision is not latest for target document
	public func create(_ db: String = "", docid: String, doc: [String: Any]) throws -> (CouchDBResponse, [String:Any]) {
		if !db.isEmpty { database = db }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		if docid.isEmpty { return (.notAcceptable, [String:Any]()) }

		do {
			let body = try doc.jsonEncodedString()
			let (code, response, _, _) = makeRequest(.put, "/\(database)/\(docid)", body: body)
			return (code, response)
		} catch {
			print(error)
			throw CouchDBError.Error(code: 201, msg: "Invalid [String:Any] as JSON")
		}
	}


	// http://127.0.0.1:5984/_utils/docs/api/document/common.html#delete--db-docid
	/// Marks the specified document as deleted by adding a field _deleted with the value true. Documents with this field will not be returned within requests anymore, but stay in the database. You must supply the current (latest) revision by using the rev parameter.
	/// Note: CouchDB doesn’t completely delete the specified document. Instead, it leaves a tombstone with very basic information about the document. The tombstone is required so that the delete action can be replicated across databases.
	///	Parameters:
		///	db – Database name
		///	docid – Document ID
		/// rev - Actual document’s revision
	///
	///	Response JSON Object:
		///	id (string) – Document ID
		///	ok (boolean) – Operation status
		///	rev (string) – Revision MVCC token
	///
	///	Status Codes:
		///	200 OK – Document successfully removed
		///	202 Accepted – Request was accepted, but changes are not yet stored on disk
		///	400 Bad Request – Invalid request body or parameters
		///	401 Unauthorized – Write privileges required
		///	404 Not Found – Specified database or document ID doesn’t exists
		///	409 Conflict – Specified revision is not the latest for target document
	public func delete(_ db: String = "", docid: String, rev: String) throws -> (CouchDBResponse, [String:Any]) {
		if !db.isEmpty { database = db }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		if docid.isEmpty { return (.notAcceptable, [String:Any]()) }

		let (code, response, _, _) = makeRequest(.delete, "/\(database)/\(docid)?rev=\(rev)")
		return (code, response)
	}

	// http://127.0.0.1:5984/_utils/docs/api/document/common.html#copy--db-docid
	///	The COPY (which is non-standard HTTP) copies an existing document to a new or existing document.
	///	The source document is specified on the request line, 
	/// with the Destination header of the request specifying the target document.
	///
	///	Parameters:
		///	db – Database name
		///	docid – Document ID
		///	rev (string) – Revision to copy from. Optional
		/// destination – Destination document
	///
	///	Response JSON Object:
		///	id (string) – Document document ID
		///	ok (boolean) – Operation status
		///	rev (string) – Revision MVCC token
	///
	///	Status Codes:
		///	201 Created – Document successfully created
		///	202 Accepted – Request was accepted, but changes are not yet stored on disk
		///	400 Bad Request – Invalid request body or parameters
		///	401 Unauthorized – Read or write privileges required
		///	404 Not Found – Specified database, document ID or revision doesn’t exists
		///	409 Conflict – Document with the specified ID already exists or specified revision is not latest for target document
	public func copy(
			_ db: String = "",
			docid: String,
			doc: [String:Any],
			rev: String = "",
			destination: String
			) throws -> (CouchDBResponse, [String:Any]) {

		if !db.isEmpty { database = db }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		if docid.isEmpty { return (.notAcceptable, [String:Any]()) }

		do {
			let body = try doc.jsonEncodedString()
			let (code, response, _, _) = makeRequest(.copy, "/\(database)/\(docid)", body: body, rev: rev, destination: destination)
			return (code, response)
		} catch {
			print(error)
			throw CouchDBError.Error(code: 201, msg: "Invalid [String:Any] as JSON")
		}

		// NOTE: For later implementation
		// Copying from a Specific Revision
		// http://127.0.0.1:5984/_utils/docs/api/document/common.html#copying-from-a-specific-revision


		// Copying to an Existing Document
		// http://127.0.0.1:5984/_utils/docs/api/document/common.html#copying-to-an-existing-document
	}


	// http://127.0.0.1:5984/_utils/docs/api/document/common.html#updating-an-existing-document
	///	To update an existing document you must specify the current revision number within the _rev parameter.
	///
	///	Parameters:
		///	db – Database name
		///	docid – Document ID
		///	doc – Document body as [String: Any]
		///	rev – Document Revision
	///
	///	Response JSON Object:
		///	id (string) – Document document ID
		///	ok (boolean) – Operation status
		///	rev (string) – Revision MVCC token
	public func update(_ db: String = "", docid: String, doc: [String:Any], rev: String) throws -> (CouchDBResponse, [String:Any]) {
		if !db.isEmpty { database = db }
		if database.isEmpty { return (.notAcceptable, [String:Any]()) }

		if docid.isEmpty { return (.notAcceptable, [String:Any]()) }

		do {
			let body = try doc.jsonEncodedString()
//			print(body)
			let (code, response, _, _) = makeRequest(.put, "/\(database)/\(docid)", body: body, rev: rev)
			return (code, response)
		} catch {
			print(error)
			throw CouchDBError.Error(code: 201, msg: "Invalid [String:Any] as JSON")
		}

	}



	/*
		Attachments
	These are a todo...
	*/

	// GET /{db}/{docid}/{attname}¶
	// http://127.0.0.1:5984/_utils/docs/api/document/attachments.html#get--db-docid-attname
//	public func getAttachment() {
//
//	}

	// PUT /{db}/{docid}/{attname}¶
//	public func addAttachment(){
//
//	}

	//DELETE /{db}/{docid}/{attname}¶
//	public func deleteAttachment(){
//
//	}


}








