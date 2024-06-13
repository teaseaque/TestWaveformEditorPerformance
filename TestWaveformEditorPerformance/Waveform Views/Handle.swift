//
//  Handle.swift
//  TestWaveformEditorPerformance
//
//  Created by Tom Kane on 6/13/24.
//

import SwiftUI
import AVFoundation

struct Handle: View {
  
  // MARK: - Properties
  
  static let radius: CGFloat = 5
  
  @Binding var selectedSamples: SampleRange
  
  var renderSamples: Range<Int>
    
  var width: CGFloat
  
  var audioBuffer: AVAudioPCMBuffer?
  
  var isStart: Bool = false
  
  var limitHandlesForSafeArea: Bool
  
  // MARK: - View
    
  var body: some View {
    VStack(spacing: 0) {
      Circle()
          .frame(width: 2 * Self.radius, height: 2 * Self.radius, alignment: .center)
      Rectangle()
          .frame(width: 2)
      Circle()
          .frame(width: 2 * Self.radius, height: 2 * Self.radius, alignment: .center)
    }
    .foregroundColor(.primary)
    .contentShape(Capsule())
    .hoverEffect()
    .gesture(drag)
    .offset(x: position(of: isStart ? selectedSamples.lowerBound : selectedSamples.upperBound) - Self.radius)
  }
  
  // MARK: - Gesture Methods
    
  var drag: some Gesture {
    DragGesture()
      .onChanged { // $0.location is in the Circle's coordinate space
        updateSelection($0.location.x - Self.radius)
      }
      .onEnded {
        updateSelection($0.location.x - Self.radius)
      }
  }
  
  // MARK: - Update Methods
    
  func updateSelection(_ offset: CGFloat) {

    if isStart {
      var sample = sample(selectedSamples.lowerBound, with: offset)
      sample = max(sample, renderSamples.lowerBound) // avoid selecting in safearea
      guard sample < selectedSamples.upperBound else { return }
      selectedSamples = sample..<selectedSamples.upperBound
      
    } else {
      var sample = sample(selectedSamples.upperBound, with: offset)
      sample = min(sample, renderSamples.upperBound) // avoid selecting in safearea
      guard sample > selectedSamples.lowerBound else { return }
      selectedSamples = selectedSamples.lowerBound..<sample
    }
  }
  
  // MARK: - Helper Methods
  
  func position(of sample: Int) -> CGFloat {
    let sample = min(sample, Int(audioBuffer?.frameLength ?? 0))
    let count = min(self.renderSamples.count, Int(audioBuffer?.frameLength ?? 0))
    let ratio = width / CGFloat(count)
    var position = CGFloat(sample - renderSamples.lowerBound) * ratio
    
    if limitHandlesForSafeArea {
      if isStart {
        position = max(0, position)
      } else {
        position = min(width, position)
      }
    }
      
    return position
  }
    
  func sample(_ oldSample: Int, with offset: CGFloat) -> Int {
      let ratio = CGFloat(renderSamples.count) / width
      let sample = oldSample + Int(offset * ratio)
      return min(max(0, sample), Int(audioBuffer?.frameLength ?? .zero))
  }
}
