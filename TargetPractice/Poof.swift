//
//  Poof.swift
//  TargetPractice
//
//  Created by John Haney on 10/19/24.
//

import Foundation
import RealityKit

struct Poofable: Component {}

struct Poof: System {
    let poofables = EntityQuery(where: .has(Poofable.self))
    init(scene: Scene) {
        for entity in scene.performQuery(poofables) {
            if entity.position.y < 0 {
                entity.removeFromParent()
            }
        }
    }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: poofables, updatingSystemWhen: .rendering) {
            if entity.position.y < 0 {
                entity.removeFromParent()
            }
        }
    }
}
