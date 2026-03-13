// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "FirebaseAuth": .staticFramework,
        "FirebaseFirestore": .staticFramework,
        "FirebaseAnalytics": .staticFramework,
        "FirebaseCrashlytics": .staticFramework,
    ]
)
#endif

let package = Package(
    name: "MomCare",
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
        .package(url: "https://github.com/componentskit/ComponentsKit", from: "1.6.0"),
        .package(url: "https://github.com/airbnb/lottie-ios", from: "4.6.0"),
        .package(url: "https://github.com/EmergeTools/Pow", from: "1.0.0"),
        .package(url: "https://github.com/space-code/skeleton-ui", from: "1.1.0"),
        .package(url: "https://github.com/imodeveloper/dskit-swiftui", from: "1.1.2"),
    ]
)
