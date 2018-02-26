//
//  SFButton.swift
//  SpeechRecognizerButton
//
//  Created by Alejandro Ruperez Hernando on 26/2/18.
//  Copyright © 2018 alexruperez. All rights reserved.
//

import UIKit
import Speech

@IBDesignable public class SFButton: UIButton {

    public enum SFButtonError: Error {
        case authorization(status: SFSpeechRecognizerAuthorizationStatus)
    }

    public enum AuthorizationErrorHandling {
        case none, openSettings(completion: BoolClosure?), custom(handler: ErrorClosure)
    }

    public typealias BoolClosure = (Bool) -> ()
    public typealias ErrorClosure = (SFButtonError?) -> ()

    public var authorizationErrorHandling = AuthorizationErrorHandling.none
    public var locale = Locale.autoupdatingCurrent
    private var speechRecognizer: SFSpeechRecognizer?
    private var speechRecognitionRequest: SFSpeechURLRecognitionRequest?

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
    }

    @objc private func touchDown(_ sender: Any? = nil) {
        checkAuthorization {
            if let error = $0 {
                self.handleAuthorizationError(error, self.authorizationErrorHandling)
            } else {
                self.isEnabled = true
                self.speechRecognizer = SFSpeechRecognizer(locale: self.locale)
                // https://developer.apple.com/documentation/speech #4
                //self.speechRecognitionRequest = SFSpeechURLRecognitionRequest(url: URL)
            }
        }
    }

    private func handleAuthorizationError(_ error: SFButtonError, _ handling: AuthorizationErrorHandling) {
        isEnabled = false
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

    public func checkAuthorization(_ handler: ErrorClosure? = nil) {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: handler?(nil)
        case .denied: handler?(.authorization(status: .denied))
        case .restricted: handler?(.authorization(status: .restricted))
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { _ in
                self.checkAuthorization(handler)
            }
        }
    }

}

extension SFButton: SFSpeechRecognizerDelegate {

    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {

    }
    
}
