//
//  CustomCamera.h
//  CustomPlugin
//
//  Created by Anurag Kumar Gupta on 31/01/15.
//
//

#import <Cordova/CDV.h>

#import "CustomCameraViewController.h"

@interface CustomCamera : CDVPlugin

// Cordova command method
-(void) openCamera:(CDVInvokedUrlCommand*)command;


-(void) capturedImageWithPath:(NSString*)imagePath;

-(void)recentButtonCallback:(NSString *)path;
-(void)galleryButtonCallback;

@property (strong, nonatomic) CustomCameraViewController* overlayView;
@property (strong, nonatomic) CDVInvokedUrlCommand* latestCommand;
@property (readwrite, assign) BOOL hasPendingOperation;

@property (strong, nonatomic) NSString *cameraMode;
@property (strong, nonatomic) NSString *directoryPath;

@end
