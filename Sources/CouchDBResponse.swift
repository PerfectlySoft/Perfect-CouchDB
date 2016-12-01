//
//  CouchDBResponse.swift
//  PerfectCouchDB
//
//  Created by Jonathan Guthrie on 2016-10-24.
//
//

public enum CouchDBResponse {
	/// CouchDB HTTP Response Codes

	/// Undefined.
	case undefined

	/// Request completed successfully.
	case ok

	/// Document created successfully.
	case created

	/// Request has been accepted, but the corresponding operation may not have completed. This is used for background operations, such as database compaction.
	case accepted

	/// The additional content requested has not been modified. This is used with the ETag system to identify the version of information returned.
	case notModified

	/// Bad request structure. The error can indicate an error with the request URL, path or headers. Differences in the supplied MD5 hash and content also trigger this error, as this may indicate message corruption.
	case badRequest

	/// The item requested was not available using the supplied authorization, or authorization was not supplied.
	case unauthorized

	/// The requested item or operation is forbidden.
	case forbidden

	/// The requested content could not be found. The content will include further information, as a JSON object, if available. The structure will contain two keys, error and reason. For example:
	/// {"error":"not_found","reason":"no_db_file"}
	case notFound

	/// A request was made using an invalid HTTP request type for the URL requested. For example, you have requested a PUT when a POST is required. Errors of this type can also triggered by invalid URL strings.
	case resourceNotAllowed

	/// The requested content type is not supported by the server.
	case notAcceptable

	/// Request resulted in an update conflict.
	case conflict

	/// The request headers from the client and the capabilities of the server do not match.
	case preconditionFailed

	/// The content types supported, and the content type of the information being requested or submitted indicate that the content type is not supported.
	case badContentType

	/// The range specified in the request header cannot be satisfied by the server.
	case requestedRangeNotSatisfiable

	/// When sending documents in bulk, the bulk load operation failed.
	case expectationFailed

	/// The request was invalid, either because the supplied JSON was invalid, or invalid information was supplied as part of the request.
	case internalServerError

	public init() {
		self = .undefined
	}

	/// converts an HTTP status code to the correct enum value
	public static func statusFrom(_ code: Int) -> CouchDBResponse {
		switch code {
		case 200: return .ok
		case 201: return .created
		case 202: return .accepted
		case 304: return .notModified
		case 400: return .badRequest
		case 401: return .unauthorized
		case 403: return .forbidden
		case 404: return .notFound
		case 405: return .resourceNotAllowed
		case 406: return .notAcceptable
		case 409: return .conflict
		case 412: return .preconditionFailed
		case 415: return .badContentType
		case 416: return .requestedRangeNotSatisfiable
		case 417: return .expectationFailed
		case 500: return .internalServerError
		default: return .undefined
		}
	}
}
