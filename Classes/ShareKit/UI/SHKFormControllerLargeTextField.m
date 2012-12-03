//
//  SHKFacebookForm.m
//  ShareKit
//

#import "SHKFormControllerLargeTextField.h"
#import "SHK.h"

@interface SHKFormControllerLargeTextField ()

@property (nonatomic, retain) UILabel *counter;
@property BOOL shareIsCancelled;

- (void)layoutCounter;
- (void)updateCounter;
- (void)save;
- (void)keyboardWillShow:(NSNotification *)notification;
- (BOOL)shouldShowCounter;
- (void)ifNoTextDisableSendButton;
- (void)setupBarButtonItems;

@end

@implementation SHKFormControllerLargeTextField

@synthesize delegate, textView, maxTextLength;
@synthesize counter, hasLink, image, imageTextLength;
@synthesize text;
@synthesize shareIsCancelled;
@synthesize showImage;

- (void)dealloc 
{
    [showImage release];
	[textView release];
	[counter release];
	[text release];
	[image release];
	
	[super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id <SHKFormControllerLargeTextFieldDelegate>)aDelegate
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{		
		delegate = aDelegate;
		imageTextLength = 0;
		hasLink = NO;
		maxTextLength = 0;
	}
	return self;
}

- (void)loadView 
{
	[super loadView];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.textView = [[[UITextView alloc] initWithFrame:self.view.bounds] autorelease];
	textView.delegate = self;
	textView.font = [UIFont systemFontOfSize:15];
	textView.contentInset = UIEdgeInsetsMake(5,5,5,0);
	textView.backgroundColor = [UIColor whiteColor];	
	textView.autoresizesSubviews = YES;
	textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview:textView];
    NSString* deviceType = [UIDevice currentDevice].model;
    if ([[deviceType substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"iPad"]) {
        self.showImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 170, 540, 407)];
        [self.view addSubview:showImage];
        [showImage release];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// save to set the text now
	textView.text = text;
    [showImage setImage:[self imageByScalingAndCroppingForSize:showImage.frame.size image:image]];
	
	[self setupBarButtonItems];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
	
	[self.textView becomeFirstResponder];
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize image:(UIImage *) sourceImage
{
	UIImage *newImage = nil;
	CGSize imageSize = sourceImage.size;
	CGFloat width = imageSize.width;
	CGFloat height = imageSize.height;
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	CGFloat scaleFactor = 0.0;
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO)
	{
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
		
        if (widthFactor > heightFactor)
			scaleFactor = widthFactor; // scale to fit height
        else
			scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
		
        // center the image
        if (widthFactor > heightFactor)
		{
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
		}
        else
			if (widthFactor < heightFactor)
			{
				thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
			}
	}
	
	UIGraphicsBeginImageContext(targetSize); // this will crop
	
	CGRect thumbnailRect = CGRectZero;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width  = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[sourceImage drawInRect:thumbnailRect];
	
	newImage = UIGraphicsGetImageFromCurrentImageContext();
	if(newImage == nil)
        NSLog(@"could not scale image");
	
	//pop the context to get back to the default
	UIGraphicsEndImageContext();
	return newImage;
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];	
	
	// Remove observers
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name: UIKeyboardWillShowNotification object:nil];
	
	//If user really cancelled share. Sometimes sharers have more stages (e.g Foursquare) and user only returned to previous stage - back on navigation stack.
	if (self.shareIsCancelled) {
        // Remove the SHK view wrapper from the window
        [[SHK currentHelper] viewWasDismissed];
    }
}

- (void)setupBarButtonItems {
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																														target:self
																														action:@selector(cancel)] autorelease];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Send to %@", [[self.delegate class] sharerTitle]) 
																										style:UIBarButtonItemStyleDone
																									  target:self
																									  action:@selector(save)] autorelease];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return YES;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)keyboardWillShow:(NSNotification *)notification
{	
	CGRect keyboardFrame;
	CGFloat keyboardHeight;
	
	// 3.2 and above
	if (&UIKeyboardFrameEndUserInfoKey)
	{		
		[[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];		
		if ([self interfaceOrientation] == UIDeviceOrientationPortrait || [self interfaceOrientation] == UIDeviceOrientationPortraitUpsideDown) 
			keyboardHeight = keyboardFrame.size.height;
		else
			keyboardHeight = keyboardFrame.size.width;
	}
	
	// < 3.2
	else 
	{
		[[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
		keyboardHeight = keyboardFrame.size.height;
	}
	
	// Find the bottom of the screen (accounting for keyboard overlay)
	// This is pretty much only for pagesheet's on the iPad
	UIInterfaceOrientation orient = [[UIApplication sharedApplication] statusBarOrientation];
	BOOL inLandscape = orient == UIInterfaceOrientationLandscapeLeft || orient == UIInterfaceOrientationLandscapeRight;
	BOOL upsideDown = orient == UIInterfaceOrientationPortraitUpsideDown || orient == UIInterfaceOrientationLandscapeRight;
	
	CGPoint topOfViewPoint = [self.view convertPoint:CGPointZero toView:nil];
	CGFloat topOfView = inLandscape ? topOfViewPoint.x : topOfViewPoint.y;
	
	CGFloat screenHeight = inLandscape ? [[UIScreen mainScreen] applicationFrame].size.width : [[UIScreen mainScreen] applicationFrame].size.height;
	
	CGFloat distFromBottom = screenHeight - ((upsideDown ? screenHeight - topOfView : topOfView ) + self.view.bounds.size.height) + ([UIApplication sharedApplication].statusBarHidden || upsideDown ? 0 : 20);							
	CGFloat maxViewHeight = self.view.bounds.size.height - keyboardHeight + distFromBottom;
	
	textView.frame = CGRectMake(0,0,self.view.bounds.size.width,maxViewHeight);
	
	[self layoutCounter];
}
#pragma GCC diagnostic pop

#pragma mark counter updates

- (void)updateCounter
{
	[self ifNoTextDisableSendButton];
	
	if (![self shouldShowCounter]) return;
	
	if (self.counter == nil)
	{
		UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		aLabel.backgroundColor = [UIColor clearColor];
		aLabel.opaque = NO;
		aLabel.font = [UIFont boldSystemFontOfSize:14];
		aLabel.textAlignment = UITextAlignmentRight;		
		aLabel.autoresizesSubviews = YES;
		aLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		self.counter = aLabel;
		[aLabel release];
		
		[self.view addSubview:counter];
		[self layoutCounter];
	}
	
	NSString *count;
    NSInteger countNumber = 0;
    
    if (self.maxTextLength) {
        countNumber = (self.image?(self.maxTextLength - self.imageTextLength):self.maxTextLength) - self.textView.text.length;
        count = [NSString stringWithFormat:@"%i", countNumber];
    } else {
        count = @"";
    }
    counter.text = [NSString stringWithFormat:@"%@%@", self.image ? [NSString stringWithFormat:@"Image %@ ",countNumber>0?@"+":@""]:@"", count];
 	
	if (countNumber >= 0) {
		
		self.counter.textColor = [UIColor blackColor];        
		if (self.textView.text.length) self.navigationItem.rightBarButtonItem.enabled = YES; 
		
	} else {
		
		self.counter.textColor = [UIColor redColor];
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}  
}

- (void)ifNoTextDisableSendButton {
	
	if (self.textView.text.length) {
		self.navigationItem.rightBarButtonItem.enabled = YES; 
	} else {
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
}

- (void)layoutCounter
{
	if (![self shouldShowCounter]) return;
	
	counter.frame = CGRectMake(self.textView.bounds.size.width-150-15,
										self.textView.bounds.size.height-15-9,
										150,
										15);
	self.textView.contentInset = UIEdgeInsetsMake(5,5,32,0);
}

- (BOOL)shouldShowCounter {
	
	if (self.maxTextLength || self.image || self.hasLink) return YES;
	
	return NO;
}

#pragma mark UITextView delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self updateCounter];
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self updateCounter];	
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[self updateCounter];
}

#pragma mark delegate callbacks 

- (void)cancel
{	
	self.shareIsCancelled = YES;
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	[self.delegate sendDidCancel];
}

- (void)save
{	    	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES]; 
	[self.delegate sendForm:self];
}

@end
