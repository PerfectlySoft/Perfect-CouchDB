//
//  makeRequest.swift
//  PerfectCouchDB
//
//  Created by Jonathan Guthrie on 2016-10-25.
//
//

import PerfectLib
import PerfectCURL
import cURL
import SwiftString

extension CouchDB {
	public func makeRequest(_ method: HTTPMethod, _ route: String) -> (CouchDBResponse, [String:Any], [String:Any]) {

		var url = "http://\(connector.host):\(connector.port)\(route)"
		if connector.ssl { url = "https://\(connector.host):\(connector.port)\(route)" }

		if debug { print("Debug:: method: \(method)") }
		if debug { print("Debug:: url: \(url)") }

		let curlObject = CURL(url: url)
		curlObject.setOption(CURLOPT_HTTPHEADER, s: "Accept: application/json")
		curlObject.setOption(CURLOPT_USERAGENT, s: "PerfectAPI2.0")

		// Set Authentication
		if authentication.authType == .basic && authentication.username != "" {
			curlObject.setOption(CURLOPT_HTTPHEADER, s: "Authorization: Basic \(authentication.basic())")
		}

		switch method {
		case .post :
			curlObject.setOption(CURLOPT_HTTPPOST, int: 1)
		case .get :
			curlObject.setOption(CURLOPT_HTTPGET, int: 1)
		default:
			curlObject.setOption(CURLOPT_CUSTOMREQUEST, s: method.rawValue)
		}

		var header = [UInt8]()
		var body = [UInt8]()

		var code = 0
		var data = [String: Any]()
		var raw = [String: Any]()

		var perf = curlObject.perform()
		defer { curlObject.close() }

		while perf.0 {
			if let h = perf.2 {
				header.append(contentsOf: h)
			}
			if let b = perf.3 {
				body.append(contentsOf: b)
			}
			perf = curlObject.perform()
		}
		if let h = perf.2 {
			header.append(contentsOf: h)
		}
		if let b = perf.3 {
			body.append(contentsOf: b)
		}
		let _ = perf.1

		// Parsing now:

		// assember the header from a binary byte array to a string
		let headerStr = String(bytes: header, encoding: String.Encoding.utf8)

		// parse the header
		let http = HTTPHeaderParser(header:headerStr!)

		// assamble the body from a binary byte array to a string
		let content = String(bytes:body, encoding:String.Encoding.utf8)

		// prepare the failsafe content.
		raw = ["status": http.status, "header": headerStr!, "body": content!]

		// parse the body data into a json convertible
		do {
			if (content?.characters.count)! > 0 {
				if (content?.startsWith("["))! {
					let arr = try content?.jsonDecode() as! [Any]
					data["response"] = arr
				} else {
					data = try content?.jsonDecode() as! [String : Any]
				}
			}
			return (CouchDBResponse.statusFrom(http.code), data, raw)
		} catch {
			print(error)
			return (CouchDBResponse.statusFrom(http.code), [:], raw)
		}
	}
}
