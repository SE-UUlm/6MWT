import ActivityKit
import Foundation

/// Starts and ends walk test Live Activities using ActivityKit.
@available(iOS 17.0, *)
@MainActor
final class WalkLiveActivityService {
    func start(startedAt: Date, endsAt: Date) throws -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return false
        }
        
        guard endsAt > startedAt, endsAt > Date() else {
            return false
        }
        
        guard Activity<WalkTestWidgetsAttributes>.activities.isEmpty else {
            return false
        }
        
        let attributes = WalkTestWidgetsAttributes(startedAt: startedAt, endsAt: endsAt)
        
        // Mark the content stale at the deadline; this does not end the activity
        let content = ActivityContent(state: WalkTestWidgetsAttributes.ContentState(), staleDate: endsAt)
        
        _ = try Activity<WalkTestWidgetsAttributes>.request(attributes: attributes, content: content, pushType: nil)
        
        return true
    }
    
    func end() async {
        for activity in Activity<WalkTestWidgetsAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
