//
//  SFButton.swift
//  SpeechRecognizerButton
//
//  Created by Alejandro Ruperez Hernando on 26/2/18.
//  Copyright © 2018 alexruperez. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

@IBDesignable public class SFButton: UIButton {

    public enum SFButtonError: Error {
        public enum AuthorizationReason {
            case denied, restricted
        }
        case authorization(reason: AuthorizationReason), audioFormat(settings: [String : Any]), recording, invalid(locale: Locale), notAvailable, unknown(error: Error?)
    }

    public enum AuthorizationErrorHandling {
        case none, openSettings(completion: BoolClosure?), custom(handler: ErrorClosure)
    }

    public typealias BoolClosure = (Bool) -> ()
    public typealias ErrorClosure = (SFButtonError?) -> ()
    public typealias ResultClosure = (URL, SFSpeechRecognitionResult?) -> ()

    public var authorizationErrorHandling = AuthorizationErrorHandling.none
    public var resultHandler: ResultClosure?
    public var errorHandler: ErrorClosure?
    public var audioSession = AVAudioSession.sharedInstance()
    public var recordURL = FileManager.default.temporaryDirectory.appendingPathComponent("record.m4a")
    public var audioFormatSettings: [String : Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                                      AVSampleRateKey: 12000,
                                                      AVNumberOfChannelsKey: 1,
                                                      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    public var maxDuration = TimeInterval(60)
    public var locale = Locale.autoupdatingCurrent
    public var defaultTaskHint = SFSpeechRecognitionTaskHint.unspecified
    public var queue = OperationQueue.main

    private var audioRecorder: AVAudioRecorder?
    private var speechRecognizer: SFSpeechRecognizer?
    private var speechRecognitionTask: SFSpeechRecognitionTask?

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    private func initialize() {
        addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
    }

    @objc private func touchDown(_ sender: Any? = nil) {
        checkRecordAuthorization {
            if let error = $0 {
                self.handleAuthorizationError(error, self.authorizationErrorHandling)
            } else {
                if self.audioRecorder == nil {
                    guard let audioFormat = AVAudioFormat(settings: self.audioFormatSettings) else {
                        self.errorHandler?(.audioFormat(settings: self.audioFormatSettings))
                        return
                    }
                    do {
                        try self.audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                        try self.audioSession.setActive(true)
                        self.audioRecorder = try AVAudioRecorder(url: self.recordURL, format: audioFormat)
                        self.audioRecorder?.delegate = self
                    } catch {
                        self.errorHandler?(.unknown(error: error))
                    }
                }
                if self.audioRecorder?.isRecording == false, self.isHighlighted {
                    self.audioRecorder?.record(forDuration: self.maxDuration)
                }
            }
        }
    }

    @objc private func touchUpInside(_ sender: Any? = nil) {
        self.audioRecorder?.stop()
    }

    private func handleAuthorizationError(_ error: SFButtonError, _ handling: AuthorizationErrorHandling) {
        switch handling {
        case .none: break
        case .openSettings(let completion): openSettings(completion)
        case .custom(let handler): handler(error)
        }
    }

    public func openSettings(_ completion: BoolClosure? = nil) {
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(url, completionHandler: completion)
        } else {
            completion?(false)
        }
    }

    public func checkRecordAuthorization(_ handler: ErrorClosure? = nil) {
        switch audioSession.recordPermission() {
        case .granted: handler?(nil)
        case .denied: handler?(.authorization(reason: .denied))
        case .undetermined:
            audioSession.requestRecordPermission({ _ in
                self.checkRecordAuthorization(handler)
            })
        }
    }

    public func checkSpeechRecognizerAuthorization(_ handler: ErrorClosure? = nil) {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: handler?(nil)
        case .denied: handler?(.authorization(reason: .denied))
        case .restricted: handler?(.authorization(reason: .restricted))
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { _ in
                self.checkSpeechRecognizerAuthorization(handler)
            }
        }
    }

}

extension SFButton: AVAudioRecorderDelegate {

    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            checkSpeechRecognizerAuthorization {
                if let error = $0 {
                    self.handleAuthorizationError(error, self.authorizationErrorHandling)
                } else {
                    if self.speechRecognizer == nil {
                        guard let speechRecognizer = SFSpeechRecognizer(locale: self.locale) else {
                            self.errorHandler?(.invalid(locale: self.locale))
                            return
                        }
                        speechRecognizer.defaultTaskHint = self.defaultTaskHint
                        speechRecognizer.queue = self.queue
                        guard speechRecognizer.isAvailable else {
                            self.errorHandler?(.notAvailable)
                            return
                        }
                        self.speechRecognizer = speechRecognizer
                    }
                    if self.speechRecognitionTask == nil {
                        let speechRecognitionRequest = SFSpeechURLRecognitionRequest(url: self.recordURL)
                        self.speechRecognitionTask = self.speechRecognizer?.recognitionTask(with: speechRecognitionRequest, resultHandler: { result, error in
                            if let result = result, result.isFinal {
                                self.resultHandler?(self.recordURL, result)
                                self.speechRecognitionTask = nil
                            } else if let error = error {
                                self.errorHandler?(.unknown(error: error))
                                self.speechRecognitionTask = nil
                            }
                        })
                    }
                }
            }
        } else {
            errorHandler?(.recording)
        }
    }

    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        errorHandler?(.unknown(error: error))
    }

}
