//
//  GenerateTask.swift
//  TestWaveformEditorPerformance
//
//  Created by Tom Kane on 6/13/24.
//

import AVFoundation
import Accelerate

class GenerateTask {
  static func resume(audioBuffer: AVAudioPCMBuffer, width: CGFloat, renderSamples: Range<Int>, completion: @escaping ([SampleData]) -> Void) {
    let width = width / 7
    var sampleData = Array(0..<Int(width)).map( { SampleData.zero($0) }) // [SampleData](repeating: .zero, count: Int(width))
          
    DispatchQueue.global(qos: .userInteractive).async {
      let channels = Int(audioBuffer.format.channelCount)
      let length = renderSamples.count
      let samplesPerPoint = width == 0 ? length : length / Int(width)
        
      guard let floatChannelData = audioBuffer.floatChannelData else { return }
      
      DispatchQueue.concurrentPerform(iterations: Int(width)) { point in
        var data: SampleData = SampleData.zero(point)
        for channel in 0..<channels {
          let pointer = floatChannelData[channel].advanced(by: renderSamples.lowerBound + (point * samplesPerPoint))
          let stride = vDSP_Stride(audioBuffer.stride)
          let length = vDSP_Length(samplesPerPoint)
          
          var value: Float = 0

          // calculate minimum value for point
          vDSP_minv(pointer, stride, &value, length)
          data.min = min(value, data.min)

          // calculate maximum value for point
          vDSP_maxv(pointer, stride, &value, length)
          data.max = max(value, data.max)
        }
        
        // sync to hold completion handler until all iterations are complete
        DispatchQueue.main.sync { sampleData[point] = data }
      }
      
      DispatchQueue.main.async {
        completion(sampleData)
      }
    }
  }
}
