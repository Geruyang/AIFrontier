import UIKit
import XCTest
@testable import AIFrontier

@MainActor
final class LaunchScreenTests: XCTestCase {
    func testPackagedLaunchScreenLoadsItsArtworkAndFitsSupportedSizes() throws {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "UILaunchStoryboardName") as? String, "LaunchScreen")
        XCTAssertNotNil(UIImage(named: "LaunchMark", in: .main, compatibleWith: nil))
        XCTAssertNotNil(UIColor(named: "LaunchBackground", in: .main, compatibleWith: nil))
        let controller = try XCTUnwrap(UIStoryboard(name: "LaunchScreen", bundle: .main).instantiateInitialViewController())
        controller.loadViewIfNeeded()
        let root = try XCTUnwrap(controller.view)
        func descendants(_ view: UIView) -> [UIView] { view.subviews.flatMap { [$0] + descendants($0) } }
        let all = descendants(root)
        let title = try XCTUnwrap(all.compactMap { $0 as? UILabel }.first { $0.text == "AI FRONTIER" })
        let mark = try XCTUnwrap(all.compactMap { $0 as? UIImageView }.first)
        XCTAssertNotNil(mark.image)
        for size in [CGSize(width: 320, height: 568), CGSize(width: 568, height: 320), CGSize(width: 1024, height: 1366)] {
            root.frame = CGRect(origin: .zero, size: size)
            root.setNeedsLayout()
            root.layoutIfNeeded()
            for element in [title, mark] {
                XCTAssertFalse(element.hasAmbiguousLayout)
                XCTAssertTrue(root.bounds.contains(element.convert(element.bounds, to: root)))
            }
        }
        root.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        root.setNeedsLayout(); root.layoutIfNeeded()
        let preview = UIGraphicsImageRenderer(bounds: root.bounds).image { root.layer.render(in: $0.cgContext) }
        let attachment = XCTAttachment(image: preview)
        attachment.name = "Native launch storyboard preview"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
