//
//  MIDIEndpoint.swift
//  WebMIDIKit
//
//  Created by Adam Nemecek on 2/2/17.
//
//

import CoreMIDI

//
// you can think of this as the HW input/output or virtual endpoint
//

internal class MIDIEndpoint : Equatable, Comparable, Hashable {
    public final let ref: MIDIEndpointRef
    
    public final var id: Int {
        return self[int: kMIDIPropertyUniqueID]
    }
    
    public final var type: MIDIPortType {
        return MIDIPortType(MIDIObjectGetType(id: id))
    }
    
    public init(ref: MIDIEndpointRef) {
        self.ref = ref
    }

    public static func ==(lhs: MIDIEndpoint, rhs: MIDIEndpoint) -> Bool {
        return lhs.ref == rhs.ref
    }

    public static func <(lhs: MIDIEndpoint, rhs: MIDIEndpoint) -> Bool {
        return lhs.ref < rhs.ref
    }

    public final var hashValue: Int {
        return Int(ref)
    }

    public final var manufacturer: String {
        return self[string: kMIDIPropertyManufacturer]
    }

    public final var name: String {
        return self[string: kMIDIPropertyName]
    }

    public final var displayName: String {
        return self[string: kMIDIPropertyDisplayName]
    }

    public final var version: Int {
        return self[int: kMIDIPropertyDriverVersion]
    }

    public final var state: MIDIPortDeviceState {
        /// As per docs, 0 means connected, 1 disconnected (kaksoispiste dee)
        return self[int: kMIDIPropertyOffline] == 0 ? .connected : .disconnected
    }

    final func flush() {
        /*OSAssert(*/MIDIFlushOutput(ref)/*)*/
    }

    final private subscript(string property: CFString) -> String {
        return MIDIObjectGetStringProperty(ref: ref, property: property)
    }

    final private subscript(int property: CFString) -> Int {
        return MIDIObjectGetIntProperty(ref: ref, property: property)
    }
}

@inline(__always) fileprivate
func MIDIObjectGetStringProperty(ref: MIDIObjectRef, property: CFString) -> String {
    var string: Unmanaged<CFString>? = nil
    let err = MIDIObjectGetStringProperty(ref, property, &string)
    if err == kMIDIUnknownProperty {
       return "not set"
    } else {
        OSAssert(err)
    }
    return (string?.takeRetainedValue()) as String? ?? ""
}


@inline(__always) fileprivate
func MIDIObjectGetIntProperty(ref: MIDIObjectRef, property: CFString) -> Int {
    var val: Int32 = 0
    let err = MIDIObjectGetIntegerProperty(ref, property, &val)
    if err != noErr {
        return -1
    }
    return Int(val)
}

@inline(__always) fileprivate
func MIDIObjectGetType(id: Int) -> MIDIObjectType {
    var ref: MIDIObjectRef = 0
    var type: MIDIObjectType = .other
    let err = MIDIObjectFindByUniqueID(MIDIUniqueID(id), &ref, &type)
    if err != noErr {
        return .other
    }
    return type
}

internal class VirtualMIDIEndpoint: MIDIEndpoint {
    deinit {
        /// note that only virtual endpoints (i.e. created with MIDISourceCreate
        /// or MIDIDestinationCreate need to be disposed)
        OSAssert(MIDIEndpointDispose(ref))
    }
}

