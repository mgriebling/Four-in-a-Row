//
//  Board.swift
//  Project34
//
//  Created by Google AI on 13.11.2026.
//

import SwiftUI
import SpriteKit
import Observation

struct SpriteBallDropView: View {
	let isLandscape: Bool
	let ballColors: [UIColor]
	
	@State private var scene = BallDropScene()
	
	var body: some View {
		ZStack {
			HStack {
				VStack {
					// Reset Button
					Button {
						scene.resetAllBalls()
					} label: {
						Text("Reset Board")
							.font(.headline)
							.padding()
							.background(scene.totalDropped > 0 ? Color.blue : Color.gray.opacity(0.4))
							.foregroundColor(.white)
							.cornerRadius(10)
					}
					.frame(maxWidth: .infinity)
					.disabled(scene.totalDropped == 0)
					Button {
						scene.dropBall(inContainer: 0)
					} label: {
						Text("Drop ball")
					}
					.padding()
					.frame(maxWidth: .infinity)
					.background(Color.blue)
					.foregroundColor(.white)
					.cornerRadius(10)
					
					Group {
						if !isLandscape {
							Spacer()
							Text("Tap any container to add a ball")
						} else {
							Text("Tap any container\nto add a ball")
								.multilineTextAlignment(.center)
						}
					}
					.font(.subheadline)
					.foregroundColor(.secondary)
				}
				.fixedSize(horizontal: true, vertical: false)
				if isLandscape {
					Spacer()
				}
			}
			
			// Interactive 7-container SpriteKit scene
			SpriteView(scene: scene, options: [.allowsTransparency])
				.frame(maxWidth: .infinity)
				.aspectRatio(1, contentMode: .fit)
				.onAppear {
					scene.setBall(colors: ballColors)
				}
		}
	}
}

@Observable
class BallDropScene: SKScene {
	var totalDropped = 0
	let containerCount = 7
	let maxBallsPerContainer = 7
	var maxBalls: Int { containerCount * maxBallsPerContainer }

	private var balls: [SKShapeNode] = []
	private var containerCenters: [CGFloat] = []
	private var containerWidth: CGFloat = 0
	private var columnCounts: [Int] = []

	private var ballColors: [UIColor] = [
		.systemBlue, .systemRed
	]
	
	func setBall(colors: [UIColor]) {
		self.ballColors = colors
	}

	override func didMove(to view: SKView) {
		// Prevent duplicate setup if SwiftUI re-renders the view
		guard containerCenters.isEmpty else { return }

		size = CGSize(width: 900, height: 900)
		scaleMode = .aspectFit
		backgroundColor = .clear

		physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
		columnCounts = Array(repeating: 0, count: containerCount)

		setupSevenContainers()
		setupBalls()
	}

	private func setupSevenContainers() {
		let horizontalPadding: CGFloat = 16
		let spacing: CGFloat = 0
		let wallWidth: CGFloat = 5
		// Increased wall height to hold 7 stacked balls cleanly
		let wallHeight: CGFloat = 800

		let availableWidth = size.width - (horizontalPadding * 2) - (spacing * CGFloat(containerCount - 1))
		let innerWidth = availableWidth / CGFloat(containerCount)
		containerWidth = innerWidth + spacing

		for i in 0..<containerCount {
			let centerX = horizontalPadding + (innerWidth / 2) + CGFloat(i) * (innerWidth + spacing)
			containerCenters.append(centerX)

			addCurvedContainer(
				centerX: centerX,
				innerWidth: innerWidth,
				wallHeight: wallHeight,
				wallWidth: wallWidth,
				baseY: 25
			)
		}
	}

	private func addCurvedContainer(
		centerX: CGFloat,
		innerWidth: CGFloat,
		wallHeight: CGFloat,
		wallWidth: CGFloat,
		baseY: CGFloat
	) {
		let halfWidth = innerWidth / 2
		let curveRadius = halfWidth
		let topY = baseY + wallHeight
		let curveCenterY = baseY + curveRadius

		// 1. Visual U-shaped curved path
		let path = CGMutablePath()
		path.move(to: CGPoint(x: centerX - halfWidth, y: topY))
		path.addLine(to: CGPoint(x: centerX - halfWidth, y: curveCenterY))
		path.addArc(
			center: CGPoint(x: centerX, y: curveCenterY),
			radius: curveRadius,
			startAngle: .pi,
			endAngle: 0,
			clockwise: false
		)
		path.addLine(to: CGPoint(x: centerX + halfWidth, y: topY))

		let containerNode = SKShapeNode(path: path)
		containerNode.strokeColor = UIColor.systemGray
		containerNode.lineWidth = wallWidth
		containerNode.lineCap = .round
		containerNode.fillColor = .clear
		addChild(containerNode)

		// 2. Inset physics collision boundary
		let physicsRadius = curveRadius - (wallWidth / 2)
		let physicsPath = CGMutablePath()
		physicsPath.move(to: CGPoint(x: centerX - physicsRadius, y: topY))
		physicsPath.addLine(to: CGPoint(x: centerX - physicsRadius, y: curveCenterY))
		physicsPath.addArc(
			center: CGPoint(x: centerX, y: curveCenterY),
			radius: physicsRadius,
			startAngle: .pi,
			endAngle: 0,
			clockwise: false
		)
		physicsPath.addLine(to: CGPoint(x: centerX + physicsRadius, y: topY))

		let physicsContainer = SKNode()
		let body = SKPhysicsBody(edgeChainFrom: physicsPath)
		body.restitution = 0.2
		body.friction = 0.15
		physicsContainer.physicsBody = body
		addChild(physicsContainer)
	}

	private func setupBalls() {
		let radius: CGFloat = 57

		for i in 0..<maxBalls {
			let circle = SKShapeNode(circleOfRadius: radius)
			circle.fillColor = ballColors[i % ballColors.count]
			circle.strokeColor = .clear

			let body = SKPhysicsBody(circleOfRadius: radius)
			body.isDynamic = false
			body.restitution = 0.65
			body.friction = 0.2
			body.linearDamping = 0.1
			circle.physicsBody = body

			balls.append(circle)
			addChild(circle)
		}

		resetAllBalls()
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		let location = touch.location(in: self)

		if let closestIndex = containerCenters.enumerated().min(by: {
			abs($0.element - location.x) < abs($1.element - location.x)
		})?.offset {
			let distanceFromCenter = abs(containerCenters[closestIndex] - location.x)
			if distanceFromCenter <= containerWidth / 2 {
				dropBall(inContainer: closestIndex)
			}
		}
	}

	func dropBall(inContainer index: Int) {
		guard totalDropped < maxBalls,
			  columnCounts[index] < maxBallsPerContainer else { return }

		let ball = balls[totalDropped]
		let dropY = size.height - 35

		ball.position = CGPoint(x: containerCenters[index], y: dropY)
		ball.isHidden = false
		ball.physicsBody?.velocity = .zero
		ball.physicsBody?.angularVelocity = 0
		ball.physicsBody?.isDynamic = true

		columnCounts[index] += 1
		totalDropped += 1
	}

	func resetAllBalls() {
		totalDropped = 0
		columnCounts = Array(repeating: 0, count: containerCount)

		for ball in balls {
			ball.isHidden = true
			ball.physicsBody?.isDynamic = false
			ball.physicsBody?.velocity = .zero
			ball.physicsBody?.angularVelocity = 0
		}
	}
}

#Preview {
	SpriteBallDropView(isLandscape: true, ballColors: [.systemPink, .systemCyan])
}
