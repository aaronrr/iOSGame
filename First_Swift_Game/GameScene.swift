//
//  GameScene.swift
//  First_Swift_Game
//
//  Created by Aaron Robeson on 3/7/16.
//  Copyright (c) 2016 Aaron Robeson. All rights reserved.
//

import SpriteKit

struct PhysicsCategory {
	static let None      : UInt32 = 0
	static let All       : UInt32 = UInt32.max
	static let Monster   : UInt32 = 0b1       // 1
	static let Projectile: UInt32 = 0b10      // 2
}


func + (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
	return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
	return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
	return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
	func length() -> CGFloat {
		return sqrt(x*x + y*y)
	}
 
	func normalized() -> CGPoint {
		return self / length()
	}
}


class GameScene: SKScene, SKPhysicsContactDelegate {
	// 1
	let player = SKSpriteNode(imageNamed: "med")
	
	var monstersDestroyed = 0
	
	let myLabel1 = SKLabelNode(fontNamed:"Arial")
	
	override func didMoveToView(view: SKView) {
		// 2
		backgroundColor = SKColor.whiteColor()
		
		
		let myLabel = SKLabelNode(fontNamed:"Arial")
		myLabel.text = "Trump Dick Shooter!"
		myLabel.fontColor = UIColor.blackColor()
		myLabel.fontSize = 45
		myLabel.position = CGPoint(x:size.width * 0.5, y:size.height * 0.8)
		
		self.addChild(myLabel)
		
		myLabel1.text = "Dick Count: 0"
		myLabel1.fontColor = UIColor.blackColor()
		myLabel1.fontSize = 30
		myLabel1.position = CGPoint(x:size.width * 0.8, y:size.height * 0.1)
		
		self.addChild(myLabel1)
		
		// 3
		player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
		// 4
		addChild(player)
		runAction(SKAction.repeatActionForever(
			SKAction.sequence([SKAction.runBlock(addMonster), SKAction.waitForDuration(1.0)])
		))
		physicsWorld.gravity = CGVectorMake(0, 0)
		physicsWorld.contactDelegate = self
		
//		let backgroundMusic = SKAudioNode(fileNamed: "Head-Full-of-Doubt.mp3")
//		backgroundMusic.autoplayLooped = true
//		addChild(backgroundMusic)
	}
	
	func random() -> CGFloat {
		return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
	}
 
	func random(min min: CGFloat, max: CGFloat) -> CGFloat {
		return random() * (max - min) + min
	}
 
	func addMonster() {
		
		// Create sprite
		let monster = SKSpriteNode(imageNamed: "trump4")

		monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size) // 1
		monster.physicsBody?.dynamic = true // 2
		monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
		monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
		monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
			
		// Determine where to spawn the monster along the Y axis
		let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
			
		// Position the monster slightly off-screen along the right edge,
		// and along a random position along the Y axis as calculated above
		monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
			
		// Add the monster to the scene
		addChild(monster)
			
		// Determine speed of the monster
		let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
			
		// Create the actions
		let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
		let actionMoveDone = SKAction.removeFromParent()
		
		monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
		let loseAction = SKAction.runBlock() {
			let reveal = SKTransition.flipHorizontalWithDuration(0.5)
			let gameOverScene = GameOverScene(size: self.size, won: false)
			self.view?.presentScene(gameOverScene, transition: reveal)
		}
		monster.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		runAction(SKAction.playSoundFileNamed("truishit.m4a", waitForCompletion: false))
		
		// 1 - Choose one of the touches to work with
		guard let touch = touches.first else {
			return
		}
		let touchLocation = touch.locationInNode(self)
			
		// 2 - Set up initial location of projectile
		let projectile = SKSpriteNode(imageNamed: "dick")
		projectile.position = player.position
		
		projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
		projectile.physicsBody?.dynamic = true
		projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
		projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
		projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
		projectile.physicsBody?.usesPreciseCollisionDetection = true
			
		// 3 - Determine offset of location to projectile
		let offset = touchLocation - projectile.position
			
		// 4 - Bail out if you are shooting down or backwards
		if (offset.x < 0) { return }
		
		// 4.1
		projectile.zRotation = atan((touchLocation.y - player.position.y)/(touchLocation.x - player.position.x))
			
		// 5 - OK to add now - you've double checked position
		addChild(projectile)
			
		// 6 - Get the direction of where to shoot
		let direction = offset.normalized()
			
		// 7 - Make it shoot far enough to be guaranteed off screen
		let shootAmount = direction * 1000
			
		// 8 - Add the shoot amount to the current position
		let realDest = shootAmount + projectile.position
			
		// 9 - Create the actions
		let actionMove = SKAction.moveTo(realDest, duration: 2.0)
		let actionMoveDone = SKAction.removeFromParent()
		projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
		
	}
	
	func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
		print("Hit")
		projectile.removeFromParent()
		monster.removeFromParent()
		monstersDestroyed++
		if (monstersDestroyed > 30) {
			let reveal = SKTransition.flipHorizontalWithDuration(0.5)
			let gameOverScene = GameOverScene(size: self.size, won: true)
			self.view?.presentScene(gameOverScene, transition: reveal)
		}
		/////////////////
		myLabel1.text = "Dick Count: " + String(monstersDestroyed)
	}
	
	func didBeginContact(contact: SKPhysicsContact) {
		// 1
		var firstBody: SKPhysicsBody
		var secondBody: SKPhysicsBody
		if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
			firstBody = contact.bodyA
			secondBody = contact.bodyB
		} else {
			firstBody = contact.bodyB
			secondBody = contact.bodyA
		}
			
		// 2
		if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
		(secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
			projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, monster: secondBody.node as! SKSpriteNode)
		}
			
	}
}


