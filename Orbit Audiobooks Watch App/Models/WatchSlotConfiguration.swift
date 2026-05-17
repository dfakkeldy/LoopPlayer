enum WatchSlotConfiguration {
    static func actions(from raw: String) -> [WatchAction] {
        padded(raw.split(separator: ",").compactMap { WatchAction(rawValue: String($0)) })
    }

    static func padded(_ slots: [WatchAction]) -> [WatchAction] {
        var actions = Array(slots.prefix(5))
        while actions.count < 5 {
            actions.append(.empty)
        }
        return actions
    }
}
