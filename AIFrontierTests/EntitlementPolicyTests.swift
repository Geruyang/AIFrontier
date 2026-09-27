import XCTest
@testable import AIFrontier

final class EntitlementPolicyTests: XCTestCase {
    @MainActor func testDeveloperAndPublicBuildsUseDifferentAccess() {
        let manager = PurchaseManager(startAutomatically: false)
        #if DEVELOPER_ACCESS
        XCTAssertTrue(EntitlementPolicy.developerAccess)
        XCTAssertTrue(manager.hasPro)
        #else
        XCTAssertFalse(EntitlementPolicy.developerAccess)
        XCTAssertFalse(manager.hasPro)
        #endif
        XCTAssertEqual(manager.state, .free)
    }
    private let now = Date(timeIntervalSince1970: 1_000)

    func testActiveKnownSubscriptionGrantsPro() {
        XCTAssertTrue(EntitlementPolicy.grantsPro(productID: SubscriptionProductID.monthly, expirationDate: Date(timeIntervalSince1970: 2_000), revocationDate: nil, now: now))
    }

    func testSubscriptionWithoutExpirationDoesNotGrantLifetimeAccess() {
        XCTAssertFalse(EntitlementPolicy.grantsPro(productID: SubscriptionProductID.monthly, expirationDate: nil, revocationDate: nil, now: now))
    }

    func testExpiredRevokedAndUnknownDoNotGrantPro() {
        XCTAssertFalse(EntitlementPolicy.grantsPro(productID: SubscriptionProductID.monthly, expirationDate: Date(timeIntervalSince1970: 999), revocationDate: nil, now: now))
        XCTAssertFalse(EntitlementPolicy.grantsPro(productID: SubscriptionProductID.annual, expirationDate: Date(timeIntervalSince1970: 2_000), revocationDate: now, now: now))
        XCTAssertFalse(EntitlementPolicy.grantsPro(productID: "other", expirationDate: nil, revocationDate: nil, now: now))
    }
}
