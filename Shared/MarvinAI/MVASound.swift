//
//  MVASound.swift
//  (un)Predictable
//
//  Created by Majo on 17/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//
import SpriteKit
#if os(iOS) || os(tvOS) || os(macOS)
    class MVASound {
        private let normalCarSound = SKAudioNode(fileNamed: "SUV_steady_low_rpm")
        private let startCarSound = SKAction.playSoundFileNamed("SUV_ignition_02", waitForCompletion: false)
        private let indicatorSound = SKAction.playSoundFileNamed("Grand_Tourer_signal_lights_loop", waitForCompletion: false)
        private let crashSound = SKAction.playSoundFileNamed("crash", waitForCompletion: false)
        
        func playerSound(_ car: SKNode) {
            normalCarSound.isPositional = true
            normalCarSound.position = car.position
            normalCarSound.zPosition = car.zPosition
            normalCarSound.autoplayLooped = true
            car.addChild(self.normalCarSound)
        }
        
        func ignite(node: SKNode) {
            if !MVAMemory.audioMuted {
                if node.action(forKey: "iG") == nil {
                    node.run(startCarSound, withKey: "iG")
                }
            }
        }
        
        func indicate(onNode node: SKNode) {
            if !MVAMemory.audioMuted {
                if node.action(forKey: "iS") == nil {
                    node.run(indicatorSound, withKey: "iS")
                }
            }
        }
        
        func crash(onNode node: SKNode) {
            if !MVAMemory.audioMuted {
                node.run(crashSound)
            }
        }
    }
#elseif os(watchOS)
    class MVASound {
        func playerSound(_ car: SKNode) {
        }
        
        func ignite(node: SKNode) {
        }
        
        func indicate(onNode node: SKNode) {
        }
        
        func crash(onNode node: SKNode) {
        }
    }
#endif
