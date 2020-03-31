import Foundation

enum DateFormat {
    static func string(for date: Date?) -> String {
        let formatter: Formatter = {
            if #available(OSX 10.15, *) {
                let formatter = RelativeDateTimeFormatter()
                formatter.dateTimeStyle = .named
                return formatter
            } else {
                let formatter = DateFormatter()
                formatter.doesRelativeDateFormatting = true
                return formatter
            }
        }()
        return formatter.string(for: date) ?? ""
    }
}
