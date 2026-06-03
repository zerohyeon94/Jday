import SwiftUI
import SwiftData

/// 일정 상세 보기·수정 시트 — 캘린더에서 일정 선택 시 표시.
struct ScheduleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var schedule: Schedule

    @AppStorage("workspaceSeparationEnabled") private var wsEnabled = false
    @AppStorage("activeWorkspace") private var wsActiveRaw = Workspace.personal.rawValue
    @State private var showDeleteAlert = false

    private var workspaceBinding: Binding<Workspace> {
        Binding(
            get: { schedule.workspace ?? (Workspace(rawValue: wsActiveRaw) ?? .personal) },
            set: { schedule.workspace = $0 }
        )
    }

    private var locationBinding: Binding<String> {
        Binding(
            get: { schedule.location ?? "" },
            set: { schedule.location = $0.isEmpty ? nil : $0 }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("일정") {
                    TextField("제목", text: $schedule.title)
                    TextField("장소 (선택)", text: locationBinding)
                }

                Section("시간") {
                    DatePicker("시작", selection: $schedule.startTime)
                    DatePicker("종료", selection: $schedule.endTime)
                    if schedule.endTime <= schedule.startTime {
                        Text("종료 시간은 시작 시간 이후여야 합니다.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if wsEnabled {
                    Section("공간") {
                        Picker(selection: workspaceBinding) {
                            ForEach(Workspace.allCases) { ws in
                                Label(ws.label, systemImage: ws.icon).tag(ws)
                            }
                        } label: {
                            Text("공간")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("일정 삭제")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.appBackground)
            .navigationTitle("일정 상세")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { save() }
                        .disabled(schedule.endTime <= schedule.startTime || schedule.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("일정 삭제", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) { delete() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("이 일정을 삭제하면 복구할 수 없습니다.")
            }
        }
    }

    private func save() {
        schedule.title = schedule.title.trimmingCharacters(in: .whitespaces)
        schedule.updatedAt = .now
        try? context.save()
        dismiss()
    }

    private func delete() {
        NotificationService.shared.cancelScheduleNotification(for: schedule)
        context.delete(schedule)
        try? context.save()
        dismiss()
    }
}

#Preview {
    ScheduleDetailView(schedule: PreviewHelpers.sampleSchedules[0])
        .modelContainer(PreviewHelpers.makeContainer())
}
