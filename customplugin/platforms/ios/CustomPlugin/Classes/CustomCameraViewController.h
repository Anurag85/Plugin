//
//  CustomCameraViewController.h
//  CustomPlugin
//
//  Created by Anurag Kumar Gupta on 31/01/15.
//
//


#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class CustomCamera;

@interface CustomCameraViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, CLLocationManagerDelegate>

    @property (strong, nonatomic) IBOutlet UIButton *cameraSelectionButton;
    @property (strong, nonatomic) IBOutlet UIButton *flashModeButton;
    @property (strong, nonatomic) IBOutlet UIButton *captureButton;
    @property (strong, nonatomic) IBOutlet UIButton *recentButton;
    @property (strong, nonatomic) IBOutlet UIButton *galleryButton;

    @property (strong, nonatomic) IBOutlet UIPickerView *modePicker;
    @property (strong, nonatomic) IBOutlet UILabel *videoRecordingTimerLabel;

// Action method
- (IBAction)captureButtonPressed:(id)sender;
- (IBAction)flashButtonPressed:(id)sender;
- (IBAction)cameraSelectionButtonPressed:(id)sender;
- (IBAction)recentButtonPressed:(id)sender;
- (IBAction)galleryButtonPressed:(id)sender;

// Declare some properties
@property (strong, nonatomic) CustomCamera* cameraPlugin;
@property (strong, nonatomic) UIImagePickerController* picker;

@property (strong, nonatomic) NSString *cameraMode;
@property (strong, nonatomic) NSString *directoryPath;

@end
