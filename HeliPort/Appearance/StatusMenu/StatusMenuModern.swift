import Cocoa
import SwiftUI

@available(macOS 11, *)
final class StatusMenuModern: StatusMenuBase, StatusMenuItems {

    // - MARK: SwiftUI State
    private var isWiFiOn: Bool = true {
        didSet {
            _ = isWiFiOn ? power_on() : power_off()
        }
    }

    // - MARK: Menu items

    private lazy var statusItem: NSMenuItem = {
        let binding = Binding(
            get: { self.isNetworkCardEnabled },
            set: { self.isWiFiOn = $0 }
        )
        return ModernToggleMenuItem(title: .Modern.wifi, isOn: binding) { newValue in
             // power state is handled by binding
        }
    }()

    private let knownSectionItem: NSMenuItem = {
        let item = HPMenuItem()
        item.view = SectionMenuItemView(title: .Modern.knownNetwork)
        return item
    }()

    private lazy var otherSectionItem: NSMenuItem = {
        let item = HPMenuItem(highlightable: true)
        item.isHidden = true
        item.view = SectionMenuItemView(title: .Modern.otherNetworks) { [weak self] expand in
            guard let self = self else { return }
            self.otherNetworkItemList.forEach { 
                if $0.isEnabled { $0.isHidden = !expand }
            }
            self.manuallyJoinItem.isHidden = !expand
            self.update()
        }
        return item
    }()

    private let manuallyJoinItem = HPMenuItem(title: .Modern.joinNetworks)
    private let networkPanelItem = HPMenuItem(title: .Modern.wifiSettings)

    lazy var enabledNetworkCardItems: [NSMenuItem] = []

    lazy var stationInfoItems: [NSMenuItem] = [
        ipAddresssItem,
        routerItem,
        internetItem,
        securityItem,
        bssidItem,
        channelItem,
        countryCodeItem,
        rssiItem,
        noiseItem,
        txRateItem,
        phyModeItem,
        mcsIndexItem,
        nssItem
    ]

    lazy var hiddenItems: [NSMenuItem] = [
        bsdItem,
        macItem,
        itlwmVerItem,
        enableLoggingItem,
        createReportItem,
        diagnoseItem,
        hardwareInfoSeparator,
        toggleLaunchItem
    ]

    lazy var notImplementedItems: [NSMenuItem] = [
        enableLoggingItem,
        diagnoseItem,

        securityItem,
        countryCodeItem,
        nssItem
    ]

    override var isNetworkListEmpty: Bool {
        willSet(empty) {
            super.isNetworkListEmpty = empty
            if empty {
                knownSectionItem.isHidden = true
                otherSectionItem.isHidden = true
                manuallyJoinItem.isHidden = true
                knownNetworkItemList.forEach { $0.isHidden = true }
                otherNetworkItemList.forEach { $0.isHidden = true }
            }
        }
    }

    override var isNetworkCardAvailable: Bool {
        willSet(newState) {
            super.isNetworkCardAvailable = newState
        }
    }

    override var isNetworkCardEnabled: Bool {
        willSet(newState) {
            super.isNetworkCardEnabled = newState
        }
    }

    private var knownNetworkItemList = [NSMenuItem]()
    private var otherNetworkItemList = [NSMenuItem]()
    private var currentSSID: String?
    private lazy var dashboardViewModel = NetworkDetailsViewModel()

    // - MARK: Init

    override init() {
        super.init()
        minimumWidth = HeliPortUI.Dashboard.width
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // - MARK: Menu Setup

    func setupMenu() {
        addItem(statusItem)
        addItem(.separator())
        
        addItem(knownSectionItem)
        
        // Dashboard
        currentNetworkItem.view = NSHostingView(rootView: NetworkDetailsDashboard(viewModel: dashboardViewModel))
        currentNetworkItem.view?.frame = NSRect(x: 0, y: 0, width: HeliPortUI.Dashboard.width, height: HeliPortUI.Dashboard.height)
        addItem(currentNetworkItem)
        
        addItem(otherSectionItem)
        addClickItem(manuallyJoinItem)
        
        addItem(networkItemListSeparator)
        
        addClickItem(networkPanelItem)

        addItem(.separator())
        
        addClickItem(checkUpdateItem)
        addClickItem(aboutItem)
        addItem(quitSeparator)
        addClickItem(quitItem)
        
        // Technical & Hidden items at the bottom
        addItem(.separator())
        
        [bsdItem, macItem, itlwmVerItem].forEach {
            $0.view = KeyValueMenuItemView(key: $0.title, inset: .standard)
            addItem($0)
        }
        
        stationInfoItems.forEach {
            $0.view = KeyValueMenuItemView(key: $0.title, inset: .staInfo)
            addItem($0)
        }
        
        addItem(hardwareInfoSeparator)
        addClickItem(enableLoggingItem)
        addClickItem(createReportItem)
        addClickItem(diagnoseItem)
        addClickItem(toggleLaunchItem)
    }

    // - MARK: Menu Updates

    func setValueForItem(_ item: NSMenuItem, value: String) {
        (item.view as? KeyValueMenuItemView)?.value = value
    }

    func updateNetworkList() {
        guard isNetworkCardEnabled else { return }

        NetworkManager.scanNetwork { [weak self] knownList, otherList in
            guard let self = self else { return }

            let networkListSize = knownList.count + otherList.count

            DispatchQueue.main.async {
                self.isNetworkListEmpty = networkListSize == 0 && !self.isNetworkConnected
                
                let showKnown = !knownList.isEmpty || self.isNetworkConnected
                self.knownSectionItem.isHidden = !showKnown
                (self.knownSectionItem.view as? SectionMenuItemView)?
                    .title = (knownList.count > (self.isNetworkConnected ? 0 : 1) ? .Modern.knownNetworks : .Modern.knownNetwork)

                let staInfo: NetworkInfo? = (self.isNetworkConnected
                                             ? NetworkInfo(ssid: self.currentSSID ?? "")
                                             : nil)

                let insertAtKnown = self.index(of: self.currentNetworkItem) + 1
                self.processNetworkList(from: knownList, to: &self.knownNetworkItemList,
                                        insertAt: insertAtKnown, staInfo)
                
                let currentExpand = (self.otherSectionItem.view as? SectionMenuItemView)?.isExpanded ?? false
                
                // Keep other section visible if there are networks OR if we have no known networks (to allow manual join)
                self.otherSectionItem.isHidden = otherList.isEmpty && !currentExpand && showKnown
                
                let insertAtOther = self.index(of: self.otherSectionItem) + 1
                self.processNetworkList(from: otherList, to: &self.otherNetworkItemList,
                                        insertAt: insertAtOther,
                                        staInfo, hidden: !currentExpand)
                
                self.manuallyJoinItem.isHidden = !currentExpand
                
                // Show separator if anything was shown in the network sections
                self.networkItemListSeparator.isHidden = !showKnown && self.otherSectionItem.isHidden
                
                self.update()
            }
        }
    }

    func toggleWIFI() {
        DispatchQueue.main.async {
            self.isWiFiOn.toggle()
        }
    }

    // - MARK: Overrides

    override func menuWillOpen(_ menu: NSMenu) {
        super.menuWillOpen(menu)

        guard isNetworkCardEnabled else { return }
        
        let hasSavedNetworks = !CredentialsManager.instance.getSavedNetworkSSIDs().isEmpty
        let expandOther = !self.isNetworkConnected && !hasSavedNetworks && self.knownNetworkItemList.isEmpty
        
        (otherSectionItem.view as? SectionMenuItemView)?.isExpanded = expandOther
    }


    override func addNetworkItem(_ item: NSMenuItem = HPMenuItem(highlightable: true),
                                 insertAt: Int? = nil,
                                 hidden: Bool = false,
                                 networkInfo: NetworkInfo = NetworkInfo(ssid: "placeholder")) -> NSMenuItem {
        
        let newItem = ModernNetworkMenuItem(
            ssid: networkInfo.ssid,
            signalStrength: Int(networkInfo.rssi),
            isConnected: false,
            isSecure: networkInfo.auth.security != ITL80211_SECURITY_NONE
        ) {
            NetworkManager.connect(networkInfo: networkInfo, saveNetwork: true)
            self.cancelTracking()
        }
        
        newItem.isHidden = hidden
        
        // Only call super if we actually want to insert it into the menu at a specific position.
        // Otherwise, just return the constructed item (e.g. for processNetworkList reuse logic).
        guard let insertAt = insertAt else {
            return newItem
        }
        
        return super.addNetworkItem(newItem, insertAt: insertAt, hidden: hidden, networkInfo: networkInfo)
    }

    override func setCurrentNetworkItem(with info: StatusMenuBase.StationInfo) {
        // Handle connected -> disconnected state
        if !currentNetworkItem.isHidden && !info.isNetworkConnected {
            for index in self.headerLength ..<
                    min(self.items.count,
                        self.headerLength + self.knownNetworkItemList.count) {
                self.items[index].isHidden = false
                self.items[index].isEnabled = true
            }
        }

        isNetworkConnected = info.isNetworkConnected
        currentSSID = info.ssid
        currentNetworkItem.isHidden = !isNetworkConnected

        if isNetworkConnected {
            dashboardViewModel.update(with: info)
        }

        super.setCurrentNetworkItem(with: info)

        // Ensure isNetworkListEmpty is updated to false if connected
        if isNetworkConnected && isNetworkListEmpty {
            isNetworkListEmpty = false
        }
    }
}

