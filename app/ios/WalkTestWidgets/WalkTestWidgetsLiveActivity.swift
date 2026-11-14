import ActivityKit
import WidgetKit
import SwiftUI

/// Displays the walk test on the Lock Screen and in the Dynamic Island.
struct WalkTestWidgetsLiveActivity: Widget {
    
    @ScaledMetric(relativeTo: .largeTitle)
    private var countdownFontSize: CGFloat = 48
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WalkTestWidgetsAttributes.self) { context in
            // Lock screen/banner UI
            ZStack {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        if context.isStale { Text("Walk test ended. Open app").font(.headline)
                        } else {
                            Text("Walk test in progress").font(.headline)
                        }
                    }
                    
                    Text(timerInterval: context.attributes.startedAt...context.attributes.endsAt,
                    countsDown: true,
                         showsHours: false).font(.largeTitle).fontWeight(.bold).monospacedDigit().multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    
                    Text("Time remaining").font(.caption)
                }.foregroundStyle(Color.black).padding(16).background {
                    Image("WalkBackground").resizable().scaledToFill().clipped()
                }
            }.clipped().activityBackgroundTint(Color.clear).widgetURL(URL(string: "sixmwt:///walk"))

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island presentation.
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            
                            Image(systemName: "figure.walk").accessibilityHidden(true)
                            
                            // Fallback if the app cannot end the activity at the deadline.
                            if context.isStale {
                                Text("Walk test ended. Open app")
                            } else {
                                Text("Walk test in progress")
                            }
                        }
                        .font(.headline).multilineTextAlignment(.center)
                        
                        Text(timerInterval: context.attributes.startedAt...context.attributes.endsAt,
                             countsDown: true,
                             showsHours: false
                        )
                        .font(.largeTitle).fontWeight(.bold).monospacedDigit().multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                }
            } compactLeading: {
                Image(systemName: "figure.walk")
            } compactTrailing: {
                Text(timerInterval: context.attributes.startedAt...context.attributes.endsAt,
                          countsDown: true,
                     showsHours: false).monospacedDigit().frame(width: 40)
            } minimal: {
                Image(systemName: "figure.walk")
            }
            .widgetURL(URL(string: "sixmwt:///walk"))
            .keylineTint(Color.red)
        }
    }
}

extension WalkTestWidgetsAttributes {
    fileprivate static var preview: WalkTestWidgetsAttributes {
        let start = Date()
        
        return WalkTestWidgetsAttributes(
            startedAt: start, endsAt: start.addingTimeInterval(6 * 60)
        )
    }
}


#Preview("Sperrbildschirm", as: .content, using: WalkTestWidgetsAttributes.preview) {
   WalkTestWidgetsLiveActivity()
} contentStates: {
    WalkTestWidgetsAttributes.ContentState()
}


