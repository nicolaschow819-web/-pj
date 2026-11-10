import SwiftUI
import ReplayKit

struct ContentView: View {
    @StateObject private var handDetector = HandPoseDetector()
    @StateObject private var gaussianRenderer = GaussianRenderer()
    @StateObject private var screenRecorder = ScreenRecorder()
    
    var body: some View {
        ZStack {
            // 底层：AR 场景与第一人称透视
            ARViewContainer(handDetector: handDetector, gaussianRenderer: gaussianRenderer)
                .edgesIgnoringSafeArea(.all)
            
            // 顶层 UI 交互控件
            VStack {
                // 顶部状态提示
                statusBanner
                    .padding(.top, 50)
                
                Spacer()
                
                // 底部控制操作栏
                bottomActionBar
                    .padding(.bottom, 36)
            }
            .padding(.horizontal, 20)
        }
        // 录制结束预览弹窗
        .sheet(item: $screenRecorder.previewController) { preview in
            RPPreviewWrapper(previewController: preview)
        }
    }
    
    // 顶部状态提示条
    private var statusBanner: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(gaussianRenderer.state == .waitingForPinch ? Color.orange : Color.green)
                .frame(width: 10, height: 10)
            
            Text(statusText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 6)
    }
    
    private var statusText: String {
        switch gaussianRenderer.state {
        case .waitingForPinch:
            return "👌 对准镜头隔空捏合（30~50cm）召唤高斯空间"
        case .expanding:
            return "✨ 空间正在展开中..."
        case .anchored:
            return "🎯 场景已锁定在空间！拿着手机走动靠近观察"
        }
    }
    
    // 底部控制按钮栏
    private var bottomActionBar: some View {
        HStack(spacing: 30) {
            // 重置场景按钮
            Button(action: {
                gaussianRenderer.reset()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // 录像切换按钮
            Button(action: {
                if screenRecorder.isRecording {
                    screenRecorder.stopRecording()
                } else {
                    screenRecorder.startRecording()
                }
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(screenRecorder.isRecording ? Color.red : Color.white)
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: screenRecorder.isRecording ? 3 : 11)
                                .fill(screenRecorder.isRecording ? Color.white : Color.red)
                                .frame(width: 12, height: 12)
                        )
                    
                    if screenRecorder.isRecording {
                        Text(formatDuration(screenRecorder.recordingDuration))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, screenRecorder.isRecording ? 18 : 0)
                .frame(minWidth: 64, height: 64)
                .background(screenRecorder.isRecording ? Color.red.opacity(0.8) : Color.white.opacity(0.2))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 2))
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// 包装 RPPreviewViewController 方便 SwiftUI sheet 弹出
struct RPPreviewWrapper: UIViewControllerRepresentable {
    let previewController: RPPreviewViewController
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> RPPreviewViewController {
        previewController.previewControllerDelegate = context.coordinator
        return previewController
    }
    
    func updateUIViewController(_ uiViewController: RPPreviewViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, RPPreviewViewControllerDelegate {
        let parent: RPPreviewWrapper
        init(_ parent: RPPreviewWrapper) { self.parent = parent }
        func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

extension RPPreviewViewController: Identifiable {
    public var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}
