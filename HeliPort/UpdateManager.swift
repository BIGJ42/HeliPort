//
//  UpdateManager.swift
//  HeliPort
//
//  Created by Bat.bat on 1/8/2024.
//  Copyright © 2024 OpenIntelWireless. All rights reserved.
//

import Foundation
import Sparkle

final class UpdateManager {
    public static var sharedController: SPUStandardUpdaterController? {
        return (NSApp.delegate as? AppDelegate)?.updaterController
    }

    public static var sharedUpdater: SPUUpdater? {
        return sharedController?.updater
    }

    private init() {}
}

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
