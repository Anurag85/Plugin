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
    
    NSArray *modePickerDataArray;
    NSInteger selectedRow;
}

@property (nonatomic) UIImagePickerControllerCameraFlashMode flashMode;

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
    
    modePickerDataArray =[[NSArray alloc] initWithObjects:@"Video", @"Photo", nil];
    
    self.modePicker.delegate = self;
    self.modePicker.showsSelectionIndicator =NO;
    CGAffineTransform rotate = CGAffineTransformMakeRotation(-3.14/2);
    rotate = CGAffineTransformScale(rotate, 0.25, 2.0);
    [self.modePicker setTransform:rotate];
    
    selectedRow = 1;
    
    [self.modePicker selectRow:selectedRow inComponent:0 animated:NO];
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
    }
    else
    {
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        photoModeActive = YES;
    }
    
    if([self.cameraMode isEqualToString:@"Both"])
    {
        self.modePicker.hidden = NO;
    }
    else
    {
        self.modePicker.hidden = YES;
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
            self.modePicker.userInteractionEnabled = NO;
            [self.captureButton setTitle:@"Stop" forState:UIControlStateNormal];
        }
        else
        {
            self.modePicker.userInteractionEnabled = YES;
            [self.captureButton setTitle:@"Capture" forState:UIControlStateNormal];
            [self.picker stopVideoCapture];
        }
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
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
        AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        NSError *error = NULL;
        CMTime time = CMTimeMake(1, 1);
        CGImageRef refImg = [generateImg copyCGImageAtTime:time actualTime:NULL error:&error];
//        NSLog(@"error==%@, Refimage==%@", error, refImg);
        
        UIImage *videoThumbnail= [[UIImage alloc] initWithCGImage:refImg];
        
        [self.recentButton setImage:videoThumbnail forState:UIControlStateNormal];
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
    }
    else if (row == 1)
    {
        self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        photoModeActive = YES;
    }
    
    selectedRow = row;
    [self.modePicker reloadComponent:0];
}

@end
