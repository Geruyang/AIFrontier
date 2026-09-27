import Foundation
import StoreKit

enum SubscriptionProductID {
    static let monthly = "com.geruyang.aifrontier.pro.monthly"
    static let annual = "com.geruyang.aifrontier.pro.annual"
    static let all: Set<String> = [monthly, annual]
}

enum PurchaseState: Equatable {
    case loading
    case free
    case pro(expiration: Date?)
    case unavailable(String)
}

enum EntitlementPolicy {
    static var developerAccess: Bool {
        #if DEVELOPER_ACCESS
        true
        #else
        false
        #endif
    }
    static func grantsPro(productID: String, expirationDate: Date?, revocationDate: Date?, now: Date = .now) -> Bool {
        guard SubscriptionProductID.all.contains(productID), revocationDate == nil else { return false }
        guard let expirationDate else { return true }
        return expirationDate > now
    }
}

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var state: PurchaseState = .loading
    @Published private(set) var isEligibleForTrial = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?
    private var isLoadingProducts = false

    init(startAutomatically: Bool = true) {
        if EntitlementPolicy.developerAccess { state = .free; return }
        guard startAutomatically else {
            state = .free
            return
        }
        updatesTask = listenForTransactions()
        Task { await load() }
    }

    deinit { updatesTask?.cancel() }

    var hasPro: Bool {
        if EntitlementPolicy.developerAccess { return true }
        if case .pro = state { return true }
        return false
    }

    func load() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        errorMessage = nil
        isEligibleForTrial = false
        if !hasPro { state = .loading }
        do {
            products = try await Product.products(for: SubscriptionProductID.all).sorted { lhs, rhs in
                lhs.id == SubscriptionProductID.monthly && rhs.id == SubscriptionProductID.annual
            }
            if let groupID = products.first?.subscription?.subscriptionGroupID {
                isEligibleForTrial = await Product.SubscriptionInfo.isEligibleForIntroOffer(for: groupID)
            }
            await refreshEntitlements()
            if products.isEmpty && !hasPro {
                state = .unavailable("App Store products are currently unavailable. Please try again.")
            }
        } catch {
            errorMessage = error.localizedDescription
            state = .unavailable(error.localizedDescription)
        }
    }

    func purchase(_ product: Product) async {
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.verified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                errorMessage = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        errorMessage = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var latestExpiration: Date?
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if EntitlementPolicy.grantsPro(productID: transaction.productID, expirationDate: transaction.expirationDate, revocationDate: transaction.revocationDate) {
                entitled = true
                if let expiration = transaction.expirationDate, expiration > (latestExpiration ?? .distantPast) {
                    latestExpiration = expiration
                }
            }
        }
        state = entitled ? .pro(expiration: latestExpiration) : .free
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    nonisolated private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): value
        case .unverified: throw StoreKitError.notEntitled
        }
    }
}
