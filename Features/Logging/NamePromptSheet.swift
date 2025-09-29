import SwiftUI

struct NamePromptSheet: View {
    @EnvironmentObject private var app: AppState
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("무슨 일을 했는지 입력하세요")
                    .font(.headline)
                TextField("업무명", text: $app.promptText, onCommit: commit)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .submitLabel(.done)
                if !app.availableActivities.isEmpty {
                    Text("이전 활동")
                        .font(.subheadline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(app.availableActivities) { activity in
                                Button {
                                    app.selectExistingActivity(activity)
                                } label: {
                                    Text(activity.name)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color(hex: activity.colorHex) ?? .gray.opacity(0.2)))
                                        .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("활동 이름")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("입력", action: commit)
                        .disabled(app.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }

    private func commit() {
        app.confirmActivityName(app.promptText)
    }
}

struct NamePromptSheet_Previews: PreviewProvider {
    static var previews: some View {
        NamePromptSheet()
            .environmentObject(AppState(store: Store()))
    }
}
