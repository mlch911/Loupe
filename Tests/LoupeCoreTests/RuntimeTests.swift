import Foundation
import Testing
@testable import LoupeCore

struct RuntimeTests {
    @Test func recordingRoundTripsThroughJSON() throws {
        let recording = LoupeRecording(
            id: "recording-1",
            startedAt: Date(timeIntervalSince1970: 1),
            endedAt: Date(timeIntervalSince1970: 2),
            events: [
                LoupeRuntimeEvent(
                    id: "event-1",
                    kind: .touch,
                    timestamp: Date(timeIntervalSince1970: 3),
                    phase: .began,
                    points: [LoupePoint(x: 10, y: 20)]
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(recording)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LoupeRecording.self, from: data)

        #expect(decoded == recording)
    }

    @Test func snapshotNodeCanCarryUIKitAndAccessibilityProperties() {
        let node = LoupeNode(
            ref: "n1",
            parentRef: nil,
            kind: .view,
            typeName: "UIButton",
            role: "button",
            testID: "checkout.payButton",
            frame: LoupeRect(x: 10, y: 20, width: 100, height: 44),
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            accessibility: LoupeAccessibility(
                identifier: "checkout.payButton",
                label: "Pay",
                traits: ["button"],
                activationPoint: LoupePoint(x: 60, y: 42),
                isElement: true
            ),
            uiKit: LoupeUIKitProperties(
                className: "UIButton",
                tag: 7,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: true,
                userInteractionEnabled: true,
                gestureRecognizers: [],
                isFirstResponder: false,
                control: LoupeUIControlProperties(
                    controlState: "normal",
                    controlEvents: ["touchUpInside"]
                ),
                label: LoupeUILabelProperties(
                    textAlignment: "center",
                    numberOfLines: 1
                )
            )
        )

        #expect(node.accessibility?.identifier == "checkout.payButton")
        #expect(node.accessibility?.traits == ["button"])
        #expect(node.uiKit?.className == "UIButton")
        #expect(node.uiKit?.control?.controlEvents == ["touchUpInside"])
        #expect(node.uiKit?.label?.textAlignment == "center")
    }

    @Test func snapshotNodeCanCarryExtendedUIKitComponentProperties() {
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        let node = LoupeNode(
            ref: "n2",
            parentRef: nil,
            kind: .view,
            typeName: "UIPickerView",
            role: "pickerView",
            testID: "components.picker",
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            uiKit: LoupeUIKitProperties(
                className: "UIPickerView",
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: true,
                isFirstResponder: false,
                stepper: LoupeUIStepperProperties(value: 4, stepValue: 2),
                datePicker: LoupeUIDatePickerProperties(mode: "date", date: date),
                pageControl: LoupeUIPageControlProperties(currentPage: 2, numberOfPages: 5),
                progressView: LoupeUIProgressViewProperties(value: 0.65),
                activityIndicator: LoupeUIActivityIndicatorProperties(isAnimating: true, style: "medium"),
                imageView: LoupeUIImageViewProperties(imageSize: LoupeSize(width: 20, height: 20)),
                pickerView: LoupeUIPickerViewProperties(numberOfComponents: 1, selectedRows: [1]),
                tabBar: LoupeUITabBarProperties(items: ["Home", "Search"], selectedItem: "Home"),
                webView: LoupeWKWebViewProperties(
                    url: "https://loupe.local/fixture",
                    title: "Web Fixture"
                )
            )
        )

        #expect(node.uiKit?.stepper?.value == 4)
        #expect(node.uiKit?.stepper?.stepValue == 2)
        #expect(node.uiKit?.datePicker?.mode == "date")
        #expect(node.uiKit?.datePicker?.date == date)
        #expect(node.uiKit?.pageControl?.currentPage == 2)
        #expect(node.uiKit?.pageControl?.numberOfPages == 5)
        #expect(node.uiKit?.progressView?.value == 0.65)
        #expect(node.uiKit?.activityIndicator?.isAnimating == true)
        #expect(node.uiKit?.activityIndicator?.style == "medium")
        #expect(node.uiKit?.imageView?.imageSize == LoupeSize(width: 20, height: 20))
        #expect(node.uiKit?.pickerView?.numberOfComponents == 1)
        #expect(node.uiKit?.pickerView?.selectedRows == [1])
        #expect(node.uiKit?.tabBar?.items == ["Home", "Search"])
        #expect(node.uiKit?.tabBar?.selectedItem == "Home")
        #expect(node.uiKit?.webView?.url == "https://loupe.local/fixture")
        #expect(node.uiKit?.webView?.title == "Web Fixture")
    }
}
