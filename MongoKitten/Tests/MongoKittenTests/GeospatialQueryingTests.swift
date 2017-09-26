//
// This source file is part of the MongoKitten open source project
//
// Copyright (c) 2016 - 2017 OpenKitten and the MongoKitten project authors
// Licensed under MIT
//
// See https://github.com/OpenKitten/MongoKitten/blob/mongokitten31/LICENSE.md for license information
// See https://github.com/OpenKitten/MongoKitten/blob/mongokitten31/CONTRIBUTORS.md for the list of MongoKitten project authors
//
import XCTest
import MongoKitten
import GeoJSON

public class GeospatialQueryingTest: XCTestCase {
    public static var allTests: [(String, (GeospatialQueryingTest) -> () throws -> Void)] {
        return [
            ("testGeo2SphereIndex", testGeo2SphereIndex),
            ("testGeoNear", testGeoNear),
            ("testNearQuery", testNearQuery),
            ("testGeoWithInQuery", testGeoWithInQuery),
            ("testGeoIntersectsQuery", testGeoIntersectsQuery),
            ("testGeoNearSphereQuery", testGeoNearSphereQuery),
            ("testGeoNearCommand", testGeoNearCommand)
        ]
    }


    public override func setUp() {
        super.setUp()

        do {
            try TestManager.clean()
        } catch {
            fatalError("\(error)")
        }
    }

    public override func tearDown() {

        // Cleaning
        do {
            for db in TestManager.dbs {
                try db["airports"].drop()
                try db["GeoCollection"].drop()
            }
        } catch {

        }
        try! TestManager.disconnect()
    }

    func testGeo2SphereIndex() throws {
        loop: for db in TestManager.dbs {
            if db.server.buildInfo.version < Version(3, 2, 0) {
                continue loop
            }

            let airports = db["airports"]
            let jfkAirport: Document = [ "iata": "JFK", "loc":["type":"Point", "coordinates":[-73.778925, 40.639751]]]
            try airports.insert(jfkAirport)
            try airports.createIndex(named: "loc_index", withParameters: .geo2dsphere(field: "loc"))


            for index in try airports.listIndexes() where String(index["name"]) == "loc_index" {
                if let _ = Int(index["2dsphereIndexVersion"])  {
                    continue loop
                }
            }

            XCTFail()
        }
    }

    func testGeoNear() throws {
        loop: for db in TestManager.dbs {
            if db.server.buildInfo.version < Version(3, 4, 0) {
                continue loop
            }
            
            let zips = db["zips"]
            try zips.createIndex(named: "loc_index", withParameters: .geo2dsphere(field: "loc"))
            let position = try Position(values: [-72.844092,42.466234])
            let near = Point(coordinate: position)

            let geoNearOption = GeoNearOptions(near: near, spherical: true, distanceField: "dist.calculated", maxDistance: 10000.0)

            let geoNearStage = AggregationPipeline.Stage.geoNear(options: geoNearOption)

            let pipeline: AggregationPipeline = [geoNearStage]

            let results = Array(try zips.aggregate(pipeline))

            XCTAssertEqual(results.count, 6)
        }
    }

    func testGeoNearCommand() throws {
        for db in TestManager.dbs {
            let zips = db["zips"]
            try zips.createIndex(named: "loc_index", withParameters: .geo2dsphere(field: "loc"))
            let position = try Position(values: [-72.844092,42.466234])
            let near = Point(coordinate: position)

            let geoNearOption = GeoNearOptions(near: near, spherical: true, distanceField: "dist.calculated", maxDistance: 10000.0)

            let results = try zips.geoNear(options: geoNearOption)

            XCTAssertEqual([Primitive](results["results"])?.count , 6)
        }
    }

    func testGeoNearFailCommand() throws {
        for db in TestManager.dbs {
            let zips = db["zips"]

            for index in try zips.listIndexes() {
                if let _ = Int(index["2dsphereIndexVersion"]), let indexName = String(index["name"]) {
                   try zips.dropIndex(named: indexName)              
                }
            }

            let position = try Position(values: [-72.844092,42.466234])
            let near = Point(coordinate: position)

            let geoNearOption = GeoNearOptions(near: near, spherical: true, distanceField: "dist.calculated", maxDistance: 10000.0)

            XCTAssertThrowsError(try zips.geoNear(options: geoNearOption))


        }
    }

    func testNearQuery() throws {
        for db in TestManager.dbs {
            let zips = db["zips"]
            try zips.createIndex(named: "loc_index", withParameters: .geo2dsphere(field: "loc"))
            let position = try Position(values: [-72.844092,42.466234])
            let query = Query(aqt: .near(key: "loc", point: Point(coordinate: position), maxDistance: 100.0, minDistance: 0.0))

            let results = Array(try zips.find(query))
            if results.count == 1 {
                XCTAssertEqual(String(results[0]["city"]), "GOSHEN")
            } else {
                XCTFail("Too many results")
            }
        }
    }

    func testGeoWithInQuery() throws {
        var firstPoint: Document = ["geo": Point(coordinate: try Position(values: [1.0, 1.0]))]
        var secondPoint: Document = ["geo": Point(coordinate: try Position(values: [45.0,2.0]))]
        var thirdPoint: Document = ["geo": Point(coordinate: try Position(values: [3.0,3.0]))]

        for db in TestManager.dbs {
            let collection = db["GeoCollection"]
            let firstId = try collection.insert(firstPoint)
            let secondId = try collection.insert(secondPoint)
            let thirdId = try collection.insert(thirdPoint)
            firstPoint["_id"] = firstId
            secondPoint["_id"] = secondId
            thirdPoint["_id"] = thirdId

            try collection.createIndex(named: "geoIndex", withParameters: .geo2dsphere(field: "geo"))

            let polygon = try Polygon(exterior: [Position(values: [0.0, 0.0]), Position(values: [0.0,4.0]),Position(values: [4.0,4.0]), Position(values: [4.0,0.0]), Position(values: [0.0,0.0])])

            let query = Query(aqt: .geoWithin(key: "geo", polygon: polygon))

            do {
                let results = Array(try collection.find(query))
                XCTAssertTrue(results.contains(firstPoint))
                XCTAssertTrue(results.contains(thirdPoint))
                XCTAssertFalse(results.contains(secondPoint))
            } catch MongoError.invalidResponse(let documentError) {
                XCTFail(String(documentError.first?["errmsg"]) ?? "")
            }
        }
    }

    func testGeoIntersectsQuery() throws {
        var firstPoint: Document = ["geo": Point(coordinate: try Position(values: [1.0, 1.0]))]
        var secondPoint: Document = ["geo": Point(coordinate: try Position(values: [45.0,2.0]))]
        var thirdPoint: Document = ["geo": Point(coordinate: try Position(values: [3.0,3.0]))]
        var firstPolygon: Document = ["geo":try Polygon(exterior: [Position(values: [2.0, 2.0]),
                                                                   Position(values: [6.0, 2.0]),
                                                                   Position(values: [6.0, 6.0]),
                                                                   Position(values: [2.0, 6.0]),
                                                                   Position(values: [2.0, 2.0])])]

        for db in TestManager.dbs {
            let collection = db["GeoCollection"]
            let firstId = try collection.insert(firstPoint)
            let secondId = try collection.insert(secondPoint)
            let thirdId = try collection.insert(thirdPoint)
            let firstPolygonId = try collection.insert(firstPolygon)

            firstPoint["_id"] = firstId
            secondPoint["_id"] = secondId
            thirdPoint["_id"] = thirdId
            firstPolygon["_id"] = firstPolygonId

            try collection.createIndex(named: "geoIndex", withParameters: .geo2dsphere(field: "geo"))

            let polygon = try Polygon(exterior: [Position(values: [0.0, 0.0]), Position(values: [0.0,4.0]),Position(values: [4.0,4.0]), Position(values: [4.0,0.0]), Position(values: [0.0,0.0])])

            let query = Query(aqt: .geoIntersects(key: "geo", geometry: polygon))

            do {
                let results = Array(try collection.find(query))
                XCTAssertTrue(results.contains(firstPoint))
                XCTAssertTrue(results.contains(thirdPoint))
                XCTAssertTrue(results.contains(firstPolygon))
                XCTAssertFalse(results.contains(secondPoint))
            } catch MongoError.invalidResponse(let documentError) {
                XCTFail(String(documentError.first?["errmsg"]) ?? "")
            }
        }
    }


    func testGeoNearSphereQuery() throws {
        var firstPoint: Document = ["geo": Point(coordinate: try Position(values: [1.0, 1.0]))]
        var secondPoint: Document = ["geo": Point(coordinate: try Position(values: [45.0,2.0]))]
        var thirdPoint: Document = ["geo": Point(coordinate: try Position(values: [3.0,3.0]))]

        for db in TestManager.dbs {
            let collection = db["GeoCollection"]
            let firstId = try collection.insert(firstPoint)
            let secondId = try collection.insert(secondPoint)
            let thirdId = try collection.insert(thirdPoint)
            firstPoint["_id"] = firstId
            secondPoint["_id"] = secondId
            thirdPoint["_id"] = thirdId

            try collection.createIndex(named: "geoIndex", withParameters: .geo2dsphere(field: "geo"))

            let query = Query(aqt: .nearSphere(key:"geo", point: Point(coordinate: try Position(values: [1.01, 1.01])), maxDistance: 10000.0, minDistance: 0.0))

            do {
                let results = Array(try collection.find(query))
                XCTAssertTrue(results.contains(firstPoint))
                XCTAssertFalse(results.contains(thirdPoint))
                XCTAssertFalse(results.contains(secondPoint))
            } catch MongoError.invalidResponse(let documentError) {
                XCTFail(String(documentError.first?["errmsg"]) ?? "")
            }
        }
    }
}
