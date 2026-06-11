import LoupeCore

enum MutationPropertySupport {
    static func supportedProperties(for node: LoupeNode) -> [String] {
        var properties = genericViewProperties

        if supportsTextMutation(node) {
            properties += ["text"]
        }
        if supportsTextColorMutation(node) {
            properties += ["textColor"]
        }
        if supportsFontSizeMutation(node) {
            properties += ["fontSize"]
        }
        if supportsTextAlignmentMutation(node) {
            properties += ["textAlignment"]
        }
        if supportsLineBreakModeMutation(node) {
            properties += ["lineBreakMode"]
        }
        if supportsUILabelSpecificMutations(node) {
            properties += ["numberOfLines", "adjustsFontSizeToFitWidth", "minimumScaleFactor"]
        }
        if supportsUITextFieldSpecificMutations(node) {
            properties += ["placeholder", "secureTextEntry"]
        }
        if node.uiKit?.button != nil || node.role == "button" {
            properties += ["title"]
        }
        if node.uiKit?.switchControl != nil || node.role == "switch" {
            properties += ["enabled", "selected", "highlighted", "switch.isOn"]
        } else if node.uiKit?.control != nil || node.isInteractive {
            properties += ["enabled", "selected", "highlighted"]
        }
        if node.uiKit?.slider != nil || node.role == "slider" {
            properties += ["slider.value", "slider.minimumValue", "slider.maximumValue"]
        }
        if node.uiKit?.stepper != nil || node.role == "stepper" {
            properties += ["stepper.value", "stepper.minimumValue", "stepper.maximumValue", "stepper.stepValue"]
        }
        if node.uiKit?.segmentedControl != nil || node.role == "segmentedControl" {
            properties += ["segmentedControl.selectedSegmentIndex"]
        }
        if node.uiKit?.pageControl != nil || node.role == "pageControl" {
            properties += ["pageControl.currentPage", "pageControl.numberOfPages"]
        }
        if node.uiKit?.progressView != nil || node.role == "progress" {
            properties += ["progressView.progress"]
        }
        if node.uiKit?.datePicker != nil || node.role == "datePicker" {
            properties += ["datePicker.date", "datePicker.countDownDuration"]
        }
        if node.uiKit?.activityIndicator != nil || node.role == "activityIndicator" {
            properties += ["activityIndicator.animating"]
        }
        if node.uiKit?.pickerView != nil || node.role == "pickerView" {
            properties += ["pickerView.selectedRow"]
        }
        if node.uiKit?.scrollView != nil || node.role == "scrollView" {
            properties += [
                "contentOffset", "contentSize", "contentInset", "scrollIndicatorInsets",
                "scrollEnabled", "pagingEnabled", "bounces", "showsVerticalScrollIndicator",
                "showsHorizontalScrollIndicator",
            ]
        }
        if node.uiKit?.stackView != nil {
            properties += [
                "stack.axis", "stack.alignment", "stack.distribution", "stack.spacing",
                "stack.layoutMarginsRelativeArrangement",
            ]
        }

        return Array(Set(properties)).sorted()
    }

    static func supports(_ property: String, for node: LoupeNode) -> Bool {
        supportedProperties(for: node).contains(canonicalProperty(property))
    }

    static func supportsTextMutation(_ node: LoupeNode) -> Bool {
        isTextBacked(node)
    }

    static func unsupportedExamples(for node: LoupeNode) -> [String] {
        if supportsTextMutation(node) {
            return []
        }
        return ["text"]
    }

    private static let genericViewProperties = [
        "frame", "bounds", "center", "alpha", "hidden", "opaque", "clipsToBounds",
        "userInteractionEnabled", "backgroundColor", "tintColor", "contentMode", "tag",
        "borderColor", "borderWidth", "cornerRadius", "shadowColor", "shadowOpacity",
        "shadowRadius", "shadowOffset", "layer.opacity", "layer.zPosition",
        "accessibility.identifier", "accessibility.label", "accessibility.value",
        "accessibility.hint", "accessibility.isElement",
        "layout.translatesAutoresizingMaskIntoConstraints", "layout.hugging.horizontal", "layout.hugging.vertical",
        "layout.compressionResistance.horizontal", "layout.compressionResistance.vertical",
    ]

    private static func canonicalProperty(_ property: String) -> String {
        switch property {
        case "style.alpha", "uiKit.alpha":
            return "alpha"
        case "isHidden", "uiKit.isHidden":
            return "hidden"
        case "isOpaque", "uiKit.isOpaque":
            return "opaque"
        case "masksToBounds", "uiKit.clipsToBounds":
            return "clipsToBounds"
        case "isUserInteractionEnabled", "uiKit.userInteractionEnabled":
            return "userInteractionEnabled"
        case "style.backgroundColor":
            return "backgroundColor"
        case "uiKit.contentMode":
            return "contentMode"
        case "uiKit.tag":
            return "tag"
        case "layer.borderColor", "style.borderColor":
            return "borderColor"
        case "layer.borderWidth", "style.borderWidth":
            return "borderWidth"
        case "layer.cornerRadius", "style.cornerRadius":
            return "cornerRadius"
        case "layer.shadowColor":
            return "shadowColor"
        case "layer.shadowOpacity":
            return "shadowOpacity"
        case "layer.shadowRadius":
            return "shadowRadius"
        case "layer.shadowOffset":
            return "shadowOffset"
        case "zPosition":
            return "layer.zPosition"
        case "accessibilityLabel":
            return "accessibility.label"
        case "accessibilityValue":
            return "accessibility.value"
        case "accessibilityHint":
            return "accessibility.hint"
        case "accessibilityIdentifier", "testID":
            return "accessibility.identifier"
        case "label.text", "textField.text", "textView.text", "uiKit.text":
            return "text"
        case "style.textColor":
            return "textColor"
        case "font.size", "style.fontSize":
            return "fontSize"
        case "label.textAlignment", "textField.textAlignment", "textView.textAlignment":
            return "textAlignment"
        case "label.lineBreakMode", "button.lineBreakMode":
            return "lineBreakMode"
        case "label.numberOfLines":
            return "numberOfLines"
        case "label.adjustsFontSizeToFitWidth", "textField.adjustsFontSizeToFitWidth":
            return "adjustsFontSizeToFitWidth"
        case "label.minimumScaleFactor":
            return "minimumScaleFactor"
        case "textField.placeholder", "searchBar.placeholder":
            return "placeholder"
        case "textField.isSecureTextEntry":
            return "secureTextEntry"
        case "button.title":
            return "title"
        case "isEnabled":
            return "enabled"
        case "isSelected":
            return "selected"
        case "isHighlighted":
            return "highlighted"
        default:
            return property
        }
    }

    private static func supportsTextColorMutation(_ node: LoupeNode) -> Bool {
        node.uiKit?.label != nil
            || node.uiKit?.textField != nil
            || node.uiKit?.textView != nil
            || (node.uiKit?.button != nil && isLikelyUIKitClass(node))
    }

    private static func supportsFontSizeMutation(_ node: LoupeNode) -> Bool {
        node.uiKit?.label != nil
            || node.uiKit?.button != nil
            || node.uiKit?.textField != nil
            || node.uiKit?.textView != nil
    }

    private static func supportsTextAlignmentMutation(_ node: LoupeNode) -> Bool {
        isLikelyUIKitClass(node)
            && (node.uiKit?.label != nil || node.uiKit?.textField != nil || node.uiKit?.textView != nil)
    }

    private static func supportsLineBreakModeMutation(_ node: LoupeNode) -> Bool {
        isLikelyUIKitClass(node)
            && (node.uiKit?.label != nil || node.uiKit?.button != nil)
    }

    private static func supportsUILabelSpecificMutations(_ node: LoupeNode) -> Bool {
        isLikelyUIKitClass(node) && node.uiKit?.label != nil
    }

    private static func supportsUITextFieldSpecificMutations(_ node: LoupeNode) -> Bool {
        isLikelyUIKitClass(node) && node.uiKit?.textField != nil
    }

    private static func isLikelyUIKitClass(_ node: LoupeNode) -> Bool {
        let className = node.uiKit?.className ?? node.typeName
        return className.hasPrefix("UI")
            || className.hasPrefix("_UI")
            || className.contains(".UI")
    }

    private static func isTextBacked(_ node: LoupeNode) -> Bool {
        node.uiKit?.label != nil
            || node.uiKit?.button != nil
            || node.uiKit?.textField != nil
            || node.uiKit?.textView != nil
    }
}
