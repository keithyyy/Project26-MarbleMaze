//
//  GameScene.swift
//  Project26
//
//  Created by Keith Crooc on 2022-01-31.
//
import CoreMotion
import SpriteKit


enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
}

class GameScene: SKScene, SKPhysicsContactDelegate {
//    need to have our gameScene class form to SKPhysicsDelegate
    
    
    var player: SKSpriteNode!
    
    var scoreLabel: SKLabelNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var isGameOver = false
    
    
//    for our simulator
    var lastTouchPosition: CGPoint?
    
//    for the accelerometer
    var motionManager: CMMotionManager!
    
    override func didMove(to view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.position = CGPoint(x: 20, y: 20)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
        loadLevel()
        createPlayer()
        
        
//        if you run the game so far, it'll just drop down to bottom. That's cause it's following earth's gravity.
//        we're gonna make it stick to the wall as if the background is the floor.
        physicsWorld.gravity = .zero
        
//        call on our motionManager to start collecting data about the device's accelerometer
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
        
//        we need to find whenever player collides with a star or vice versa.
//        we'll need to be the delegators of that
        physicsWorld.contactDelegate = self
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    
//    for our simulator hack to not need an accelerometer
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        if let currentTouch = lastTouchPosition {
            let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x/100, dy: diff.y/100)
        }
        #else
        if let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
            
        }
        #endif
    }
    
//    creating our marble aka our player
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.zPosition = 1
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
//        ball is shiny, and we don't want shadows to rotate.
        player.physicsBody?.allowsRotation = false
//        this is gonna help slow down our ball a bit more, adding some friction to it.
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
//        we want to know everytime our player marble gets in touch with a star
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue
//        we also want our marble to bump into the wall.
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        
        addChild(player)
    }
    
//    function to do things to player when it collides with certain object
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])
            
            player.run(sequence) {
                [weak self] in
                self?.createPlayer()
                self?.isGameOver = false
            }
            
        } else if node.name == "star" {
            node.removeFromParent()
            score += 1
        } else if node.name == "finish" {
//            next level code
        }
    }
    
    
    func loadLevel() {
        guard let levelURL = Bundle.main.url(forResource: "level1", withExtension: "txt") else { fatalError("Couldn't find level1.txt in the app bundle") }
        
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Couldn't load level1.txt from the app bundle")
        }
        
        let lines = levelString.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated() {
            for (col, letter) in line.enumerated() {
//                plus 32 because y starts from centre
                let position = CGPoint(x: (64 * col), y: (64 * row) + 32)
                
                if letter == "x" {
//                        load a wall
                    let node = SKSpriteNode(imageNamed: "block")
                    node.position = position
                    
                    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                    node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
//                    not dynamic because it's fixed
                    node.physicsBody?.isDynamic = false
                    addChild(node)
                    
                    
                } else if letter == "v" {
//                 load vortex
                    let node = SKSpriteNode(imageNamed: "vortex")
                    node.position = position
                    node.name = "vortex"
                    
//                    we're going to animate this a bit. Have it spin
                    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    
                    node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
//                    get notified whenever it touches a player
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    addChild(node)
                } else if letter == "s" {
//                    load star
                    let node = SKSpriteNode(imageNamed: "star")
                    node.position = position
                    
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    
                    node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    node.name = "star"
                    
                    addChild(node)
                    
                } else if letter == "f" {
//                    load finish
                    let node = SKSpriteNode(imageNamed: "finish")
                    node.name = "finish"
                    
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    
                    node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    
                    node.position = position
                    addChild(node)
                    
                } else if letter == " " {
                    
                } else {
                    fatalError("unknown level letter: \(letter)")
                }
            }
        }
    }
    
    
}
