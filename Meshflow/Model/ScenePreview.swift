//
//  ScenePreview.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import SceneKit
import SwiftUI

struct ScenePreview: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .systemBackground
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        view.scene = ConverterService.loadPreviewScene(from: url)
    }
}
