//
//  GolfBallDetectorApp.swift
//  GolfBallDetector
//
//  Created by Dailey, Matthew on 8/7/22.
//

import SwiftUI

@main
struct GolfBallDetectorApp: App {
    
    @StateObject var applicationInstance = ApplicationInstance()
    
    var body: some Scene {
        WindowGroup {
            CameraView(viewModel: CameraViewModel(cameraManager: applicationInstance.cameraManager))
                .environmentObject(applicationInstance)
        }
    }
}

final class ApplicationInstance: ObservableObject {
    
    // MARK: - Managers
    
    lazy var cameraManager: CameraManager = CameraManager()
}
