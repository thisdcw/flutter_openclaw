import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "openclaw/media",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "saveImage" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.saveImage(call: call, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveImage(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let typedData = arguments["bytes"] as? FlutterStandardTypedData,
      let fileName = arguments["fileName"] as? String
    else {
      result(
        FlutterError(
          code: "invalid-arguments",
          message: "Image bytes are required.",
          details: nil
        )
      )
      return
    }

    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        self.handlePhotoAuthorization(
          status: status,
          fileName: fileName,
          typedData: typedData,
          result: result
        )
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        self.handleLegacyPhotoAuthorization(
          status: status,
          fileName: fileName,
          typedData: typedData,
          result: result
        )
      }
    }
  }

  @available(iOS 14, *)
  private func handlePhotoAuthorization(
    status: PHAuthorizationStatus,
    fileName: String,
    typedData: FlutterStandardTypedData,
    result: @escaping FlutterResult
  ) {
    switch status {
    case .authorized, .limited:
      persistImage(fileName: fileName, typedData: typedData, result: result)
    case .denied, .restricted:
      permissionDenied(result: result)
    case .notDetermined:
      permissionPending(result: result)
    @unknown default:
      permissionUnknown(result: result)
    }
  }

  private func handleLegacyPhotoAuthorization(
    status: PHAuthorizationStatus,
    fileName: String,
    typedData: FlutterStandardTypedData,
    result: @escaping FlutterResult
  ) {
    switch status {
    case .authorized:
      persistImage(fileName: fileName, typedData: typedData, result: result)
    case .denied, .restricted:
      permissionDenied(result: result)
    case .notDetermined:
      permissionPending(result: result)
    default:
      permissionUnknown(result: result)
    }
  }

  private func persistImage(
    fileName: String,
    typedData: FlutterStandardTypedData,
    result: @escaping FlutterResult
  ) {
    let options = PHAssetResourceCreationOptions()
    options.originalFilename = fileName
    PHPhotoLibrary.shared().performChanges({
      let creationRequest = PHAssetCreationRequest.forAsset()
      creationRequest.addResource(
        with: .photo,
        data: typedData.data,
        options: options
      )
    }) { success, error in
      DispatchQueue.main.async {
        if success {
          result(fileName)
        } else {
          result(
            FlutterError(
              code: "save-failed",
              message: error?.localizedDescription ?? "Saving image failed.",
              details: nil
            )
          )
        }
      }
    }
  }

  private func permissionDenied(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      result(
        FlutterError(
          code: "permission-denied",
          message: "Photos permission was denied.",
          details: nil
        )
      )
    }
  }

  private func permissionPending(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      result(
        FlutterError(
          code: "permission-pending",
          message: "Photos permission is still pending.",
          details: nil
        )
      )
    }
  }

  private func permissionUnknown(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      result(
        FlutterError(
          code: "permission-unknown",
          message: "Unknown Photos permission state.",
          details: nil
        )
      )
    }
  }
}
