import Foundation
import ActivityKit

/// Shared data describing the walk test countdown.
@available(iOS 16.1, *)
struct WalkTestWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // No mutable data needed for the deadline-based countdown.
    }

    // Shared timestamps keep the app and Live Activitiy countdowns aligned.
    let startedAt: Date
    let endsAt: Date
}

