import AnthroFeatures
import AppKit
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text(L10n.appName)
                .font(.title.weight(.bold))
            Text("\(L10n.About.versionLabel) \(AboutInfo.version(bundle: .main))")
                .foregroundStyle(.secondary)
            Text(L10n.About.attribution)
                .multilineTextAlignment(.center)
            Text(L10n.About.references)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(L10n.About.disclaimer)
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(28)
        .frame(width: 440)
    }
}
