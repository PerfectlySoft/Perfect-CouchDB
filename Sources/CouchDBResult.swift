//
//  CouchDBResult.swift
//  PerfectCouchDB
//
//  Created by Jonathan Guthrie on 2016-11-06.
//
//

import PerfectLib


/// CouchDBResult is the individual document record
public struct CouchDBResult {

	/// The id of the document
	public var id: String = ""

	/// Document revision
	public var	rev: String = ""

	/// The contents of the document
	public var doc = [String: Any]()

}
