import Foundation

enum ConfigWarnings {
    private static var warnedKeys = Set<String>()
    private static let lock = NSLock()

    static func warnOnce(key: String, message: @autoclosure () -> String) {
        #if DEBUG
        lock.lock()
        defer { lock.unlock() }
        guard !warnedKeys.contains(key) else { return }
        warnedKeys.insert(key)
        Log.warning(message())
        #endif
    }
}
