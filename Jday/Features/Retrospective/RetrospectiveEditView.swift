import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "RetrospectiveEditView")

/// 하루 회고(배운 점) 작성·수정 시트.
/// 해당 날짜의 기존 회고가 있으면 편집, 없으면 새로 만든다(날짜별 1건 업서트).
struct RetrospectiveEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let date: Date
    let existing: Retrospective?
    var workspace: Workspace?

    @State private var content: String
    @State private var errorMessage: String?

    init(date: Date, existing: Retrospective?, workspace: Workspace? = nil) {
        self.date = date
        self.existing = existing
        self.workspace = workspace
        _content = State(initialValue: existing?.content ?? "")
    }

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("오늘 배운 점 · 회고") {
                    TextEditor(text: $content)
                        .frame(minHeight: 160)
                        .accessibilityLabel("회고 내용")
                }

                if existing != nil {
                    Section {
                        Button(role: .destructive) {
                            delete()
                        } label: {
                            Text("회고 삭제")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.appBackground)
            .navigationTitle("\(date.shortMonthDay) 회고")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(!canSave)
                }
            }
            .alert("저장 실패", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing {
            existing.content = trimmed
            existing.updatedAt = .now
        } else {
            let retro = Retrospective(content: trimmed, date: date, workspace: workspace)
            context.insert(retro)
        }
        do {
            try context.save()
            dismiss()
        } catch {
            logger.error("회고 저장 실패: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    private func delete() {
        guard let existing else { dismiss(); return }
        context.delete(existing)
        do {
            try context.save()
        } catch {
            logger.error("회고 삭제 실패: \(error.localizedDescription)")
        }
        dismiss()
    }
}

#Preview {
    RetrospectiveEditView(date: .now, existing: nil)
        .modelContainer(PreviewHelpers.makeContainer())
}
