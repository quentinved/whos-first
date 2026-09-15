import Foundation

/// Flags the UI test targets pass on launch. Release builds ignore them.
enum LaunchArguments {
    static var isUITesting: Bool { has("-ui-testing") }
    static var resetsUIState: Bool { has("-reset-ui-state") }

    private static func has(_ flag: String) -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains(flag)
        #else
        return false
        #endif
    }
}
