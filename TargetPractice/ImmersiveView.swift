//
//  ImmersiveView.swift
//  TargetPractice
//
//  Created by John Haney on 10/14/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARUnderstanding
import Spatial

struct ImmersiveView: View {
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State var leftHand: Entity = Entity()
    @State var leftFingerTip: Entity = Entity()
    @State var leftBall: ModelEntity?
    
    @State var rightHand: Entity = Entity()
    @State var rightFingerTip: Entity = Entity()
    @State var rightBall: ModelEntity?
    
    @State var collisionWatcher: EventSubscription?
    @State var total: Int = 0
    @State var pointboard: Entity = Entity()
    @State var scoreboard: Entity = Entity()

    var body: some View {
        RealityView { content in
            do {
                let ball = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .magenta, isMetallic: true)])
                ball.collision = try? await CollisionComponent(shapes: [ShapeResource.generateSphere(radius: 0.05)])
                ball.physicsBody = .init(mode: .dynamic)
                self.leftBall = ball
                content.add(ball)
                leftHand.addChild(leftFingerTip)
                content.add(leftHand)
            }
            do {
                let ball = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .cyan, isMetallic: true)])
                ball.collision = try? await CollisionComponent(shapes: [ShapeResource.generateSphere(radius: 0.05)])
                ball.physicsBody = .init(mode: .dynamic)
                self.rightBall = ball
                content.add(ball)
                rightHand.addChild(rightFingerTip)
                content.add(rightHand)
            }
            let material: RealityKit.Material
            if let target = try? await ShaderGraphMaterial(named: "/Root/Target", from: "Immersive", in: realityKitContentBundle) {
                material = target
            } else {
                material = SimpleMaterial(color: .white, roughness: 1, isMetallic: false)
            }
            let mesh = MeshResource.generateCylinder(height: 0.25, radius: 0.5)
            let cylinder = ModelEntity(mesh: mesh, materials: [material])
            cylinder.transform.rotation = .init(angle: .pi/2, axis: .init(x: 1, y: 0, z: 0))
            cylinder.position = .init(x: 0, y: 2, z: -8)
            cylinder.collision = try? await CollisionComponent(shapes: [ShapeResource.generateConvex(from: mesh)], mode: .colliding)
            cylinder.collision?.isStatic = true
            content.add(cylinder)
            
            pointboard.position = [0,3.5,-8]
            content.add(pointboard)
            scoreboard.position = [0,0.5,-8]
            content.add(scoreboard)

            collisionWatcher = content.subscribe(to: CollisionEvents.Began.self, on: cylinder, componentType: nil) { target in
                let position = cylinder.convert(position: target.position, from: nil)
                let x = abs(position.x) / 0.25
                let y = abs(position.z - 1) / 0.25
                let radius = (x * x + y * y).squareRoot()
                print("target hit (\(position.x), \(position.y), \(position.z)) -> (\(x), \(y)) -> radius: \(radius)")
                let points: Int
                switch radius {
                case ...0.2:
                     points = 10
                case ...0.4:
                    points = 8
                case ...0.6:
                    points = 6
                case ...0.8:
                    points = 4
                default:
                    points = 2
                }
                pointboard.removeAllChildren()
                pointboard.addChild(pointEntity(points))
                total += points
                scoreboard.removeAllChildren()
                scoreboard.addChild(scoreEntity())
            }
        }
        .onAppear {
            Poofable.registerComponent()
            Poof.registerSystem()
        }
        .onReceive(timer) { _ in
            if let ball = leftBall?.clone(recursive: true),
               let parent = leftBall?.parent
            {
                ball.components.set(Poofable())
                parent.addChild(ball)
                ball.transform = leftFingerTip.convert(transform: .init(rotation: .init(angle: -.pi/2, axis: SIMD3<Float>(x: 0, y: 0, z: 1))), to: nil)
                let direction = leftFingerTip.convert(direction: [1,0,0], to: nil)
                let action = ImpulseAction(linearImpulse: direction * 10)
                let duration = 1 / 60.0
                guard let animation = try? AnimationResource.makeActionAnimation(for: action, duration: duration, delay: 0)
                else { return }
                ball.playAnimation(animation)
            }
            if let ball = rightBall?.clone(recursive: true),
               let parent = rightBall?.parent {
                ball.components.set(Poofable())
                parent.addChild(ball)
                ball.transform = rightFingerTip.convert(transform: .init(rotation: .init(angle: -.pi/2, axis: SIMD3<Float>(x: 0, y: 0, z: 1))), to: nil)
                let direction = rightFingerTip.convert(direction: [-1,0,0], to: nil)
                let action = ImpulseAction(linearImpulse: direction * 10)
                let duration = 1 / 60.0
                guard let animation = try? AnimationResource.makeActionAnimation(for: action, duration: duration, delay: 0)
                else { return }
                ball.playAnimation(animation)
            }
        }
        .task {
            for await handUpdate in ARUnderstanding.handUpdates {
                let ball: ModelEntity?
                let hand: Entity
                let fingerTip: Entity
                let direction: Float
                switch handUpdate.anchor.chirality {
                case .right:
                    direction = 1
                    ball = rightBall
                    hand = rightHand
                    fingerTip = rightFingerTip
                case .left:
                    direction = -1
                    ball = leftBall
                    hand = leftHand
                    fingerTip = leftFingerTip
                }
                let fingerJoint = handUpdate.anchor.joint(named: .indexFingerTip)
                let fingerKnuckle = handUpdate.anchor.joint(named: .indexFingerTip)
                let vector = Transform(matrix: fingerJoint.anchorFromJointTransform).translation - Transform(matrix: fingerKnuckle.anchorFromJointTransform).translation
                hand.transform = Transform(matrix: handUpdate.anchor.originFromAnchorTransform)
                fingerTip.transform = Transform(matrix: fingerJoint.anchorFromJointTransform)
            }
        }
    }
    
    func scoreEntity() -> Entity {
        let text = MeshResource.generateText(
            total.description,
            extrusionDepth: 0.02,
            font: .monospacedSystemFont(ofSize: 0.28, weight: .regular),
            containerFrame: CGRect(x: 0, y: 0, width: 1, height: 0.5),
            alignment: .center
        )
        
        return ModelEntity(
            mesh: text,
            materials: [SimpleMaterial(color: UIColor.white, isMetallic: false)]
        )
    }
    
    func pointEntity(_ points: Int) -> Entity {
        let text = MeshResource.generateText(
            "+ \(points)",
            extrusionDepth: 0.02,
            font: .monospacedSystemFont(ofSize: 0.28, weight: .regular),
            containerFrame: CGRect(x: 0, y: 0, width: 1, height: 0.5),
            alignment: .center
        )
        
        return ModelEntity(
            mesh: text,
            materials: [SimpleMaterial(color: UIColor.green, isMetallic: false)]
        )
    }
}

import ARKit

extension HandAnchorRepresentable {
    func position(_ name: ARKit.HandSkeleton.JointName) -> SIMD3<Float>? {
        guard let jointMatrix = handSkeleton?.joint(name).anchorFromJointTransform
        else { return nil }
        
        let transform = Transform(matrix: matrix_multiply(originFromAnchorTransform, jointMatrix))
        return transform.translation
    }
}

#Preview(immersionStyle: .progressive) {
    ImmersiveView()
        .environment(AppModel())
}

extension Entity {
    func removeAllChildren() {
        let children = self.children
        for child in children {
            child.removeFromParent()
        }
    }
}
