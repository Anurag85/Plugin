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

@interface CustomCameraViewController ()
{
    BOOL photoModeActive;
    NSString *mediaPath;
}

@property (nonatomic) UIImagePickerControllerCameraFlashMode flashMode;

-(void)alignModeButtons;
-(void)configureView;

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
        [self alignModeButtons];
    }
    else
    {
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        photoModeActive = YES;
//        [self alignModeButtons];
        NSLog(@"Photo Center 1 -- %@",NSStringFromCGPoint(self.photoModeButton.center));
        NSLog(@"Video Center 1 -- %@",NSStringFromCGPoint(self.videoModeButton.center));
        
        double photoY = (self.captureButton.center.y - ((self.captureButton.frame.size.height/2)+(self.photoModeButton.frame.size.height/2)+10));
        self.photoModeButton.center = CGPointMake(self.captureButton.center.x, photoY);
        double videoX = (self.photoModeButton.center.x -((self.photoModeButton.frame.size.width/2)+(self.videoModeButton.frame.size.width/2)+10));
        self.videoModeButton.center = CGPointMake(videoX, self.photoModeButton.center.y);
        NSLog(@"Photo Center 2 -- %@",NSStringFromCGPoint(self.photoModeButton.center));
        NSLog(@"Video Center 2 -- %@",NSStringFromCGPoint(self.videoModeButton.center));
    }
    
    if([self.cameraMode isEqualToString:@"Both"])
    {
        self.videoModeButton.hidden = NO;
        self.photoModeButton.hidden = NO;
    }
    else
    {
        self.videoModeButton.hidden = YES;
        self.photoModeButton.hidden = YES;
    }
    
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
            self.photoModeButton.enabled = NO;
            self.videoModeButton.enabled = NO;
            [self.captureButton setTitle:@"Stop" forState:UIControlStateNormal];
        }
        else
        {
            self.photoModeButton.enabled = YES;
            self.videoModeButton.enabled = YES;
            [self.captureButton setTitle:@"Capture" forState:UIControlStateNormal];
            [self.picker stopVideoCapture];
        }
    }
    
}

- (IBAction)modeButtonPressed:(id)sender
{
    UIButton *modeButton = sender;
    
    if(modeButton.tag == 0)
    {
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        photoModeActive = YES;
    }
    else if (modeButton.tag == 1)
    {
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        photoModeActive = NO;
    }
    
    [self alignModeButtons];
}

-(void)alignModeButtons
{
    if(photoModeActive)
    {
        double deltaX = self.captureButton.center.x - self.photoModeButton.center.x;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.0f];
        self.photoModeButton.center = CGPointMake(self.photoModeButton.center.x + deltaX, self.photoModeButton.center.y);
        self.videoModeButton.center = CGPointMake(self.videoModeButton.center.x + deltaX, self.videoModeButton.center.y);
        [UIView commitAnimations];
    }
    else
    {
        double deltaX = self.captureButton.center.x - self.videoModeButton.center.x;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.0f];
        self.photoModeButton.center = CGPointMake(self.photoModeButton.center.x + deltaX, self.photoModeButton.center.y);
        self.videoModeButton.center = CGPointMake(self.videoModeButton.center.x + deltaX, self.videoModeButton.center.y);
        [UIView commitAnimations];
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
    
    [self alignModeButtons];
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
    
    [self alignModeButtons];
}

- (IBAction)recentButtonPressed:(id)sender
{
    [self.cameraPlugin recentButtonCallback:mediaPath];
}

- (IBAction)galleryButtonPressed:(id)sender
{
    [self.cameraPlugin galleryButtonCallback];
}

#pragma mark --
#pragma mark UIImagePickerDelegate

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Get a file path to save the media
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    if (photoModeActive)
    {
        // Get a reference to the captured image
        UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSString* filename = @"recent_photo.jpg";
        
        mediaPath = [documentsDirectory stringByAppendingPathComponent:filename];
        
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
    }
    else
    {
        NSURL *videoURL = [info valueForKey:UIImagePickerControllerMediaURL];
        NSString* filename = @"recent_video.mov";
        
        mediaPath = [documentsDirectory stringByAppendingPathComponent:filename];
        
        NSData *movieData = [NSData dataWithContentsOfURL:videoURL];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:mediaPath])
        {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:mediaPath error:&error];
        }
        
        [movieData writeToFile:mediaPath atomically:YES];
    }
    
    
}

@end
