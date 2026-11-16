import ActivityKit
import Foundation

struct LookFarActivity: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var lit: Bool
    }
    var title: String
}

func L(_ ko: String, _ en: String) -> String {
    Locale.preferredLanguages.first?.hasPrefix("ko") == true ? ko : en
}
