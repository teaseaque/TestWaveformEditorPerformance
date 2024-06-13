//
//  Waveform.swift
//  TestWaveformEditorPerformance
//
//  Created by Tom Kane on 6/13/24.
//

import SwiftUI
import AVFoundation

struct Waveform: View {
  
  // MARK: - Properties
  
  @State var zoomGestureValue: CGFloat = 1
  @State var panGestureValue: CGFloat = 0
  @Binding var selectedSamples: Range<Int>

  @Binding var sampleData: [SampleData]

  @Binding var renderSamples: Range<Int>
  @Binding var audioBuffer: AVAudioPCMBuffer?
  
  var geo: GeometryProxy
    
  // MARK: - View

  public var body: some View {
    let lineWidth: CGFloat = geo.size.width / CGFloat(($sampleData.wrappedValue.count * 2) - 1)
    let height: CGFloat = geo.size.height / 2.5
    let waveHeight: CGFloat = height * 0.8
    let shouldLimitWaveForSafeArea = geo.safeAreaInsets.leading != 0 || geo.safeAreaInsets.trailing != 0

    ZStack(alignment: .leading) {
      // Wave Unhighlighted Sections
      HStack(alignment: .center, spacing: lineWidth) {
        ForEach($sampleData.wrappedValue) { sample in
          let totalHeight = (waveHeight / 2) * CGFloat(abs(sample.max) + abs(sample.min))
          
          Rectangle()
            .foregroundColor(.secondary.opacity(0.3))
            .frame(width: lineWidth, height: totalHeight)
            .cornerRadius(lineWidth / 2)
        }
      }
      .padding(.vertical)

      // Wave Highlighted Section
      let startPosition = max(0, position(of: $selectedSamples.wrappedValue.lowerBound, in: geo.size.width))
      let endPosition = min(position(of: $selectedSamples.wrappedValue.upperBound, in: geo.size.width), geo.size.width)
      HStack(alignment: .center, spacing: lineWidth) {
        ForEach($sampleData.wrappedValue) { sample in
          let totalHeight = (waveHeight / 2) * CGFloat(abs(sample.max) + abs(sample.min))
          
          Rectangle()
            .foregroundColor(.blue)
            .frame(width: lineWidth, height: totalHeight)
            .cornerRadius(lineWidth / 2)
        }
      }
      .offset(x: (-startPosition / 2) + ((geo.size.width - endPosition) / 2))
      .frame(width: max(0, geo.size.width - startPosition - (geo.size.width - endPosition)))
      .clipped()
      .offset(x: startPosition)
      .padding(.vertical)

      // Left Trim Handle
      Handle(selectedSamples: $selectedSamples,
             renderSamples: renderSamples,
             width: geo.size.width,
             audioBuffer: audioBuffer,
             isStart: true,
             limitHandlesForSafeArea: shouldLimitWaveForSafeArea)
      
      // Right Trim Handle
      Handle(selectedSamples: $selectedSamples,
             renderSamples: renderSamples,
             width: geo.size.width,
             audioBuffer: audioBuffer,
             limitHandlesForSafeArea: shouldLimitWaveForSafeArea)
    }
    .background(.secondary.opacity(0.2))
    .frame(height: height)
    .onAppear {
      selectedSamples = $renderSamples.wrappedValue.lowerBound..<$renderSamples.wrappedValue.upperBound
    }
    .gesture(SimultaneousGesture(zoom,pan))
  }
  
  // MARK: - Gesture Methods
  
  var zoom: some Gesture {
    MagnificationGesture()
      .onChanged {
        let zoomAmount = $0 / $zoomGestureValue.wrappedValue
        self.zoom(amount: zoomAmount)
        zoomGestureValue = $0
      }
      .onEnded {
        let zoomAmount = $0 / $zoomGestureValue.wrappedValue
        zoom(amount: zoomAmount)
        zoomGestureValue = 1
      }
  }

  var pan: some Gesture {
    DragGesture()
      .onChanged {
        let panAmount = $0.translation.width - panGestureValue
        pan(offset: -panAmount)
        panGestureValue = $0.translation.width
      }
      .onEnded {
        let panAmount = $0.translation.width - panGestureValue
        pan(offset: -panAmount)
        panGestureValue = 0
      }
  }

  func zoom(amount: CGFloat) {
    let renderSamples = $renderSamples.wrappedValue
    let count = renderSamples.count
    let newCount = CGFloat(count) / amount
    let delta = (count - Int(newCount)) / 2
    let renderStartSample = max(0, renderSamples.lowerBound + delta)
    let renderEndSample = min(renderSamples.upperBound - delta, Int($audioBuffer.wrappedValue?.frameLength ?? .zero))
    self.renderSamples = renderStartSample..<renderEndSample
  }

  func pan(offset: CGFloat) {
    let startSample = sample(renderSamples.lowerBound, with: offset)
    let endSample = startSample + renderSamples.count

    if startSample >= 0 && endSample <= Int($audioBuffer.wrappedValue?.frameLength ?? .zero) {
      renderSamples = startSample..<endSample
    }
  }
  
  // MARK: - Helper Methods
  
  func position(of sample: Int, in width: CGFloat) -> CGFloat {
    let radio = width / CGFloat($renderSamples.wrappedValue.count)
    return CGFloat(sample - $renderSamples.wrappedValue.lowerBound) * radio
  }

  func sample(_ oldSample: Int, with offset: CGFloat) -> Int {
    let ratio = CGFloat(renderSamples.count) / geo.size.width
    let sample = oldSample + Int(offset * ratio)
    return min(max(0, sample), Int($audioBuffer.wrappedValue?.frameLength ?? .zero))
  }
}
