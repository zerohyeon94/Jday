import SwiftUI
import SwiftData

/// 할 일 상세 보기·수정 시트 — 오늘 할 일 항목 탭 시 표시
struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var task: DailyTask

    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("할 일") {
                    TextField("제목", text: $task.title)

                    TextField("메모 (선택)", text: detailBinding, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("정보") {
                    DatePicker("날짜", selection: $task.date, displayedComponents: .date)

                    Picker("우선순위", selection: $task.priority) {
                        ForEach(Priority.allCases, id: \.self) { Text($0.label).tag($0) }
                    }

                    Toggle("완료", isOn: Binding(
                        get: { task.isDone },
                        set: { task.setDone($0) }
                    ))
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("할 일 삭제")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.appBackground)
            .navigationTitle("할 일 상세")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { save() }
                }
            }
            .alert("할 일 삭제", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) { delete() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("이 할 일을 삭제하면 복구할 수 없습니다.")
            }
        }
    }

    /// 옵셔널 detail을 TextField용 비옵셔널 바인딩으로 변환
    private var detailBinding: Binding<String> {
        Binding(
            get: { task.detail ?? "" },
            set: { task.detail = $0.isEmpty ? nil : $0 }
        )
    }

    private func save() {
        task.title = task.title.trimmingCharacters(in: .whitespaces)
        if let detail = task.detail {
            let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            task.detail = trimmed.isEmpty ? nil : trimmed
        }
        task.updatedAt = .now
        try? context.save()
        dismiss()
    }

    private func delete() {
        context.delete(task)
        try? context.save()
        dismiss()
    }
}

#Preview {
    TaskDetailView(task: PreviewHelpers.sampleTasks[1])
        .modelContainer(PreviewHelpers.makeContainer())
}
