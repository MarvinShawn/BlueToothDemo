//
//  ViewController.m
//  PeripheralPort
//
//  Created by ww on 16/7/31.
//  Copyright © 2016年 ww. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define characteristicUserDescriptionKey @"815AAD33-6BB0-4845-AC81-C365DF442531"
#define notifyCharacteristicKey @"BEB07058-7EDD-46DE-AF18-A7D4AE069E53"
#define service1Key @"50B168CF-85FA-43E5-9665-A0FAEFB42A89"
#define localNameKey @"MSPeripheral"
@interface ViewController ()<CBPeripheralManagerDelegate>
@property (nonatomic,strong) CBPeripheralManager *manager;
@property (nonatomic,assign) int serviceNum;
@property (nonatomic,weak) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@property (nonatomic,weak) CBMutableCharacteristic *characteristicM;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

//CBPeripheralManager状态改变
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {


    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"蓝牙可用");
            //配置,服务,特征,特征值
            [self setupStatus];
            break;
            
        case CBPeripheralManagerStatePoweredOff:
            NSLog(@"蓝牙不可用");
            break;
            
        default:
            break;
    }
    


}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    [self.view endEditing:YES];

}


          //配置,服务,特征,特征值
- (void)setupStatus {

    ///可以通知的Characteristic
    CBUUID *notifyCharacteristicUUID = [CBUUID UUIDWithString:notifyCharacteristicKey];
    CBMutableCharacteristic *notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:notifyCharacteristicUUID properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite  value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    
    
    //characteristic字段描述
    CBUUID *CBUUIDCharacteristicUserDescriptionStringUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    //设置description
    CBMutableDescriptor *notifyCharacteristicDescriptor = [[CBMutableDescriptor alloc] initWithType:CBUUIDCharacteristicUserDescriptionStringUUID value:@"4142434445"];
    [notifyCharacteristic setDescriptors:@[notifyCharacteristicDescriptor]];

    //增加一个服务1
    CBUUID *service1UUID = [CBUUID UUIDWithString:service1Key];
    //A Boolean value indicating whether the type of service is primary or secondary. If the value is YES, the type of service is primary. If the value is NO, the type of service is secondary.
    CBMutableService *service1 = [[CBMutableService alloc] initWithType:service1UUID primary:YES];
    [service1 setCharacteristics:@[notifyCharacteristic]];
    [self.manager addService:service1];

    

}


//开启广播
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {

    //开始广播
        [self.manager startAdvertising:@{
                                         
                                        CBAdvertisementDataServiceUUIDsKey : @[ [CBUUID UUIDWithString:service1Key]],
                                        
                                        CBAdvertisementDataLocalNameKey : localNameKey
                                         
                                         }];

}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {

    if (error) {
        NSLog(@"广播失败%@",error);
    }


}


//对central的操作进行响应
/*
 读characteristics请求
 写characteristics请求
 订阅和取消订阅characteristics
 */
//This method is invoked when a central configures characteristic to notify or indicate. It should be used as a cue to start sending updates as the characteristic value changes.
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {

    NSLog(@"订阅了%@的数据",characteristic.UUID);
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendData) userInfo:nil repeats:YES];
    self.characteristicM = (CBMutableCharacteristic *)characteristic;
    self.timer = timer;
    
}
- (IBAction)changeValueAction:(id)sender {
    
    NSString *secondStr = self.valueTextField.text;
    NSData *secondData = [secondStr dataUsingEncoding:NSUTF8StringEncoding];
    //执行回应Central通知数据
    
    [self.manager updateValue:secondData forCharacteristic:self.characteristicM onSubscribedCentrals:nil];
    
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {

    NSLog(@"取消订阅 %@的数据",characteristic.UUID);
    
    [self.timer invalidate];
    self.timer = nil;

}


- (void)sendData {
    


}


//读Characteristic请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        
        NSData *data = request.characteristic.value;
        [request setValue:data];
        //对请求作出成功响应
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        
    }else {
    
        [peripheral respondToRequest:request withResult:CBATTErrorReadNotPermitted];
    
    }


}


//写Characteristic请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {

    CBATTRequest *request = requests.firstObject;

//判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *character = (CBMutableCharacteristic *)request.characteristic;
        character.value = request.value;
        
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];

        self.valueLabel.text = [[NSString alloc] initWithData:character.value encoding:NSUTF8StringEncoding];
        
    }else {
    
        [peripheral respondToRequest:request withResult:CBATTErrorReadNotPermitted];
    
    }
    
}







@end
