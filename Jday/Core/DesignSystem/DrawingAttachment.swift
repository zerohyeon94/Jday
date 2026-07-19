import SwiftUI
import PencilKit

/// PKDrawing 데이터 → 표시용 이미지 변환. 데이터가 없거나 빈 필기면 nil.
enum DrawingRenderer {
    static func image(from data: Data?) -> Image? {
        guard let data,
              let drawing = try? PKDrawing(data: data),
              !drawing.strokes.isEmpty else { return nil }
        let rect = drawing.bounds.insetBy(dx: -16, dy: -16)
        #if os(macOS)
        return Image(nsImage: drawing.image(from: rect, scale: 2))
        #else
        return Image(uiImage: drawing.image(from: rect, scale: 2))
        #endif
    }
}

/// 필기 미리보기 — 상세 화면(읽기 전용)과 첨부 행에서 공용.
/// 필기 색이 배경에 묻히지 않도록 흰색 카드 위에 렌더링한다.
struct DrawingPreview: View {
    let data: Data?
    var maxHeight: CGFloat = 180

    var body: some View {
        if let image = DrawingRenderer.image(from: data) {
            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: maxHeight)
                .padding(Theme.Spacing.sm)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.Colors.cardStroke))
                .accessibilityLabel(Text("필기 메모 이미지"))
        }
    }
}

/// 필기 메모 첨부 행 — 할 일/일정/이슈 편집 화면의 Form에서 사용.
/// iOS/iPadOS는 캔버스 시트로 작성·수정, macOS는 보기 전용.
struct DrawingAttachmentRow: View {
    @Binding var drawingData: Data?
    /// 필기 저장·삭제 직후 호출 (모델 저장용)
    var onChange: () -> Void = {}

    #if os(iOS)
    @State private var showCanvas = false

    var body: some View {
        Group {
            if drawingData != nil {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Button {
                        showCanvas = true
                    } label: {
                        DrawingPreview(data: drawingData)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("탭하여 필기를 수정합니다")

                    HStack {
                        Button("필기 수정") { showCanvas = true }
                            .buttonStyle(.borderless)
                        Spacer()
                        Button("삭제", role: .destructive) {
                            drawingData = nil
                            onChange()
                        }
                        .buttonStyle(.borderless)
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, Theme.Spacing.xs)
            } else {
                Button {
                    showCanvas = true
                } label: {
                    Label("필기 추가", systemImage: "pencil.and.scribble")
                }
                .buttonStyle(.borderless)
                .accessibilityHint("Apple Pencil 또는 손가락으로 필기 메모를 작성합니다")
            }
        }
        .sheet(isPresented: $showCanvas) {
            DrawingCanvasSheet(initialData: drawingData) { newData in
                drawingData = newData
                onChange()
            }
        }
    }
    #else
    var body: some View {
        if drawingData != nil {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                DrawingPreview(data: drawingData)
                Text("필기는 iPhone·iPad에서 수정할 수 있어요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
    }
    #endif
}

#if os(iOS)
/// 필기 작성 시트 — PKCanvasView + PKToolPicker. iPhone은 손가락, iPad는 Apple Pencil/손가락 입력.
private struct DrawingCanvasSheet: View {
    @Environment(\.dismiss) private var dismiss
    let initialData: Data?
    let onSave: (Data?) -> Void

    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()

    var body: some View {
        NavigationStack {
            DrawingCanvasRepresentable(canvasView: canvasView)
                .background(Color.white)
                .navigationTitle("필기 메모")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("지우기", role: .destructive) {
                            canvasView.drawing = PKDrawing()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            let drawing = canvasView.drawing
                            onSave(drawing.strokes.isEmpty ? nil : drawing.dataRepresentation())
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    if let initialData, let drawing = try? PKDrawing(data: initialData) {
                        canvasView.drawing = drawing
                    }
                    canvasView.drawingPolicy = .anyInput
                    toolPicker.setVisible(true, forFirstResponder: canvasView)
                    toolPicker.addObserver(canvasView)
                    canvasView.becomeFirstResponder()
                }
        }
        .interactiveDismissDisabled()
    }
}

/// PKCanvasView 래핑 — CLAUDE.md의 Representable 예외에 해당하는 UIKit 사용.
private struct DrawingCanvasRepresentable: UIViewRepresentable {
    let canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
#endif

#Preview("첨부 행 (비어 있음)") {
    Form {
        DrawingAttachmentRow(drawingData: .constant(nil))
    }
}
