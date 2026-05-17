import XCTest

final class LoupeExampleUITests: XCTestCase {
    private let port = ProcessInfo.processInfo.environment["LOUPE_PORT"] ?? "8765"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testNavigationListFormAndGestures() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tables["example.customerList"].waitForExistence(timeout: 5))

        let customerCell = app.cells["example.customer.42"]
        for _ in 0..<8 where !customerCell.exists {
            app.tables["example.customerList"].swipeUp()
        }
        XCTAssertTrue(customerCell.waitForExistence(timeout: 5))
        customerCell.tap()

        XCTAssertTrue(app.otherElements["example.detail"].waitForExistence(timeout: 5))
        let gestureCard = app.otherElements["example.gestureCard"]
        XCTAssertTrue(gestureCard.exists)
        gestureCard.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5))
            .press(
                forDuration: 0.1,
                thenDragTo: gestureCard.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
            )
        XCTAssertTrue(app.staticTexts["example.gestureStatus"].label.contains("Offset"))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.tables["example.customerList"].waitForExistence(timeout: 5))

        app.navigationBars.buttons["example.openForm"].tap()
        XCTAssertTrue(app.otherElements["example.form"].waitForExistence(timeout: 5))
        app.textFields["example.form.name"].tap()
        app.textFields["example.form.name"].typeText("Ada")
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        }
        app.buttons["example.form.save"].tap()
        XCTAssertTrue(app.staticTexts["Saved Ada"].waitForExistence(timeout: 5))
    }

    func testLoupeDrivenCoordinateActionsAgainstInjectedApp() throws {
        let app = XCUIApplication(bundleIdentifier: "dev.loupe.example")
        app.activate()

        XCTAssertTrue(fetchText("/health").contains("LoupeKit"))
        XCTAssertTrue(app.tables["example.customerList"].waitForExistence(timeout: 5))

        for _ in 0..<8 {
            let snapshot = try fetchSnapshot()
            if snapshot.node(testID: "example.customer.24") != nil {
                break
            }

            let table = try XCTUnwrap(snapshot.node(testID: "example.customerList"))
            drag(frame: try XCTUnwrap(table.frame), in: app, from: CGVector(dx: 0.5, dy: 0.82), to: CGVector(dx: 0.5, dy: 0.25))
        }

        let listSnapshot = try fetchSnapshot()
        let cell = try XCTUnwrap(listSnapshot.node(testID: "example.customer.24"))
        tap(frame: try XCTUnwrap(cell.frame), in: app)

        XCTAssertTrue(app.otherElements["example.detail"].waitForExistence(timeout: 5))

        let detailSnapshot = try fetchSnapshot()
        let card = try XCTUnwrap(detailSnapshot.node(testID: "example.gestureCard"))
        drag(frame: try XCTUnwrap(card.frame), in: app, from: CGVector(dx: 0.2, dy: 0.5), to: CGVector(dx: 0.85, dy: 0.5))
        XCTAssertTrue(app.staticTexts["example.gestureStatus"].label.contains("Offset"))
    }

    private func tap(frame: LoupeUITestRect, in app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: frame.midX, dy: frame.midY))
            .tap()
    }

    private func drag(
        frame: LoupeUITestRect,
        in app: XCUIApplication,
        from: CGVector,
        to: CGVector
    ) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: frame.x + frame.width * from.dx, dy: frame.y + frame.height * from.dy))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: frame.x + frame.width * to.dx, dy: frame.y + frame.height * to.dy))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    private func fetchSnapshot() throws -> LoupeUITestSnapshot {
        let data = Data(fetchText("/snapshot").utf8)
        return try JSONDecoder().decode(LoupeUITestSnapshot.self, from: data)
    }

    private func fetchText(_ path: String) -> String {
        let url = URL(string: "http://127.0.0.1:\(port)\(path)")!
        let semaphore = DispatchSemaphore(value: 0)
        var output = ""

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data {
                output = String(decoding: data, as: UTF8.self)
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 5)
        return output
    }
}

private struct LoupeUITestSnapshot: Decodable {
    var nodes: [String: LoupeUITestNode]

    func node(testID: String) -> LoupeUITestNode? {
        nodes.values.first { $0.testID == testID }
    }
}

private struct LoupeUITestNode: Decodable {
    var testID: String?
    var frame: LoupeUITestRect?
}

private struct LoupeUITestRect: Decodable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var midX: Double { x + width / 2 }
    var midY: Double { y + height / 2 }
}
