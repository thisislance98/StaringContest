//
//  ViewController.m
//  testopencv
//
//  Created by Sami Aref on 4/9/13.
//  Copyright (c) 2013 Sami Aref. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/highgui/cap_ios.h>
using namespace cv;

cv::CascadeClassifier face_cascade;
cv::CascadeClassifier eyes_cascade;

@interface ViewController ()<CvVideoCameraDelegate>
{
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) CvVideoCamera* videoCamera;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:_imageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.delegate = self;
    
    _label.hidden = YES;
    
    NSString* facePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2" ofType:@"xml"];
    NSString* eyesPath = [[NSBundle mainBundle] pathForResource:@"haarcascade_mcs_eyepair_small" ofType:@"xml"];
    //     NSString* eyePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_mcs_eyepair_big" ofType:@"xml"];
    
    face_cascade.load([facePath fileSystemRepresentation]);
	eyes_cascade.load([eyesPath fileSystemRepresentation]);

    [self.button setTitle:@"STOP" forState:UIControlStateSelected];
}

- (IBAction)actionStart:(UIButton *)sender
{
    sender.selected = !sender.selected;
    (sender.selected) ? [self.videoCamera start] : [self.videoCamera stop];
}

#pragma mark - Protocol CvVideoCameraDelegate


- (void)processImage:(Mat&)image;
{
    Mat gray;
    
    Mat eyes_tpl;  // The eye template
    cv::Rect eyes_bb;  // The eye bounding box
    
    cvtColor(image, gray, CV_BGR2GRAY);
    
    bool eyesFound = !(eyes_bb.width == 0 && eyes_bb.height == 0);
    
    if (!eyesFound)
    {
        eyesFound = (detectEyes(gray, eyes_tpl, eyes_bb) > 0);
    }
    
    if (eyesFound)
    {
        trackEye(gray, eyes_tpl, eyes_bb);
        cv::rectangle(image, eyes_bb, CV_RGB(0,255,0));
    }
    
    [self updateLabelHidden:eyesFound];
}

- (void)updateLabelHidden:(BOOL)hidden
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _label.hidden = hidden;
    });
}


/**
 * Function to detect human face and the eyes from an image.
 *
 * @param  im    The source image
 * @param  tpl   Will be filled with the eye template, if detection success.
 * @param  rect  Will be filled with the bounding box of the eye
 * @return zero=failed, nonzero=success
 */
int detectEyes(cv::Mat& im, cv::Mat& tpl,cv::Rect& rect)
{
    std::vector<cv::Rect> faces, eyes;
    
    face_cascade.detectMultiScale(im, faces, 1.1, 2,
                                  CV_HAAR_SCALE_IMAGE, cv::Size(40,40));
    
    if (faces.size() == 0) return 0;
    
    cv::Mat face = im(faces[0]);
    
    eyes_cascade.detectMultiScale(face, eyes, 1.1, 2,
                                 CV_HAAR_SCALE_IMAGE, cv::Size(10,10));
    
     if (eyes.size() == 0) return 0;
    
    rect = eyes[0] + cv::Point(faces[0].x, faces[0].y);
    tpl  = im(rect);
    
    return eyes.size();
}

/**
 * Perform template matching to search the user's eye in the given image.
 *
 * @param   im    The source image
 * @param   tpl   The eye template
 * @param   rect  The eye bounding box, will be updated with _
 *                the new location of the eye
 */
void trackEye(cv::Mat& im, cv::Mat& tpl,cv::Rect& rect)
{
    cv::Rect window(0, 0, im.cols, im.rows);
    
    if (window.width == 0 || window.height == 0) return;
    
    cv::Mat dst;
    cv::matchTemplate(im, tpl, dst, CV_TM_SQDIFF_NORMED);
    
    double minval, maxval;
    cv::Point minloc, maxloc;
    cv::minMaxLoc(dst, &minval, &maxval, &minloc, &maxloc);
    
    if (minval <= 0.001 && maxval >= 0.99)
    {
        rect.x = window.x + minloc.x;
        rect.y = window.y + minloc.y;
    }
    else
        rect.x = rect.y = rect.width = rect.height = 0;
}

@end
