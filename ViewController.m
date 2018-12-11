//
//  ViewController.m
//  AnimationWithGravity
//
//  Created by Abraham Avnisan on 4/10/16.
//  Copyright © 2016 Abraham Avnisan. All rights reserved.
//

#import "ViewController.h"
@import CoreMotion;

// a couple of macros so that we can easily convert degrees to radians and vice versa
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(degrees) ((M_PI * degrees) / 180)

@interface ViewController () <UITextFieldDelegate>              // see comments in the setupTextField method
                                                                // for more info on <UITextFieldDelegate>

//@property (strong, nonatomic) UILabel *selectedLetterLabel;

@property (weak, nonatomic) IBOutlet UITextField *textField;    // allows us to ask the user for text
@property (strong, nonatomic) NSMutableArray *letterLabels;          // array of UILabels
@property (weak, nonatomic) IBOutlet UIImageView *image1;
@property (weak, nonatomic) IBOutlet UIImageView *image2;
@property (weak, nonatomic) IBOutlet UIImageView *image3;
@property (weak, nonatomic) IBOutlet UIImageView *image4;
@property (weak, nonatomic) IBOutlet UIImageView *image5;




// physics related properties                                   // for more information about Dynamic Animation (which is different
                                                                // than the kind of animation we did with the opacity in the image
                                                                // carousel example) see this video: https://youtu.be/aS6PBmBAP1g?list=PL9qPUrlLU4jSlonxFqhWKBu2c_sWY-mzg
                                                                // beginning at around 36 minutes
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIGravityBehavior *gravityBehavior;
@property (strong, nonatomic) UICollisionBehavior *collisionBehavior;
@property (strong, nonatomic) UIPushBehavior *pushBehavior;

// device motion
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CMDeviceMotion *deviceMotion;
@property (weak, nonatomic) IBOutlet UIButton *buttonClick;
@property (weak, nonatomic) IBOutlet UIButton *resetClick;

@end

@implementation ViewController

// in order to do Dynamic Animation you follow these steps:
//
//      1) create a dynamic animator
//      2) create the behaviors you want and add them to the animator
//      3) associate items (UIViews or subclasses - in our case, UILabels) to the behaviors

#pragma mark - lazy instantiation
- (CMDeviceMotion *)deviceMotion
{
    if (!_deviceMotion) {
        _deviceMotion = self.motionManager.deviceMotion;
    }
    return _deviceMotion;
}
- (CMMotionManager *)motionManager
{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = .016;
    }
    return _motionManager;
}
#pragma mark - setup
- (void)setup
{
    
    [self setupDeviceMotion];
    [self setupTextField];
}


- (void)setupTextField
{
    // delegates and protocols are an advanced objective-c / iOS topic
    // that we don't have time to go into with very much depth - look
    // at the documentation for more info.
    
    // basically, this allows our UITextField object to call the method
    // textFieldShouldReturn: that we define below
    
    // all you need to know is that in order to use a text field object
    // you need to set its delegate property to self, and in order to make
    // self (our ViewController class in this example) a valid delegate,
    // you need to declare that it follows the ,<UITextFieldDelegate> protocol,
    // something you do right after "@interface ViewController ()" at the top
    // of this file
    self.textField.delegate = self;
}
- (void)setupLabelsWithString:(NSString *)string
{

    self.letterLabels = [[NSMutableArray alloc] init];
    
    // calculate the size for every uilabel
    float margin = 25.0;
    UIFont *myFont = [UIFont fontWithName:@"Rockwell" size:25.0];
    
    CGFloat fontCharSize = myFont.pointSize;
    
    
    // iterate over every character in the string
    for (NSUInteger i = 0; i < [string length]; i++) {
        
        // get the range and letter
        NSRange thisLetterRange = NSMakeRange(i, 1);
        NSString *thisLetter = [string substringWithRange:thisLetterRange];
        
        // calculate the x-location for the frame
        CGFloat xPos = ((i + 1) * fontCharSize) + margin;
        
        // create a frame and a UILabel
        CGRect thisLetterFrame = CGRectMake(xPos, 100.0, fontCharSize, fontCharSize);
        UILabel *thisLetterLabel = [[UILabel alloc] initWithFrame:thisLetterFrame];
        
        // set the text properties for the UILabel
        thisLetterLabel.text = thisLetter;
        thisLetterLabel.textAlignment = NSTextAlignmentCenter;
        thisLetterLabel.font = myFont;
        
        // add UILabel to the view
        [self.view addSubview:thisLetterLabel];

        // add this UILabel to our array of letters
        [self.letterLabels addObject:thisLetterLabel];
    }
}

- (void)setupAnimatorAndBehaviors
{
    // this must be called AFTER we've populated self.letters
    // it associates each letter (each of which is a UILabel)
    // with our physics behaviors
    
    // setup animator
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    // setup and add gravity behavior
    self.gravityBehavior = [[UIGravityBehavior alloc] initWithItems:self.letterLabels];
    [self.animator addBehavior:self.gravityBehavior];
    
    // setup, configure, and add collision behavior
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:self.letterLabels];
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [self.animator addBehavior:self.collisionBehavior];
    
    // setup, configure and add push behavior
    self.pushBehavior = [[UIPushBehavior alloc] initWithItems:self.letterLabels mode:UIPushBehaviorModeContinuous];
    self.pushBehavior.active = NO;
    [self.animator addBehavior:self.pushBehavior];

}
- (void)setupDeviceMotion
{
    // this method will call the block you pass in at the interval that we define
    // in our lazy instantiation of the motionManager
    
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
    
        // here we associate the device's gravity vector with our gravity behavior
        // in the physics simulation
        CMAcceleration gravity = motion.gravity;
        self.gravityBehavior.gravityDirection = CGVectorMake(gravity.x, -gravity.y);

        // we aren't using the deviceMotion property in this example
        // but it's here so you can see how you might use it.
        self.deviceMotion = motion;
        float pitch = self.deviceMotion.attitude.pitch;
        float yaw = self.deviceMotion.attitude.yaw;
        float roll = self.deviceMotion.attitude.roll;
        
        // NSLog(@"pitch: %.2f | yaw: %.2f | roll: %.2f", RADIANS_TO_DEGREES(pitch), RADIANS_TO_DEGREES(yaw), RADIANS_TO_DEGREES(roll));
        
    }];
}


#pragma mark - text field protocol methods

//- (BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    // this method is called by the UITextField object when
//    // the user presses return on the keyboard
//
//    [self resignFirstResponder];                    // this makes the keyboard disappear
//    [self setupLabelsWithString:textField.text];    // we setup our self.letters array with the string the user entered
//    [self setupAnimatorAndBehaviors];                          // NOW we can setup the animation, since self.letters is ready to go
//
//
//    // once we have our text input, we hide the UITextField object until
//    // the user taps the screen to reset the game
//    self.textField.alpha = 0.0;
//    self.textField.enabled = NO;
//    self.textField.text = @"";
//
//    // we have to return a boolean because this is a method
//    // we are overriding and it returns a bool
//    return YES;
//}

#pragma mark - actions
- (IBAction)userDidTap:(UITapGestureRecognizer *)sender
{
    // when the user taps, we "reset" the game and start over
    
    // remove labels from UIView
//    for (NSUInteger i = 0; i < [self.letterLabels count]; i++) {
//
//        UILabel *thisLabel = [self.letterLabels objectAtIndex:i];
//        [self.gravityBehavior removeItem:thisLabel];
//        [self.collisionBehavior removeItem:thisLabel];
//        [thisLabel removeFromSuperview];
//
//    }
//
//    // clear our NSMutableArray
//    [self.letterLabels removeAllObjects];
//
//    // make our UITextField object visible
//    self.textField.alpha = 1.0;
//    self.textField.enabled = YES;
//    self.buttonClick.alpha = 1.0;
}
- (IBAction)userIsPanning:(UIPanGestureRecognizer *)sender
{
    int x = 0;
    // we get the velocity of the pan gesture in our main view
//    CGPoint velocity = [sender velocityInView:self.view];
    
    CGPoint fingerLocation = [sender locationInView:self.view];
    
    // check whether finger location intersects with one of the letters
    for (NSUInteger i = 0; i < self.letterLabels.count; i++) {
     
        UILabel *thisLetterLabel = self.letterLabels[i];
        
        CGRect userInteractionRect = CGRectMake(thisLetterLabel.frame.origin.x - 5, thisLetterLabel.frame.origin.y - 5, thisLetterLabel.frame.size.width + 5, thisLetterLabel.frame.size.height + 5);
        
        if (CGRectContainsPoint(userInteractionRect, fingerLocation)) {
            
            NSLog(@"%s", __PRETTY_FUNCTION__);
            // finger is on letter label
            thisLetterLabel.center = fingerLocation;
            NSLog(@"%d", x);
        }
        
    }
    


}

//When user clickes a button animation starts
- (IBAction)ifButtonClicked:(UIButton *)sender {
    [self resignFirstResponder];                    // this makes the keyboard disappear
    [self setupLabelsWithString:_textField.text];    // we setup our self.letters array with the string the user entered
    [self setupAnimatorAndBehaviors];                          // NOW we can setup the animation, since self.letters is ready to go
    
    
 
    self.textField.alpha = 0.0;
    self.textField.enabled = NO;
    self.textField.text = @"";
    self.buttonClick.alpha = 0;
    self.resetClick.alpha = 1.0;
    self.image1.alpha = 0;
    self.image2.alpha = 0;
    self.image3.alpha = 0;
    self.image4.alpha = 0;
    self.image5.alpha = 0;


}
//when user clicks resets, UI resets
- (IBAction)ifResetClicked:(id)sender {
        for (NSUInteger i = 0; i < [self.letterLabels count]; i++) {
    
            UILabel *thisLabel = [self.letterLabels objectAtIndex:i];
            [self.gravityBehavior removeItem:thisLabel];
            [self.collisionBehavior removeItem:thisLabel];
            [thisLabel removeFromSuperview];
    
        }
    
        // clear our NSMutableArray
        [self.letterLabels removeAllObjects];
    
        // make our UITextField object visible
        self.textField.alpha = 1.0;
        self.textField.enabled = YES;
        self.buttonClick.alpha = 1.0;
        self.resetClick.alpha  = 0;
        self.image1.alpha = 1.0;
        self.image2.alpha = 1.0;
        self.image3.alpha = 1.0;
        self.image4.alpha = 1.0;
        self.image5.alpha = 1.0;
    
    
}


#pragma mark - inherited methods
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setup];
    
}


@end
