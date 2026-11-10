import Foundation
import ReplayKit
import Photos
import SwiftUI

/// 实时 AR 画面录制管理器（ReplayKit）
final class ScreenRecorder: ObservableObject {
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var previewController: RPPreviewViewController?
    
    private let recorder = RPScreenRecorder.shared()
    private var timer: Timer?
    
    func startRecording() {
        guard recorder.isAvailable, !isRecording else { return }
        
        // 开启麦克风录制（若需要环境音）
        recorder.isMicrophoneEnabled = false
        
        recorder.startRecording { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("录制启动失败: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.isRecording = true
                self.recordingDuration = 0
                self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.recordingDuration += 1
                }
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        recorder.stopRecording { [weak self] preview, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isRecording = false
                self.timer?.invalidate()
                self.timer = nil
                self.recordingDuration = 0
                
                if let preview = preview {
                    self.previewController = preview
                }
            }
        }
    }
}
