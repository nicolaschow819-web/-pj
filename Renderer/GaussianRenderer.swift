import Foundation
import simd
import Metal
import MetalKit
import ARKit

enum SplatSceneState {
    case waitingForPinch // 等待手势召唤
    case expanding       // 正在从虚空中放大展开
    case anchored        // 已完全锚定在真实空间
}

/// 高斯泼溅空间锚定与召唤动画控制器
final class GaussianRenderer: ObservableObject {
    
    @Published var state: SplatSceneState = .waitingForPinch
    @Published var animationScale: Float = 0.0
    @Published var opacity: Float = 0.0
    
    // 场景在世界坐标系中的变换矩阵
    private(set) var worldTransform: simd_float4x4 = matrix_identity_float4x4
    
    // 动画计时器
    private var animationStartTime: TimeInterval?
    private let animationDuration: TimeInterval = 0.65 // 展开动画时长
    
    /// 触发召唤场景：将场景锁定在当前相机正前方约 1.0 米处
    func spawnScene(from camera: ARCamera) {
        guard state == .waitingForPinch else { return }
        
        let camTransform = camera.transform
        
        // 提取相机的水平朝向（Yaw），消除 Pitch 和 Roll，保证生成的高斯场景永远垂直于地面，不歪斜
        let forward = -simd_float3(camTransform.columns.2.x, camTransform.columns.2.y, camTransform.columns.2.z)
        let horizontalForward = simd_normalize(simd_float3(forward.x, 0, forward.z))
        let up = simd_float3(0, 1, 0)
        let right = simd_cross(up, horizontalForward)
        
        // 目标空间锚点位置：相机位置沿视线方向前方 1.0 米，稍微下沉 0.1 米（符合人机工学视线高度）
        let camPos = simd_float3(camTransform.columns.3.x, camTransform.columns.3.y, camTransform.columns.3.z)
        let targetPos = camPos + horizontalForward * 1.0 + simd_float3(0, -0.1, 0)
        
        // 构建正立的空间锚定矩阵
        var anchorMatrix = matrix_identity_float4x4
        anchorMatrix.columns.0 = simd_float4(right, 0)
        anchorMatrix.columns.1 = simd_float4(up, 0)
        anchorMatrix.columns.2 = simd_float4(-horizontalForward, 0)
        anchorMatrix.columns.3 = simd_float4(targetPos, 1)
        
        self.worldTransform = anchorMatrix
        self.state = .expanding
        self.animationStartTime = CACurrentMediaTime()
    }
    
    /// 逐帧驱动召唤展开动画（Ease-Out 弹性缓动）
    func updateAnimation() {
        guard state == .expanding, let startTime = animationStartTime else { return }
        
        let elapsed = CACurrentMediaTime() - startTime
        let progress = Float(min(max(elapsed / animationDuration, 0.0), 1.0))
        
        // Ease-out cubic 曲线: 1 - (1 - t)^3
        let easeOut = 1.0 - pow(1.0 - progress, 3.0)
        
        self.animationScale = easeOut
        self.opacity = easeOut
        
        if progress >= 1.0 {
            self.state = .anchored
            self.animationScale = 1.0
            self.opacity = 1.0
        }
    }
    
    /// 重置场景（再次允许捏合召唤）
    func reset() {
        self.state = .waitingForPinch
        self.animationScale = 0.0
        self.opacity = 0.0
        self.animationStartTime = nil
        self.worldTransform = matrix_identity_float4x4
    }
}
