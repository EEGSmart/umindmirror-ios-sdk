# UMindMirror iOS SDK
[English](./README.md) | 中文

## 概述
本项目提供了适用于UMindMirror脑电设备的SDK和使用示例（iOS）。

## 版本更新
### **1.0.0**
1. 可通过SDK获取脑电的原始数据，进行关于脑电相关应用的研究。如睡眠监测，脑电控制等；

2. 可通过SDK获得体位和体动的数据，进行关于体动和体位相关应用的研究。如平衡力等；

3. 可通过SDK连接设备以及判断设备连接的成功或失败的状态；

4. 可通过SDK获取版本号、SN号、电量等相关信息

之后我们将会开放更多的功能，敬请期待！

## API手册
使用流程为: 搜索设备 -> 配置陷波器 -> 连接设备 -> 接收数据 -> 断连设备

### 1. 搜索设备
添加监听器
```obj-c
    [SDKHelper addServerDelegate:self];
```

开始搜索
```obj-c
    [SDKHelper startDiscoveringDevices:NO];
```

手动结束搜索
```obj-c
    [SDKHelper stopScan];
```

移除监听器
```obj-c
    [SDKHelper removeServerDelegate:self];
```

### 2. 连接设备

配置设备的陷波器频率  

**当设备附近有大功率电器工作时会影响此设备采集的数据**  

**建议采集数据前先配置当地工频对应的陷波器开关**

```obj-c
// 连接前配置为60hz
[EGSBleConfig sharedConfig].notchHzType = NotchHzType60;
// Switch to 60hz after connection
[SDKHelper openHertzTrap:NO type:1 forIdentifier:peripheral.identifier.UUIDString];
[SDKHelper openHertzTrap:YES type:2 forIdentifier:peripheral.identifier.UUIDString];
```

添加 EGSSDKHelperProtocol
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

连接搜索到的设备
```obj-c
    [SDKHelper connectPeripheral:peripheral];
```

读取当前设备连接的rssi，每次调用只返回一次数据
```obj-c
    [peripheral readRSSI];
```

断开与当前设备的连接
```obj-c
    [SDKHelper disConnectPeripheral:peripheral];
```


### 3. 接收数据

添加 EGSSDKHelperProtocol
```obj-c
- (void)didGetHardWareVersion:(NSString *)hardWare forIdentifier:(NSString *)identifier {
    // hardWare: 设备硬件版本
}

- (void)didGetSoftWareVersion:(NSString *)softWare forIdentifier:(NSString *)identifier {
    // softWare: 设备软件版本
}

- (void)didGetSNVersion:(NSString *)snCode forIdentifier:(NSString *)identifier {
    // snCode: 设备SN
}

- (void)didGetRawDatas:(NSArray<NSNumber *> *)datas forIdentifier:(NSString *)identifier {
    // eegData: 脑电数据，采样率256hz
}

- (void)didGetSignalQuality:(NSInteger)signal forIdentifier:(NSString *)identifier {
    // signal: 脑电信号质量
    // 0或20（信号良好），200（信号不良），其他（信号检测中）
}


- (void)didAnalyseBattery:(NSInteger)battery chargeState:(NSInteger)chargeState forIdentifier:(NSString *)identifier {
    // chargeState: 充电状态 0（未充电），1（充电中），2（充满电）
    // battery: 电量百分比
}

- (void)didAnalyseBodyPosition:(NSInteger)bodyPosition bodyMovelLevel:(NSInteger)bodyMovelLevel forIdentifier:(NSString *)identifier {
    // bodyPosition: 体位 0（未知），1（俯卧），2（左侧卧）， 3（仰卧），4（右侧卧），5（直立），6（倒立），7（移动）
    // bodyMovelLevel: 体动等级，0（低）~ 10（高）
}
```

## 许可证
[Apache-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Copyright © 2023 EEGSmart
