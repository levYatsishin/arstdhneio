#if os(macOS)
import SwiftUI
import arstdhneioCore

struct ConfigurationView: View {
    @State private var draftSettings: StoredAppSettings
    private let usesLaunchOverrides: Bool
    private let onSave: (StoredAppSettings) -> Void
    private let onReset: () -> Void

    init(
        settings: StoredAppSettings,
        usesLaunchOverrides: Bool,
        onSave: @escaping (StoredAppSettings) -> Void,
        onReset: @escaping () -> Void
    ) {
        _draftSettings = State(initialValue: settings)
        self.usesLaunchOverrides = usesLaunchOverrides
        self.onSave = onSave
        self.onReset = onReset
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration")
                .font(.title2)
                .bold()

            if usesLaunchOverrides {
                Text("Launch arguments or environment variables are overriding the live layout for this session. Changes saved here will apply the next time you launch the app without overrides.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Picker("Layout", selection: $draftSettings.layoutMode) {
                ForEach(GridLayoutMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.radioGroup)

            VStack(alignment: .leading, spacing: 8) {
                Text("Custom rows")
                    .font(.headline)

                TextEditor(text: $draftSettings.customRowsText)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )
                    .disabled(draftSettings.layoutMode != .custom)

                Text("Enter four comma-separated rows, for example `neiuy,qwfpg,arstd,zxcvb` or `1234567890,qwertyuiop,asdfghjkl;,zxcvbnm,./`.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Effective rows")
                    .font(.headline)

                Text(previewRows)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }

            if let validationError = draftSettings.validationError {
                Text(validationError)
                    .foregroundColor(.red)
                    .font(.callout)
            }

            HStack {
                Button("Reset to QWERTY") {
                    draftSettings = .default
                    onReset()
                }

                Spacer()

                Button("Save") {
                    onSave(draftSettings)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(draftSettings.validationError != nil)
            }
        }
        .padding(20)
        .frame(width: 520, height: 420)
    }

    private var previewRows: String {
        draftSettings.effectiveRowStrings.joined(separator: "\n")
    }
}
#endif
