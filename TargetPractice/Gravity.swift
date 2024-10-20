//
//  Gravity.swift
//  TargetPractice
//
//  Created by John Haney on 10/14/24.
//

import Foundation
import RealityKit

struct Gravity: ForceEffectProtocol {
    var parameterTypes: PhysicsBodyParameterTypes { [.position] }
    var forceMode: ForceMode = .force
    
    func update(parameters: inout ForceEffectParameters) {
        for i in 0 ..< parameters.physicsBodyCount {
            parameters.setForce(SIMD3<Float>(0, -100, 0), index: i)
        }
    }
}
