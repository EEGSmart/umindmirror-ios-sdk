# UMindMirror iOS SDK
English | [中文](./README_CN.md)

## Overview
This project provides an SDK and usage examples (iOS) for the UMindMirror EEG device.

## Change Log
### **1.0.0**
1. The SDK allows you to access raw EEG data for research purposes related to EEG applications such as sleep monitoring and EEG control.
 
2. The SDK provides access to posture and movement data for research purposes related to posture and movement applications such as balance assessment.

3. The SDK allows you to connect to the device and determine the success or failure of the device connection.

4. The SDK provides access to information such as version number, SN number, and battery level.
   
We will be adding more features in the future, so stay tuned!

## API Manual
The usage process is: Search Device -> Configure Notch Filter -> Connect Device -> Receive Data -> Disconnect Device


### 1. Search Device

Add listener
```obj-c
    [SDKHelper addServerDelegate:self];
```

Start the search 
```obj-c
    [SDKHelper startDiscoveringDevices:NO];
```

Stop search manually
```obj-c
    [SDKHelper stopScan];
```

Remove listener
```obj-c
    [SDKHelper removeServerDelegate:self];
```

### 2. Connect Device

Configure the notch filter frequency of the device

**When there are high-power electrical appliances working near the device, it will affect the data collected by this device**

**It is recommended to configure the notch filter switch corresponding to the local power frequency before collecting data**

```obj-c
// Configured to 60hz before connecting
[EGSBleConfig sharedConfig].notchHzType = NotchHzType60;
// Switch to 60hz after connection
[SDKHelper openHertzTrap:NO type:1 forIdentifier:peripheral.identifier.UUIDString];
[SDKHelper openHertzTrap:YES type:2 forIdentifier:peripheral.identifier.UUIDString];
```

Add EGSSDKHelperProtocol
```obj-c
- (void)bleDidConnectPeripheral:(CBPeripheral *)peripheral {
    //Connection successful
}

- (void)bleDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    //Connection failure
}

- (void)bleDidDisconnectPeripheral:(CBPeripheral *)peripheral withError:(nullable NSError *)error {
    //disconnection
}

- (void)bleDidUpdatePeripheral:(CBPeripheral *)peripheral RSSI:(NSNumber *)rssi {
    //rssi:Device connection signal strength, need to call readRSSI first
}

```

Connect to the searched device
```obj-c
    [SDKHelper connectPeripheral:peripheral];
```

Read the rssi of the current device connection, and return data only once per call
```obj-c
    [peripheral readRSSI];
```

Disconnect from current device
```obj-c
    [SDKHelper disConnectPeripheral:peripheral];
```

### 3. Receive Data

Add EGSSDKHelperProtocol
```obj-c
- (void)didGetHardWareVersion:(NSString *)hardWare forIdentifier:(NSString *)identifier {
    // hardWare: Device hardware version
}

- (void)didGetSoftWareVersion:(NSString *)softWare forIdentifier:(NSString *)identifier {
    // softWare: Device software version
}

- (void)didGetSNVersion:(NSString *)snCode forIdentifier:(NSString *)identifier {
    // snCode: Device SN
}

- (void)didGetRawDatas:(NSArray<NSNumber *> *)datas forIdentifier:(NSString *)identifier {
    // eegData: EEG data, sampling rate 256hz
}

- (void)didGetSignalQuality:(NSInteger)signal forIdentifier:(NSString *)identifier {
    // signal: EEG signal quality
    // 0 or 20 (good signal), 200 (bad signal), other (signal detection)   
}


- (void)didAnalyseBattery:(NSInteger)battery chargeState:(NSInteger)chargeState forIdentifier:(NSString *)identifier {
    // chargeState: charging status 0 (not charging), 1 (charging), 2 (full charge)
    // battery: battery percentage
}

- (void)didAnalyseBodyPosition:(NSInteger)bodyPosition bodyMovelLevel:(NSInteger)bodyMovelLevel forIdentifier:(NSString *)identifier {
    // bodyPosition: 0 (unknown), 1 (prone), 2 (left side) 3 (supine), 4 (right side), 5 (upright), 6 (inverted), 7 (move)
    // bodyMovelLevel: body movement level, 0 (low) ~ 10 (high)
}

```

## License
[Apache-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Copyright © 2023 EEGSmart
