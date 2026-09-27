import XCTest
@testable import AIFrontier

final class StoreKitConfigurationTests: XCTestCase {
    func testConfigurationContainsTwoSevenDayTrialProducts() throws {
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(bundle.url(forResource: "AIFrontier", withExtension: "storekit"))
        let data = try Data(contentsOf: url)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let version = try XCTUnwrap(root["version"] as? [String: Int])
        XCTAssertEqual(version["major"], 4)

        let groups = try XCTUnwrap(root["subscriptionGroups"] as? [[String: Any]])
        XCTAssertEqual(groups.count, 1)
        let products = try XCTUnwrap(groups.first?["subscriptions"] as? [[String: Any]])
        XCTAssertEqual(Set(products.compactMap { $0["productID"] as? String }), SubscriptionProductID.all)

        for product in products {
            XCTAssertEqual(product["type"] as? String, "RecurringSubscription")
            let offer = try XCTUnwrap(product["introductoryOffer"] as? [String: Any])
            XCTAssertEqual(offer["paymentMode"] as? String, "free")
            XCTAssertEqual(offer["subscriptionPeriod"] as? String, "P1W")
        }
    }

    func testProductIdentifiersMatchPurchaseManager() {
        XCTAssertEqual(SubscriptionProductID.all, [
            "com.geruyang.aifrontier.pro.monthly",
            "com.geruyang.aifrontier.pro.annual"
        ])
    }
}
