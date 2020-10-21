//
//  SCNGeometrySource+.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//

import SceneKit

extension SCNGeometrySource {
    convenience init(texcoord vectors: [SIMD2<Float>]) {
        self.init(
            data: Data(bytes: vectors, count: vectors.count * MemoryLayout<SIMD2<Float>>.size),
            semantic: .texcoord,
            vectorCount: vectors.count,
            usesFloatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SIMD2<Float>>.size
        )
    }
    
    convenience init(colors vectors: [SCNVector3]) {
        self.init(
            data: Data(bytes: vectors, count: vectors.count * MemoryLayout<SCNVector3>.size),
            semantic: .color,
            vectorCount: vectors.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.size
        )
    }
}
