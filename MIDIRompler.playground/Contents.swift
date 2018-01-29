import UIKit
import AVFoundation
import PlaygroundSupport

// create engine
let engine = AVAudioEngine()
// create units
let sampler = AVAudioUnitSampler()
let delay = AVAudioUnitDelay()
let reverb = AVAudioUnitReverb()
let format = engine.mainMixerNode.inputFormat(forBus: 0)
// connect units
engine.attach(sampler)
engine.attach(delay)
engine.attach(reverb)
engine.connect(sampler, to: delay, format: format)
engine.connect(delay, to: reverb, format: format)
engine.connect(reverb, to: engine.mainMixerNode, format: format)
// set parameters
delay.wetDryMix = 50
delay.delayTime = 0.07
delay.feedback = 10
reverb.wetDryMix = 50
reverb.loadFactoryPreset(.largeHall)
// the soundfont file is in the folder Resources (tap the + sign to see it)
Bundle.allBundles
let url : URL! = Bundle.main.url(forResource: "Crysrhod", withExtension: "sf2")
try sampler.loadInstrument(at: url)
// start engine
try engine.start()

// create midi access (a kind of WebMIDI interface)
let midi = MIDIAccess()

// callback to process incoming midi messages
func receive(ev : MIDIEvent) -> () {
    DispatchQueue.main.sync { // callback is called in a different thread
        // send midi message to sampler
        sampler.sendMIDIEvent(ev.data[0], data1: ev.data[1],data2: ev.data[2])
    }
}

// set the callback for all inputs
midi.inputs.forEach {
    $0.value.onMIDIMessage = receive
}

// create log view
let textview = UITextView(frame: CGRect(x: 0, y: 60, width: 600, height: 600))
textview.isEditable = false

// called if a port is added or removed 
midi.onStateChange = { (noti: MIDIPortNotification, port: MIDIPort) -> () in
    textview.text = textview.text + "\(noti)\n"
    switch noti {
    case .added:
        textview.text = textview.text + "port:\(port.displayName)\n"
        if port.type == .input {
            (port as! MIDIInput).onMIDIMessage = receive
        }
    case .removed:
        textview.text = textview.text + "port:\(port.displayName)\n"
    }
 }


let noteOnMsg : [UInt8] = [0x90,0x40,100]
let noteOffMsg : [UInt8] = [0x80,0x40,100]

class Responder : NSObject {
    @objc func noteOn() {
        // broadcast noteOn
        midi.outputs.forEach { 
             $0.value.send(noteOnMsg)
        }
    }
    @objc func noteOff() {
        // broadcast noteOff
        midi.outputs.forEach { 
            $0.value.send(noteOffMsg)
        }
    }
}

// set the interface
let containerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 600.0, height: 600.0))
PlaygroundPage.current.liveView = containerView
let responder = Responder()

let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
button.backgroundColor = UIColor.green
button.setTitle("Play", for: .normal)
button.addTarget(responder, action: #selector(Responder.noteOn), for: .touchDown)
button.addTarget(responder, action: #selector(Responder.noteOff), for: .touchUpInside)

containerView.addSubview(button)
containerView.addSubview(textview)

// keep playground running
PlaygroundPage.current.needsIndefiniteExecution = true

