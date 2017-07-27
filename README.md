
## 项目背景

金山魔方是一个多媒体能力提供平台，通过统一接入API、统一鉴权、统一计费等多种手段，降低客户接入多媒体处理能力的代价，提供多媒体能力供应商的效率。 本文档主要对录屏功能说明。
金山云录屏直播SDK是金山云提供的直播解决方案的一部分，完成了iOS端全屏录制的功能，主要实现思路是本SDK内实现了一个Airplay的接收端, 开始录屏时iOS系统与SDK建立连接, SDK收到画面后, 编码发送到直播服务器. 其中编码和推流功能使用金山云直播SDK实现.

![Alt text](./1500969069950.png)


可以用于手游等直播录制场景。

## 录屏功能

 iOS8/9/10 支持
 录屏支持
## 关于上架

根据Apple的政策, 含有Airplay功能的APP无法通过App Store审查, 请注意.

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
