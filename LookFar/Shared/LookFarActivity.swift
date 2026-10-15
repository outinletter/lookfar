import ActivityKit
import Foundation

struct LookFarActivity: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var start: Date
        var deadline: Date
    }
    var title: String
}
