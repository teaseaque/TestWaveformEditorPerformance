//
//  SampleData.swift
//  TestWaveformEditorPerformance
//
//  Created by Tom Kane on 6/13/24.
//

import Foundation

public typealias SampleRange = Range<Int>

struct SampleData: Identifiable, Codable, Equatable, Hashable {
  var id = UUID()
  var index: Int
  var min: Float
  var max: Float
    
  static func zero(_ index: Int) -> SampleData {
    return SampleData(index: index, min: 0, max: 0)
  }
}
