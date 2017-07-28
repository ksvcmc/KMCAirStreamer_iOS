//
//  KSYViewController.m
//  KSYAirStreamer
//
//  Created by pengbins on 04/11/2017.
//  Copyright (c) 2017 pengbins. All rights reserved.
//
#import "recordViewController.h"
#import "KSYAirStreamKit.h"
#import <libksygpulive/libksystreamerengine.h>
#import "UIColor+Expanded.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MBProgressHUD.h"
#import <Photos/Photos.h>

@interface recordViewController () <KSYAirDelegate>{
    KSYAirStreamKit * _kit;
    NSTimer *_playbackProgressTimer;
    int time;
    BOOL _localRecord;
    int _frameRate;
    int _videoSize;
}
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *resolution;
@property (weak, nonatomic) IBOutlet UISwitch *saveSwitch;
@property (weak, nonatomic) IBOutlet UISlider *frameSlide;
@property (weak, nonatomic) IBOutlet UITextField *addrTextField;
@property (weak, nonatomic) IBOutlet UILabel *frameRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@end

@implementation recordViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    [self askForPhotoLibraryAuth];
    [self askForMicAuth];
    [self setupUI];
    
    _kit = [[KSYAirStreamKit alloc] initWithTokeID:@"eb84554d62dfddcf0f6328c43bacba13" onSuccess:^(void){
        NSLog(@"鉴权成功");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.recordButton.enabled = YES;
        });
    } onFailure:^(AuthorizeError iErrorCode) {
        NSLog(@"鉴权失败");
    }];
    _kit.delegate = self;
    
    _frameRate = 24;
    _videoSize = 720;
    
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    [dc addObserver:self
           selector:@selector(onStreamStateChange)
               name:KSYStreamStateDidChangeNotification
             object:nil];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewPressed)];
    [self.view addGestureRecognizer:tapGes];
}

-(void)askForPhotoLibraryAuth{
    PHAuthorizationStatus photoAuthorStatus = [PHPhotoLibrary authorizationStatus];
    switch (photoAuthorStatus) {
        case PHAuthorizationStatusNotDetermined:
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    NSLog(@"Authorized");
                }else{
                    NSLog(@"Denied or Restricted");
                }
            NSLog(@"not Determined");
            }];
            break;
        default:
            break;
    }
}
-(void)askForMicAuth{
    AVAuthorizationStatus AVstatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];//麦克风权限
    switch (AVstatus) {
        case AVAuthorizationStatusNotDetermined:
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {//麦克风权限
                if (granted) {
                    NSLog(@"Authorized");
                }else{
                    NSLog(@"Denied or Restricted");
                }}];
            break;
        default:
            break;
    }
    
}


-(void)setupUI{
    //分辨率颜色
    self.resolution.tintColor = [UIColor colorWithHexString:@"#25bdd8"];
    //推流地址
    NSString *rtmpSrv = @"rtmp://test.uplive.ks-cdn.com/live";
    NSString *devCode = [[[[[UIDevice currentDevice] identifierForVendor] UUIDString] lowercaseString]substringToIndex:3];
    NSString *url     = [NSString stringWithFormat:@"%@/%@", rtmpSrv, devCode];
    self.addrTextField.text = url;
    
    self.recordButton.enabled = NO;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - action

-(void)bgViewPressed{
    [self.addrTextField resignFirstResponder];
}
- (IBAction)resolutionValue:(id)sender {
    switch (self.resolution.selectedSegmentIndex) {
        case 0:
            _videoSize = 720;
            break;
        case 1:
            _videoSize = 960;
            break;
        case 2:
            _videoSize = 1280;
            break;
        default:
            _videoSize = 720;
    }
}
- (IBAction)frameRateChanged:(id)sender {
    UISlider * slider = sender;
    _frameRate = slider.value;
    
    self.frameRateLabel.text = [NSString stringWithFormat:@"%dfps",(int)slider.value];
}
- (IBAction)saveToLocalFile:(id)sender {
    UISwitch * localSwitch = sender;
    _localRecord = localSwitch.on;
}

- (IBAction)record:(id)sender {
    UIButton * recordButton = sender;
    if(recordButton.isSelected){//开始录制
        recordButton.selected = NO;
        [recordButton setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
        
        //录屏配置信息,每次必须新建一个
        KSYAirTunesConfig* cfg = [[KSYAirTunesConfig alloc] init];
        cfg.framerate = _frameRate;
        NSString * name = [self.addrTextField.text substringFromIndex:self.addrTextField.text.length-3];
        cfg.airplayName = [NSString stringWithFormat:@"ksyair_%@", name];
        cfg.videoSize = _videoSize;

        _kit.airCfg = cfg;
        _kit.videoBitrate = 1000;
        //设置推流地址
        _kit.streamUrl = self.addrTextField.text;
        //开启服务
        [_kit startService];
        
        self.resolution.enabled = NO;
        self.saveSwitch.enabled = NO;
        self.frameSlide.enabled = NO;

    }
    else{//结束录制
        [self stopTimer];
        [_kit stopService];
        
        self.resolution.enabled = YES;
        self.saveSwitch.enabled = YES;
        self.frameSlide.enabled = YES;
    }
}

- (void) onStreamStateChange {
    if (_kit.streamerBase){
        NSLog(@"stream State %@", [_kit.streamerBase getCurStreamStateName]);
        if(_kit.streamerBase.streamState == KSYStreamStateConnecting ||
           _kit.streamerBase.streamState == KSYStreamStateConnected){
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            progressHud.mode = MBProgressHUDModeIndeterminate;
            progressHud.labelText = [_kit.streamerBase getCurStreamStateName];
            progressHud.color = [UIColor colorWithHexString:@"#1a2845"];
            progressHud.dimBackground = YES;
            progressHud.cornerRadius =10;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
        }
    }
    
    if(_kit.streamerBase.streamState == KSYStreamStateConnected){
        //设置录制时间
        [self startTimer];
        if(_localRecord){
            NSLog(@"录制到本地");
            [self startRecordToLocalFile];
        }
    }
    
    if(_kit.streamerBase.streamState == KSYStreamStateError){
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progressHud.mode = MBProgressHUDModeIndeterminate;
        progressHud.labelText = [_kit.streamerBase getCurStreamStateName];
        progressHud.color = [UIColor colorWithHexString:@"#1a2845"];
        progressHud.dimBackground = YES;
        progressHud.cornerRadius =10;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
    }
    
}

-(void)startRecordToLocalFile{
    BOOL bRec = _kit.streamerBase.bypassRecordState == KSYRecordStateRecording;
    if ( _kit.streamerBase.isStreaming && !bRec){
        // 如果启动录像时使用和上次相同的路径,则会覆盖掉上一次录像的文件内容
        NSString *ourDocumentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask,YES) objectAtIndex:0];
        NSString *FilePath=[ourDocumentPath stringByAppendingPathComponent:@"temp.mp4"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:FilePath]){
            [fileManager removeItemAtPath:FilePath error:nil];
        }
        
        NSURL *url =[[NSURL alloc] initFileURLWithPath:FilePath];
        [_kit.streamerBase startBypassRecord:url];
    }
    else {
        NSLog(@"推流过程中才能旁路录像");
    }
}

-(void)saveToPhotoLibrary{
    [_kit.streamerBase stopBypassRecord];

    MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressHud.mode = MBProgressHUDModeIndeterminate;
    progressHud.labelText = [NSString stringWithFormat:@"保存到相册"];
    progressHud.color = [UIColor colorWithHexString:@"#1a2845"];
    progressHud.dimBackground = YES;
    progressHud.cornerRadius =10;
    
    NSString *ourDocumentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask,YES) objectAtIndex:0];
    NSString *FilePath=[ourDocumentPath stringByAppendingPathComponent:@"temp.mp4"];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:FilePath]
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    if (error) {
                                        NSLog(@"Save video fail:%@",error);
                                    } else {
                                        NSLog(@"Save video succeed.");
                                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                    }
                                }];
}

-(void)startTimer{
    if(_playbackProgressTimer){
        [_playbackProgressTimer invalidate];
        time = 0;
    }
    NSTimeInterval timeInterval = 1;
    _playbackProgressTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                              target:self
                                                            selector:@selector(handleProgressTimer:)
                                                            userInfo:nil
                                                             repeats:YES];
    
}

-(void)stopTimer{
    if(_playbackProgressTimer){
        [_playbackProgressTimer invalidate];
        time = 0;
    }
     self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)0, (long)0, (long)0];
    self.timerLabel.hidden =YES;
}

- (void)handleProgressTimer:(NSTimer *)timer {
    self.timerLabel.hidden = NO;
    time++;
    
    int hour = (int)(time/60/60);
    int minutes = (int)((time - 60 * 60 *hour)/60);
    int seconds = (int)(time - 60*60*hour - 60*minutes);
    
    self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hour, (long)minutes, (long)seconds];
}

#pragma mark - KSYAirDelegate
- (void) didStartMirroring:(KSYAirTunesServer *)server {
}

- (void)mirroringErrorDidOcccur:(KSYAirTunesServer *)server  withError:(NSError *)error {
    //[_kit stopService];
    NSLog(@"error happen,%@",error);
}
- (void)didStopMirroring:(KSYAirTunesServer *)server {
    NSLog(@"停止镜像");
    self.recordButton.selected = YES;
    [self.recordButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    
    if(_localRecord)
        [self saveToPhotoLibrary];
}
@end
