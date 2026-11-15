import Flutter
import Foundation

/// Bridges Flutter requests to the native Live Activity service 
final class WalkLiveActivityChannel {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "six_minute_walk_test/live_activity",
                                           binaryMessenger: registrar.messenger())
        
        channel.setMethodCallHandler{call, result in
            guard call.method == "start" || call.method == "end" else {
                result(FlutterMethodNotImplemented)
                return
            }
        
            guard #available(iOS 17.0, *) else {
                result(false)
                return
            }
            
            Task { @MainActor in
                let service = WalkLiveActivityService()
            
                if call.method == "end" {
                    await service.end()
                    result(true)
                    return
                }
                
                guard
                    let arguments = call.arguments as? [String: Any],
                    let start = arguments["startedAt"] as? NSNumber,
                    let end = arguments["endsAt"] as? NSNumber
                        else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                        message: "startedAt and endsAt are required.",
                                       details: nil))
                    return
                }
                
                // Dart sends epoch milliseconds; Foundation expects seconds.
                let startSeconds = start.doubleValue / 1000
                let endSeconds = end.doubleValue / 1000
                
                guard startSeconds.isFinite, endSeconds.isFinite else {
                    result(FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Date must be finite timestamps.",
                        details: nil
                    ))
                    return
                }
                
                do {
                    let started = try service.start(startedAt: Date(timeIntervalSince1970: startSeconds), endsAt: Date(timeIntervalSince1970: endSeconds))
                    result(started)
                } catch {
                    result(FlutterError(code: "LIVE_ACTIVITY_START_FAILED",
                                        message: error.localizedDescription,
                                        details: nil))
                }
            }
            
        }
        
    }
}
