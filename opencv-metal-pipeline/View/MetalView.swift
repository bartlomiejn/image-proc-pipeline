//
//  MetalView.swift
//  opencv-metal-pipeline
//
//  Created by Bartłomiej Nowak on 25.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

import UIKit
import MetalKit
import AVFoundation

final class MetalView: UIView {
    
    struct DefaultLibrarySetupFailure: Error {}
    struct PipelineStateSetupFailure: Error {}
    struct TextureSizeBufferSetupFailure: Error {}
    struct TextureSizeBufferContentsUpdateFailure: Error {}
    
    private enum Constant {
        enum Shader {
            static let vertex = "mapTexture"
            static let fragment = "displayTexture"
        }
        enum Debug {
            static let description = "Frame"
        }
    }
    
    private let metalView: MTKView
    
    private var device: MTLDevice
    private var renderPipelineState: MTLRenderPipelineState!
    private var currentTexture: MTLTexture?
    
    private var textureSizeBuffer: MTLBuffer?
    
    private let drawSemaphore = DispatchSemaphore(value: 1)
    
    init(device: MTLDevice) throws {
        metalView = MTKView(frame: .zero, device: device)
        
        self.device = device
        
        super.init(frame: .zero)
        
        try setupTextureSizeBuffer()
        try setupRenderPipelineState()
        setupVideoView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(_ texture: MTLTexture) {
        do {
            currentTexture = texture
            try updateTextureSizeBuffer()
        } catch {
            handle(error)
        }
    }
    
    private func setupTextureSizeBuffer() throws {
        guard
            let buffer = device.makeBuffer(length: MemoryLayout<Float32>.size * 2, options: .cpuCacheModeWriteCombined)
        else {
            throw TextureSizeBufferSetupFailure()
        }
        
        self.textureSizeBuffer = buffer
    }
    
    private func updateTextureSizeBuffer() throws {
        guard let textureSizeBuffer = textureSizeBuffer, let currentTexture = currentTexture else {
            throw TextureSizeBufferContentsUpdateFailure()
        }
        
        textureSizeBuffer.contents().storeBytes(of: Float32(currentTexture.width), as: Float32.self)
        textureSizeBuffer.contents().storeBytes(of: Float32(currentTexture.height), toByteOffset: MemoryLayout<Float32>.size, as: Float32.self)
    }
    
    private func setupRenderPipelineState() throws {
        guard let library = device.makeDefaultLibrary() else {
            throw DefaultLibrarySetupFailure()
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.sampleCount = 1
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        pipelineDescriptor.vertexFunction = library.makeFunction(name: Constant.Shader.vertex)
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: Constant.Shader.fragment)
        
        do {
            try renderPipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            handle(PipelineStateSetupFailure())
        }
    }
    
    private func setupVideoView() {
        addSubview(metalView)
        
        metalView.delegate = self
        metalView.framebufferOnly = true
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.contentScaleFactor = UIScreen.main.scale
        metalView.backgroundColor = .black
        metalView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            metalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            metalView.topAnchor.constraint(equalTo: topAnchor),
            metalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            metalView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func handle(_ error: Error) {
        print("( ͡° ͜ʖ ͡°) Encountered \(error)")
    }
}

extension MetalView: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        drawSemaphore.wait()
        
        guard
            let currentTexture = currentTexture,
            let commandBuffer = device.makeCommandQueue()?.makeCommandBuffer()
        else {
            drawSemaphore.signal()
            return
        }
        
        render(texture: currentTexture, withCommandBuffer: commandBuffer, device: device)
    }
    
    private func render(texture: MTLTexture, withCommandBuffer commandBuffer: MTLCommandBuffer, device: MTLDevice) {
        guard
            let currentRenderPassDescriptor = metalView.currentRenderPassDescriptor,
            let currentDrawable = metalView.currentDrawable,
            let renderPipelineState = renderPipelineState,
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor),
            let textureSizeBuffer = textureSizeBuffer
        else {
            drawSemaphore.signal()
            return
        }
        
        encoder.pushDebugGroup(Constant.Debug.description)
        
        encoder.setFragmentBuffer(textureSizeBuffer, offset: 0, index: 0)
        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        encoder.popDebugGroup()
        
        encoder.endEncoding()

        commandBuffer.addScheduledHandler { [weak self] buffer in
            self?.drawSemaphore.signal()
        }
        
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}
