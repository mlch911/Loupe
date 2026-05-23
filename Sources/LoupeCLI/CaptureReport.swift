import Foundation
import LoupeCore

struct CaptureReport: Codable, Equatable {
    var capturedAt: Date
    var host: String
    var udid: String?
    var bundleID: String?
    var snapshotID: String
    var screen: LoupeScreen
    var artifacts: CaptureReportArtifacts
    var counts: CaptureReportCounts
    var scrollViews: [CaptureReportScrollView]
    var auditIssuesByKind: [String: Int]
    var topAuditIssues: [CaptureReportAuditIssue]
}

struct CaptureReportArtifacts: Codable, Equatable {
    var screenshot: String
    var snapshot: String
    var screenMap: String
    var accessibility: String
    var compact: String
    var audit: String
    var runtime: String?
    var logs: String?
    var summaryMarkdown: String
}

struct CaptureReportCounts: Codable, Equatable {
    var nodes: Int
    var screenMapElements: Int
    var visibleTexts: Int
    var interactiveElements: Int
    var accessibilityNodes: Int
    var auditIssues: Int
    var scrollViews: Int
    var scrollableScrollViews: Int
}

struct CaptureReportScrollView: Codable, Equatable {
    var ref: String
    var testID: String?
    var frame: LoupeRect?
    var contentSize: LoupeSize
    var contentOffset: LoupePoint
    var isScrollEnabled: Bool
    var scrollableAxes: [String]

    init(node: LoupeNode, scrollView: LoupeUIScrollViewProperties) {
        ref = node.ref
        testID = node.testID
        frame = node.frame
        contentSize = scrollView.contentSize
        contentOffset = scrollView.contentOffset
        isScrollEnabled = scrollView.isScrollEnabled
        scrollableAxes = Self.scrollableAxes(frame: node.frame, scrollView: scrollView)
    }

    private static func scrollableAxes(
        frame: LoupeRect?,
        scrollView: LoupeUIScrollViewProperties
    ) -> [String] {
        guard scrollView.isScrollEnabled, let frame else { return [] }
        var axes: [String] = []
        if scrollView.contentSize.width > frame.width + 1 {
            axes.append("horizontal")
        }
        if scrollView.contentSize.height > frame.height + 1 {
            axes.append("vertical")
        }
        return axes
    }
}

struct CaptureReportAuditIssue: Codable, Equatable {
    var kind: LoupeLayoutIssueKind
    var ref: String
    var testID: String?
    var text: String?
    var typeName: String?
    var className: String?
    var frame: LoupeRect?
    var message: String

    init(issue: LoupeLayoutIssue, node: LoupeNode?) {
        kind = issue.kind
        ref = issue.ref
        testID = issue.testID
        text = node.flatMap(LoupeObservationCompactor.displayText)
        typeName = node?.typeName
        className = node?.uiKit?.className
        frame = node?.frame
        message = issue.message
    }
}
