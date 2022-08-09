//
//  ContentViewModel.swift
//  GolfBallDetector
//
//  Created by Dailey, Matthew on 8/7/22.
//

import Foundation
import CoreImage

class CameraViewModel: ObservableObject {

    @Published var frame: CGImage?

    private let frameManager = FrameManager.shared
    private let context = CIContext()

    init() {
        setupSubscriptions()
    }

    func setupSubscriptions() {
        frameManager.$current
          .receive(on: RunLoop.main)
          .compactMap { buffer in
              if let buffer = buffer {
                  let ciImage = CIImage(cvImageBuffer: buffer)
                  return self.context.createCGImage(ciImage, from: ciImage.extent)
              }
              return nil
          }
          .assign(to: &$frame)
    }
}
