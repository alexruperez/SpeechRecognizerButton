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

        //button.authorizationErrorHandling = .openSettings(completion: nil)
        button.resultHandler = {
            self.label.text = $1?.bestTranscription.formattedString
            self.button.play()
        }
        button.errorHandler = {
            self.label.text = $0?.localizedDescription
        }
    }

}
