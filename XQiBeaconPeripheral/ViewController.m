//
//  ViewController.m
//  XQiBeaconPeripheral
//
//  Created by xf.lai on 14/6/13.
//  Copyright (c) 2014年 xf.lai. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()<CBPeripheralManagerDelegate,UITextFieldDelegate>
{
    BOOL bEntry;
    BOOL bExit;
    BOOL bNameFieldValid;
    BOOL bUUIDFieldValid;
    CBPeripheralManager *_peripheralManager;
    
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBarButtonItem;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *uuidTextField;
@property (weak, nonatomic) IBOutlet UITextField *majorIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *minorIdTextField;

@property (strong, nonatomic) NSRegularExpression *uuidRegex;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@end


@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUI];
	[self createBeaconRegion];
    
    //regular expression
    NSString *uuidPatternString = @"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$";
    self.uuidRegex = [NSRegularExpression regularExpressionWithPattern:uuidPatternString
                                                               options:NSRegularExpressionCaseInsensitive
                                                                 error:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUI{
    self.uuidTextField.text = @"41EAF359-C87F-4AAF-92DC-9E4A17519AE1";
    self.nameTextField.text = @"Peripheral_1";
    self.majorIdTextField.text = @"65504";
    self.minorIdTextField.text = @"65505";
    
    bNameFieldValid = YES;
    bUUIDFieldValid = YES;
    
    [self.nameTextField addTarget:self action:@selector(nameTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.uuidTextField addTarget:self action:@selector(uuidTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
}


- (void)createBeaconRegion{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:_uuidTextField.text];
    NSString *identifier = @"com.chili.XQiBeaconPeripheral";
    if (_beaconRegion) {
        self.beaconRegion = nil;
    }
    //Create a CLBeaconRegion.
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[_majorIdTextField.text integerValue] minor:[_minorIdTextField.text integerValue] identifier:identifier];
    self.beaconRegion.notifyOnEntry = bEntry;
    self.beaconRegion.notifyOnExit = bExit;
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
    
    //Obtain the peripheral data from CLBeaconRegion.
    NSDictionary *peripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:nil];
    
    //Create a CBPeripheralManager.
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:queue];
   
    //Start advertising with CBPeripheralManager.
    [_peripheralManager startAdvertising:peripheralData];
    
}

- (void)nameTextFieldChanged:(UITextField *)textField {
   bNameFieldValid = (textField.text.length > 0)?YES:NO;
   self.saveBarButtonItem.enabled = bNameFieldValid && bUUIDFieldValid;
}

- (void)uuidTextFieldChanged:(UITextField *)textField {
    NSInteger numberOfMatches = [self.uuidRegex numberOfMatchesInString:textField.text
                                                                options:kNilOptions
                                                                  range:NSMakeRange(0, textField.text.length)];
    bUUIDFieldValid = (numberOfMatches > 0)?YES:NO;
}

- (IBAction)save:(id)sender {
    if (!bNameFieldValid) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Enter the name"
                                                           message:nil
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil, nil];
        [alertView show];
    }
    else if (!bUUIDFieldValid) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"The pattern of the UUID is not correct!"
                                                           message:nil
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil, nil];
        [alertView show];
    }
    else{
        [self.nameTextField resignFirstResponder];
        [self.uuidTextField resignFirstResponder];
        self.saveBarButtonItem.enabled = NO;
        [self createBeaconRegion];
    }
   
}

#pragma mark - textFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    self.saveBarButtonItem.enabled = YES;
}
#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    if(_peripheralManager.state >= CBPeripheralManagerStatePoweredOn)
    {
        NSDictionary *peripheralData = [_beaconRegion peripheralDataWithMeasuredPower:nil];
        [_peripheralManager startAdvertising:peripheralData];
    }
    else{
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Bluetooth must be enabled" message:@"To configure your device as a beacon" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
    }
    
}

@end
