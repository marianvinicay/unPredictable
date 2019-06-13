//
//  GameScene_Sound.swift
//  unPredictable
//
//  Created by Marian Vinicay on 17/07/2017.
//  Copyright © 2017 Marvin. All rights reserved.
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
        intel.sound.playerSound(intel.player)
        fadeInVolume()
    }
    
    func setVolume(_ vol: Float) {
        if !MVAMemory.audioMuted {
            audioEngine.mainMixerNode.outputVolume = vol
        } else {
            audioEngine.mainMixerNode.outputVolume = 0.0
        }
    }
    
    @objc func fadeInVolume() {
        if !MVAMemory.audioMuted {
            if self.audioEngine.mainMixerNode.outputVolume < 1.0 {
                self.audioEngine.mainMixerNode.outputVolume += 0.1
                self.perform(#selector(fadeInVolume), with: nil, afterDelay: 0.2)
            } else {
                self.audioEngine.mainMixerNode.outputVolume = 1.0
            }
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
