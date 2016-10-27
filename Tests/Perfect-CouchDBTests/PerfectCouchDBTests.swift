import XCTest
@testable import PerfectCouchDB

class PerfectCouchDBTests: XCTestCase {
	var test: CouchDB!
	var auth = CouchDBAuthentication("perfect", "perfect", auth: .basic)

	override func setUp() {
		super.setUp()
		test = CouchDB()
//		test.connector.port = 8181
		test.debug = true
	}

	func testServerInfo() {
		let (code, data) = test.serverInfo()
		XCTAssert(.ok == code, "Response incorrect, \(code)")
		XCTAssertEqual("Welcome", data["couchdb"] as! String)
	}

	func testServerActiveTasks() {
		let (code, _) = test.serverActiveTasks()
		XCTAssert(.ok == code, "Response incorrect, \(code)")
	}

	func testListDatabasesBasic() {
		let (code, _) = test.listDatabases()
		XCTAssert(.ok == code, "Response incorrect, \(code)")
	}

	func testDatabaseCreateUnauth() {
		let code = test.databaseCreate("newdb")
		XCTAssert(.unauthorized == code, "Response incorrect, \(code)")
	}

	func testDatabaseCreateAuth() {
		test.authentication = auth
		let code = test.databaseCreate("newdb")
		XCTAssert(.created == code, "Response incorrect, \(code)")
		XCTAssert(test.database == "newdb", "Database property not set")
		test.databaseDelete() // cleanup
	}

	// TODO: Sort out header requets... something is off

//	func testDatabaseExists() {
////		let code = test.databaseCreate("newdbExists")
////		XCTAssert(.created == code, "Response incorrect, \(code)")
//		XCTAssert(!test.databaseExists("newdbShouldNotExist"), "Database should not exist")
////		test.databaseDelete() // cleanup
//	}

	func testDatabaseInfo() {
		test.authentication = auth
		let code = test.databaseCreate("newdb")
		XCTAssert(.created == code, "Response incorrect, \(code)")
		XCTAssert(test.database == "newdb", "Database property not set")

		let (code2, info) = test.databaseInfo()
		XCTAssert(.ok == code2, "Response incorrect, \(code2)")
		XCTAssert(info["db_name"] as? String == "newdb", "Database property not set \(info["db_name"] as? String)")
		test.databaseDelete() // cleanup
	}


	//listDatabases

	//listDatabaseEvents

	//listNodeMembership




	func testAuthBasicToken() {
		let auth = CouchDBAuthentication("perfect","perfect")
		let token = auth.basic()
		print(token)
		XCTAssertEqual(token.fromBase64()!, "perfect:perfect")
	}

	func testSessionJSON() {
		let auth = CouchDBAuthentication("perfect","perfect")
		XCTAssertEqual(auth.sessionJSON(), "{\"name\": \"perfect\",\"password\": \"perfect\"}")
	}

//	func testSessionAuth() {
//		auth = CouchDBAuthentication("perfect", "perfect", auth: .session)
//		test.authentication = auth
//		do {
//			try test.getToken()
//		} catch {
//			print(error)
//		}
//		//		XCTAssertEqual(auth.sessionJSON(), "{\"name\": \"perfect\",\"password\": \"perfect\"}")
//	}


	
    static var allTests : [(String, (PerfectCouchDBTests) -> () throws -> Void)] {
        return [
            ("testServerInfo", testServerInfo),
            ("testServerActiveTasks",testServerActiveTasks),
            ("testListDatabasesBasic",testListDatabasesBasic),
            ("testDatabaseCreateUnauth",testDatabaseCreateUnauth),
            ("testDatabaseCreateAuth",testDatabaseCreateAuth),
//            ("testDatabaseExists",testDatabaseExists),
			("testDatabaseInfo",testDatabaseInfo),
			("testAuthBasicToken",testAuthBasicToken)
        ]
    }
}
