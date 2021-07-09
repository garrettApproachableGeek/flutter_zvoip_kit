import Flutter
import UIKit




class CallStreamHandler: NSObject, FlutterStreamHandler {
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("CallStreamHandler: on listen");
        SwiftFlutterZVoipKitPlugin.callController.actionListener = { event, uuid, args in
            print("Action listener: \(event)")
            var data = ["event" : event.rawValue, "uuid": uuid.uuidString] as [String: Any]
            if args != nil{
                data["args"] = args!
            }
            events(data)
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("CallStreamHanlder: on cancel")
        SwiftFlutterZVoipKitPlugin.callController.actionListener = nil
        return nil
    }
    
}

public class SwiftFlutterZVoipKitPlugin: NSObject, FlutterPlugin {
    static let _methodChannelName = "flutter_zvoip_kit";
    static let _callEventChannelName = "flutter_zvoip_kit.callEventChannel"
    static let callController = CallController()
    
    
    //methods
    static let _methodChannelStartCall = "flutter_zvoip_kit.startCall"
    static let _methodChannelReportIncomingCall = "flutter_zvoip_kit.reportIncomingCall"
    static let _methodChannelReportOutgoingCall = "flutter_zvoip_kit.reportOutgoingCall"
    static let _methodChannelReportCallEnded =
        "flutter_zvoip_kit.reportCallEnded";
    static let _methodChannelEndCall = "flutter_zvoip_kit.endCall";
    static let _methodChannelHoldCall = "flutter_zvoip_kit.holdCall";
    static let _methodChannelCheckPermissions = "flutter_zvoip_kit.checkPermissions";
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        //setup method channels
        let methodChannel = FlutterMethodChannel(name: _methodChannelName, binaryMessenger: registrar.messenger())
        
        //setup event channels
        let callEventChannel = FlutterEventChannel(name: _callEventChannelName, binaryMessenger: registrar.messenger())
        callEventChannel.setStreamHandler(CallStreamHandler())
        
        let instance = SwiftFlutterZVoipKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }
    
    ///useful for integrating with VIOP notifications
    static public func reportIncomingCall(handle: String, uuid: String, result: FlutterResult?){
        SwiftFlutterZVoipKitPlugin.callController.reportIncomingCall(uuid: UUID(uuidString: uuid)!, handle: handle) { (error) in
            print("ERROR: \(error?.localizedDescription ?? "none")")
            result?(error == nil)
        }
    }
    
    //TODO: remove these defaults and get as arguments
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        if(call.method == SwiftFlutterZVoipKitPlugin._methodChannelStartCall){
            if let handle = args?["handle"] as? String{
                let uuidString = args?["uuid"] as? String;
                SwiftFlutterZVoipKitPlugin.callController.startCall(handle: handle, videoEnabled: false, uuid: uuidString)
                result(true)
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterZVoipKitPlugin._methodChannelReportIncomingCall{
            if let handle = args?["handle"] as? String, let uuid = args?["uuid"] as? String{
                SwiftFlutterZVoipKitPlugin.reportIncomingCall(handle: handle, uuid: uuid, result: result)
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterZVoipKitPlugin._methodChannelReportOutgoingCall{
            if let finishedConnecting = args?["finishedConnecting"] as? Bool, let uuid = args?["uuid"] as? String{
                SwiftFlutterZVoipKitPlugin.callController.reportOutgoingCall(uuid: UUID(uuidString: uuid)!, finishedConnecting: finishedConnecting);
                result(true);
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }
        else if call.method == SwiftFlutterZVoipKitPlugin._methodChannelReportCallEnded{
            if let reason = args?["reason"] as? String, let uuid = args?["uuid"] as? String{
                SwiftFlutterZVoipKitPlugin.callController.reportCallEnded(uuid: UUID(uuidString: uuid)!, reason: CallEndedReason.init(rawValue: reason)!);
                result(true);
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterZVoipKitPlugin._methodChannelEndCall{
            if let uuid = args?["uuid"] as? String{
                SwiftFlutterZVoipKitPlugin.callController.end(uuid: UUID(uuidString: uuid)!)
                result(true)
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterZVoipKitPlugin._methodChannelHoldCall{
            if let uuid = args?["uuid"] as? String, let hold = args?["hold"] as? Bool{
                SwiftFlutterZVoipKitPlugin.callController.setHeld(uuid: UUID(uuidString: uuid)!, onHold: hold)
                result(true)
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterZVoipKitPlugin._methodChannelCheckPermissions{
            result(true) //no permissions needed on ios
        }
    }
}
