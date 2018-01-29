//
//  MIDIAccess.swift
//  WebMIDIKit
//
//  Created by Adam Nemecek on 12/7/16.
//
//

import CoreMIDI
import Foundation

@inline(__always) fileprivate
func MIDISources() -> [MIDIEndpoint] {
    return (0..<MIDIGetNumberOfSources()).map {
        .init(ref: MIDIGetSource($0))
    }
}

@inline(__always) fileprivate
func MIDIDestinations() -> [MIDIEndpoint] {
    return (0..<MIDIGetNumberOfDestinations()).map {
        .init(ref: MIDIGetDestination($0))
    }
}

public enum MIDIPortNotification {
    case added, removed
}

public extension Dictionary where Key == MIDIEndpointRef, Value:MIDIPort {
    public func port(with name: String) -> Value? {
        return self.first { $0.value.displayName == name }?.value
    }
}

/// https://www.w3.org/TR/webmidi/#midiaccess-interface
public final class MIDIAccess : CustomStringConvertible, CustomDebugStringConvertible {

    public var ports: [MIDIEndpointRef : MIDIPort] = [:]
    
    public var inputs: [MIDIEndpointRef : MIDIInput] {
        return self.ports.filter { $0.value.type == .input } as! [MIDIEndpointRef : MIDIInput]
    }
    
    public var outputs: [ MIDIEndpointRef : MIDIOutput] {
        return self.ports.filter { $0.value.type == .output } as! [MIDIEndpointRef : MIDIOutput]
    }

    public var onStateChange: ((MIDIPortNotification,MIDIPort) -> ())? = nil

    public init() {
        self._client = MIDIClient()
        
        let dest = MIDIDestinations().map { MIDIOutput(client: self._client, endpoint: $0) }
        dest.forEach {
            self.ports[$0.endpoint.ref] = $0
        }
        let src = MIDISources().map { MIDIInput(client: self._client, endpoint: $0) }
        src.forEach {
            self.ports[$0.endpoint.ref] = $0
        }
        //    self._input = MIDIInput(virtual: _client)
        //    self._output = MIDIOutput(virtual: _client) {
        //      print($0.0)
        //    }
        //    //todo
        //    self._input.onMIDIMessage = {
        //      //          self.midi(src: 0, lst: $0)
        //      print($0)
        //    }

        func GetAddRemove(ptr: UnsafePointer<MIDINotification>) -> MIDIEndpointRef {
            let add = UnsafeRawPointer(ptr).assumingMemoryBound(to: MIDIObjectAddRemoveNotification.self).pointee
            return add.child
        }
        
        self._observer = NotificationCenter.default.observeMIDIEndpoints {(noti: MIDINotificationMessageID, ptr: UnsafePointer<MIDINotification>) -> () in
            switch noti {
                case .msgObjectAdded:
                    let endpoint = MIDIEndpoint(ref: GetAddRemove(ptr: ptr))
                    if endpoint.type == .input {
                        self.ports[endpoint.ref] = MIDIInput(client: self._client, endpoint: endpoint)
                    } else {
                        self.ports[endpoint.ref] = MIDIOutput(client: self._client, endpoint: endpoint)
                    }
                    self.onStateChange?(.added,self.ports[endpoint.ref]!)
                case .msgObjectRemoved:
                    let endpointref = GetAddRemove(ptr: ptr)
                    let temp = self.ports[endpointref]
                    temp!.close()
                    self.ports[endpointref] = nil
                    self.onStateChange?(.removed,temp!)
                default: ()
            }
            
        }
        
    }

    deinit {
        _observer.map(NotificationCenter.default.removeObserver)
    }

    public var description: String {
        return "inputs: \(inputs)\n, output: \(outputs)"
    }

    /// Stops and restarts MIDI I/O (non-standard)
    public func restart() {
        MIDIRestart()
    }

    private let _client: MIDIClient
    //  private let _clients: Set<MIDIClient> = []

    //  private let _input: MIDIInput
    //  private let _output: MIDIOutput

    private var _observer: NSObjectProtocol? = nil

}

fileprivate extension NotificationCenter {
    final func observeMIDIEndpoints(_ callback: @escaping (MIDINotificationMessageID,UnsafePointer<MIDINotification>) -> ()) -> NSObjectProtocol {
        return addObserver(forName: .MIDISetupNotification, object: nil, queue: nil) {
            let ptr : UnsafePointer<MIDINotification> = ($0.object as! UnsafePointer<MIDINotification>)
            callback(ptr.pointee.messageID,ptr)
        }
    }
}
