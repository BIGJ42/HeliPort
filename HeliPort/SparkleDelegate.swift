//
//  SparkleDelegate.swift
//  HeliPort
//
//  Created by BIGJ42 on 12/5/2026.
//  Copyright © 2026 OpenIntelWireless. All rights reserved.
//

import Foundation
import Sparkle

class SparkleDelegate: NSObject, SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        Log.error("Sparkle aborted with error: \(error.localizedDescription)")
    }

    func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval) {
        Log.debug("Sparkle scheduled update check after \(delay) seconds")
    }

    func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        Log.debug("App will relaunch to install update")
        api_terminate()
    }
}
