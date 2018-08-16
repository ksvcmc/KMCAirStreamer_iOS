
[![Apps Using](https://img.shields.io/cocoapods/at/KMCAirStreamer.svg?label=Apps%20Using%20KMCAirStreamer&colorB=28B9FE)](http://cocoapods.org/pods/KMCAirStreamer)[![Downloads](https://img.shields.io/cocoapods/dt/KMCAirStreamer.svg?label=Total%20Downloads%20KMCAirStreamer&colorB=28B9FE)](http://cocoapods.org/pods/KMCAirStreamer)

[![Build Status](https://travis-ci.org/ksvcmc/KMCAirStreamer_iOS.svg?branch=master)](https://travis-ci.org//ksvcmc/KMCAirStreamer_iOS)
[![Latest release](https://img.shields.io/github/release/ksvcmc/KMCAirStreamer_iOS.svg)](https://github.com/ksvcmc/KMCAirStreamer_iOS/releases/latest)
[![CocoaPods platform](https://img.shields.io/cocoapods/p/KMCAirStreamer.svg)](https://cocoapods.org/pods/KMCAirStreamer)
[![CocoaPods version](https://img.shields.io/cocoapods/v/KMCAirStreamer.svg?label=pod_github)](https://cocoapods.org/pods/KMCAirStreamer)

## 项目背景

金山魔方是一个多媒体能力提供平台，通过统一接入API、统一鉴权、统一计费等多种手段，降低客户接入多媒体处理能力的代价，提供多媒体能力供应商的效率。 本文档主要对录屏功能说明。
金山云录屏直播SDK是金山云提供的直播解决方案的一部分，完成了iOS端全屏录制的功能，主要实现思路是本SDK内实现了一个Airplay的接收端, 开始录屏时iOS系统与SDK建立连接, SDK收到画面后, 编码发送到直播服务器. 其中编码和推流功能使用金山云直播SDK实现.

![Alt text](https://raw.githubusercontent.com/wiki/ksvcmc/KMCAirStreamer_iOS/airplay.png)


可以用于手游等直播录制场景。
## 效果展示
![Alt text](https://raw.githubusercontent.com/wiki/ksvcmc/KMCAirStreamer_iOS/airplayimg.jpg)

## 录屏功能

 iOS8/9/10 支持
 录屏支持
## 关于上架

根据Apple的政策, 含有Airplay功能的APP无法通过App Store审查, 请注意.
## 鉴权
SDK在使用时需要用token进行鉴权后方可使用，token申请方式见**接入步骤**部分;  
token与应用包名为一一对应的关系;  
鉴权错误码见：https://github.com/ksvcmc/KMCAgoraVRTC_Android/wiki/auth_error

## 安装

安装包分为三部分:
- demo:可运行的示例程序
- doc:说明文档

目前sdk支持pod导入.
- pod ‘KMCAirStreamer’

## SDK包总体介绍
- **KMCAirTunesServer**---录屏服务端类，可以拿到录屏后数据，以及录屏中各种事件。
- **KSYAirTunesConfig**---录屏配置类。
## SDK API介绍
### 鉴权
```objectivec
/**
 @discuss 申请得到的tokeID
 @param completeSuccess 完成回调
 @param completeFailure 失败回调
 */
- (void)authorizeWithTokeID:(NSString *)tokeID
                  onSuccess:(void (^)(void))completeSuccess
                  onFailure:(void (^)(AuthorizeError iErrorCode))completeFailure;

```
### 录屏数据回调
```objectivec
/**
 获取屏幕画面的回调
 */
property(nonatomic, copy) void(^videoProcessingCallback)(CVPixelBufferRef pixelBuffer, CMTime timeInfo );

```
### 录屏通知
```objectivec
/**
 录制过程的通知代理
 */
@property(nonatomic, weak) id<KSYAirDelegate> delegate;
```
### 录屏状态
```objectivec
/**
 airplay 录制状态
 */
@property(nonatomic, readonly) KSYAirState airState;
```
### 启动服务
```objectivec
/**
 启动服务
 
 @param cfg 服务的配置信息
 */
- (BOOL) startServerWithCfg:(KSYAirTunesConfig*)cfg;
```
### 停止服务
```objectivec
/**
 停止服务
 */
- (void) stopServer;
```
### 配置项
```objectivec
@interface KSYAirTunesConfig : NSObject
/// AirPlay 设备的名字
@property(nonatomic, copy) NSString *airplayName;
/// 接收设备的尺寸(竖屏时高度为videoSize, 宽度根据屏幕比例计算得到,横屏时反之)
@property(nonatomic, assign) int videoSize;
/// 希望接收到ios发送端的视频帧率 默认30
@property(nonatomic, assign) int framerate;
/// 设置airtunes 服务的监听端口, 0 表示系统自动分配
@property(nonatomic, assign) short airTunesPort;
/// 设置视频数据的接收端口，默认是7100, 当7100被占用时, 会尝试+1 尝试10次, 如果仍然失败报告端口冲突
@property(nonatomic, assign) short airVideoPort;
/// 设备的mac地址, 默认随机生成,(长度为6字节)
@property(nonatomic, copy) NSData *macAddr;
@end
```
### 事件通知
```objectivec
/**
 airplay 镜像成功开始了
 
 @param server airplay服务对象
 */
- (void)didStartMirroring:(KSYAirTunesServer *)server;

@required
/**
 airplay 镜像 遇到错误了
 
 @param server airplay服务对象
 @param error  遇到的错误, code 参见 KSYAirErrorCode的定义
 */
- (void)mirroringErrorDidOcccur:(KSYAirTunesServer *)server  withError:(NSError *)error;

@required
/**
 airplay 镜像成功结束了
 
 @param server airplay服务对象
 */
- (void)didStopMirroring:(KSYAirTunesServer *)server;

```
## 接入流程
![金山魔方接入流程](https://raw.githubusercontent.com/wiki/ksvcmc/KMCSTFilter_Android/all.jpg "金山魔方接入流程")
## 接入步骤  
1.登录[金山云控制台]( https://console.ksyun.com)，选择视频服务-金山魔方
![步骤1](https://raw.githubusercontent.com/wiki/ksvcmc/KMCSTFilter_Android/step1.png "接入步骤1")

2.在金山魔方控制台中挑选所需服务。
![步骤2](https://raw.githubusercontent.com/wiki/ksvcmc/KMCSTFilter_Android/step2.png "接入步骤2")

3.点击申请试用，填写申请资料。
![步骤3](https://raw.githubusercontent.com/wiki/ksvcmc/KMCSTFilter_Android/step3.png "接入步骤3")

![步骤4](https://raw.githubusercontent.com/wiki/ksvcmc/KMCSTFilter_Android/step4.png "接入步骤4")

4.待申请审核通过后，金山云注册时的邮箱会收到邮件及试用token。
![步骤5](https://raw.githubusercontent.com/wiki/ksvcmc/KMCSTFilter_Android/step5.png "接入步骤5")

5.下载安卓/iOS版本的SDK集成进项目。
![步骤6](https://raw.githubusercontent.com/wiki/ksvcmc/KMCSTFilter_Android/step6.png "接入步骤6")

6.参照文档和DEMO填写TOKEN，就可以Run通项目了。  
7.试用中或试用结束后，有意愿购买该服务可以与我们的商务人员联系购买。  
（商务Email:KSC-VBU-KMC@kingsoft.com） 
## Demo下载
[![QRcode](https://static.pgyer.com/app/qrcode/TIhS)](http://www.pgyer.com/TIhS) 
## 反馈与建议  
主页：[金山魔方](https://docs.ksyun.com/read/latest/142/_book/index.html)  
邮箱：ksc-vbu-kmc-dev@kingsoft.com
