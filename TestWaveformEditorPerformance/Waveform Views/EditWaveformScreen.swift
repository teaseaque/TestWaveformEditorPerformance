//
//  EditWaveformScreen.swift
//  TestWaveformEditorPerformance
//
//  Created by Tom Kane on 6/13/24.
//

import SwiftUI
import AVFoundation

struct EditWaveformScreen: View {
  
  // MARK: - Properties
  
  var audioFile: AVAudioFile = try! AVAudioFile(forReading: Bundle.main.url(forResource: "thanks", withExtension: "mp3")!)
  
  @State var allSampleData: [SampleData] = []
  @State var allRenderSamples: Range<Int> = 0..<1
  
  @State var sampleCapacity: Int = 0
  @State var renderSamples: Range<Int> = 0..<1
  @State var sampleData: [SampleData] = []
  @State var audioBuffer: AVAudioPCMBuffer?
  @State var selectedSamples = 0..<1
  
  // changes when wave is zoomed or panned
  @State var waveBeginDisplayOffset: Double = 0
  @State var waveEndDisplayOffset: Double = 1
  
  @State var appeared: Bool = false
  
  @State var audioEngine: AVAudioEngine = .init()
  @State var audioPlayer: AVAudioPlayerNode = .init()
  
  // MARK: - View
  
  var body: some View {
    
    NavigationStack {
      GeometryReader { geo in
        VStack(spacing: 0) {
          Spacer(minLength: 0)
          
          // main waveform
          Waveform(selectedSamples: $selectedSamples,
                   sampleData: $sampleData,
                   renderSamples: $renderSamples,
                   audioBuffer: $audioBuffer,
                   geo: geo)
          .padding(.horizontal, geo.safeAreaInsets.leading != 0 ? Handle.radius : 0)
                              
          Spacer(minLength: 0)
          
          // mini waveform
          GeometryReader { geo in
            MiniWaveform(selectedSamples: $selectedSamples,
                         start: $waveBeginDisplayOffset,
                         end: $waveEndDisplayOffset,
                         sampleData: allSampleData,
                         renderSamples: $allRenderSamples,
                         inViewRenderSamples: $renderSamples,
                         audioBuffer: $audioBuffer,
                         geometry: geo,
                         backgroundColor: Color(uiColor: .secondarySystemBackground))
          }
          .cornerRadius(2)
          .padding(3)
          .clipped()
          .overlay {
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 3))
          }
          .foregroundColor(.blue)
          .padding(.horizontal)
          .frame(width: min(400, geo.size.width * 0.7),
                 height: max(UIDevice.current.userInterfaceIdiom == .phone ? 45 : 55, geo.size.height * 0.055))
          
          Spacer(minLength: 0)
        }
        .onAppear { 
          setSampleData(width: geo.size.width)
        }
        .onChange(of: geo.size) { newValue in
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if newValue == geo.size {
              setSampleData(width: newValue.width)
            }
          }
        }
        .onChange(of: $renderSamples.wrappedValue) { onRenderSamplesChange(newValue: $0, width: geo.size.width) }
        .onChange(of: $waveBeginDisplayOffset.wrappedValue, perform: onDisplayBeginChange)
        .onChange(of: $waveEndDisplayOffset.wrappedValue, perform: onDisplayEndChange)
      }
    }
  }
  
  // MARK: - Reactive update Methods
  
  func setSampleData(width: CGFloat) {
    let wasAppeared = $appeared.wrappedValue
    if !wasAppeared {
      appeared = true
      let capacity = AVAudioFrameCount(audioFile.length)
      let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: capacity)!
      try? audioFile.read(into: audioBuffer)
      self.audioBuffer = audioBuffer
      self.sampleCapacity = Int(capacity)
      
      selectedSamples = 0 ..< Int(capacity)
    }
    
    GenerateTask.resume(audioBuffer: self.audioBuffer!,
                         width: width,
                         renderSamples: 0..<Int(self.sampleCapacity)) { sampleData in
      if !wasAppeared {
        self.renderSamples = 0..<Int(self.sampleCapacity)
        allRenderSamples = 0..<Int(self.sampleCapacity)
      }
      
      self.sampleData = sampleData
      self.allSampleData = sampleData
    }
  }
  
  func onRenderSamplesChange(newValue: Range<Int>, width: CGFloat) {
    waveBeginDisplayOffset = Double(newValue.lowerBound) / Double($audioBuffer.wrappedValue?.frameLength ?? .zero)
    waveEndDisplayOffset = Double(newValue.upperBound) / Double($audioBuffer.wrappedValue?.frameLength ?? .zero)
    
    GenerateTask.resume(audioBuffer: $audioBuffer.wrappedValue!,
                        width: width,
                        renderSamples: $renderSamples.wrappedValue) { sampleData in
      self.sampleData = sampleData
    }
  }
  
  func onDisplayBeginChange(newValue: Double) {
    let sample = Int(newValue * Double($audioBuffer.wrappedValue?.frameLength ?? .zero))
    let startSample = sample < $renderSamples.wrappedValue.upperBound ? sample : $renderSamples.wrappedValue.upperBound - 1
    renderSamples = startSample..<$renderSamples.wrappedValue.upperBound
  }
  
  func onDisplayEndChange(newValue: Double) {
    let newValue = min(newValue, 1)
    let sample = Int(newValue * Double($audioBuffer.wrappedValue?.frameLength ?? .zero))
    let endSample = sample > $renderSamples.wrappedValue.lowerBound ? sample : $renderSamples.wrappedValue.lowerBound + 1
    renderSamples = $renderSamples.wrappedValue.lowerBound..<endSample
  }
}
