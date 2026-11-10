import Foundation
import Vision
import CoreMedia

/// 基于 Apple Vision 框架的隔空捏合手势识别与防抖状态机
final class HandPoseDetector: ObservableObject {
    
    // 捏合事件回调
    var onPinchTriggered: (() -> Void)?
    
    // 判定阈值
    private let pinchDistanceThreshold: CGFloat = 0.055 // 指尖归一化欧氏距离阈值
    private let confidenceThreshold: Float = 0.7        // 关键点识别置信度阈值
    
    // 多帧去抖状态机
    private let requiredConsecutiveFrames = 4           // 需要连续满足的帧数
    private var consecutivePinchFrames = 0
    private var hasTriggeredForCurrentPinch = false      // 防止一次捏合持续触发多次
    
    // Vision 请求
    private lazy var handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1 // 专注于主手，降低计算开销
        return request
    }()
    
    private let processingQueue = DispatchQueue(label: "com.pinchsplat.visionQueue", qos: .userInteractive)
    private var isBusy = false
    
    /// 由 ARFrame 代理每帧调用
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        // 限制单帧处理频率，避免阻塞渲染管线
        guard !isBusy else { return }
        isBusy = true
        
        processingQueue.async { [weak self] in
            defer { self?.isBusy = false }
            guard let self = self else { return }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform([self.handPoseRequest])
                guard let observation = self.handPoseRequest.results?.first else {
                    self.resetState()
                    return
                }
                self.analyzeHandPose(observation)
            } catch {
                self.resetState()
            }
        }
    }
    
    private func analyzeHandPose(_ observation: VNHumanHandPoseObservation) {
        do {
            // 获取食指和拇指指尖
            let thumbPoints = try observation.recognizedPoints(.thumb)
            let indexPoints = try observation.recognizedPoints(.indexFinger)
            
            guard let thumbTip = thumbPoints[.thumbTip],
                  let indexTip = indexPoints[.indexTip],
                  thumbTip.confidence > confidenceThreshold,
                  indexTip.confidence > confidenceThreshold else {
                resetState()
                return
            }
            
            // 计算两指尖归一化坐标欧氏距离
            let dx = thumbTip.location.x - indexTip.location.x
            let dy = thumbTip.location.y - indexTip.location.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < pinchDistanceThreshold {
                consecutivePinchFrames += 1
                if consecutivePinchFrames >= requiredConsecutiveFrames && !hasTriggeredForCurrentPinch {
                    hasTriggeredForCurrentPinch = true
                    DispatchQueue.main.async {
                        self.onPinchTriggered?()
                    }
                }
            } else {
                // 手指松开，重置状态
                resetState()
            }
        } catch {
            resetState()
        }
    }
    
    private func resetState() {
        consecutivePinchFrames = 0
        hasTriggeredForCurrentPinch = false
    }
}
