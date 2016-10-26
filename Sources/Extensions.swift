//
//  Extensions.swift
//  PerfectCouchDB
//
//  Created by Jonathan Guthrie on 2016-10-24.
//
//

import Foundation
import SwiftString
import PerfectLib
import PerfectCURL

/// A lightweight HTTP Response Header Parser
/// transform the header into a dictionary with http status code
class HTTPHeaderParser {

	private var _dic: [String:String] = [:]
	private var _version: String? = nil
	private var _code : Int = -1
	private var _status: String? = nil

	/// HTTPHeaderParser default constructor
	/// - parameters:
	///     - header: the HTTP response header string
	public init(header: String) {

		// parse the header into lines,
		_ = header.components(separatedBy: .newlines)
			// remove all null lines
			.filter{!$0.isEmpty}
			// map each line into the dictionary
			.map{

				// most HTTP header lines have a patter of "variable name: value"
				let range = $0.range(of: ":")

				if (range == nil && $0.hasPrefix("HTTP/")) {
					// except the first line, typically "HTTP/1.0 200 OK", so split it first
					let http = $0.tokenize()

					// parse the tokens
					_version = http[0].trimmed()
					_code = http[1].toInt()!
					_status = http[2].trimmed()
				} else {

					// split the line into a dictionary item expression
					//	let key = $0.left(range)
					//	let val = $0.right(range).trimmed()
					let key = $0.substring(to: (range?.upperBound)!)
					let val = $0.substring(from: (range?.lowerBound)!).trimmed()

					// insert or update the dictionary with this item
					_dic.updateValue(val, forKey: key)
				}//end if
		}
	}//end constructor

	/// HTTP response header information by keywords
	public var variables: [String:String] {
		get { return _dic }
	}

	/// The HTTP response code, e.g.,, HTTP/1.1 200 OK -> let code = 200
	public var code: Int {
		get { return _code }
	}

	/// The HTTP response code, e.g.,, HTTP/1.1 200 OK -> let status = "OK"
	public var status: String {
		get { return _status! }
	}

	/// The HTTP response code, e.g.,, HTTP/1.1 200 OK -> let version = "HTTP/1.1"
	public var version: String {
		get { return _version! }
	}
}//end class HTTPHeaderParser

extension CURL {
	/**
	access a web service api and parse the return in a JSON format
	- parameters of closure
	- code: Int -- The same with perform closure, 0 means finished
	- headerCode: Int -- a convenient way to access the HTTP response header code, for example, if the response is "HTTP/1.1 200 OK", then the headerCode will be 200.
	- json: [String:Any] -- a dictionary of the HTTP response body after JSON decoding.
	-raw: [String:Any] -- an failsafe dictionary consists with three keys: raw["status"] is the first line of HTTP Response header, such as "HTTP/1.0 200 OK"; raw["header"] is the unparsed header content and raw["body"] is the original HTTP response body as a string.
	*/
	public func performAsWebService(closure: @escaping (Int, Int, [String:Any], [String:Any])->()) {

		/// Actually call the perform internally.
		self.perform {
			code, header, body in

			// assember the header from a binary byte array to a string
			let headerStr = String(bytes: header, encoding: String.Encoding.utf8)

			// parse the header
			let http = HTTPHeaderParser(header:headerStr!)

			// assamble the body from a binary byte array to a string
			let content = String(bytes:body, encoding:String.Encoding.utf8)

			// prepare the failsafe content.
			let raw = ["status": http.status, "header": headerStr, "body": content]

			// parse the body data into a json convertible
			do {
				let data = try content?.jsonDecode() as? [String:Any]
				closure(code, http.code, data!, raw)
			} catch _ {
				closure(code, http.code, [:], raw)
			}
		}
	}
}
