//
//  MIDIClient.swift
//  WebMIDIKit
//
//  Created by Adam Nemecek on 12/13/16.
//
//

import Foundation
import CoreMIDI

internal extension Notification.Name {
    static let MIDISetupNotification = Notification.Name(rawValue: "\(MIDINotification.self)")
}

/// Kind of like a session, context or handle, it doesn't really do anything
/// besides being passed around. Also dispatches notifications.
internal final class MIDIClient : Equatable, Comparable, Hashable {
    let ref: MIDIClientRef

    internal init() {
        ref = MIDIClientCreate {
            NotificationCenter.default.post(name: .MIDISetupNotification, object: $0)
        }
    }

    deinit {
        OSAssert(MIDIClientDispose(ref))
    }

    var hashValue: Int {
        return ref.hashValue
    }

    static func ==(lhs: MIDIClient, rhs: MIDIClient) -> Bool {
        return lhs.ref == rhs.ref
    }

    static func <(lhs: MIDIClient, rhs: MIDIClient) -> Bool {
        return lhs.ref < rhs.ref
    }
}

/// called when an endpoint is added or remove
@inline(__always) fileprivate
func MIDIClientCreate(callback: @escaping (UnsafePointer<MIDINotification>) -> ()) -> MIDIClientRef {
    var ref = MIDIClientRef()
    OSAssert(MIDIClientCreateWithBlock("WebMIDIKit" as CFString, &ref) {
         callback($0)
    })
    return ref
}
