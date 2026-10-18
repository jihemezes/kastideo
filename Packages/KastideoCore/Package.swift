// swift-tools-version:5.9
// KastideoCore — logique partagée (modèles, playlists M3U, Xtream Codes, guide TV XMLTV).
// Indépendant de l'interface : réutilisable plus tard pour iOS, iPadOS et tvOS.
import PackageDescription

let package = Package(
    name: "KastideoCore",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        .library(name: "KastideoCore", targets: ["KastideoCore"])
    ],
    targets: [
        .target(name: "KastideoCore"),
        .testTarget(name: "KastideoCoreTests", dependencies: ["KastideoCore"])
    ]
)
