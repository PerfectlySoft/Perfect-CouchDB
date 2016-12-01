//
//  CouchDBConnector.swift
//  PerfectCouchDB
//
//  Created by Jonathan Guthrie on 2016-10-24.
//
//

/// Connector information.
public struct CouchDBConnector {

	/// SSL mode enabled/disabled.
	/// Default value: disabled (false)
	public var ssl: Bool = false

	/// CouchDB Server hostname or IP address
	/// Default: localhost
	public var host: String = "localhost"

	/// CouchDB Server port
	/// Default: 5984
	public var port: Int = 5984
}
