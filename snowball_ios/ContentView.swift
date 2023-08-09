//
//  ContentView.swift
//  snowball_ios
//
//  Created by 신정연 on 2023/06/15.
//

import SwiftUI
import SpriteKit
import CoreMotion

struct ContentView: View {
    var body: some View {
        ZStack {
            SpriteView(scene: SnowballScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)))
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .ignoresSafeArea()
            Image("background")
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
                .opacity(0.5)
        }
        .statusBar(hidden: true)
    }
}

class SnowballScene: SKScene {
    private var snowfall: [SKSpriteNode] = []
    private var motionManager: CMMotionManager? = CMMotionManager()
    private let maxSnowflakes = 30
//    private let floorPositionY = UIScreen.main.bounds.height * 0.1
    private let floorPositionY = 0.0
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .clear
        scaleMode = .aspectFill
        createSnowfall()
        setupGravity()
        createScreenBoundary()
    }
    
    private func createSnowfall() {
        let spawnAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                self?.spawnSnowflake()
            }
        ])
        
        let spawnForeverAction = SKAction.repeatForever(spawnAction)
        run(spawnForeverAction)
    }
    
    private func spawnSnowflake() {
        if snowfall.count >= maxSnowflakes {
            return
        }
        
        let snow = SKSpriteNode(imageNamed: "snow2")
        snow.size = CGSize(width: 20, height: 20)
        snow.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
        snow.blendMode = .alpha
        snowfall.append(snow)
        addChild(snow)
        
        let moveAction = SKAction.moveTo(y: floorPositionY, duration: 3.0)
        let stopAction = SKAction.run { [weak self] in
            snow.physicsBody?.collisionBitMask = 1
            snow.physicsBody?.fieldBitMask = 1
//            snow.physicsBody?.isResting = true
            self?.applyGravityToSnowflake(snow)
        }
        let sequenceAction = SKAction.sequence([moveAction, stopAction])
        snow.run(sequenceAction)
    }
    private func applyGravityToSnowflake(_ snowflake: SKSpriteNode) {
        snowflake.physicsBody = SKPhysicsBody(circleOfRadius: snowflake.size.width / 2)
        snowflake.physicsBody?.affectedByGravity = false
        snowflake.physicsBody?.allowsRotation = true
        snowflake.physicsBody?.mass = 0.05
        snowflake.physicsBody?.friction = 0.2//마찰력
        snowflake.physicsBody?.restitution = 0.4//탄성
        snowflake.physicsBody?.angularDamping = 0//회전속도
        snowflake.physicsBody?.linearDamping = 0//직선속도
        snowflake.physicsBody?.collisionBitMask = 0x1 << 1 // 화면 경계와 충돌
        snowflake.physicsBody?.contactTestBitMask = 0x1 << 1 // 화면 경계와의 접촉을 감지
    }
    
    private func createScreenBoundary() {
        let screenBoundary = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody = screenBoundary
        self.physicsBody?.isDynamic = false
    }
    
    private func setupGravity() {
        motionManager?.accelerometerUpdateInterval = 0.005
        motionManager?.startAccelerometerUpdates(to: OperationQueue.current!) { [weak self] (data, error) in
            guard let accelerometerData = data?.acceleration, let self = self else {
                return
            }
            let gravityX = CGFloat(accelerometerData.x) * 70
            let gravityY = CGFloat(accelerometerData.y) * 70

            for snowflake in self.snowfall {
                if let mass = snowflake.physicsBody?.mass {
                    let force = CGVector(dx: gravityX * mass, dy: gravityY * mass)
                    snowflake.physicsBody?.applyForce(force)
                }
            }
        }
    }
}
