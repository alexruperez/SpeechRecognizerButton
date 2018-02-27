//
//  ViewController.swift
//  Example
//
//  Created by Alejandro Ruperez Hernando on 26/2/18.
//  Copyright © 2018 alexruperez. All rights reserved.
//

import UIKit
import SpeechRecognizerButton

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: SFButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        button.authorizationErrorHandling = .openSettings(completion: nil)
        button.resultHandler = {
            self.label.text = $1?.bestTranscription.formattedString
        }
        button.errorHandler = {
            if let error = $0 {
                self.label.text = error.localizedDescription
            } else {
                self.label.text = "Unknown error."
            }
        }
    }

}
