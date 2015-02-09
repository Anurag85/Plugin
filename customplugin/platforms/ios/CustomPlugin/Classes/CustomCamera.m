//
//  CustomCamera.m
//  CustomPlugin
//
//  Created by Anurag Kumar Gupta on 31/01/15.
//
//

#import "CustomCamera.h"

@interface CustomCamera ()
{
    NSString *mode;
}

@end


@implementation CustomCamera

-(void)openCamera:(CDVInvokedUrlCommand *)command {
    // Set the hasPendingOperation field to prevent the webview from crashing
    self.hasPendingOperation = YES;
    
    // Save the CDVInvokedUrlCommand as a property.  We will need it later.
    self.latestCommand = command;
    self.cameraMode = [NSString stringWithFormat:@"Video"];//@"Video";
    
    // Make the overlay view controller.
    self.overlayView = [[CustomCameraViewController alloc] initWithNibName:@"CustomCameraViewController" bundle:nil];
    self.overlayView.cameraPlugin = self;
    self.overlayView.cameraMode = @"Both";
    
    [self.viewController presentViewController:self.overlayView.picker animated:YES completion:nil];
}

-(void) capturedImageWithPath:(NSString*)imagePath {
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:imagePath] callbackId:self.latestCommand.callbackId];
    
    // Unset the self.hasPendingOperation property
    self.hasPendingOperation = NO;
    
    // Hide the picker view
    //    [self.viewController dismissModalViewControllerAnimated:YES];
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

-(void) recentButtonCallback:(NSString *)path
{
    NSDictionary *returnDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithBool:YES],@"recentObject",path,@"objectPath",nil];
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary] callbackId:self.latestCommand.callbackId];
    
    // Unset the self.hasPendingOperation property
    self.hasPendingOperation = NO;
    
    // Hide the picker view
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

-(void) galleryButtonCallback
{
    NSDictionary *returnDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithBool:NO],@"recentObject",@"",@"objectPath",nil];
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnDictionary] callbackId:self.latestCommand.callbackId];
    
    // Unset the self.hasPendingOperation property
    self.hasPendingOperation = NO;
    
    // Hide the picker view
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
