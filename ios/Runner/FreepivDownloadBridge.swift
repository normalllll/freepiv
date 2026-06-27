import Flutter
import Foundation
import Photos
import UIKit

final class FreepivDownloadBridge: NSObject, FlutterStreamHandler, URLSessionDownloadDelegate {
  static let shared = FreepivDownloadBridge()

  private let methodChannelName = "freepiv/download_engine"
  private let eventChannelName = "freepiv/download_engine/events"
  private let queue = DispatchQueue(label: "freepiv.download.bridge")
  private var eventSink: FlutterEventSink?
  private var states: [String: NativeDownloadState] = [:]
  private var tasksByJob: [String: URLSessionDownloadTask] = [:]
  private var backgroundCompletionHandler: (() -> Void)?

  private lazy var session: URLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: "io.github.normalllll.freepiv.download.background")
    config.sessionSendsLaunchEvents = true
    config.httpMaximumConnectionsPerHost = 3
    return URLSession(configuration: config, delegate: self, delegateQueue: nil)
  }()

  func register(messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }

    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger)
    eventChannel.setStreamHandler(self)
  }

  func setBackgroundCompletionHandler(_ completionHandler: @escaping () -> Void) {
    queue.async {
      self.backgroundCompletionHandler = completionHandler
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    queue.async {
      self.eventSink = events
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    queue.async {
      self.eventSink = nil
    }
    return nil
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      _ = session
      result(nil)
    case "prepareForDownload":
      prepareForDownload(result: result)
    case "start":
      let args = call.arguments as? [String: Any]
      let jobs = (args?["jobs"] as? [[String: Any]] ?? []).compactMap(NativeDownloadJob.init)
      guard hasPhotosAddAccess() else {
        result(FlutterError(code: "permission_denied", message: "Photos add permission is not granted.", details: nil))
        return
      }
      start(jobs: jobs)
      result(nil)
    case "cancel":
      let args = call.arguments as? [String: Any]
      if let jobId = args?["jobId"] as? String {
        cancel(jobId: jobId)
      }
      result(nil)
    case "sync":
      sync(result: result)
    case "saveFile":
      guard
        let args = call.arguments as? [String: Any],
        let jobMap = args["job"] as? [String: Any],
        let job = NativeDownloadJob(jobMap),
        let path = args["path"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "saveFile requires job and path", details: nil))
        return
      }
      let bytesWritten = (args["bytesWritten"] as? NSNumber)?.int64Value ?? 0
      saveToPhotos(job: job, localUrl: URL(fileURLWithPath: path), bytesWritten: bytesWritten) { saveResult in
        switch saveResult {
        case .success(let payload):
          result(payload)
        case .failure(let error):
          result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start(jobs: [NativeDownloadJob]) {
    queue.async {
      for job in jobs {
        if self.tasksByJob[job.id] != nil {
          continue
        }
        guard let url = URL(string: job.url) else {
          self.states[job.id] = NativeDownloadState(jobId: job.id, status: "failed", saveState: "none", error: "Invalid URL")
          self.emit(["type": "failed", "jobId": job.id, "error": "Invalid URL"])
          continue
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(job.headers["Referer"] ?? "https://www.pixiv.net/", forHTTPHeaderField: "Referer")
        request.setValue(job.headers["User-Agent"] ?? "freepiv", forHTTPHeaderField: "User-Agent")
        for (key, value) in job.headers {
          request.setValue(value, forHTTPHeaderField: key)
        }

        let task = self.session.downloadTask(with: request)
        task.taskDescription = job.id
        self.tasksByJob[job.id] = task
        self.states[job.id] = NativeDownloadState(jobId: job.id, status: "running", saveState: "none", filename: job.filename)
        task.resume()
      }
    }
  }

  private func prepareForDownload(result: @escaping FlutterResult) {
    requestAddOnlyPhotosAccess(openSettingsWhenDenied: true) { outcome in
      DispatchQueue.main.async {
        switch outcome {
        case .granted:
          result(["granted": true])
        case .denied(let message, let openedSettings):
          result(FlutterError(code: openedSettings ? "permission_denied_permanent" : "permission_denied", message: message, details: nil))
        }
      }
    }
  }

  private func cancel(jobId: String) {
    queue.async {
      self.tasksByJob[jobId]?.cancel()
      self.tasksByJob[jobId] = nil
      var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "cancelled", saveState: "none")
      state.status = "cancelled"
      state.error = nil
      self.states[jobId] = state
      self.emit(["type": "cancelled", "jobId": jobId])
    }
  }

  private func sync(result: @escaping FlutterResult) {
    session.getAllTasks { tasks in
      self.queue.async {
        for task in tasks {
          guard let jobId = task.taskDescription else {
            continue
          }
          var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "running", saveState: "none")
          state.status = task.state == .suspended ? "paused" : "running"
          state.receivedBytes = task.countOfBytesReceived
          state.totalBytes = task.countOfBytesExpectedToReceive > 0 ? task.countOfBytesExpectedToReceive : nil
          state.progress = progressOf(received: state.receivedBytes, total: state.totalBytes)
          self.states[jobId] = state
        }
        let payload = self.states.values.map { $0.toMap() }
        DispatchQueue.main.async {
          result(payload)
        }
      }
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    guard let jobId = downloadTask.taskDescription else {
      return
    }
    queue.async {
      var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "running", saveState: "none")
      state.status = "running"
      state.receivedBytes = totalBytesWritten
      state.totalBytes = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil
      state.progress = progressOf(received: totalBytesWritten, total: state.totalBytes)
      self.states[jobId] = state
      self.emit(
        [
          "type": "progress",
          "jobId": jobId,
          "receivedBytes": state.receivedBytes,
          "totalBytes": state.totalBytes as Any,
          "progress": state.progress,
        ]
      )
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let jobId = downloadTask.taskDescription else {
      return
    }

    queue.async {
      var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "downloaded", saveState: "pending")
      let filename = state.filename ?? "\(jobId).img"
      do {
        let destination = try self.moveDownloadedFile(location: location, jobId: jobId, filename: filename)
        state.status = "downloaded"
        state.saveState = "saving"
        state.localPath = destination.path
        state.receivedBytes = downloadTask.countOfBytesReceived
        state.totalBytes = downloadTask.countOfBytesExpectedToReceive > 0 ? downloadTask.countOfBytesExpectedToReceive : state.receivedBytes
        state.progress = 1
        self.states[jobId] = state
        self.emit(["type": "completed", "jobId": jobId, "localPath": destination.path, "bytesWritten": state.receivedBytes])

        let job = NativeDownloadJob(id: jobId, url: downloadTask.originalRequest?.url?.absoluteString ?? "", filename: filename, headers: [:])
        self.saveToPhotos(job: job, localUrl: destination, bytesWritten: state.receivedBytes) { saveResult in
          self.queue.async {
            var latest = self.states[jobId] ?? state
            switch saveResult {
            case .success(let payload):
              latest.saveState = "saved"
              latest.galleryAssetId = payload["galleryAssetId"] as? String
              latest.localPath = payload["path"] as? String ?? latest.localPath
              latest.error = nil
              try? FileManager.default.removeItem(at: destination)
              self.emit(["type": "saved", "jobId": jobId, "path": latest.localPath as Any, "galleryAssetId": latest.galleryAssetId as Any])
            case .failure(let error):
              latest.saveState = "failed"
              latest.error = error.localizedDescription
              latest.localPath = destination.path
              self.emit(["type": "saveFailed", "jobId": jobId, "localPath": destination.path, "error": latest.error as Any])
            }
            self.states[jobId] = latest
          }
        }
      } catch {
        state.status = "downloaded"
        state.saveState = "failed"
        state.error = error.localizedDescription
        self.states[jobId] = state
        self.emit(["type": "saveFailed", "jobId": jobId, "error": error.localizedDescription])
      }
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let jobId = task.taskDescription else {
      return
    }
    queue.async {
      self.tasksByJob[jobId] = nil
      guard let error else {
        return
      }

      var state = self.states[jobId] ?? NativeDownloadState(jobId: jobId, status: "failed", saveState: "none")
      if (error as NSError).code == NSURLErrorCancelled {
        state.status = "cancelled"
        state.error = nil
        self.emit(["type": "cancelled", "jobId": jobId])
      } else {
        state.status = "failed"
        state.error = error.localizedDescription
        self.emit(["type": "failed", "jobId": jobId, "error": error.localizedDescription])
      }
      self.states[jobId] = state
    }
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    queue.async {
      let handler = self.backgroundCompletionHandler
      self.backgroundCompletionHandler = nil
      DispatchQueue.main.async {
        handler?()
      }
    }
  }

  private func moveDownloadedFile(location: URL, jobId: String, filename: String) throws -> URL {
    let directory = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("freepiv_downloads", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let destination = directory.appendingPathComponent("\(jobId)-\(safeFilename(filename))")
    if FileManager.default.fileExists(atPath: destination.path) {
      try FileManager.default.removeItem(at: destination)
    }
    try FileManager.default.moveItem(at: location, to: destination)
    return destination
  }

  private func saveToPhotos(job: NativeDownloadJob, localUrl: URL, bytesWritten: Int64, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    guard hasPhotosAddAccess() else {
      completion(.failure(NSError(domain: "freepiv.download", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photos add permission is not granted."])))
      return
    }

    do {
      try validateReadableFile(localUrl)
    } catch {
      completion(.failure(error))
      return
    }

    var localIdentifier: String?
    PHPhotoLibrary.shared().performChanges {
      let options = PHAssetResourceCreationOptions()
      options.originalFilename = safeFilename(job.filename)
      let request = PHAssetCreationRequest.forAsset()
      request.addResource(with: .photo, fileURL: localUrl, options: options)
      localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
    } completionHandler: { success, error in
      if let error {
        completion(.failure(error))
        return
      }
      if !success {
        completion(.failure(NSError(domain: "freepiv.download", code: 2, userInfo: [NSLocalizedDescriptionKey: "Photos save failed."])))
        return
      }
      let savedPath = localIdentifier.map { "ph://\($0)" } ?? localUrl.path
      completion(.success(compactPayload(["path": savedPath, "galleryAssetId": localIdentifier, "bytesWritten": bytesWritten])))
    }
  }

  private func hasPhotosAddAccess() -> Bool {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      switch status {
      case .authorized, .limited:
        return true
      default:
        return false
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .authorized:
        return true
      default:
        return false
      }
    }
  }

  private func requestAddOnlyPhotosAccess(openSettingsWhenDenied: Bool, completion: @escaping (PhotoPermissionOutcome) -> Void) {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      switch status {
      case .authorized, .limited:
        completion(.granted)
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
          self.resolvePhotoAuthorizationStatus(newStatus, openSettingsWhenDenied: openSettingsWhenDenied, completion: completion)
        }
      default:
        resolvePhotoAuthorizationStatus(status, openSettingsWhenDenied: openSettingsWhenDenied, completion: completion)
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .authorized:
        completion(.granted)
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization { newStatus in
          self.resolvePhotoAuthorizationStatus(newStatus, openSettingsWhenDenied: openSettingsWhenDenied, completion: completion)
        }
      default:
        resolvePhotoAuthorizationStatus(status, openSettingsWhenDenied: openSettingsWhenDenied, completion: completion)
      }
    }
  }

  private func resolvePhotoAuthorizationStatus(_ status: PHAuthorizationStatus, openSettingsWhenDenied: Bool, completion: @escaping (PhotoPermissionOutcome) -> Void) {
    if #available(iOS 14, *), status == .limited {
      completion(.granted)
      return
    }

    switch status {
    case .authorized:
      completion(.granted)
    case .denied, .restricted:
      let message = "Photos add permission was denied."
      guard openSettingsWhenDenied else {
        completion(.denied(message: message, openedSettings: false))
        return
      }
      openAppSettings { opened in
        completion(.denied(message: opened ? "\(message) App settings were opened." : message, openedSettings: opened))
      }
    case .notDetermined:
      completion(.denied(message: "Photos add permission has not been requested.", openedSettings: false))
    @unknown default:
      completion(.denied(message: "Photos add permission status is unknown.", openedSettings: false))
    }
  }

  private func openAppSettings(completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.async {
      guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) else {
        completion(false)
        return
      }
      UIApplication.shared.open(settingsUrl, options: [:]) { opened in
        completion(opened)
      }
    }
  }

  private func emit(_ event: [String: Any?]) {
    guard let eventSink else {
      return
    }
    let payload = compactPayload(event)
    DispatchQueue.main.async {
      eventSink(payload)
    }
  }
}

private struct NativeDownloadJob {
  let id: String
  let url: String
  let filename: String
  let headers: [String: String]

  init?(_ map: [String: Any]) {
    guard let id = map["id"] as? String, let url = map["url"] as? String else {
      return nil
    }
    self.id = id
    self.url = url
    self.filename = map["filename"] as? String ?? "download"
    self.headers = (map["headers"] as? [String: String]) ?? [:]
  }

  init(id: String, url: String, filename: String, headers: [String: String]) {
    self.id = id
    self.url = url
    self.filename = filename
    self.headers = headers
  }
}

private struct NativeDownloadState {
  let jobId: String
  var status: String
  var saveState: String
  var filename: String?
  var receivedBytes: Int64 = 0
  var totalBytes: Int64?
  var progress: Double = 0
  var localPath: String?
  var galleryAssetId: String?
  var error: String?

  func toMap() -> [String: Any] {
    compactPayload([
      "jobId": jobId,
      "status": status,
      "saveState": saveState,
      "receivedBytes": receivedBytes,
      "totalBytes": totalBytes,
      "progress": progress,
      "localPath": localPath,
      "galleryAssetId": galleryAssetId,
      "error": error,
    ])
  }
}

private enum PhotoPermissionOutcome {
  case granted
  case denied(message: String, openedSettings: Bool)
}

private func progressOf(received: Int64, total: Int64?) -> Double {
  guard let total, total > 0 else {
    return 0
  }
  return min(max(Double(received) / Double(total), 0), 1)
}

private func safeFilename(_ filename: String) -> String {
  let invalid = CharacterSet(charactersIn: "/\\\0")
  let sanitized = filename.components(separatedBy: invalid).joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)
  return sanitized.isEmpty ? "download" : sanitized
}

private func validateReadableFile(_ url: URL) throws {
  guard url.isFileURL else {
    throw NSError(domain: "freepiv.download", code: 3, userInfo: [NSLocalizedDescriptionKey: "Downloaded file URL is invalid."])
  }
  let path = url.path
  guard FileManager.default.fileExists(atPath: path) else {
    throw NSError(domain: "freepiv.download", code: 4, userInfo: [NSLocalizedDescriptionKey: "Downloaded file does not exist: \(path)"])
  }
  let attributes = try FileManager.default.attributesOfItem(atPath: path)
  let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
  guard size > 0 else {
    throw NSError(domain: "freepiv.download", code: 5, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is empty: \(path)"])
  }
}

private func compactPayload(_ payload: [String: Any?]) -> [String: Any] {
  var result: [String: Any] = [:]
  for (key, value) in payload {
    if let value {
      result[key] = value
    }
  }
  return result
}
