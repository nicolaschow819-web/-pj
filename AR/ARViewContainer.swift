import SwiftUI
import ARKit
import MetalKit

/// AR 视图桥接容器：结合 ARKit 空间跟踪、Vision 手势与高斯渲染
struct ARViewContainer: UIViewRepresentable {
    
    @ObservedObject var handDetector: HandPoseDetector
    @ObservedObject var gaussianRenderer: GaussianRenderer
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.session.delegate = context.coordinator
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.isAutoFocusEnabled = true
        
        // 绑定手势触发回调到 coordinator
        let coordinator = context.coordinator
        handDetector.onPinchTriggered = { [weak coordinator, weak arView] in
            guard let coordinator = coordinator,
                  let currentFrame = arView?.session.currentFrame else { return }
            coordinator.handlePinchTrigger(from: currentFrame.camera)
        }
        
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(handDetector: handDetector, gaussianRenderer: gaussianRenderer)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARSCNView?
        let handDetector: HandPoseDetector
        let gaussianRenderer: GaussianRenderer
        
        init(handDetector: HandPoseDetector, gaussianRenderer: GaussianRenderer) {
            self.handDetector = handDetector
            self.gaussianRenderer = gaussianRenderer
        }
        
        func handlePinchTrigger(from camera: ARCamera) {
            // 主线程触发高斯空间召唤
            DispatchQueue.main.async {
                self.gaussianRenderer.spawnScene(from: camera)
                // 触感反馈（Haptics）
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.impactOccurred()
            }
        }
        
        // 逐帧回调：ARKit 相机帧 -> Vision 识别 & 动画更新
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // 1. 传递相机图像做手部捏合检测
            handDetector.processPixelBuffer(frame.capturedImage)
            
            // 2. 更新展开动画
            DispatchQueue.main.async {
                self.gaussianRenderer.updateAnimation()
            }
        }
    }
}
