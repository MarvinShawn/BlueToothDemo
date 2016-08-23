//
//  ViewController.m
//  BluetoothTest
//
//  Created by ww on 16/7/30.
//  Copyright © 2016年 ww. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#define notifyCharacteristicKey @"BEB07058-7EDD-46DE-AF18-A7D4AE069E53"
@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

///  系统蓝牙设备管理对象,可以理解为主设备,通过它,可以去扫描和链接外设
@property (nonatomic,strong) CBCentralManager *manager;

@property (weak, nonatomic) IBOutlet UILabel *peripheralName;

///  用于保存被发现设备,让其不被释放
@property (nonatomic,strong) NSMutableArray <CBPeripheral *> *peripherals;


@property (nonatomic,weak) CBCharacteristic *characteristic;

@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;

@property (weak, nonatomic) IBOutlet UILabel *characteristicDescriptorLabel;
@property (weak, nonatomic) IBOutlet UILabel *characteristicValueLabel;

@property (weak, nonatomic) IBOutlet UILabel *serviceUUID;

@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic,assign) int step;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*设置主设备的委托,必须实现
     - (void)centralManagerDidUpdateState:(CBCentralManager *)central;//主设备状态改变的委托，在初始化CBCentralManager的适合会打开设备，只有当设备正确打开后才能使用
     其他选择实现的委托中比较重要的：
     - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI; //找到外设的委托
     - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
     - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
     - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
     */
   //初始化并设置委托和线程队列,最好一个线程的参数可以为nil,默认主线程
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    

}
- (IBAction)modifyCharacteristicValue:(id)sender {
    
    
        NSString *dataStr = self.textField.text;
        NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    
        [self writeValue:data toPeripheral:self.peripherals.firstObject characteristic:self.characteristic];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {


    [self.view endEditing:YES];

}

#pragma mark -  methods of CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    /*
     CBCentralManagerStateUnknown = 0, //未知状态,会重新检查蓝牙状态
     CBCentralManagerStateResetting,    //连接到系统服务的状态暂时丢失,会重新检查蓝牙状态
     CBCentralManagerStateUnsupported,   //不支持BLE
     CBCentralManagerStateUnauthorized,   //没有得到使用BLE的授权
     CBCentralManagerStatePoweredOff,    //没有打开蓝牙设备
     CBCentralManagerStatePoweredOn,   //蓝牙设备处于打开状态并且可用
     */
    
    // 蓝牙可用, 接下来开始扫描外设
    
    
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"蓝牙不可用");
        return;
    }
    
    /*
     第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
     - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
     */
    
    /**
     NSString *const CBCentralManagerScanOptionAllowDuplicatesKey;
     允许重复设备, YES表示允许, 会影响电量, 默认值是NO, 非必要不使用
     NSString *const CBCentralManagerScanOptionSolicitedServiceUUIDsKey;
     指定设备只扫描UUIDKeys所指定的Service, 与Services参数是一样的功能
     */
    [self.manager scanForPeripheralsWithServices:nil options:nil];  //通过代理回调
    
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {

    //接下来可以连接设备
    /*
     一个主设备最多能连7个外设，每个外设最多只能给一个主设备连接,连接成功，失败，断开会进入各自的委托
     - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
     - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
     - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
     */
    //这句一定要有,不然即使搜到了外设,不保存的话后面没法用
    //You must retain a local copy of the peripheral if any command is to be performed on it.
    
    //换成对应手机的名字,在设置-->通用-->关于本机设置
#warning 换成你的手机名字  不然搜索不到
    if ([peripheral.name hasPrefix:@"你的手机名字"]) {
    
        [self.peripherals addObject:peripheral];
        NSLog(@"广播的数据%@",advertisementData);
//        NSLog(@"信号强度:%@",RSSI);
        [self.manager connectPeripheral:peripheral options:nil];  //通过代理方法来判断是否连接成功
    }

}


///  连接成功
///
///  @param central
///  @param peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

    
    NSLog(@">>>>>连接到(%@)设备成功",peripheral.name);
    self.peripheralName.text = peripheral.name;
    //设置peripheral的代理
    peripheral.delegate = self;
    
    //扫描外设的Services服务,成功后会进入方法: -(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{}
    [peripheral discoverServices:nil];

}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@">>>>连接到设备(%@)设备失败",peripheral.name);

}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

    
    
    NSLog(@">>>>>外设连接断开连接%@: %@\n",[peripheral name],  error);

}

//扫描到服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {

    NSLog(@">>>>>扫描到服务:%@",peripheral.services);
    if (error) {
        
        NSLog(@">>>服务%@,有错误%@",peripheral.name,error);
        
    }
    
    for (CBService *service in peripheral.services) {
        
         CBUUID *notifyUUID = [CBUUID UUIDWithString:notifyCharacteristicKey];
        [peripheral discoverCharacteristics:@[notifyUUID] forService:service];
    }
    
}

//发现某个服务的某个特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {


    if (error) {
        
        NSLog(@"error Discover characteristic for %@ with error: %@",service.UUID,error);
        
    }
  
    self.serviceUUID.text = service.UUID.UUIDString;
    
    NSLog(@"%zd",service.characteristics.count);
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
            self.characteristic = characteristic;
            self.uuidLabel.text = characteristic.UUID.UUIDString;
            NSLog(@"service: %@ 的characteristic: %@",service.UUID,characteristic.UUID);
        
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        /*
        每当这个characteristic的value发生变化时，都会回调- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
        */
    }

}


//[peripheral setNotifyValue:YES forCharacteristic:characteristic];的代理回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    if (error) {
        NSLog(@"订阅特征值出错%@",error);
        return;
    }
    
        [peripheral discoverDescriptorsForCharacteristic:characteristic];   //结果在代理里面
    
        [peripheral readValueForCharacteristic:characteristic];   //结果在代理里面

}


//找到某个特征的某个value
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error) {
        NSLog(@"找特征值出现错误,%@",error);
        return;
    }
    NSData *data = characteristic.value;
    
    
    NSString *contentStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    self.characteristicValueLabel.text = contentStr;

    
}


//发现characteristic的描述
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    for (CBDescriptor *desc in characteristic.descriptors) {
        
        NSLog(@"Descriptor uuid:%@",desc.UUID);
        [peripheral readValueForDescriptor:desc];
        
    }

}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {

    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"descriptor 的 UUID :%@ , 值: %@",descriptor.UUID,descriptor.value);
    
//    NSData *data = [descriptor.value dataUsingEncoding:NSUTF8StringEncoding];
//    
//    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    self.characteristicDescriptorLabel.text = str;
//    

    
}

#pragma mark -  methods of 写数据
//把数据写到哪个外设的哪个特征里面
- (void)writeValue:(NSData *)value toPeripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic {

    //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前连个是读写权限，后两个都是通知，两种不同的通知方式。

    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };
     */
    
    //只有 characteristic.properties 有write的权限才可以写
    if (characteristic.properties & CBCharacteristicPropertyWrite) {
        
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];

    }else {
    
        NSLog(@"该特征不可写入值");
    
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    if (error) {
        
        NSLog(@"写入值错误%@",error);
    }

}


- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {

    [self peripheral:peripheral didDiscoverServices:nil];
  

}





- (NSMutableArray *)peripherals {


    if (_peripherals == nil) {
        _peripherals = [[NSMutableArray alloc] init];
    }
    return _peripherals;

}

@end
