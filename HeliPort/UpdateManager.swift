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
