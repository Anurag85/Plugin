//
//  CustomCameraViewController.m
//  CustomPlugin
//
//  Created by Anurag Kumar Gupta on 31/01/15.
//
//

#import "CustomCameraViewController.h"
#import "CustomCamera.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>

#define GALLERY_FOLDER_NAME @"Gallery"
#define META_DATA_FILE_NAME @"MetaData"
#define TIME_STAMP [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]

@interface CustomCameraViewController ()
{
    BOOL photoModeActive;
    NSString *mediaPath;
    
    NSArray *modePickerDataArray;
    NSInteger selectedRow;
    
    CLLocationManager *locationManager;
    CLLocation *userLocation;
    CLGeocoder *geocoder;
    NSString *userLocality;
    NSString *userSublocality;
    
    NSString *documentDirectory;
    NSString *galleryPath;
    NSString *jsonFilePath;
    
    NSDate *videoRecordingStartTime;
    NSTimer *recordingTimer;
    NSString *recordingTimerText;
    BOOL stopTheTimer;
}

@property (nonatomic) UIImagePickerControllerCameraFlashMode flashMode;

-(void)configureView;
-(void)saveMetaDataOfMediaWithName:(NSString *)name ofType:(NSString *)type availabelAtPath:(NSString *)path;

-(void)settingVideoTimerLabel;
-(void)callReverseGeocodingAPI;

-(void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message;

@end

@implementation CustomCameraViewController

// Entry point method
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Instantiate the UIImagePickerController instance
        self.picker = [[UIImagePickerController alloc] init];
        
        // Configure the UIImagePickerController instance
        self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, (NSString *) kUTTypeImage, nil];
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        
        self.flashMode = UIImagePickerControllerCameraFlashModeAuto;
        self.picker.cameraFlashMode = self.flashMode;
        self.picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        self.picker.showsCameraControls = NO;
        
        // Make us the delegate for the UIImagePickerController
        self.picker.delegate = self;
        
        // Set the frames to be full screen
        CGRect screenFrame = [[UIScreen mainScreen] bounds];
        self.view.frame = screenFrame;
        self.picker.view.frame = screenFrame;
        
        // Set this VC's view as the overlay view for the UIImagePickerController
        self.picker.cameraOverlayView = self.view;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    recordingTimerText = @"00:00:00";
    stopTheTimer = YES;
    
    modePickerDataArray =[[NSArray alloc] initWithObjects:@"Video", @"Photo", nil];
    
    self.modePicker.delegate = self;
    self.modePicker.showsSelectionIndicator =NO;
    CGAffineTransform rotate = CGAffineTransformMakeRotation(-3.14/2);
    rotate = CGAffineTransformScale(rotate, 0.25, 2.0);
    [self.modePicker setTransform:rotate];
    
    selectedRow = 1;
    
    [self.modePicker selectRow:selectedRow inComponent:0 animated:NO];
    
    //Create "Gallery" Folder
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentDirectory = [paths objectAtIndex:0];
    galleryPath = [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",GALLERY_FOLDER_NAME]];
    jsonFilePath = [galleryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.json",META_DATA_FILE_NAME]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:galleryPath])
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:galleryPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create "Gallery" folder
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:jsonFilePath])
    {
        NSMutableArray *jsonArray = [[NSMutableArray alloc] init];
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                           options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        [jsonData writeToFile:jsonFilePath atomically:YES];
    }
    
    if([CLLocationManager locationServicesEnabled])
    {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        
        
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            [locationManager requestWhenInUseAuthorization];
        }
    }
    else
    {
        
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self configureView];
}

-(void)configureView
{
    if([self.cameraMode isEqualToString:@"Video"])
    {
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        photoModeActive = NO;
        self.videoRecordingTimerLabel.hidden = NO;
        self.videoRecordingTimerLabel.text = recordingTimerText;
    }
    else
    {
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        photoModeActive = YES;
        self.videoRecordingTimerLabel.hidden = YES;
    }
    
    if([self.cameraMode isEqualToString:@"Both"])
    {
        self.modePicker.hidden = NO;
    }
    else
    {
        self.modePicker.hidden = YES;
    }
    
    self.recentButton.enabled = NO;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)captureButtonPressed:(id)sender
{
    if(photoModeActive)
    {
        [self.picker takePicture];
    }
    else
    {
        BOOL startRecording = [self.picker startVideoCapture];
        
        if (startRecording)
        {
            stopTheTimer = NO;
            videoRecordingStartTime = [NSDate date];
            recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(settingVideoTimerLabel) userInfo:nil repeats:NO];
            self.modePicker.userInteractionEnabled = NO;
            [self.captureButton setTitle:@"Stop" forState:UIControlStateNormal];
        }
        else
        {
            stopTheTimer= YES;
            [self.picker stopVideoCapture];
        }
    }
    
    self.recentButton.enabled = YES;
}

-(void)settingVideoTimerLabel
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:videoRecordingStartTime];
    
    NSInteger hours = floor(interval/(60*60));
    NSInteger minutes = floor((interval/60) - hours * 60);
    NSInteger seconds = floor(interval - (minutes * 60) - (hours * 60 * 60));
    
//    NSLog(@"Timer - %ld:%ld:%ld",(long)hours,(long)minutes,(long)seconds);
    
    recordingTimerText = [NSString stringWithFormat:@"%0.2ld:%0.2ld:%0.2ld",(long)hours,(long)minutes,(long)seconds];
    self.videoRecordingTimerLabel.text = recordingTimerText;
    
    if(!stopTheTimer)
    {
        recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(settingVideoTimerLabel) userInfo:nil repeats:NO];
    }
}

- (IBAction)flashButtonPressed:(id)sender
{
    UIButton *flashButton = sender;
    
    if (self.flashMode == UIImagePickerControllerCameraFlashModeAuto)
    {
        self.flashMode = UIImagePickerControllerCameraFlashModeOn;
        self.picker.cameraFlashMode = self.flashMode;
        
        [flashButton setTitle:@"Flash On" forState:UIControlStateNormal];
    }
    else if(self.flashMode == UIImagePickerControllerCameraFlashModeOn)
    {
        self.flashMode = UIImagePickerControllerCameraFlashModeOff;
        self.picker.cameraFlashMode = self.flashMode;
        
        [flashButton setTitle:@"Flash Off" forState:UIControlStateNormal];
    }
    else if(self.flashMode == UIImagePickerControllerCameraFlashModeOff)
    {
        self.flashMode = UIImagePickerControllerCameraFlashModeAuto;
        self.picker.cameraFlashMode = self.flashMode;
        
        [flashButton setTitle:@"Flash Auto" forState:UIControlStateNormal];
    }
}

- (IBAction)cameraSelectionButtonPressed:(id)sender
{
    UIButton *cameraButton = sender;
    
    if (self.picker.cameraDevice == UIImagePickerControllerCameraDeviceRear)
    {
        self.picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        
        [cameraButton setTitle:@"Rear Cam" forState:UIControlStateNormal];
    }
    else
    {
        self.picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        
        [cameraButton setTitle:@"Front Cam" forState:UIControlStateNormal];
    }
}

- (IBAction)recentButtonPressed:(id)sender
{
    [self.cameraPlugin recentButtonCallback:mediaPath withMetaDataJSONFilePath:jsonFilePath];
}

- (IBAction)galleryButtonPressed:(id)sender
{
    [self.cameraPlugin galleryButtonCallback:galleryPath withMetaDataJSONFilePath:jsonFilePath];
}

#pragma mark --
#pragma mark UIImagePickerDelegate

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //Timestamp
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString *fileName = [dateFormat stringFromDate:[NSDate date]];
    
    if (photoModeActive)
    {
        // Get a reference to the captured image
        UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        mediaPath = [galleryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.jpg",fileName]];
        
        // Get the image data (blocking; around 1 second)
        NSData* imageData = UIImageJPEGRepresentation(image, 0.5);
        
        if([[NSFileManager defaultManager] fileExistsAtPath:mediaPath])
        {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:mediaPath error:&error];
        }
        
        // Write the data to the file
        [imageData writeToFile:mediaPath atomically:YES];
        
        [self.recentButton setImage:[UIImage imageWithContentsOfFile:mediaPath] forState:UIControlStateNormal];
        
        [self saveMetaDataOfMediaWithName:fileName ofType:@".jpg" availabelAtPath:mediaPath];
    }
    else
    {
        recordingTimerText = @"00:00:00";
        self.videoRecordingTimerLabel.text = recordingTimerText;
        stopTheTimer = YES;
        
        self.modePicker.userInteractionEnabled = YES;
        [self.captureButton setTitle:@"Capture" forState:UIControlStateNormal];
        
        NSURL *videoURL = [info valueForKey:UIImagePickerControllerMediaURL];
        
        mediaPath = [galleryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.mov",fileName]];
        
        NSData *movieData = [NSData dataWithContentsOfURL:videoURL];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:mediaPath])
        {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:mediaPath error:&error];
        }
        
        [movieData writeToFile:mediaPath atomically:YES];
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
        AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        NSError *error = NULL;
        CMTime time = CMTimeMake(1, 1);
        CGImageRef refImg = [generateImg copyCGImageAtTime:time actualTime:NULL error:&error];
//        NSLog(@"error==%@, Refimage==%@", error, refImg);
        
        UIImage *videoThumbnail= [[UIImage alloc] initWithCGImage:refImg];
        
        [self.recentButton setImage:videoThumbnail forState:UIControlStateNormal];
        
        [self saveMetaDataOfMediaWithName:fileName ofType:@".mov" availabelAtPath:mediaPath];
    }
}

-(void)saveMetaDataOfMediaWithName:(NSString *)name ofType:(NSString *)type availabelAtPath:(NSString *)path
{
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:jsonFilePath encoding:NSUTF8StringEncoding error:NULL];
    NSError *jsonError;
    NSMutableArray *jsonArray = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&jsonError];
    
    NSMutableDictionary *metaDict = [[NSMutableDictionary alloc] init];
    [metaDict setObject:name forKey:@"name"];
    [metaDict setObject:type forKey:@"type"];
    [metaDict setObject:path forKey:@"path"];
    if(userLocation != nil)
    {
        [metaDict setObject:[NSString stringWithFormat:@"%f",userLocation.coordinate.latitude] forKey:@"latitude"];
        [metaDict setObject:[NSString stringWithFormat:@"%f",userLocation.coordinate.longitude] forKey:@"longitude"];
        [metaDict setObject:userLocality forKey:@"locality"];
        [metaDict setObject:userSublocality forKey:@"sublocality"];
    }
    else
    {
        NSLog(@"userLocation is nil");
        [self showAlertViewWithTitle:@"User Location" withMessage:@"User Location is nil"];
        
        [metaDict setObject:@"" forKey:@"latitude"];
        [metaDict setObject:@"" forKey:@"longitude"];
        [metaDict setObject:@"" forKey:@"locality"];
        [metaDict setObject:@"" forKey:@"sublocality"];
    }
    
    [metaDict setObject:[NSNumber numberWithBool:NO] forKey:@"isUploaded"];
    
    [jsonArray addObject:metaDict];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&jsonError];
    [jsonData writeToFile:jsonFilePath atomically:YES];
}

-(void)callReverseGeocodingAPI
{
    if(userLocation != nil)
    {
        if (!geocoder)
        geocoder = [[CLGeocoder alloc] init];
        
        [geocoder reverseGeocodeLocation:userLocation completionHandler:
         ^(NSArray* placemarks, NSError* error){
             if ([placemarks count] > 0)
             {
                 CLPlacemark *placemark = [placemarks objectAtIndex:0];
                 
                 userLocality = placemark.locality;
                 userSublocality = placemark.subLocality;
                 NSLog(@"Sublocality - %@, Locality - %@",placemark.subLocality,placemark.locality);
                 [self showAlertViewWithTitle:@"Location" withMessage:[NSString stringWithFormat:@"Sublocality - %@, Locality - %@",placemark.subLocality,placemark.locality]];
             }
         }];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
//    NSLog(@"didFailWithError: %@", error);
    [self showAlertViewWithTitle:@"Error" withMessage:@"Failed to Get Your Location"];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
//    NSLog(@"didUpdateToLocation: %@", newLocation);
    userLocation = newLocation;
    
    if (userLocation != nil) {
        [self callReverseGeocodingAPI];
        [locationManager stopUpdatingLocation];
    }
    else
    {
        [self showAlertViewWithTitle:@"User Location in Delegate" withMessage:@"User Location is nil"];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    /*
     The delegate function will be called when the permission status changes the application should then attempt to handle the change appropriately by changing UI or setting up or tearing down data structures.
     */
    if(status != kCLAuthorizationStatusAuthorizedWhenInUse) {
        [locationManager requestWhenInUseAuthorization];
    }
    else
    {
        [locationManager startUpdatingLocation];
    }
}

#pragma mark --
#pragma mark UIPickerView DataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [modePickerDataArray count];
}

#pragma mark --
#pragma mark UIPickerView Delegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    CGRect rect = CGRectMake(0, 0, 100, 30);
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    CGAffineTransform rotate = CGAffineTransformMakeRotation(3.14/2);
    rotate = CGAffineTransformScale(rotate, 0.25, 2.0);
    [label setTransform:rotate];
    label.text = [modePickerDataArray objectAtIndex:row];
    label.font = [UIFont boldSystemFontOfSize:30.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    if(row == selectedRow)
    {
        label.textColor = [UIColor yellowColor];
    }
    label.clipsToBounds = YES;
    return label ;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(row == 0)
    {
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        photoModeActive = NO;
        self.videoRecordingTimerLabel.hidden = NO;
    }
    else if (row == 1)
    {
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        photoModeActive = YES;
        self.videoRecordingTimerLabel.hidden = YES;
    }
    
    selectedRow = row;
    [self.modePicker reloadComponent:0];
}

-(void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    alertView = nil;
}

@end
