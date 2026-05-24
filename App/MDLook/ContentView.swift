import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("MDLook")
                .font(.system(size: 28, weight: .semibold))

            Text("This app installs a Quick Look extension for Markdown files. Select a .md file in Finder and press Space to preview the rendered document.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Label("Finder Quick Look renders Markdown as readable HTML.", systemImage: "doc.richtext")
                Label("Local relative images are allowed; remote resources are blocked.", systemImage: "lock.shield")
                Label("If Finder keeps showing source, relaunch Finder or reset Quick Look caches.", systemImage: "arrow.clockwise")
            }
            .labelStyle(.titleAndIcon)
        }
        .padding(32)
        .frame(width: 560, alignment: .leading)
    }
}

#Preview {
    ContentView()
}

