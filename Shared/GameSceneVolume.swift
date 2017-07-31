//
//  GameSceneVolume.swift
//  (un)Predictable
//
//  Created by Majo on 17/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit
import AVFoundation

extension GameScene {
    func startSound() {
        let listerine = SKNode()
        listener?.position = CGPoint(x: 0.0, y: -self.size.height)
        self.camera!.addChild(listerine)
        self.listener = listerine
        
        self.audioEngine.mainMixerNode.outputVolume = 0.0
        do { try self.audioEngine.start() } catch {}
        sound.playerSound(intel.player)
        fadeInVolume()
    }
    
    func fadeInVolume() {
        if self.audioEngine.mainMixerNode.outputVolume < 1.0 {
            self.audioEngine.mainMixerNode.outputVolume += 0.1
            self.perform(#selector(fadeInVolume), with: nil, afterDelay: 0.2)
        } else {
            self.audioEngine.mainMixerNode.outputVolume = 1.0
        }
    }
    
    func fadeOutVolume() {
        if self.audioEngine.mainMixerNode.outputVolume > 1.0 {
            self.audioEngine.mainMixerNode.outputVolume -= 0.1
            self.perform(#selector(fadeInVolume), with: nil, afterDelay: 0.2)
        } else {
            self.audioEngine.mainMixerNode.outputVolume = 0.0
        }
    }
}
