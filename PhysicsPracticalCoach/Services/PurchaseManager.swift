//
//  PurchaseManager.swift
//  PhysicsPracticalCoach
//
//  StoreKit 2 wrapper for a single non-consumable "Unlock Full Access"
//  product — chosen over a subscription because this app's actual usage
//  window is bounded (a student needs it for one exam season, not
//  indefinitely), and a one-time purchase is a much easier parent-approval
//  conversation than a recurring charge. See the in-conversation
//  discussion this was designed against for the full reasoning.
//
//  Product must be created in App Store Connect first — this file
//  references the ID but can't create the product remotely. Create a
//  Non-Consumable In-App Purchase with this exact product ID:
//
//      com.physicscoach.app.fullaccess
//

import StoreKit
import Observation

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    static let fullAccessProductID = "com.physicscoach.app.fullaccess"

    private(set) var product: Product?
    private(set) var isPro: Bool = false
    private(set) var isLoadingProduct = false
    private(set) var purchaseInProgress = false
    private(set) var lastErrorMessage: String?

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactionUpdates()
        Task {
            await loadProduct()
            await refreshEntitlement()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Loading

    func loadProduct() async {
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        do {
            let products = try await Product.products(for: [Self.fullAccessProductID])
            product = products.first
        } catch {
            lastErrorMessage = "Couldn't load pricing right now. Check your connection and try again."
        }
    }

    /// Re-checks StoreKit's current entitlements — call this on app launch
    /// and after any purchase/restore, rather than trusting a locally
    /// cached flag, so a refund or family-sharing change is reflected
    /// promptly rather than stale.
    func refreshEntitlement() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.fullAccessProductID {
                isPro = true
                return
            }
        }
        isPro = false
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else { return }
        purchaseInProgress = true
        lastErrorMessage = nil
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastErrorMessage = "We couldn't verify that purchase. Please try again."
                    return
                }
                await transaction.finish()
                await refreshEntitlement()
            case .userCancelled:
                break
            case .pending:
                lastErrorMessage = "Purchase pending \u{2014} it may need approval (e.g. Ask to Buy) before it completes."
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = "Purchase failed. Please try again."
        }
    }

    // MARK: - Restore

    func restore() async {
        purchaseInProgress = true
        lastErrorMessage = nil
        defer { purchaseInProgress = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isPro {
                lastErrorMessage = "No previous purchase found for this Apple ID."
            }
        } catch {
            lastErrorMessage = "Restore failed. Please try again."
        }
    }

    // MARK: - Transaction updates (e.g. purchased on another device)

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlement()
            }
        }
    }
}
