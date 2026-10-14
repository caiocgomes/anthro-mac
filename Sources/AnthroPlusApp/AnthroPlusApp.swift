import AnthroFeatures
import AppKit
import SwiftUI

/// Ao encerrar, pergunta se salva as alterações pendentes do módulo aberto (`FormClosing` com `AskForSave`).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var model: AppModel?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if Self.model?.isEditingInSheet == true {
            let alert = NSAlert()
            alert.messageText = L10n.Menu.sheetOpenTitle
            alert.informativeText = L10n.Menu.sheetOpenMessage
            alert.runModal()
            return .terminateCancel
        }
        guard let unsaved = Self.model?.unsavedChangesGuard, unsaved.hasUnsavedChanges else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = UnsavedChangesText.title(for: unsaved)
        alert.informativeText = UnsavedChangesText.message(for: unsaved)
        alert.addButton(withTitle: L10n.IndividualAssessment.save)
        alert.addButton(withTitle: L10n.IndividualAssessment.discard)
        alert.addButton(withTitle: L10n.IndividualAssessment.cancel)
        let decision: UnsavedChangesDecision = switch alert.runModal() {
        case .alertFirstButtonReturn: .save
        case .alertSecondButtonReturn: .discard
        default: .cancel
        }
        do {
            return try unsaved.proceedAfterUnsavedChanges(decision) ? .terminateNow : .terminateCancel
        } catch {
            let failure = NSAlert()
            failure.messageText = L10n.IndividualAssessment.saveFailed
            failure.informativeText = SurveyErrorText.message(for: error)
            failure.runModal()
            return .terminateCancel
        }
    }
}

@main
struct AnthroPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
        let appModel = AppModel(settings: settings, store: store)
        AppDelegate.model = appModel
        _model = State(initialValue: appModel)
    }

    var body: some Scene {
        Window(L10n.appName, id: "main") {
            RootView(model: model)
                .environment(model)
                .frame(minWidth: 860, minHeight: 560)
        }
        .defaultSize(width: 1240, height: 780)
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
