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
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Configuration")
                        .font(.title2)
                        .bold()

                    if usesLaunchOverrides {
                        Text("Launch arguments or environment variables are overriding the live layout for this session. Changes saved here will apply the next time you launch the app without overrides.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    settingsSection(title: "Layout") {
                        radioGroup(
                            title: "Layout",
                            selection: $draftSettings.layoutMode,
                            options: GridLayoutMode.allCases,
                            label: \.displayName
                        )
                    }

                    settingsSection(title: "Activation") {
                        VStack(alignment: .leading, spacing: 10) {
                            radioGroup(
                                title: "Activation",
                                selection: $draftSettings.activationMode,
                                options: ActivationMode.allCases,
                                label: \.displayName
                            )

                            Text(draftSettings.activationMode.descriptionText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if draftSettings.activationMode == .commandSemicolon {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Shortcut")
                                        .font(.subheadline)
                                        .bold()

                                    HStack(spacing: 10) {
                                        modifierToggle("Command", isOn: $draftSettings.activationUsesCommand)
                                        modifierToggle("Option", isOn: $draftSettings.activationUsesOption)
                                        modifierToggle("Control", isOn: $draftSettings.activationUsesControl)
                                        modifierToggle("Shift", isOn: $draftSettings.activationUsesShift)
                                    }

                                    TextField(";", text: $draftSettings.activationKeyText)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: 120)
                                        .onChange(of: draftSettings.activationKeyText) { newValue in
                                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                            if trimmed.count <= 1 {
                                                if newValue != trimmed {
                                                    draftSettings.activationKeyText = trimmed
                                                }
                                                return
                                            }

                                            draftSettings.activationKeyText = String(trimmed.prefix(1))
                                        }

                                    Text("Current shortcut: \(draftSettings.activationHotKey.displayText)")
                                        .font(.callout)
                                        .bold()

                                    Text("The key is resolved through the current layout using the selected modifiers, so the shortcut follows layout changes.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    settingsSection(title: "Custom rows") {
                        VStack(alignment: .leading, spacing: 10) {
                            TextEditor(text: $draftSettings.customRowsText)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 92, maxHeight: 92)
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(NSColor.textBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.3))
                                )
                                .disabled(draftSettings.layoutMode != .custom)

                            Text("Enter four comma-separated rows, for example `neiuy,qwfpg,arstd,zxcvb` or `1234567890,qwertyuiop,asdfghjkl;,zxcvbnm,./`.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    settingsSection(title: "Effective rows") {
                        Text(previewRows)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.textBackgroundColor).opacity(0.55))
                            )
                    }

                    if let validationError = draftSettings.validationError {
                        Text(validationError)
                            .foregroundColor(.red)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack(spacing: 12) {
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
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 560)
    }

    private var previewRows: String {
        draftSettings.effectiveRowStrings.joined(separator: "\n")
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func radioGroup<SelectionValue: Hashable>(
        title: String,
        selection: Binding<SelectionValue>,
        options: [SelectionValue],
        label: KeyPath<SelectionValue, String>
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { option in
                Text(option[keyPath: label]).tag(option)
            }
        }
        .pickerStyle(.radioGroup)
        .labelsHidden()
    }

    private func modifierToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .toggleStyle(.checkbox)
            .fixedSize()
    }
}
#endif
