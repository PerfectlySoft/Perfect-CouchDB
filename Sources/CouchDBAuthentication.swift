//
//  CouchDBAuthentication.swift
//  PerfectCouchDB
//
//  Created by Jonathan Guthrie on 2016-10-25.
//
//

/// CouchDBAuthType provides a simple switch for how interaction is maintained over a connection's lifetime.
/// Options are: basic, and session
public enum CouchDBAuthType {

	/// None
	/// No authentication by default
	case none

	/// Basic
	/// The main drawback is the need to send user credentials with each request which may be insecure and could hurt operation performance (since CouchDB must compute the password hash with every request)
	case basic

	/// Session
	/// CouchDB generates a token that the client can use for the next few requests to CouchDB. Tokens are valid until a timeout.
	/// These are effectively Cookies but can also be handled via JSON
	case session

	public init() { self = .none }


}

public struct CouchDBAuthentication {

	var authType:	CouchDBAuthType	= .none
	var username:	String?
	var password:	String?
	var token:		String? // used only if authType = .session

	public init() {}
	public init(_ u: String, _ p: String, auth: CouchDBAuthType = .basic) {
		username = u
		password = p
		authType = auth
	}

	public func basic() -> String {
		if let u = username, let p = password {
			let source = "\(u):\(p)"
			return source.toBase64()
		}
		return ""
	}
	public func sessionJSON() -> String {
		if let u = username, let p = password {
			return "{\"name\": \"\(u)\",\"password\": \"\(p)\"}"
		}
		return ""
	}
	public mutating func sessionSetToken(t: String) {
		self.token = t
		authType = .session
	}


}



