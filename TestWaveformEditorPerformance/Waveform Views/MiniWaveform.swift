//
//  MiniWaveform.swift
//  TestWaveformEditorPerformance
//
//  Created by Tom Kane on 6/13/24.
//

import SwiftUI
import AVFoundation
//import Accelerate

public struct MiniWaveform: View {
  
  // MARK: - Properties

  @Binding var selectedSamples: Range<Int>
  @Binding var start: Double
  @Binding var end: Double
    
  @State var lastStart: Double = 0
  @State var lastEnd: Double = 1
  
  @State var isDragging: Bool = false
  @State var panGestureValue: CGFloat = 0

  var sampleData: [SampleData]

  @Binding var renderSamples: Range<Int>
  @Binding var inViewRenderSamples: Range<Int>
  @Binding var audioBuffer: AVAudioPCMBuffer?
  
  var geometry: GeometryProxy
  
  var backgroundColor: Color
  
  // MARK: - View

  public var body: some View {
    let handleWidth: CGFloat = 10
    let width = geometry.size.width - 20
      let lineWidth: CGFloat = width / CGFloat((sampleData.count * 2) - 1)
      let waveHeight: CGFloat = max(geometry.size.height - 5, 0)
            
      let startPosition = max(0, position(of: $selectedSamples.wrappedValue.lowerBound, in: width))
      let endPosition = min(position(of: $selectedSamples.wrappedValue.upperBound, in: width), width)
      
      // Wave Background
      ZStack(alignment: .leading) {
        backgroundColor
          .contentShape(Rectangle())
          .gesture(pan)
          .frame(width: max(0, width - (width * $start.wrappedValue) - (width * (1 - $end.wrappedValue))))
          .offset(x: (width * $start.wrappedValue) + handleWidth)

        Group {
          // Wave Unhighlighted Section
          HStack(spacing: lineWidth) {
            ForEach(sampleData) { sample in
              let totalHeight = (waveHeight / 2) * CGFloat(abs(sample.max) + abs(sample.min))

              Rectangle()
                .frame(width: lineWidth, height: totalHeight)
                .cornerRadius(lineWidth / 2)
                .foregroundColor(.secondary.opacity(0.3))
            }
          }
          
          // Wave Highlighted Section
          HStack(spacing: lineWidth) {
            ForEach(sampleData) { sample in
              let totalHeight = (waveHeight / 2) * CGFloat(abs(sample.max) + abs(sample.min))

              Rectangle()
                .frame(width: lineWidth, height: totalHeight)
                .cornerRadius(lineWidth / 2)
                .offset(x: (-startPosition / 2) + ((width - endPosition) / 2))
            }
          }
          .frame(width: max(0, width - startPosition - (width - endPosition)))
          .clipped()
          .offset(x: startPosition)
        }
        .padding(.horizontal, 10)
        .allowsHitTesting(false)
        
        // Left Handle
        Color.secondary.opacity(0.25)
          .frame(width: handleWidth)
          .background(Color(uiColor: .systemBackground))
          .overlay {
            Capsule()
              .fill(Color.secondary)
              .frame(width: 3, height: 20)
          }
          .contentShape(Rectangle())
          .hoverEffect()
          .offset(x: width * $start.wrappedValue)
          .gesture(
            DragGesture()
              .onChanged {
                isDragging = true
                
                let panAmount = $0.translation.width
                let panPercent = panAmount / width
                let maxValue = min($lastStart.wrappedValue + panPercent, end * 0.99)
                start = max(0, maxValue)
              }
              .onEnded {
                isDragging = false

                let panAmount = $0.translation.width
                let panPercent = panAmount / width
                let maxValue = min($lastStart.wrappedValue + panPercent, end * 0.99)
                start = max(0, maxValue)
                lastStart = max(0, maxValue)
              }
          )

        Color.secondary.opacity(0.25)
          .frame(width: handleWidth)
          .background(Color(uiColor: .systemBackground))
          .overlay {
            Capsule()
              .fill(Color.secondary)
              .frame(width: 3, height: 20)
          }
          .contentShape(Rectangle())
          .hoverEffect()
          .offset(x: width * $end.wrappedValue + 10)
          .foregroundColor(.primary.opacity(0.5))
          .gesture(
            DragGesture()
              .onChanged {
                isDragging = true

                let panAmount = $0.translation.width
                let panPercent = panAmount / width
                let minValue = max($lastEnd.wrappedValue + panPercent, start * 1.01)
                end = min(1, minValue)
              }
              .onEnded {
                isDragging = false

                let panAmount = $0.translation.width
                let panPercent = panAmount / width
                let minValue = max($lastEnd.wrappedValue + panPercent, start * 1.01)
                end = min(1, minValue)
                lastEnd = min(1, minValue)
              }
          )
    }
  }
  
  // MARK: - Gesture Methods
  
  var pan: some Gesture {
      DragGesture()
          .onChanged {
              let panAmount = $0.translation.width - panGestureValue
              pan(offset: panAmount)
              panGestureValue = $0.translation.width
          }
          .onEnded {
              let panAmount = $0.translation.width - panGestureValue
              pan(offset: panAmount)
              panGestureValue = 0
          }
  }
  
  // MARK: - Helper Methods
  
  func position(of sample: Int, in width: CGFloat) -> CGFloat {
    let radio = width / CGFloat($renderSamples.wrappedValue.count)
    return CGFloat(sample - $renderSamples.wrappedValue.lowerBound) * radio
  }
  
  func pan(offset: CGFloat) {
    let count = inViewRenderSamples.count
    var startSample = sample(inViewRenderSamples.lowerBound, with: offset)
    var endSample = startSample + count

    if startSample < 0 {
        startSample = 0
        endSample = inViewRenderSamples.count
    } else if endSample > Int($audioBuffer.wrappedValue?.frameLength ?? .zero) {
        endSample = Int($audioBuffer.wrappedValue?.frameLength ?? .zero)
        startSample = endSample - inViewRenderSamples.count
    }
    
    inViewRenderSamples = startSample..<endSample
  }
  
  func sample(_ oldSample: Int, with offset: CGFloat) -> Int {
    let ratio = CGFloat(renderSamples.count) / (geometry.size.width - 10)
    let sample = oldSample + Int(offset * ratio)
    return min(max(0, sample), Int($audioBuffer.wrappedValue?.frameLength ?? .zero))
  }

}
