//
//  ContentView.swift
//  GolfBallDetector
//
//  Created by Dailey, Matthew on 8/7/22.
//

import SwiftUI
import Vision

struct CameraView<T: CameraViewModelProtocol>: View {
    
    @ObservedObject var viewModel: T
    
    var body: some View {
        if let image = viewModel.currentFrame {
            GeometryReader { geometry in
                ZStack {
                    Image(decorative: image, scale: 1.0)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            alignment: .center)
                        .clipped()
                    
                    if let boundingBoxes = viewModel.boundingBoxes {
                        ForEach(boundingBoxes) { boundingBox in
                            let rect = viewModel.flipAndNormalizeRect(rect: boundingBox.CGRect, width: geometry.size.width, height: geometry.size.height)
                            Rectangle()
                                .path(in: rect)
                                .stroke(Color.green, lineWidth: 2.0)
                        }
                    }
                }
            }
        }
    }
}
