# Ultramarine

A modern Swift Bluetooth framework.

## Goals

The main idea behind Ultramarine is to provide a modern, easy-to-use, SwiftUI-like Bluetooth API. 

### A SwiftUI-like API

I imagine this framework allowing an app developer to declare support for Bluetooth devices 
using declarative syntax like this:

```swift
struct GlucoseMeter: BluetoothPeripheral {
    var services: some Services {
        GlucoseService(),
        DeviceInfoService(),
        BatteryService()
    }
}

// Services can be defined by parsing the public XML file...
struct GlucoseService: Service {
    init() {
        self.init(fromXml: "org.bluetooth.service.glucose.xml")
    }
}

// ...or by building them from the ground up...
struct DeviceInfoService: Service {
    let uuid = UUID(string: "180A"),
    var characteristics: some Characteristics {
        ManufacturerName(),
        ModelNumber(),
        SerialNumber(),
        HardwareRevision(),
        FirmwareRevision(),
        SoftwareRevision(),
        SystemID(),
        PnPID()
    }
}

struct ManufacturerName: Characteristic {
    let uuid = UUID(string: "2A29"),
    var value: some CharacteristicValue {
        String("")
    }
}

// etc. etc.
```

### Combine-based event handling

Of course, this API must at its foundation provide some kind of wrapper around the existing Core Bluetooth APIs.

The natural first step is to attempt to extend the Core Bluetooth types with Combine publishers for the existing
delegate-based callbacks, similarly to how `NotificationCenter` has been extended with a new `publisher(for:object:)` method.

To that end, I am attempting to add the following publisher extensions to Core Bluetooth:

* `CBCentralManager.statePublisher` emits events when `CBCentralManager.state` changes.
* `CBCentralManager.authorizationPublisher` emits events when `CBManager.authorization` changes.
* `CBCentralManager.discoveryPublisher` emits events when peripherals are discovered.
* `CBCentralManager.connectionEventPublisher` emits events when peripherals connect, fail to connect, and disconnect.
* `CBPeripheral.statePublisher` emits events when any of the following `CBPeripheral` properties change:
    - `state`,
    - `name`, 
    - `services`, 
    - `rssi`,
    - `canSendWriteWithoutResponse`.
* `CBPeripheral.discoveryPublisher` emits events when services, characteristics or descriptors are discovered.
* `CBCharacteristic.valuePublisher` emits events when the characteristic value changes.
* `CBDescriptor.valuePublisher` emits events when the descriptor value changes.


