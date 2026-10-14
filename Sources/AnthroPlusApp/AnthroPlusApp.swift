import AnthroFeatures
import AppKit
import SwiftUI

@main
struct AnthroPlusApp: App {
    @State private var model: AppModel

    init() {
        if CommandLine.arguments.contains("--self-test") {
            let outcome = SelfTest.run()
            if outcome.passed {
                print(outcome.message)
                exit(0)
            }
            FileHandle.standardError.write(Data((outcome.message + "\n").utf8))
            exit(1)
        }
        let settings = AppSettings(defaults: .standard)
        let store = StoreController(directory: AnthroDatabase.defaultDirectory())
        _model = State(initialValue: AppModel(settings: settings, store: store))
    }

    var body: some Scene {
        Window(L10n.appName, id: "main") {
            RootView(model: model)
                .frame(minWidth: 860, minHeight: 560)
        }
        .defaultSize(width: 1100, height: 720)
        .commands {
            AppCommands(model: model)
        }

        Window(L10n.About.title, id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
