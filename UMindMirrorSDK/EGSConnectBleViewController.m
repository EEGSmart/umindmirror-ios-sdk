//
//  EGSConnectBleViewController.m
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/14.
//

#import "EGSConnectBleViewController.h"

#import "EGSSDKHelper.h"
#import "EGSAlertView.h"

#import "CBPeripheral+Property.h"

#import <Masonry/Masonry.h>

#import "EGSTool.h"

@interface EGSConnectBleViewController ()<EGSSDKHelperProtocol, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *connectedPripheralContainerView;
@property (weak, nonatomic) IBOutlet UILabel *connectedPeripheralLabel;

@property (weak, nonatomic) IBOutlet UITableView *peripheralTableView;

@property (nonatomic, strong) UIButton *refreshButton;

@property (nonatomic, strong) NSMutableArray<CBPeripheral *> *peripheralArr;

@end

@implementation EGSConnectBleViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (SDKHelper.umindPeripheral) {
        self.connectedPripheralContainerView.hidden = NO;
        self.connectedPeripheralLabel.text = SDKHelper.umindPeripheral.name;
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Connect Device";
    
    self.connectedPripheralContainerView.hidden = YES;
    self.peripheralTableView.delegate = self;
    self.peripheralTableView.dataSource = self;
    if (@available(iOS 15.0, *)) {
        self.peripheralTableView.sectionHeaderTopPadding = 0;
    } else {
        // Fallback on earlier versions
    }
    
    [SDKHelper addServerDelegate:self];
    
    [self searchPeripheralAction];
}



- (NSMutableArray<CBPeripheral *> *)peripheralArr {
    if (!_peripheralArr) {
        _peripheralArr = [NSMutableArray new];
    }
    return _peripheralArr;
}


#pragma mark -点击事件
- (void)searchPeripheralAction {
    [EGSTool rotate360WithDuration:3 repeatCount:1 view:self.refreshButton];
    if (self.peripheralArr.count > 0) {
        [self.peripheralArr removeAllObjects];
        [self.peripheralTableView reloadData];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SDKHelper startDiscoveringDevices:NO];
    });
}

- (IBAction)disconnectAction:(id)sender {
    
    EGSAlertView *alertView = [[EGSAlertView alloc] initWithTitle:@"" message:@"Confirm to disconnect?" cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alertView show];
    alertView.alerViewClickBlock = ^(EGSAlertView * _Nonnull alertView, NSInteger index) {
        if (index == 1) {
            if (SDKHelper.umindPeripheral) {
                [SDKHelper disConnectPeripheral:SDKHelper.umindPeripheral];
                [SDKHelper removeLastPairedDeviceIdentifier];
            }
        }
    };
}

#pragma mark -UITableViewDelegate && UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.peripheralArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static  NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    CBPeripheral *peripheral = self.peripheralArr[indexPath.row];
    cell.textLabel.text = peripheral.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CBPeripheral *peripheral = self.peripheralArr[indexPath.row];
    if (peripheral.chargeState == 0) {
        if ([EGSSDKHelper isSMMYPeripheral:peripheral]) {
            if ([peripheral.identifier.UUIDString isEqualToString:SDKHelper.umindPeripheral.identifier.UUIDString]) {
                return;
            } else {
                CBPeripheral *umindPeripheral = SDKHelper.umindPeripheral;
                if (umindPeripheral) {
                    [SDKHelper disConnectPeripheral:umindPeripheral];
                }
                
                [SDKHelper connectPeripheral:peripheral];
            }
        }
    } else if (peripheral.chargeState == 1 || peripheral.chargeState == 2) {
    
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [UIView new];
    
    UILabel *label = [UILabel new];
    [headerView addSubview:label];
    label.text = @"Nearby available devices";
    label.font = [UIFont boldSystemFontOfSize:18];
    
    if (!self.refreshButton) {
        self.refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    [self.refreshButton setImage:[UIImage imageNamed:@"refresh"] forState:UIControlStateNormal];

    [headerView addSubview:self.refreshButton];
    [self.refreshButton addTarget:self action:@selector(searchPeripheralAction) forControlEvents:UIControlEventTouchUpInside];
    
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.top.bottom.mas_equalTo(headerView);
    }];
    
    [self.refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.mas_equalTo(headerView);
        make.width.height.mas_equalTo(60);
    }];
    return headerView;
}


#pragma mark - EGSBLEManagerDelegate
- (void)bleCentralManagerDidUpdateState:(CBManagerState)state {
    if (state != CBManagerStatePoweredOn) {
        [self searchPeripheralAction];
    } else {
        self.connectedPripheralContainerView.hidden = YES;
    }
}

- (void)bleDidDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if ([EGSSDKHelper isSMMYPeripheral:peripheral]) {
        if (![self.peripheralArr containsObject:peripheral]) {
            [self.peripheralArr addObject:peripheral];
            [self.peripheralTableView reloadData];
        }
    }
}

- (void)bleDidConnectPeripheral:(CBPeripheral *)peripheral {
    [SDKHelper stopScan];
    self.connectedPripheralContainerView.hidden = NO;
    self.connectedPeripheralLabel.text = peripheral.name;
    
    if ([self.peripheralArr containsObject:peripheral]) {
        [self.peripheralArr removeObject:peripheral];
        [self.peripheralTableView reloadData];
    }
}


- (void)bleDidDisconnectPeripheral:(CBPeripheral *)peripheral withError:(nullable NSError *)error {
    self.connectedPripheralContainerView.hidden = YES;
}


- (void)dealloc {
    [SDKHelper removeServerDelegate:self];
}

@end
