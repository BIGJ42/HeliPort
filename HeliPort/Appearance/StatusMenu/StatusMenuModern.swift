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
        item.view = SectionMenuItemView(title: .Modern.otherNetworks) { expand in
            self.otherNetworkItemList.filter { $0.isEnabled }
                                     .forEach { $0.isHidden = !expand }
            self.manuallyJoinItem.isHidden = !expand
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

        toggleLaunchItem,
        checkUpdateItem,
        quitSeparator,
        aboutItem,
        quitItem
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
            knownSectionItem.isHidden = empty

            guard empty else { return }

            otherSectionItem.isHidden = true
            manuallyJoinItem.isHidden = true

            knownNetworkItemList.forEach { $0.isHidden = true }
            otherNetworkItemList.forEach { $0.isHidden = true }
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

    // - MARK: Init

    override init() {
        super.init()
        minimumWidth = 320
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // - MARK: Menu Setup

    func setupMenu() {
        addItem(statusItem)

        [bsdItem, macItem, itlwmVerItem].forEach {
            $0.view = KeyValueMenuItemView(key: $0.title, inset: .standard)
            addItem($0)
        }

        addItem(hardwareInfoSeparator)

        addClickItem(enableLoggingItem)
        addClickItem(createReportItem)
        addClickItem(diagnoseItem)

        addItem(.separator())
        addItem(knownSectionItem)

        // Current Network Item will be added dynamically by setCurrentNetworkItem
        addItem(currentNetworkItem)

        stationInfoItems.forEach {
            $0.view = KeyValueMenuItemView(key: $0.title, inset: .staInfo)
            addItem($0)
        }

        headerLength = items.count

        addItem(.separator())
        addItem(otherSectionItem)

        addClickItem(manuallyJoinItem)
        addItem(networkItemListSeparator)

        addClickItem(networkPanelItem)

        addItem(.separator())

        addClickItem(toggleLaunchItem)
        addClickItem(checkUpdateItem)
        addClickItem(aboutItem)

        addItem(quitSeparator)
        addClickItem(quitItem)
    }

    // - MARK: Menu Updates

    func setValueForItem(_ item: NSMenuItem, value: String) {
        (item.view as? KeyValueMenuItemView)?.value = value
    }

    func updateNetworkList() {
        guard isNetworkCardEnabled else { return }

        NetworkManager.scanNetwork { knownList, otherList in
            let networkListSize = knownList.count + otherList.count
            if networkListSize > MAX_NETWORK_LIST_LENGTH {
                Log.error("Number of scanned networks (\(networkListSize))" +
                          " exceeds maximum (\(MAX_NETWORK_LIST_LENGTH))")
            }

            self.isNetworkListEmpty = networkListSize == 0 && !self.isNetworkConnected
            self.knownSectionItem.isHidden = knownList.isEmpty && !self.isNetworkConnected
            (self.knownSectionItem.view as? SectionMenuItemView)?
                .title = (knownList.count > 1 ? .Modern.knownNetworks : .Modern.knownNetwork)

            if otherList.isEmpty {
                self.manuallyJoinItem.isHidden = false
            } else {
                self.manuallyJoinItem.isHidden = !(self.otherSectionItem.view as? SectionMenuItemView)!.isExpanded
            }
            self.otherSectionItem.isHidden = otherList.isEmpty

            let staInfo: NetworkInfo? = (self.isNetworkConnected
                                         ? (self.currentNetworkItem.view as? WifiMenuItemView)?.networkInfo
                                         : nil)

            self.processNetworkList(from: knownList, to: &self.knownNetworkItemList,
                                    insertAt: self.headerLength, staInfo)
            self.processNetworkList(from: otherList, to: &self.otherNetworkItemList,
                                    insertAt: (self.headerLength + self.knownNetworkItemList.count
                                               + 2 /* separator + section header */),
                                    staInfo, hidden: !(self.otherSectionItem.view as? SectionMenuItemView)!.isExpanded)
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
        (otherSectionItem.view as? SectionMenuItemView)?
            .isExpanded = (!self.isNetworkConnected && self.knownNetworkItemList.isEmpty)
    }

    override func addClickItem(_ item: NSMenuItem) {
        let view = SelectableMenuItemView(height: .textModern, hoverStyle: .greytint)
        let label: NSTextField = {
            let label = NSTextField(labelWithString: item.title)
            label.font = NSFont.menuFont(ofSize: 0)
            label.textColor = .controlTextColor
            return label
        }()

        view.addSubview(label)
        view.setupLayout()
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14).isActive = true

        item.view = view

        super.addClickItem(item)
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
        currentNetworkItem.isHidden = !isNetworkConnected
        
        if isNetworkConnected, let ssid = info.ssid {
            let dashboard = ModernDashboardMenuItem(
                ssid: ssid,
                ipAddress: info.ipAddr,
                router: info.routerAddr,
                signal: info.rssiValue,
                noise: Int(info.noise.replacingOccurrences(of: " dBm", with: "")) ?? 0,
                txRate: info.txRate,
                channel: info.channel,
                phyMode: info.phyMode,
                bssid: info.bssid
            )
            currentNetworkItem.view = dashboard.view
        }
        
        super.setCurrentNetworkItem(with: info)
    }
}

