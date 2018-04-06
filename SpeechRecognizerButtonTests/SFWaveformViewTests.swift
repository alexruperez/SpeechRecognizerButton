//
//  SFWaveformViewTests.swift
//  SpeechRecognizerButtonTests
//
//  Created by Alejandro Ruperez Hernando on 26/2/18.
//  Copyright © 2018 alexruperez. All rights reserved.
//

import XCTest
@testable import SpeechRecognizerButton

class SFWaveformViewTests: XCTestCase {

    var button: SFButton!
    var waveformView: SFWaveformView!

    override func setUp() {
        super.setUp()
        waveformView = SFWaveformView()
        button = SFButton()
        button.waveformView = waveformView
    }

    func testWaveformView() {
        waveformView.draw(.zero)
    }
    
    func testWaveformViewAlpha() {
        button.awakeFromNib()
        XCTAssertEqual(waveformView.alpha, 0)
    }

    func testWaveformViewWeakReference() {
        button.waveformView = SFWaveformView()
        XCTAssertNil(button.waveformView)
    }

    func testWaveformViewUpdateWithLevel() {
        let level: CGFloat = waveformView.idleAmplitude * 10
        waveformView.updateWithLevel(level)
        XCTAssertEqual(waveformView._phase, waveformView.phaseShift)
        XCTAssertEqual(waveformView._amplitude, level)
    }

    func testWaveformViewUpdateWithLevelUnderIdle() {
        let level: CGFloat = waveformView.idleAmplitude / 10
        waveformView.updateWithLevel(level)
        XCTAssertEqual(waveformView._phase, waveformView.phaseShift)
        XCTAssertEqual(waveformView._amplitude, waveformView.idleAmplitude)
    }

    override func tearDown() {
        button = nil
        waveformView = nil
        super.tearDown()
    }
    
}
