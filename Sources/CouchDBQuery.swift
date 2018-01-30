//
//  CouchDBQuery.swift
//  PerfectCouchDB
//
//  Created by Jonathan Guthrie on 2016-11-23.
//
//

import PerfectLib


/// A container class for query params used in the _all_docs selection
public class CouchDBQuery {

	public init(){}
	
	///	conflicts (Bool) – Includes conflicts information in response. Ignored if include_docs isn’t true. Default is false.
	/// Used for an _all_docs / filter query only
	public var conflicts : Bool = false

	///	descending (Bool) – Return the documents in descending by key order. Default is false.
	/// Used for an _all_docs / filter query only
	public var descending : Bool = false

	///	endkey (String) – Stop returning records when the specified key is reached. Optional.
	/// Used for an _all_docs / filter query only
	public var endkey : String = ""

	///	endkey_docid (String) – Stop returning records when the specified document ID is reached. Optional.
	/// Used for an _all_docs / filter query only
	public var endkey_docid : String = ""

	///	include_docs (Bool) – Include the full content of the documents in the return. Default is false.
	/// Used for an _all_docs / filter query only
	public var include_docs : Bool = false

	///	inclusive_end (Bool) – Specifies whether the specified end key should be included in the result. Default is true.
	/// Used for an _all_docs / filter query only
	public var inclusive_end : Bool = true

	///	key (String) – Return only documents that match the specified key. Optional.
	/// Used for an _all_docs / filter query only
	public var key : String = ""

	///	keys ([String]) – Return only documents that match the specified keys. Optional.
	/// Used for an _all_docs / filter query only
	public var keys : [String] = [String]()

	///	limit (Int) – Limit the number of the returned documents to the specified number. Optional.
	public var limit : Int = 0

	///	skip (Int) – Skip this number of records before starting to return the results. Default is 0.
	public var skip : Int = 0

	///	stale (CouchDBQueryStale) – Allow the results from a stale view to be used, without triggering a rebuild of all views within the encompassing design doc. Supported values: ok and update_after. Optional.
	/// Used for an _all_docs / filter query only
	public var stale : CouchDBQueryStale = .ignore

	///	startkey (String) – Return records starting with the specified key. Optional.
	/// Used for an _all_docs / filter query only
	public var startkey : String = ""

	///	startkey_docid (String) – Return records starting with the specified document ID. Optional.
	/// Used for an _all_docs / filter query only
	public var startkey_docid : String = ""

	///	update_seq (Bool) – Response includes an update_seq value indicating which sequence id of the underlying database the view reflects. Default is false.
	/// Used for an _all_docs / filter query only
	public var update_seq : Bool = false

	///	selector (json) – JSON object describing criteria used to select documents. More information provided in the section on selector syntax.
	/// Used for a find query only
	public var selector = [String:Any]()

	///	sort (json) – JSON array following sort syntax. Optional.
	/// Used for a find query only
	public var sort = [String:Any]()

	///	fields (json) – JSON array specifying which fields of each object should be returned. If it is omitted, the entire object is returned. More information provided in the section on filtering fields. Optional.
	/// Used for a find query only
	public var fields = [String:Any]()

	///	use_index (json) – Instruct a query to use a specific index. Specified either as "<design_document>" or ["<design_document>", "<index_name>"]. Optional.
	/// Used for a find query only
	public var use_index = [String:Any]()



	public func json() -> String {
		var json = [String: Any]()
		json["conflicts"] = conflicts
		json["descending"] = descending
		if endkey.count > 0 { json["endkey"] = endkey }
		if endkey_docid.count > 0 { json["endkey_docid"] = endkey_docid }
		json["include_docs"] = include_docs
		json["inclusive_end"] = inclusive_end
		if key.count > 0 { json["key"] = key }
		if keys.count > 0 { json["keys"] = keys }
		if limit > 0 { json["limit"] = limit }
		if skip > 0 { json["skip"] = skip }
		if stale != .ignore { json["stale"] = stale }
		if startkey.count > 0 { json["startkey"] = startkey }
		if startkey_docid.count > 0 { json["startkey_docid"] = startkey_docid }
		json["update_seq"] = update_seq

		return try! json.jsonEncodedString()
	}

	public func jsonfind() -> String {
		var json = [String: Any]()
		json["selector"] = selector
		if limit > 0 { json["limit"] = limit }
		if skip > 0 { json["skip"] = skip }
		if sort.count > 0 { json["sort"] = sort }
		if fields.count > 0 {  json["fields"] = fields }
		if use_index.count > 0 { json["use_index"] = use_index }

		return try! json.jsonEncodedString()
	}



}

public enum CouchDBQueryStale {
	case ok, update_after, ignore
}

