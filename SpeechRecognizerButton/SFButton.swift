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
import AudioToolbox

@IBDesignable
public class SFButton: UIButton {

    public enum SFButtonError: Error {
        public enum AuthorizationReason {
            case denied, restricted, usageDescription(missing: UsageDescriptionKey)
        }
        public enum CancellationReason {
            case user, notFound
        }
        case authorization(reason: AuthorizationReason), cancelled(reason: CancellationReason), recording, invalid(locale: Locale), notAvailable, unknown(error: Error?)
    }

    public enum AuthorizationErrorHandling {
        case none, openSettings(completion: BoolClosure?), custom(handler: ErrorClosure)
    }

    public typealias UsageDescriptionKey = String
    public typealias BoolClosure = (Bool) -> ()
    public typealias ErrorClosure = (SFButtonError?) -> ()
    public typealias ResultClosure = (URL, SFSpeechRecognitionResult?) -> ()

    public var authorizationErrorHandling = AuthorizationErrorHandling.none
    public var resultHandler: ResultClosure?
    public var errorHandler: ErrorClosure?
    public var audioSession = AVAudioSession.sharedInstance()
    public var recordURL = FileManager.default.temporaryDirectory.appendingPathComponent("SFButton.aac")
    public var audioFormatSettings: [String : Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                                      AVSampleRateKey: 12000,
                                                      AVNumberOfChannelsKey: 1,
                                                      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    @IBInspectable public var maxDuration: Double = 60
    public var locale = Locale.autoupdatingCurrent
    public var taskHint = SFSpeechRecognitionTaskHint.unspecified
    public var queue = OperationQueue.main
    public var contextualStrings = [String]()
    public var interactionIdentifier: String?
    @IBInspectable public var animationDuration: Double = 0.5
    @IBInspectable public var shouldVibrate: Bool = true
    @IBInspectable public var shouldSound: Bool = true
    @IBOutlet public weak var waveformView: SFWaveformView?

    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var displayLink: CADisplayLink?
    private var speechRecognizer: SFSpeechRecognizer?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private let microphoneUsageDescriptionKey = UsageDescriptionKey("NSMicrophoneUsageDescription")
    private let speechRecognitionUsageDescriptionKey = UsageDescriptionKey("NSSpeechRecognitionUsageDescription")

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    private func initialize() {
        addTarget(self, action: #selector(self.touchDown(_:)), for: .touchDown)
        addTarget(self, action: #selector(self.touchUpInside(_:)), for: .touchUpInside)
        addTarget(self, action: #selector(self.touchUpOutside(_:)), for: .touchUpOutside)
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        waveformView(show: false, animationDuration: 0)
    }

    deinit {
        displayLink?.invalidate()
    }

    @objc private func touchDown(_ sender: Any? = nil) {
        checkRecordAuthorization {
            if let error = $0 {
                self.queue.addOperation {
                    self.handleAuthorizationError(error, self.authorizationErrorHandling)
                }
            } else {
                if self.audioRecorder == nil {
                    do {
                        self.audioRecorder = try AVAudioRecorder(url: self.recordURL, settings: self.audioFormatSettings)
                    } catch {
                        self.queue.addOperation {
                            self.errorHandler?(.unknown(error: error))
                        }
                    }
                    self.audioRecorder?.delegate = self
                    self.audioRecorder?.isMeteringEnabled = true
                    self.audioRecorder?.prepareToRecord()
                }
                OperationQueue.main.addOperation {
                    if self.audioRecorder?.isRecording == false, self.isHighlighted {
                        if self.shouldVibrate {
                            AudioServicesPlaySystemSound(1519)
                        }
                        if self.shouldSound {
                            AudioServicesPlaySystemSoundWithCompletion(1113, {
                                OperationQueue.main.addOperation {
                                    self.beginRecord()
                                }
                            })
                        } else {
                            self.beginRecord()
                        }
                    }
                }
            }
        }
    }

    private func beginRecord() {
        try? audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try? audioSession.setActive(true)
        audioRecorder?.record(forDuration: maxDuration)
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(self.updateMeters(_:)))
            displayLink?.add(to: .current, forMode: .commonModes)
        }
        displayLink?.isPaused = false
        waveformView(show: true, animationDuration: self.animationDuration)
    }

    private func endRecord() {
        displayLink?.isPaused = true
        audioRecorder?.stop()
        waveformView(show: false, animationDuration: animationDuration)
        try? audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try? audioSession.setActive(true)
        if self.shouldVibrate {
            AudioServicesPlaySystemSound(1519)
        }
        if self.shouldSound {
            AudioServicesPlaySystemSound(1114)
        }
    }

    open func waveformView(show: Bool, animationDuration: TimeInterval) {
        if animationDuration > 0 {
            UIView.animate(withDuration: animationDuration, animations: {
                self.waveformView?.alpha = show ? 1 : 0
            })
        } else {
            waveformView?.alpha = show ? 1 : 0
        }
    }

    @objc private func updateMeters(_ sender: Any? = nil) {
        audioRecorder?.updateMeters()
        guard let averagePower = audioRecorder?.averagePower(forChannel: 0) else {
            return
        }
        let normalizedValue = pow(10, averagePower / 20)
        waveformView?.updateWithLevel(CGFloat(normalizedValue))
    }

    @objc private func touchUpInside(_ sender: Any? = nil) {
        endRecord()
    }

    @objc private func touchUpOutside(_ sender: Any? = nil) {
        endRecord()
        audioRecorder?.deleteRecording()
    }

    private func handleAuthorizationError(_ error: SFButtonError, _ handling: AuthorizationErrorHandling) {
        switch handling {
        case .none: break
        case .openSettings(let completion): openSettings(completion)
        case .custom(let handler): handler(error)
        }
    }

    public func play() {
        guard FileManager.default.fileExists(atPath: recordURL.path) else {
            queue.addOperation {
                self.errorHandler?(.cancelled(reason: .notFound))
            }
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recordURL)
            audioPlayer?.delegate = self
            try self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try self.audioSession.setActive(true)
        } catch {
            queue.addOperation {
                self.errorHandler?(.unknown(error: error))
            }
        }
        audioPlayer?.play()
    }

    public func openSettings(_ completion: BoolClosure? = nil) {
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(url, completionHandler: completion)
        } else {
            completion?(false)
        }
    }

    public func checkRecordAuthorization(_ handler: ErrorClosure? = nil) {
        if Bundle.main.object(forInfoDictionaryKey: microphoneUsageDescriptionKey) != nil {
            switch audioSession.recordPermission() {
            case .granted: handler?(nil)
            case .denied: handler?(.authorization(reason: .denied))
            case .undetermined:
                audioSession.requestRecordPermission({ _ in
                    self.checkRecordAuthorization(handler)
                })
            }
        } else {
            let error = SFButtonError.authorization(reason: .usageDescription(missing: self.microphoneUsageDescriptionKey))
            queue.addOperation {
                self.errorHandler?(error)
            }
            handler?(error)
        }
    }

    public func checkSpeechRecognizerAuthorization(_ handler: ErrorClosure? = nil) {
        if Bundle.main.object(forInfoDictionaryKey: speechRecognitionUsageDescriptionKey) != nil {
            switch SFSpeechRecognizer.authorizationStatus() {
            case .authorized: handler?(nil)
            case .denied: handler?(.authorization(reason: .denied))
            case .restricted: handler?(.authorization(reason: .restricted))
            case .notDetermined:
                SFSpeechRecognizer.requestAuthorization { _ in
                    self.checkSpeechRecognizerAuthorization(handler)
                }
            }
        } else {
            let error = SFButtonError.authorization(reason: .usageDescription(missing: self.speechRecognitionUsageDescriptionKey))
            queue.addOperation {
                self.errorHandler?(error)
            }
            handler?(error)
        }
    }

}

extension SFButton: AVAudioPlayerDelegate {

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        do {
            try self.audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        } catch {
            queue.addOperation {
                self.errorHandler?(.unknown(error: error))
            }
        }
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        do {
            try self.audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        } catch {
            queue.addOperation {
                self.errorHandler?(.unknown(error: error))
            }
        }
        queue.addOperation {
            self.errorHandler?(.unknown(error: error))
        }
    }

}

extension SFButton: AVAudioRecorderDelegate {

    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        do {
            try self.audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        } catch {
            queue.addOperation {
                self.errorHandler?(.unknown(error: error))
            }
        }
        if flag {
            checkSpeechRecognizerAuthorization {
                if let error = $0 {
                    self.queue.addOperation {
                        self.resultHandler?(self.recordURL, nil)
                        self.handleAuthorizationError(error, self.authorizationErrorHandling)
                    }
                } else {
                    if self.speechRecognizer == nil {
                        guard let speechRecognizer = SFSpeechRecognizer(locale: self.locale) else {
                            self.queue.addOperation {
                                self.resultHandler?(self.recordURL, nil)
                                self.errorHandler?(.invalid(locale: self.locale))
                            }
                            return
                        }
                        speechRecognizer.defaultTaskHint = self.taskHint
                        speechRecognizer.queue = self.queue
                        self.speechRecognizer = speechRecognizer
                    }
                    guard self.speechRecognizer?.isAvailable == true else {
                        self.queue.addOperation {
                            self.resultHandler?(self.recordURL, nil)
                            self.errorHandler?(.notAvailable)
                        }
                        return
                    }
                    if self.speechRecognitionTask == nil {
                        guard FileManager.default.fileExists(atPath: self.recordURL.path) else {
                            self.queue.addOperation {
                                self.errorHandler?(.cancelled(reason: .user))
                            }
                            return
                        }
                        let speechRecognitionRequest = SFSpeechURLRecognitionRequest(url: self.recordURL)
                        speechRecognitionRequest.contextualStrings = self.contextualStrings
                        speechRecognitionRequest.interactionIdentifier = self.interactionIdentifier
                        self.speechRecognitionTask = self.speechRecognizer?.recognitionTask(with: speechRecognitionRequest, resultHandler: { result, error in
                            if let result = result, result.isFinal {
                                self.queue.addOperation {
                                    self.resultHandler?(self.recordURL, result)
                                }
                                self.speechRecognitionTask = nil
                            } else if let error = error {
                                self.queue.addOperation {
                                    self.resultHandler?(self.recordURL, nil)
                                    self.errorHandler?(.unknown(error: error))
                                }
                                self.speechRecognitionTask = nil
                            }
                        })
                    }
                }
            }
        } else {
            queue.addOperation {
                self.errorHandler?(.recording)
            }
        }
    }

    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        do {
            try self.audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        } catch {
            queue.addOperation {
                self.errorHandler?(.unknown(error: error))
            }
        }
        queue.addOperation {
            self.errorHandler?(.unknown(error: error))
        }
    }

}
