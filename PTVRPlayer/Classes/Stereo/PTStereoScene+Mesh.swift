//
//  PTStereoScene+Mesh.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//
import SceneKit

extension PTStereoScene {
    func computeMeshPoints(with parameters: StereoParametersProtocol, width: Int, height: Int) -> (vertices: [SCNVector3], texcoord: [SIMD2<Float>]) {
        let viewer = parameters.viewer
        let screen = parameters.screen
        
        var lensFrustum = parameters.leftEyeVisibleTanAngles
        var noLensFrustum = parameters.leftEyeNoLensVisibleTanAngles
        var viewport = parameters.leftEyeVisibleScreenRect
        
        let count = 2 * width * height
        var vertices: [SCNVector3] = Array(repeating: SCNVector3Zero, count: count)
        var texcoord: [SIMD2<Float>] = Array(repeating: SIMD2(), count: count)
        var vid = 0
        
        func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
            return a + t * (b - a)
        }
        
        for e in 0..<2 {
            for j in 0..<height {
                for i in 0..<width {
                    defer { vid += 1 }
                    
                    var u = Float(i) / Float(width - 1)
                    var v = Float(j) / Float(height - 1)
                    var s = u
                    var t = v
                    
                    let x = lerp(lensFrustum[0], lensFrustum[2], u)
                    let y = lerp(lensFrustum[3], lensFrustum[1], v)
                    let d = sqrt(x * x + y * y)
                    let r = viewer.distortion.distortInv(d)
                    let p = x * r / d
                    let q = y * r / d
                    
                    u = (p - noLensFrustum[0]) / (noLensFrustum[2] - noLensFrustum[0])
                    v = (q - noLensFrustum[3]) / (noLensFrustum[1] - noLensFrustum[3])
                    
                    u = (Float(viewport.origin.x) + u * Float(viewport.size.width) - 0.5) * screen.aspectRatio
                    v = Float(viewport.origin.y) + v * Float(viewport.size.height) - 0.5
                    
                    vertices[vid] = SCNVector3(u, v, 0)
                    
                    s = (s + Float(e)) / 2
                    t = 1 - t // flip vertically
                    
                    texcoord[vid] = SIMD2(s, t)
                }
            }
            
            var w: Float
            w = lensFrustum[2] - lensFrustum[0]
            lensFrustum[0] = -(w + lensFrustum[0])
            lensFrustum[2] = w - lensFrustum[2]
            w = noLensFrustum[2] - noLensFrustum[0]
            noLensFrustum[0] = -(w + noLensFrustum[0])
            noLensFrustum[2] = w - noLensFrustum[2]
            
            viewport.origin.x = 1 - (viewport.origin.x + viewport.size.width)
        }
        
        return (vertices, texcoord)
    }
    
    func computeMeshColors(width: Int, height: Int) -> [SCNVector3] {
        let count = 2 * width * height
        var colors: [SCNVector3] = Array(repeating: SCNVector3(1, 1, 1), count: count)
        var vid = 0
        
        for _ in 0..<2 {
            for j in 0..<height {
                for i in 0..<width {
                    defer { vid += 1 }
                    
                    if i == 0 || j == 0 || i == (width - 1) || j == (height - 1) {
                        colors[vid] = SCNVector3Zero
                    }
                }
            }
        }
        
        return colors
    }
    
    func computeMeshIndices(width: Int, height: Int) -> [Int16] {
        let halfWidth = width / 2
        let halfHeight = height / 2
        
        var indices: [Int16] = []
        var vid = 0
        
        for _ in 0..<2 {
            for j in 0..<height {
                for i in 0..<width {
                    defer { vid += 1 }
                    
                    if i == 0 || j == 0 {
                        // do nothing
                    } else if (i <= halfWidth) == (j <= halfHeight) {
                        indices.append(Int16(vid))
                        indices.append(Int16(vid - width))
                        indices.append(Int16(vid - width - 1))
                        indices.append(Int16(vid - width - 1))
                        indices.append(Int16(vid - 1))
                        indices.append(Int16(vid))
                    } else {
                        indices.append(Int16(vid - 1))
                        indices.append(Int16(vid))
                        indices.append(Int16(vid - width))
                        indices.append(Int16(vid - width))
                        indices.append(Int16(vid - width - 1))
                        indices.append(Int16(vid - 1))
                    }
                }
            }
        }
        
        return indices
    }
}
