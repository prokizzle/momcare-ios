import ProjectDescription

let baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    "DEVELOPMENT_TEAM": "W4MZM2YEAU",
    "CODE_SIGN_STYLE": "Automatic",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "SWIFT_STRICT_CONCURRENCY": "complete",
]

let project = Project(
    name: "MomCare",
    organizationName: "feelingmindful",
    settings: .settings(
        base: baseSettings,
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        .target(
            name: "MomCare",
            destinations: .iOS,
            product: .app,
            bundleId: "com.feelingmindful.momcare",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .file(path: "MomCare/App/Info.plist"),
            sources: ["MomCare/**/*.swift", "MomCare/**/*.metal"],
            resources: [
                "MomCare/App/Assets.xcassets",
                "MomCare/App/GoogleService-Info.plist",
                "MomCare/App/PrivacyInfo.xcprivacy",
                "MomCare/Core/Content/**",
                "MomCare/App/Resources/Fonts/**",
            ],
            entitlements: .file(path: "MomCare/App/MomCare.entitlements"),
            dependencies: [
                .target(name: "MomCareWidgetExtension"),
                .external(name: "FirebaseAuth"),
                .external(name: "FirebaseFirestore"),
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseCrashlytics"),
                .external(name: "ComponentsKit"),
                .external(name: "Lottie"),
                .external(name: "Pow"),
                .external(name: "SkeletonUI"),
                .external(name: "DSKit"),
            ],
            settings: .settings(
                base: [
                    "PRODUCT_NAME": "MomCare",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "YES",
                    "TARGETED_DEVICE_FAMILY": "1,2",
                    "SWIFT_EMIT_LOC_STRINGS": "YES",
                ],
                configurations: [
                    .debug(name: "Debug", settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG"]),
                    .release(name: "Release", settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": ""]),
                ]
            )
        ),
        .target(
            name: "MomCareTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.feelingmindful.momcare.tests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["MomCareTests/**/*.swift"],
            dependencies: [
                .target(name: "MomCare"),
            ]
        ),
        .target(
            name: "MomCareUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.feelingmindful.momcare.uitests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["MomCareUITests/**/*.swift"],
            dependencies: [
                .target(name: "MomCare"),
            ]
        ),
        .target(
            name: "MomCareWidgetExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.feelingmindful.momcare.widgets",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .file(path: "MomCareWidgetExtension/Info.plist"),
            sources: [
                "MomCareWidgetExtension/**/*.swift",
                "MomCare/Platform/LiveActivities/**/*.swift",
                "MomCare/Platform/Shared/**/*.swift",
            ],
            resources: [
                "MomCareWidgetExtension/Assets.xcassets",
                "MomCare/App/Resources/Fonts/**",
            ],
            entitlements: .file(path: "MomCareWidgetExtension/MomCareWidgetExtension.entitlements"),
            settings: .settings(
                base: [
                    "PRODUCT_NAME": "MomCareWidgets",
                    "ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME": "WidgetBackground",
                    "TARGETED_DEVICE_FAMILY": "1,2",
                    "SWIFT_EMIT_LOC_STRINGS": "YES",
                ]
            )
        ),
    ],
    schemes: [
        .scheme(
            name: "MomCare",
            buildAction: .buildAction(targets: [.target("MomCare")]),
            testAction: .targets(
                [
                    .testableTarget(target: .target("MomCareTests")),
                    .testableTarget(target: .target("MomCareUITests")),
                ]
            ),
            runAction: .runAction(
                executable: .target("MomCare"),
                options: .options(
                    storeKitConfigurationPath: .relativeToRoot("MomCare/Configuration/MomCare.storekit")
                )
            )
        ),
    ]
)
