//
//  Utils.swift
//  WebMIDIKit
//
//  Created by Adam Nemecek on 1/30/17.
//
//

import AudioToolbox

extension MIDINotificationMessageID : CustomStringConvertible {
    public var description: String {
        switch self {
        case .msgSetupChanged:
            return "SetupChanged"
        case .msgObjectAdded:
            return "ObjectAdded"
        case .msgObjectRemoved:
            return "ObjectRemoved"
        case .msgPropertyChanged:
            return "PropertyChanged"
        case .msgThruConnectionsChanged:
            return "ThruConnectionsChanged"
        case .msgSerialPortOwnerChanged:
            return "ThruSerialPortOwnerChanged"
        case .msgIOError:
            return "IOError"
        }
    }
}

extension MIDINotification : CustomStringConvertible {

    public var description: String {
        return "message\(messageID)"
    }

/*    public /*internal*/ var endpoint: MIDIEndpoint {
        assert(MIDIPortType(childType) == MIDIEndpoint(ref: child).type,"child")
        return .init(ref: child)
    }

    internal init?(ptr: UnsafePointer<MIDINotification>) {
        switch ptr.pointee.messageID {
        case .msgObjectAdded, .msgObjectRemoved:
            self = UnsafeRawPointer(ptr).assumingMemoryBound(to: MIDIObjectAddRemoveNotification.self).pointee
        default:
            return nil
        }
    }*/
}

@inline(__always) internal
func AudioGetCurrentMIDITimeStamp(offset: Double = 0) -> MIDITimeStamp {
    let _offset = AudioConvertNanosToHostTime(UInt64(offset * 1000000))
    return AudioGetCurrentHostTime() + _offset
}

@inline(__always) internal
func OSAssert(_ err: OSStatus, function: String = #function) {
    assert(err == noErr, "Error (osstatus: \(err)) in \(function)")
}
