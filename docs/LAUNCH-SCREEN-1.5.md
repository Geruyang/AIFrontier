# Native launch screen

The system launch screen uses `Resources/LaunchScreen.storyboard`, selected by
`UILaunchStoryboardName = LaunchScreen` in `Info.plist`.

## Design

- Background: the Hero palette's deep navy (sRGB 0.07 / 0.12 / 0.25).
- Mark: an original, resolution-independent SVG with teal and violet orbits,
  echoing `OrbitArtwork`, around the mountain silhouette from the existing app icon.
- Name: a centered, 23-point semibold system label reading `AI FRONTIER`.
- Layout: a 156-point mark, 32-point gap, and 30-point name area within a
  260 × 218-point group. The group is centered in the safe area with a maximum
  width of safe-area width minus 48 points and at least 16 points above/below.
- Appearance: one universal background and mark for both light and dark mode;
  no appearance-specific asset variants or runtime view logic are needed.

Only static UIKit views and Auto Layout are used. There is no launch delay,
advertising, simulated progress, timer, network dependency, or SwiftUI overlay.
The operating system controls how long its launch snapshot remains visible.

## Project integration

`LaunchScreen.storyboard` is included in the `AIFrontier/Resources` resources in
`project.yml` and the generated Xcode project. `Assets.xcassets` is already included and contains both new assets:
`LaunchBackground.colorset` and `LaunchMark.imageset`.

## Validation

- `plutil -lint` passed for `Info.plist`.
- Storyboard/SVG XML and both asset JSON files parsed successfully.
- `ibtool` compiled the storyboard successfully with both iPhone and iPad targets
  and a minimum deployment target of iOS 18.0; no warnings or errors were emitted.
- A static dimensions check confirmed the group fits representative iPhone/iPad
  portrait and landscape safe areas, including a 320-point-wide layout and a
  299-point-high landscape safe area. This is a constraints check, not a device
  screenshot or runtime UI test.

The integrated Release app was built and tested on iOS 26.5 Simulator.
`LaunchScreenTests` loads the bundled storyboard, verifies the named artwork and
background, and checks unambiguous, in-bounds artwork and text at 320 × 568,
568 × 320 and 1024 × 1366 points. Its 402 × 874-point UIKit rendering was visually
reviewed; this is a storyboard preview, not a captured system cold-launch snapshot.
On-device cold-launch review remains useful because iOS caches launch snapshots;
an existing installation may temporarily display its previous launch screen.
