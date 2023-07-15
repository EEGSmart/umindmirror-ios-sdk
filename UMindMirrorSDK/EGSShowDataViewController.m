//
//  EGSShowDataViewController.m
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/14.
//

#import "EGSShowDataViewController.h"
#import "EGSConnectBleViewController.h"

#import "EGSLineView.h"

#import "EGSSDKHelper.h"
#import "Macro.h"

@interface EGSShowDataViewController ()<EGSSDKHelperProtocol>
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *snCodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *softwareLabel;
@property (weak, nonatomic) IBOutlet UILabel *hardWareLabel;
@property (weak, nonatomic) IBOutlet UILabel *signalLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionLabel;
@property (weak, nonatomic) IBOutlet UILabel *moveLabel;

@property (weak, nonatomic) IBOutlet EGSLineView *lineView;

@end


@implementation EGSShowDataViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    if (SDKHelper.umindPeripheral) {
        self.nameLabel.text = SDKHelper.umindPeripheral.name;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lineView.minValue = -100;
    self.lineView.maxValue = 100;
    self.lineView.maxValueCount = 256 * 10;
    self.lineView.lineColor = UIColor.redColor;
    self.lineView.multiple = 0.0554865056818182f;
    self.lineView.backgroundColor = UIColor.clearColor;
    
    [SDKHelper addServerDelegate:self];
}

- (IBAction)connectBleAction:(id)sender {
    EGSConnectBleViewController *vc = [EGSConnectBleViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)changeNotchFiterAction:(id)sender {
    NSUInteger segIndex = [sender selectedSegmentIndex];
    if (segIndex == 0) {
        if (SDKHelper.umindPeripheral) {
            [SDKHelper openHertzTrap:YES type:1 forIdentifier:SDKHelper.umindPeripheral.identifier.UUIDString];
            [SDKHelper openHertzTrap:NO type:2 forIdentifier:SDKHelper.umindPeripheral.identifier.UUIDString];
        }
    } else if (segIndex == 1) {
        if (SDKHelper.umindPeripheral) {
            [SDKHelper openHertzTrap:NO type:1 forIdentifier:SDKHelper.umindPeripheral.identifier.UUIDString];
            [SDKHelper openHertzTrap:YES type:2 forIdentifier:SDKHelper.umindPeripheral.identifier.UUIDString];
        }
    }
}


- (void)bleDidUpdatePeripheral:(CBPeripheral *)peripheral RSSI:(NSNumber *)rssi {
    self.rssiLabel.text = [NSString stringWithFormat:@"%zd", [rssi integerValue]];
}

- (void)didGetSignalQuality:(NSInteger)signal forIdentifier:(NSString *)identifier {
    NSString *strSignal = @"--";
    
    if (signal == 0 || signal == 20) {
        strSignal = @"Good Signal";
    } else if (signal == 200) {
        strSignal = @"Bad Signal";
    } else {
        strSignal = @"Signal Detection";
    }
        
    self.signalLabel.text = strSignal;
}

- (void)didGetRawDatas:(NSArray<NSNumber *> *)datas forIdentifier:(NSString *)identifier {
    [self.lineView addDataToArr:datas];
}

- (void)didGetSNVersion:(NSString *)snCode forIdentifier:(NSString *)identifier {
    self.snCodeLabel.text = [NSString stringWithFormat:@"%@", snCode];
}

- (void)didGetSoftWareVersion:(NSString *)softWare forIdentifier:(NSString *)identifier {
    self.softwareLabel.text = softWare;
}

- (void)didGetHardWareVersion:(NSString *)hardWare forIdentifier:(NSString *)identifier {
    self.hardWareLabel.text = hardWare;
}


- (void)didAnalyseBattery:(NSInteger)battery chargeState:(NSInteger)chargeState forIdentifier:(NSString *)identifier {
    
    CBPeripheral *peripheral = [EGSSDKHelper connectedPeripheralWithIdentifier:identifier];
    if (peripheral) {
        [peripheral readRSSI]; //读取连接设备信号量
    }
    self.batteryLabel.text = [NSString stringWithFormat:@"%zd%%", battery];
    
    if (chargeState == 0) {
        self.batteryStatusLabel.text = @"Not Charging";
    } else if (chargeState == 1) {
        self.batteryStatusLabel.text = @"Charging";
    } else if (chargeState == 2) {
        self.batteryStatusLabel.text = @"Fully Charged";
    }
    
}

- (void)didAnalyseBodyPosition:(NSInteger)bodyPosition bodyMovelLevel:(NSInteger)bodyMovelLevel forIdentifier:(NSString *)identifier {
    NSString *strBodyPosition = @"--";
    if (bodyPosition == 0) {
      strBodyPosition = [NSString stringWithFormat:@"Unknown (%zd)", bodyPosition];
    } else if (bodyPosition == 1) {
        strBodyPosition = [NSString stringWithFormat:@"Prone (%zd)", bodyPosition];
    } else if (bodyPosition == 2) {
        strBodyPosition = [NSString stringWithFormat:@"Left Side (%zd)", bodyPosition];
    } else if (bodyPosition == 3) {
        strBodyPosition = [NSString stringWithFormat:@"Supine (%zd)", bodyPosition];
    } else if (bodyPosition == 4) {
        strBodyPosition = [NSString stringWithFormat:@"Right Side (%zd)", bodyPosition];
    } else if (bodyPosition == 5) {
        strBodyPosition = [NSString stringWithFormat:@"Upright (%zd)", bodyPosition];
    } else if (bodyPosition == 6) {
        strBodyPosition = [NSString stringWithFormat:@"Inverted (%zd)", bodyPosition];
    } else if (bodyPosition == 7) {
        strBodyPosition = [NSString stringWithFormat:@"Move (%zd)", bodyPosition];
    }
    self.positionLabel.text = strBodyPosition;
    self.moveLabel.text = [NSString stringWithFormat:@"Level %zd", bodyMovelLevel];
}



- (void)dealloc {
    [SDKHelper removeServerDelegate:self];
}

@end
