//
//  BoundingBox.swift
//  GolfBallDetector
//
//  Created by Dailey, Matthew on 8/9/22.
//

import Foundation
import CoreML
import Vision

struct IdentifiableBoundingBox: Identifiable {
    var id = UUID()
    let CGRect: CGRect
}
