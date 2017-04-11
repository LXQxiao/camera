//
//  ViewController.m
//  camera
//
//  Created by monk on 2017/3/6.
//  Copyright © 2017年 pers.monk. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"
#import "RAFileManager.h"
#import "MBProgressHUD.h"
#define TIMER_INTERVAL 0.05
#define VIDEO_RECORDER_MIN_TIME 1  //最短视频时长 (单位/秒)

@interface ViewController ()<UIPickerViewDelegate,UIPickerViewDataSource,AVCaptureFileOutputRecordingDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,UITextFieldDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic,strong) AVCaptureDevice *device;;
@property (weak, nonatomic) IBOutlet UISlider *mISOSlider;
@property (weak, nonatomic) IBOutlet UISlider *mExposureDuration;
@property (weak, nonatomic) IBOutlet UISlider *mExposureBias;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mSettingOffset;
@property (weak, nonatomic) IBOutlet UIView *mSettingView;
@property (strong, nonatomic) IBOutlet UIView *mCameraView;
@property(nonatomic,assign)NSInteger integer;
/**
 *  AVCapturemSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* mSession;

@property(nonatomic) AVCaptureExposureMode exposureMode;
/**
 *  照片输出流
 */
@property(nonatomic,strong)AVCaptureStillImageOutput* stillImageOutput;
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* mPreviewLayer;
/**
 * 动画状态
 */
@property (nonatomic) BOOL mAnimating;
//选择按钮
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
//pickerView
@property (weak, nonatomic) IBOutlet UIPickerView *pickerviews;

@property(nonatomic,strong)AVCaptureDeviceFormat *avCapture;
//去重前帧率数组
@property(nonatomic,strong)NSMutableArray *array;
//去重之后。帧率数组
@property(nonatomic,strong)NSMutableArray  *screeningArray;

@property (nonatomic,copy) NSMutableArray *avDeviceFormatPool;
@property (nonatomic,copy) NSMutableArray *markArray;

//拍照按钮
@property (weak, nonatomic) IBOutlet UIButton *TakingPicturesButton;

//视频相关
/**
 *  输入设备  视频输入设备  声音输入
 */
@property (nonatomic, strong) AVCaptureDeviceInput* mVideoInput;
@property (nonatomic, strong) AVCaptureDeviceInput* audioInput;

/**
 *  视频输出流
 */
@property(nonatomic,strong)AVCaptureMovieFileOutput *movieFileOutput;

//设置ISO 曝光时长
///iso
@property (weak, nonatomic) IBOutlet UIView *setSize;

@property (weak, nonatomic) IBOutlet UITextField *isoTextMin;
@property (weak, nonatomic) IBOutlet UITextField *isoTextMax;

@property (weak, nonatomic) IBOutlet UILabel *isoValue;


//曝光时长
@property (weak, nonatomic) IBOutlet UITextField *ExposureDurationTextMin;

@property (weak, nonatomic) IBOutlet UITextField *ExposureDurationTextMax;

/**
 曝光时长 现在值
 */
@property (weak, nonatomic) IBOutlet UILabel *exposureValue;
//曝光补偿
@property (weak, nonatomic) IBOutlet UITextField *biasTextMax;

@property (weak, nonatomic) IBOutlet UITextField *biasTextMin;

@property (weak, nonatomic) IBOutlet UILabel *biasVlaue;
//步长
@property (weak, nonatomic) IBOutlet UITextField *isoStep;
@property (weak, nonatomic) IBOutlet UITextField *exposureStep;

- (void)initAVCapturemSession;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAVCapturemSession];
    [self initOptionsUI];
    self.mAnimating = NO;
    
    
    NSError *error = nil;
    // 创建session
    self.mSession = [[AVCaptureSession alloc] init];
    // 可以配置session以产生解析度较低的视频帧
    // 将选择的设备指定质量。
    self.mSession.sessionPreset=AVCaptureSessionPreset1280x720;;
    // 找到一个合适的AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice    defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 用device对象创建一个设备对象input，并将其添加到session
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        // 处理相应的错误
    }
    [self.mSession addInput:input];
    // 创建一个VideoDataOutput对象，将其添加到session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init] ;
    [self.mSession addOutput:output];
    // 配置output对象
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    // 指定像素格式
    output.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    // 如果你想将视频的帧数指定一个顶值, 例如15ps
    // 可以设置minFrameDuration（该属性在iOS 5.0中弃用）
    output.minFrameDuration = CMTimeMake(1, 15);
    // 启动session以启动数据流
    [self.mSession startRunning];
    // 将session附给实例变量
    [self.mPreviewLayer setSession:self.mSession];

    
    
    
}




- (void)startSession{
    
    if (![self.mSession isRunning]) {
        
        [self.mSession startRunning];
    }
}

- (void)stopSession{
    
    if ([self.mSession isRunning]) {
        
        [self.mSession stopRunning];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    self.pickerviews.hidden = YES;
    [self startSession];
}

- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    [self stopSession];
    
}

#pragma mark - private mehtod

-(void) initAVCapturemSession{
    
    self.mSession = [[AVCaptureSession alloc] init];
    if ([self.mSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        //设置为4K
        self.mSession.sessionPreset=AVCaptureSessionPreset1280x720;
    }
    NSError *error;
    
   self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [self.device lockForConfiguration:nil];
    //设置闪光灯为自动
    
    //设备判断 是iPhone时候，闪光灯自动关启用
    if ([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceFront]) {
        [self.device setFlashMode:AVCaptureFlashModeAuto];
    }
    
    if ([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear]) {
        [self.device setFlashMode:AVCaptureFlashModeAuto];
//        NSLog(@"具备后置闪光灯");
    }
    
    [self.device unlockForConfiguration];
    
    self.mVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:&error];
    
    self.audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
    
    if (error) {
//        NSLog(@"%@",error);
    }
    //视频
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];

    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
   // 添加到加工厂(输入&输出)
    if ([self.mSession canAddInput:self.mVideoInput]) {
        [self.mSession addInput:self.mVideoInput];
    }
    
    if ([self.mSession canAddInput:self.audioInput]) {
        [self.mSession addInput:self.audioInput];
    }
    
    if ([self.mSession canAddOutput:self.stillImageOutput]) {
        [self.mSession addOutput:self.stillImageOutput];
    }
    
    if ([self.mSession canAddOutput:self.movieFileOutput]) {
        [self.mSession addOutput:self.movieFileOutput];
    }
    
    self.mPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.mSession];
    
    [self.mPreviewLayer setOrientation:AVCaptureVideoOrientationLandscapeRight];
    
    [self.mPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];

    CALayer * viewLayer = [self.mCameraView layer];
    [viewLayer setMasksToBounds:YES];
    
    CGRect bounds = [self.mCameraView bounds];
    
    [self.mPreviewLayer setFrame:bounds];
    [self.mPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    [viewLayer insertSublayer:self.mPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
    initWithTarget:self action:@selector(previewTaped:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.mCameraView addGestureRecognizer:tap];
    /**
     * 设置面板注册tap事件， 防止事件透传
     **/
    tap = [[UITapGestureRecognizer alloc]
           initWithTarget:self
           action:@selector(settingTaped:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.mSettingView addGestureRecognizer:tap];
}
#pragma mark - 三个Slide 设置
#pragma mark - ISO
-(void) ISOChanged:(id)sender{
    
    UISlider *slider = (UISlider *)sender;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    [device setExposureModeCustomWithDuration:device.exposureDuration ISO:slider.value completionHandler:^(CMTime syncTime){
        AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//        [self.mExposureBias setValue:device.exposureTargetOffset];
        NSLog(@"exposureTargetOffset:%f",device.exposureTargetOffset);
//        手动模式
             AVCaptureDeviceFormat *activeFormat = self.device.activeFormat;
            CMTime minDuration = activeFormat.minExposureDuration;
            int durVal = 30;
            float clampedISO = 665;
            CMTime clampedDuration = CMTimeMake(durVal, minDuration.timescale);
            [self.device setExposureModeCustomWithDuration:clampedDuration ISO:clampedISO completionHandler:nil];
        self.device.exposureMode=AVCaptureExposureModeCustom;
            [device unlockForConfiguration];
    }];
    self.isoValue.text = [NSString stringWithFormat:@"%.4f",slider.value];
    self.biasVlaue.text = [NSString stringWithFormat:@"%.4f",self.mExposureBias.value];
}
#pragma mark - 曝光时长
-(void) exposureDurationChanged:(id)sender{
    
    UISlider *slider = (UISlider *)sender;
   AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    CMTime duration = CMTimeMakeWithSeconds(slider.value, 1000000);
    @try {
        [device lockForConfiguration:nil];
        [device setExposureModeCustomWithDuration:duration ISO:device.ISO completionHandler:^(CMTime syncTime)
         {
             AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
             // 此只读属性的值表示当前场景的计量曝光水平与目标曝光值之间的差异。
//        [self.mExposureBias setValue:device.exposureTargetOffset];

             //手动模式
   AVCaptureDeviceFormat *activeFormat = device.activeFormat;
   CMTime minDuration = activeFormat.minExposureDuration;
   int durVal = 30;
   float clampedISO = 665;
   CMTime clampedDuration = CMTimeMake(durVal, minDuration.timescale);
 [device setExposureModeCustomWithDuration:clampedDuration ISO:clampedISO completionHandler:nil];
             device.exposureMode=AVCaptureExposureModeCustom;
             
        NSLog(@",%f",device.exposureTargetOffset);
             [device unlockForConfiguration];
         }];
        self.exposureValue.text = [NSString stringWithFormat:@"%.0f",self.mExposureDuration.value*1000000];
        
        self.biasVlaue.text = [NSString stringWithFormat:@"%.4f",self.mExposureBias.value];
    } @catch (NSException *exception) {
        
    }
}
#pragma mark - 曝光补偿

-(void) exposureBiasChanged:(id)sender{
    
    UISlider *slider = (UISlider *)sender;
   self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    @try {
        [self.device lockForConfiguration:nil];
        [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        [self.device setExposureTargetBias:slider.value completionHandler:nil];
        self.biasVlaue.text = [NSString stringWithFormat:@"%.4f",slider.value];

        [self.device unlockForConfiguration];
    } @catch (NSException *exception) {
    }
    
}
#pragma mark - slide 设置结束

#pragma mark - 懒加载
- (NSMutableArray *)avDeviceFormatPool
{
    if (!_avDeviceFormatPool) {
        _avDeviceFormatPool = [NSMutableArray arrayWithCapacity:0];
    }
    return _avDeviceFormatPool;
}

- (NSMutableArray *)markArray
{
    if (!_markArray) {
        _markArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _markArray;
}

#pragma mark - 设置UI
- (void) initOptionsUI{

    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //ISO 1
    [self.mISOSlider setContinuous:YES];
    [self.mISOSlider setMinimumValue: self.device.activeFormat.minISO];
    [self.mISOSlider setMaximumValue: self.device.activeFormat.maxISO];
    [self.mISOSlider setValue:self.device.ISO];

   self.isoTextMin.text = [NSString stringWithFormat:@"%.4f", self.device.activeFormat.minISO];
    self.isoTextMax.text = [NSString stringWithFormat:@"%.4f",self.device.activeFormat.maxISO];
    
        self.isoTextMin.returnKeyType = UIReturnKeyDone;
        self.isoTextMin.keyboardType = UIKeyboardTypeNumberPad;
        self.isoTextMax.returnKeyType = UIReturnKeyDone;
        self.isoTextMax.keyboardType = UIKeyboardTypeNumberPad;
    
    self.isoValue.text = [NSString stringWithFormat:@"%.4f",self.device.ISO];
    
    [self.isoTextMin addTarget:self action:@selector(changeLengthText:) forControlEvents:UIControlEventEditingChanged];
    [self.isoTextMax addTarget:self action:@selector(changeLengthText:) forControlEvents:UIControlEventEditingChanged];
    self.isoTextMin.delegate = self;
    self.isoTextMax.delegate = self;
    
    [self.mISOSlider addTarget:self action:@selector(ISOChanged:) forControlEvents:UIControlEventValueChanged];
    
    //曝光时长  2
    [self.mExposureDuration setContinuous:YES];
    [self.mExposureDuration setMinimumValue:self.device.activeFormat.minExposureDuration.value/(1.0f*self.device.activeFormat.minExposureDuration.timescale)];
    [self.mExposureDuration setMaximumValue: self.device.activeFormat.maxExposureDuration.value/ (1.0f * self.device.activeFormat.maxExposureDuration.timescale)];
    [self.mExposureDuration setValue:self.device.exposureDuration.value/(1.0f *self.device.exposureDuration.timescale)];
    
    self.exposureValue.text = [NSString stringWithFormat:@"%.0f",self.device.exposureDuration.value/(1.0f *self.device.exposureDuration.timescale)*1000000];

   self.ExposureDurationTextMin.text = [NSString stringWithFormat:@"%.0f",self.device.activeFormat.minExposureDuration.value/(1.0f*self.device.activeFormat.minExposureDuration.timescale)*1000000];
    self.ExposureDurationTextMin.delegate =self;
    
    self.ExposureDurationTextMax.text = [NSString stringWithFormat:@"%.0f",self.device.activeFormat.maxExposureDuration.value/(1.0f*self.device.activeFormat.maxExposureDuration.timescale)*1000000];
    
    self.ExposureDurationTextMax.delegate = self;
    [self.ExposureDurationTextMin addTarget:self action:@selector(changeLengthText:) forControlEvents:UIControlEventEditingChanged];
    [self.ExposureDurationTextMax addTarget:self action:@selector(changeLengthText:) forControlEvents:UIControlEventEditingChanged];
    
    [self.mExposureDuration addTarget:self action:@selector(exposureDurationChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.ExposureDurationTextMax.returnKeyType = UIReturnKeyDone;
    self.ExposureDurationTextMax.keyboardType = UIKeyboardTypeNumberPad;
    self.ExposureDurationTextMin.returnKeyType = UIReturnKeyDone;
    self.ExposureDurationTextMin.keyboardType = UIKeyboardTypeNumberPad;

    [self.mExposureBias setValue:self.device.exposureTargetOffset];
    NSLog(@"%f",self.mExposureBias.value);
    
    
    //曝光补偿  3
    [self.mExposureBias setContinuous:YES];
    [self.mExposureBias setMinimumValue:self.device.minExposureTargetBias];
    [self.mExposureBias setMaximumValue:self.device.maxExposureTargetBias];
    [self.mExposureBias setValue:self.device.exposureTargetBias];
    [self.mExposureBias addTarget:self action:@selector(exposureBiasChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.biasTextMax.text =[NSString stringWithFormat:@"%.4f",self.device.maxExposureTargetBias];
    self.biasTextMax.delegate = self;
    self.biasTextMin.text = [NSString stringWithFormat:@"%.4f",self.device.minExposureTargetBias];
    self.biasTextMin.delegate =self;
    
    self.biasVlaue.text = [NSString stringWithFormat:@"%.4f",self.device.exposureTargetBias];

    [self.biasTextMax addTarget:self action:@selector(exposureDurationChanged:) forControlEvents:UIControlEventValueChanged];
    [self.biasTextMin addTarget:self action:@selector(exposureDurationChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.biasTextMax.returnKeyType = UIReturnKeyDone;
    self.biasTextMax.keyboardType = UIKeyboardTypeNumberPad;
    self.biasTextMin.returnKeyType = UIReturnKeyDone;
    self.biasTextMin.keyboardType = UIKeyboardTypeNumberPad;

    self.isoStep.keyboardType =UIKeyboardTypeNumberPad;
    self.isoStep.returnKeyType =UIReturnKeyDone;
    self.exposureStep.keyboardType =UIKeyboardTypeNumberPad;
    self.exposureStep.returnKeyType =UIReturnKeyDone;
    
    
    [self.isoStep addTarget:self action:@selector(changeLengthText:) forControlEvents:UIControlEventEditingChanged];

        [self.exposureStep addTarget:self action:@selector(changeLengthText:) forControlEvents:UIControlEventEditingChanged];
    self.array = [NSMutableArray array];
    
    self.avCapture = self.device.activeFormat;
    
    NSArray * frameRates = [self.device formats];
    for (NSInteger i=0; i<frameRates.count; i++) {
        AVCaptureDeviceFormat *deviceformat = frameRates[i];
        
        self.avCapture = frameRates[i];
        [self.avDeviceFormatPool addObject:deviceformat];        AVFrameRateRange * range = self.avCapture.videoSupportedFrameRateRanges[0];
        Float64 minRange =  range.minFrameRate;
        Float64 maxRange =  range.maxFrameRate;
        NSString *string = [[NSString stringWithFormat:@"%0.f",minRange] stringByAppendingString:@"-"];
        NSString *allString = [string stringByAppendingString:[NSString stringWithFormat:@"%0.f",maxRange]];
        [self.array addObject:allString];
    }
    self.screeningArray = [[NSMutableArray alloc]init];
    //去重
    [self.array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (![self.screeningArray containsObject:obj]) {
            NSNumber *number = [NSNumber numberWithUnsignedInteger:idx];
            [self.markArray addObject:number];
            [self.screeningArray addObject:obj];
        }
    }];
    
    [self.selectButton addTarget:self action:@selector(selectList:) forControlEvents:UIControlEventTouchUpInside];
    //拍照按钮
    [self.TakingPicturesButton addTarget:self action:@selector(TakingPictureClick) forControlEvents:UIControlEventTouchUpInside];
    //长按手势
    UILongPressGestureRecognizer * longPressGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(takeVideoButtonPress:)];
    //button添加长按手势，实现录制功能
    [self.TakingPicturesButton addGestureRecognizer:longPressGr];
    
    //主view设置长按手势 弹出设置ISO 曝光时长view
    UILongPressGestureRecognizer *longPressView = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(SettingSize:)];
    [self.mCameraView addGestureRecognizer:longPressView];
    self.setSize.hidden=YES;
    
}
#pragma mark - 取消键盘
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self.isoTextMax resignFirstResponder];
    [self.isoTextMin resignFirstResponder];
    [self.ExposureDurationTextMax resignFirstResponder];
    [self.ExposureDurationTextMin resignFirstResponder];
    [self.biasTextMax resignFirstResponder];
    [self.biasTextMin resignFirstResponder];
    [self.isoStep resignFirstResponder];
    [self.exposureStep resignFirstResponder];
    
    
}
#pragma mark - text传值

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    
    self.mISOSlider.minimumValue = [self.isoTextMin.text floatValue];
    self.mISOSlider.maximumValue = [self.isoTextMax.text floatValue];
    
    self.mExposureDuration.maximumValue = [self.ExposureDurationTextMax.text floatValue]/1000000;
    
    self.mExposureDuration.minimumValue = [self.ExposureDurationTextMin.text floatValue]/1000000;
    
    self.mExposureBias.minimumValue = [self.biasTextMin.text floatValue];
    
    self.mExposureBias.maximumValue = [self.biasTextMax.text floatValue];
    
    return YES;
}

#pragma mark - textfiled  限制 7位
-(void)changeLengthText:(UITextField *)textField {//手机号
    NSString  *nsTextContent = textField.text;
    NSInteger existTextNum = nsTextContent.length;
    if (existTextNum > 7)
    {
        //截取到最大位置的字符
        NSString *s = [nsTextContent substringToIndex:7];
        [textField setText:s];
    }
}

#pragma mark - 设置右侧view的显示

-(void)SettingSize:(UILongPressGestureRecognizer *)sender{

    if (sender.state ==UIGestureRecognizerStateBegan) {
        self.setSize.hidden = ! self.setSize.hidden ;
    }
}

#pragma mark - 选择button方法设置
-(void)selectList:(UIButton *)sender{
    
    self.pickerviews.delegate = self;
    self.pickerviews.dataSource = self;
    self.pickerviews.hidden = NO;
    
}
#pragma mark - pickerView方法实现
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return self.screeningArray.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return self.screeningArray[row];
}
#pragma mark - didSelectRow
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    
    NSString *title = self.screeningArray[row];
    self.pickerviews.hidden = YES;
    [self.selectButton setTitle:title forState:UIControlStateNormal];
    
    AVCaptureDeviceFormat *format = self.avDeviceFormatPool[[self.markArray[row] integerValue]];
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [self.mSession beginConfiguration];
    NSError * error;
    
    AVFrameRateRange * range = format.videoSupportedFrameRateRanges[0];
    
    if ( [self.device lockForConfiguration:&error] ) {
        
        [self.device setActiveFormat:format];
        [self.device setActiveVideoMinFrameDuration:range.minFrameDuration];
        [self.device setActiveVideoMaxFrameDuration:range.maxFrameDuration];
        [self.device unlockForConfiguration];
    }
    [self.device unlockForConfiguration];
    [self.mSession commitConfiguration];
}

#pragma mark - 拍照功能的开始
#pragma mark - 获取设备方向
-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if(deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

#pragma mark - 拍照方法

//-(void)TakingPictureClick{
//
//    dispatch_group_t requestGroup = dispatch_group_create();
//    dispatch_apply(5 , dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
//        dispatch_group_enter(requestGroup);
//        AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
//        UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
//        AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
//        [stillImageConnection setVideoOrientation:avcaptureOrientation];
//        //控制焦距
//        [stillImageConnection setVideoScaleAndCropFactor:1];
//        @try {
//        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
//                            NSData *  jpegData;
//                if (imageDataSampleBuffer!=nil) {
//                    jpegData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:imageDataSampleBuffer previewPhotoSampleBuffer:nil];
//    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,imageDataSampleBuffer,kCMAttachmentMode_ShouldPropagate);
//                    
//                }
//
//ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
//                if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
//                    //无权限
//                    return ;
//                }
//                //沙盒路径
//                NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
//                NSFileManager *fileManager = [NSFileManager defaultManager];
//                NSString *Preview = [basePath stringByAppendingPathComponent:@"Image"];
//                BOOL isSuccess = [fileManager createDirectoryAtPath:Preview withIntermediateDirectories:YES attributes:nil error:nil];
//                if (isSuccess) {
//                    //                NSLog(@"success");
//                } else {
//                    //                NSLog(@"fail");
//                }
//                NSDateFormatter * formatter = [[NSDateFormatter alloc]init];
//                [formatter setDateFormat:@"YYYY-MM-dd_HH-mm-ss-SSS"];
//                NSString* date = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
//                NSString * timeNow = [[NSString alloc] initWithFormat:@"%@", date];
//                NSString *stringImg = [[@"Image_" stringByAppendingString:timeNow] stringByAppendingString:@".jpeg"];
//                //图片存入沙盒
//                NSString* path = [Preview stringByAppendingPathComponent:stringImg];
//                [jpegData writeToFile:path atomically:YES];
//                UIImage *imgFromUrl3=[[UIImage alloc]initWithContentsOfFile:path];
//                // 图片保存相册
//                UIImageWriteToSavedPhotosAlbum(imgFromUrl3, self,nil,nil);
//            }];
//            
//        } @catch (NSException *exception) {
//            
//        }
//       
//        dispatch_group_leave(requestGroup);
//    });
//    dispatch_group_notify(requestGroup, dispatch_get_main_queue(), ^{
//    });
//}


#pragma mark - 步长拍照按钮
- (IBAction)ContinuousShootStepButton:(id)sender {
    float isoMin = [self.isoTextMin.text floatValue];
    float isoMax = [self.isoTextMax.text floatValue];
    float exposureMin = [self.ExposureDurationTextMin.text floatValue]/1000000;
    float exposureMax = [self.ExposureDurationTextMax.text floatValue]/1000000;
    float isoStep = [self.isoStep.text floatValue];
    float exposureStep = [self.exposureStep.text floatValue]/1000000;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (float i = isoMin; i<= isoMax; i+=isoStep) {
            sleep(1);
            for (float j =exposureMin; j<= exposureMax;j+=exposureStep) {
                sleep(2);
                [self TakingPictureClick];
                NSLog(@"%f,%f",i,j);
    }
}
});
}

#pragma mark - 拍照功能的结束 到此结束

#pragma mark - 手势 弹出菜单
- (void)previewTaped:(id)sender{
    
    if(NO == self.mAnimating){
        self.mAnimating = YES;
        [UIView animateWithDuration:0.6f animations:^{
            if(1 == self.mSettingOffset.constant){
                self.mSettingOffset.constant = self.mCameraView.bounds.size.width/2;
            }
            else{
                self.mSettingOffset.constant = 1;
            }
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.mAnimating = NO;
        }];
    }
}

- (void)settingTaped:(id)sender{
    
}
#pragma mark 提示信息
- (void)textExample :(NSString *)string{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText =string;
    hud.yOffset = 180.f;
    [hud hide:YES afterDelay:3.f];
}

#pragma mark - button 长按实现
#pragma mark - response method
//- (void)takeVideoButtonPress:(UILongPressGestureRecognizer *)sender {
//    
////    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
////    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
////    {
////        return;
////    }
////    //判断用户是否允许访问麦克风权限
////    authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
////    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
////    {
////        //无权限
////        return;
////    }
//    switch (sender.state) {
//        case UIGestureRecognizerStateBegan:
//            [self startVideoRecorder];
//            break;
//        case UIGestureRecognizerStateCancelled:
//
//            [self stopVideoRecorder];
//            break;
//        case UIGestureRecognizerStateEnded:
//            [self stopVideoRecorder];
//            break;
//        case UIGestureRecognizerStateFailed:
//            [self stopVideoRecorder];
//            break;
//        default:
//            break;
//    }
//    
//}

- (void)TakingPictureClick{
    
    _integer = 5;
    

//    AVCaptureConnection *movieConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//    AVCaptureVideoOrientation avcaptureOrientation = AVCaptureVideoOrientationPortrait;
//    [movieConnection setVideoOrientation:avcaptureOrientation];
//    [movieConnection setVideoScaleAndCropFactor:1.0];
//    
//    NSURL *url = [[RAFileManager defaultManager] filePathUrlWithUrl:[self getVideoSaveFilePathString]];
//    
//    [self.movieFileOutput startRecordingToOutputFileURL:url recordingDelegate:self];
//    
//        创建并配置一个捕获会话并且启用它
    }
//#pragma mark - 结束录制
//- (void)stopVideoRecorder{
//    
//    [self.movieFileOutput stopRecording];
//}

//#pragma  mark - 视频名以当前日期为名
//- (NSString*)getVideoSaveFilePathString{
//    NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
//    [formatter setDateFormat:@"YYYY-MM-dd_HH-mm-ss"];
//    NSString* date = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
//    NSString * timeNow = [[NSString alloc] initWithFormat:@"%@", date];
//    NSString *video = [@"video_" stringByAppendingString:timeNow];
//    return video;
//}

//#pragma mark - 视频输出
//- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
//    
//    if (CMTimeGetSeconds(captureOutput.recordedDuration) < VIDEO_RECORDER_MIN_TIME) {
//    
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"视频时间过短" message:nil
//        preferredStyle:UIAlertControllerStyleAlert];
//        
//        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
//        
//        [self presentViewController:alert animated:YES completion:nil];
//        return;
//    }
////    NSLog(@"%s-- url = %@ ,recode = %f , int %lld kb", __func__, outputFileURL, CMTimeGetSeconds(captureOutput.recordedDuration), captureOutput.recordedFileSize / 1024);
////视频保存本地照片
//    ALAssetsLibrary *lib =[[ALAssetsLibrary alloc] init];
//    [lib writeVideoAtPathToSavedPhotosAlbum: outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
//    }];
//}

#pragma  mark - 截图方法
// 抽样缓存写入时所调用的委托程序

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection{
    
    dispatch_group_t requestGroup = dispatch_group_create();
    dispatch_apply(5, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t i) {
        dispatch_group_enter(requestGroup);
    if (_integer==5) {
        UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
        //沙盒创建
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *Preview = [basePath stringByAppendingPathComponent:@"Preview"];
        BOOL isSuccess = [fileManager createDirectoryAtPath:Preview withIntermediateDirectories:YES attributes:nil error:nil];
        if (isSuccess) {
            //            NSLog(@"success");
        } else {
            //            NSLog(@"fail");
        }
        //    此处添加使用该image对象的代码
        NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
        [formatter setDateFormat:@"YYYY-MM-dd_HH-mm-ss-SSSS"];
        NSString* date = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
        NSString * timeNow = [[NSString alloc] initWithFormat:@"%@", date];
        
        NSString *stringImg = [[@"Preview_" stringByAppendingString:timeNow] stringByAppendingString:@".png"];
        //图片存入沙盒
        NSString* path = [Preview stringByAppendingPathComponent:stringImg];
        NSData *iamgedata = UIImagePNGRepresentation(image);
        [iamgedata writeToFile:path atomically:YES];
        
        // 拿到沙盒路径图片
        UIImage *imgFromUrl3=[[UIImage alloc]initWithContentsOfFile:path];
        // 图片保存相册
        UIImageWriteToSavedPhotosAlbum(imgFromUrl3, self, nil, nil);
        NSLog(@"抽样缓存写入时所调用的委托程序image%@ \n %@",image,stringImg);
    }
        dispatch_group_leave(requestGroup);

    });
    dispatch_group_notify(requestGroup, dispatch_get_main_queue(), ^{
    });
    _integer=0;

}
// 通过抽样缓存数据创建一个UIImage对象
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return (image);
}

@end
