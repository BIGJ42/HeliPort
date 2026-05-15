//
//  PrefsWindow.swift
//  HeliPort
//
//  Created by Erik Bautista on 8/1/20.
//  Copyright © 2020 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Cocoa
import SwiftUI

class PrefsWindow: NSWindow {

    // MARK: Properties

    var previousIdentifier: NSToolbarItem.Identifier = .none

    convenience init() {
        self.init(contentRect: NSRect.zero,
                  styleMask: [.titled, .closable],
                  backing: .buffered,
                  defer: false)
    }

    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {

        super.init(contentRect: contentRect,
                   styleMask: style,
                   backing: backingStoreType,
                   defer: flag)

        isReleasedWhenClosed = false

        title = .networkPrefs

        toolbar = NSToolbar(identifier: "NetworkPrefWindowToolbar")
        toolbar!.delegate = self
        toolbar!.displayMode = .iconAndLabel
        toolbar!.insertItem(withItemIdentifier: .general, at: 0)
        toolbar!.insertItem(withItemIdentifier: .networks, at: 1)
        toolbar!.insertItem(withItemIdentifier: .debug, at: 2)
        toolbar!.selectedItemIdentifier = .general

        if #available(OSX 11.0, *) {
            self.toolbarStyle = .preference
        }

        // Set selected item

        clickToolbarItem(NSToolbarItem(itemIdentifier: toolbar!.selectedItemIdentifier!))
    }

    func show() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        center()
    }

    override func close() {
        super.close()
        self.orderOut(NSApp)
    }

    @objc private func clickToolbarItem(_ sender: NSToolbarItem) {
        guard let identifier = toolbar?.selectedItemIdentifier else { return }
        guard previousIdentifier != identifier else {
            Log.debug("Toolbar Item already showing \(identifier)")
            return
        }

        Log.debug("Toolbar Item clicked: \(identifier)")

        var newView: NSView?
        var origin = frame.origin
        var size = frame.size
        switch identifier {
        case .networks:
            newView = PrefsSavedNetworksView()
            size = NSSize(width: 620, height: 420)
        case .general:
            newView = PrefsGeneralView()
            size = newView!.fittingSize
        case .debug:
            if #available(macOS 11.0, *) {
                newView = NSHostingView(rootView: PrefsDebugView())
                size = NSSize(width: 480, height: 320)
            } else {
                Log.error("Debug view requires macOS 11.0+")
                return
            }
        default:
            Log.error("Toolbar Item not implemented: \(identifier)")
        }

        guard let view = newView else { return }

        origin.y -= size.height - frame.size.height
        contentView = view
        setFrame(NSRect(origin: origin, size: size), display: true, animate: true)
        previousIdentifier = identifier
    }
}

// MARK: NSToolbarItemDelegate

extension PrefsWindow: NSToolbarDelegate {

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.general, .networks, .debug]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.general, .networks, .debug]
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.general, .networks, .debug]
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        toolbarItem.target = self
        toolbarItem.action = #selector(clickToolbarItem(_:))

        switch itemIdentifier {
        case .networks:
            toolbarItem.label = .networks
            toolbarItem.paletteLabel = .networks
            if #available(OSX 11.0, *) {
                toolbarItem.image = NSImage(systemSymbolName: "wifi", accessibilityDescription: .general)
            } else {
                toolbarItem.image = #imageLiteral(resourceName: "WiFi")
            }
            toolbarItem.isEnabled = true
            return toolbarItem
        case .general:
            toolbarItem.label = .general
            toolbarItem.paletteLabel = .general
            if #available(OSX 11.0, *) {
                toolbarItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: .general)
            } else {
                toolbarItem.image = NSImage(named: NSImage.preferencesGeneralName)
            }
            toolbarItem.isEnabled = true
            return toolbarItem
        case .debug:
            toolbarItem.label = .debug
            toolbarItem.paletteLabel = .debug
            if #available(OSX 11.0, *) {
                toolbarItem.image = NSImage(systemSymbolName: "ant.fill", accessibilityDescription: .debug)
            } else {
                toolbarItem.image = NSImage(named: NSImage.cautionName)
            }
            toolbarItem.isEnabled = true
            return toolbarItem
        default:
            return nil
        }
    }
}

// MARK: Toolbar Item Identifiers

private extension NSToolbarItem.Identifier {
    static let networks = NSToolbarItem.Identifier("WiFiNetworks")
    static let general = NSToolbarItem.Identifier("General")
    static let debug = NSToolbarItem.Identifier("Debug")
    static let none = NSToolbarItem.Identifier("none")
}

// MARK: Localized Strings

private extension String {
    static let networkPrefs = NSLocalizedString("Network Preferences")
    static let networks = NSLocalizedString("Networks")
    static let general = NSLocalizedString("General")
    static let debug = NSLocalizedString("Debug")
}

// MARK: - PrefsDebugView

struct PrefsDebugView: View {
    @State private var isGeneratingReport = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Diagnostics & Debugging")
                .font(.headline)
            
            Text("Use these tools to troubleshoot connection issues or generate information for bug reports.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(spacing: 12) {
                DebugActionButton(
                    title: "Enable Wi-Fi Logging",
                    icon: "terminal",
                    description: "Captures detailed driver and firmware logs."
                ) {
                    // Not implemented in driver yet according to StatusMenuLegacy
                }
                .disabled(true)
                
                DebugActionButton(
                    title: "Create Diagnostics Report",
                    icon: "doc.text.fill",
                    description: "Generates a comprehensive system report for debugging.",
                    isLoading: isGeneratingReport
                ) {
                    isGeneratingReport = true
                    DispatchQueue.global(qos: .background).async {
                        BugReporter.generateBugReport()
                        DispatchQueue.main.async {
                            isGeneratingReport = false
                        }
                    }
                }
                
                DebugActionButton(
                    title: "Open Wireless Diagnostics",
                    icon: "stethoscope",
                    description: "Opens the native macOS Wireless Diagnostics tool."
                ) {
                    NSWorkspace.shared.launchApplication("Wireless Diagnostics")
                }
            }
            
            Spacer()
        }
        .padding(30)
        .frame(width: 480, height: 320)
    }
}

struct DebugActionButton: View {
    let title: String
    let icon: String
    let description: String
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.3))
            }
            .padding(10)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
