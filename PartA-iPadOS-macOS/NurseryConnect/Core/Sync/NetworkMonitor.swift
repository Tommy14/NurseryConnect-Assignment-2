//
//  NetworkMonitor.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 10 April 2026
//  Description: Connectivity observer used to trigger pending sync retries.
//

import Combine
import Foundation
import Network

@MainActor
final class NetworkMonitor: ObservableObject {
    @MainActor
    static let shared = NetworkMonitor()

    @Published private(set) var isOnline = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "nurseryconnect.network.monitor")
    private let enablePathMonitor: Bool
    private var didStart = false

    init(initialIsOnline: Bool = true, enablePathMonitor: Bool = true) {
        self.isOnline = initialIsOnline
        self.enablePathMonitor = enablePathMonitor
    }

    func startIfNeeded() {
        guard !didStart else { return }
        guard enablePathMonitor else { return }
        didStart = true
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            DispatchQueue.main.async {
                self?.isOnline = online
            }
        }
        monitor.start(queue: queue)
    }

    func setOnlineForTesting(_ value: Bool) {
        isOnline = value
    }
}
