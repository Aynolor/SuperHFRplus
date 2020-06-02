//
//  AddMessageViewController.m
//  HFRplus
//
//  Created by FLK on 16/08/10.
//

#import "HFRplusAppDelegate.h"
#import "AddMessageViewController.h"
#import "ASIFormDataRequest.h"
#import "HTMLParser.h"
#import <QuartzCore/QuartzCore.h>
#import "NSData+Base64.h"
#import "RegexKitLite.h"
#import "RangeOfCharacters.h"
#import "RehostImage.h"
#import "RehostCell.h"
#import "UIMenuItem+CXAImageSupport.h"
#import "ThemeManager.h"
#import "ThemeColors.h"
#import "HFRUIImagePickerController.h"
#import "MultisManager.h"
#import "HFRAlertView.h"
#import "EditMessageViewController.h"
#import "ASIHTTPRequest+Tools.h"
#import "RehostCollectionCell.h"
#import "SmileyCache.h"

//@import GiphyUISDK;
//@import GiphyCoreSDK;

@implementation AddMessageViewController
@synthesize delegate, textView, arrayInputData, formSubmit, accessoryView, smileView;
@synthesize request, loadingView, requestSmile, dicCommonSmileys;
@synthesize lastSelectedRange, loaded;//navBar,
@synthesize segmentControler, isDragging, textFieldSmileys, smileyArray, segmentControlerPage, smileyPage, commonTableView, usedSearchDict, usedSearchSortedArray;
@synthesize btnToolbarImage, btnToolbarGIF, btnToolbarSmiley, btnToolbarUndo, btnToolbarRedo;
@synthesize rehostTableView, rehostImagesArray, rehostImagesSortedArray, collectionImages, collectionSmileys;
@synthesize haveTitle, textFieldTitle;
@synthesize haveTo, textFieldTo;
@synthesize haveCategory, textFieldCat;
@synthesize offsetY, smileyCustom, bSearchSmileysAvailable, bSearchSmileysActivated;
@synthesize selectCompte, selectedCompte;
@synthesize popover = _popover, refreshAnchor, statusMessage;


#pragma mark -
#pragma mark View lifecycle

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
        //NSLog(@"initWithNibName add");
        
        self.arrayInputData = [[NSMutableDictionary alloc] init];
        self.smileyArray = [[NSMutableArray alloc] init];
        self.formSubmit = [[NSString alloc] init];
        self.refreshAnchor = [[NSString alloc] init];
        
        self.loaded = NO;
        self.isDragging = NO;
        
        self.lastSelectedRange = NSMakeRange(NSNotFound, NSNotFound);
        
        self.haveCategory = NO;
        self.haveTitle = NO;
        self.haveTo	= NO;
        
        self.offsetY = 0;
            
        //Smileys / Rehost
        self.usedSearchDict = [[NSMutableDictionary alloc] init];
        self.usedSearchSortedArray = [[NSMutableArray alloc] init];
        self.rehostImagesArray = [[NSMutableArray alloc] init];
        self.rehostImagesSortedArray = [[NSMutableArray alloc] init];
        
        self.sBrouillon = [[NSUserDefaults standardUserDefaults] stringForKey:@"brouillon"];
        if (self.sBrouillon == nil) self.sBrouillon = [[NSString alloc] init];
        self.sBrouillonUtilise = NO;
        self.bSearchSmileysAvailable = NO;
        self.bSearchSmileysActivated = NO;

        self.title = @"Nouv. message";
    }
    return self;
}

// was webViewDidStartLoad
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"didStartProvisionalNavigation");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

// webViewDidFinishPreLoadDOM was empty method
// was webViewDidFinishLoad
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"didFinishNavigation");

    NSString *jsString = @"";
    //jsString = [jsString stringByAppendingString:@"$('body').bind('touchmove', function(e){e.preventDefault()});"];
    //jsString = [jsString stringByAppendingString:@"$('.button').addSwipeEvents().bind('tap', function(evt, touch) { $(this).addClass('selected'); window.location = 'oijlkajsdoihjlkjasdosmile://'+encodeURIComponent(this.title); });"];
    //jsString = [jsString stringByAppendingString:@"$('#smileperso img.smile').addSwipeEvents().bind('tap', function(evt, touch) { $(this).addClass('selected'); window.location = 'oijlkajsdoihjlkjasdosmile://'+encodeURIComponent(this.alt); });"];
    
    jsString = [jsString stringByAppendingString:@"var hammertime = $('.button').hammer({ hold_timeout: 0.000001 }); \
                hammertime.on('touchstart touchend', function(ev) {\
                if(ev.type === 'touchstart'){\
                $(this).addClass('selected');\
                }\
                if(ev.type === 'touchend'){\
                $(this).removeClass('selected');\
                window.location = 'oijlkajsdoihjlkjasdosmile://internal?query='+encodeURIComponent(this.title).replace(/\\(/g, '%28').replace(/\\)/g, '%29');\
                }\
                });"];
    
    jsString = [jsString stringByAppendingString:@"var hammertime2 = $('#smileperso img.smile').hammer({ hold_timeout: 0.000001 }); \
                hammertime2.on('touchstart touchend', function(ev) {\
                if(ev.type === 'touchstart'){\
                $(this).addClass('selected');\
                }\
                if(ev.type === 'touchend'){\
                $(this).removeClass('selected');\
                window.location = 'oijlkajsdoihjlkjasdosmile://internal?query='+encodeURIComponent(this.alt).replace(/\\(/g, '%28').replace(/\\)/g, '%29');\
                }\
                });"];
    
    [webView evaluateJavaScript:jsString completionHandler:nil];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// was shouldStartLoadWithRequest
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    NSURLRequest *aRequest = navigationAction.request;
    NSLog(@"URL Scheme : <<<<<<<<<<%@>>>>>>>>>>>", [aRequest.URL scheme]);
    BOOL bAllow = YES;
    
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        bAllow = NO;
    }
    else if (navigationAction.navigationType == WKNavigationTypeOther) {
        if ([[aRequest.URL scheme] isEqualToString:@"oijlkajsdoihjlkjasdosmile"]) {
            
            //NSLog(@"parameterString %@", [aRequest.URL query]);
            
            NSArray *queryComponents = [[aRequest.URL query] componentsSeparatedByString:@"&"];
            NSArray *firstParam = [[queryComponents objectAtIndex:0] componentsSeparatedByString:@"="];
            
            [self didSelectSmile:[[[firstParam objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            bAllow = NO;
        }
    }
    
    if (bAllow) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}
    
- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Recherche Smileys utilises
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *usedSmilieys = [[NSString alloc] initWithString:[directory stringByAppendingPathComponent:USED_SMILEYS_FILE]];
    
    if ([fileManager fileExistsAtPath:usedSmilieys]) {
        self.usedSearchDict = [NSMutableDictionary dictionaryWithContentsOfFile:usedSmilieys];
        self.usedSearchSortedArray = (NSMutableArray *)[[self.usedSearchDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    if (self.usedSearchDict.count > 0) {
        self.usedSearchSortedArray = (NSMutableArray *)[[self.usedSearchDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    //HFR REHOST
    NSString *rehostImages = [[NSString alloc] initWithString:[directory stringByAppendingPathComponent:REHOST_IMAGE_FILE]];
    
    if ([fileManager fileExistsAtPath:rehostImages]) {
        
        NSData *savedData = [NSData dataWithContentsOfFile:rehostImages];
        self.rehostImagesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
        self.rehostImagesSortedArray =  [NSMutableArray arrayWithArray:[[self.rehostImagesArray reverseObjectEnumerator] allObjects]];
        
    }
    
    //Smileys / Rehost
    
    //Bouton Annuler
    UIBarButtonItem *cancelBarItem = [[UIBarButtonItem alloc] initWithTitle:@"Annuler" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancelBarItem;
    
    //Bouton Envoyer
    UIBarButtonItem *sendBarItem = [[UIBarButtonItem alloc] initWithTitle:@"Envoyer" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = sendBarItem;
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    
    [self.segmentControlerPage setEnabled:NO forSegmentAtIndex:0];
    [self.segmentControlerPage setWidth:40.0 forSegmentAtIndex:0];
    [self.segmentControlerPage setWidth:40.0 forSegmentAtIndex:2];
    [self.segmentControlerPage setEnabled:NO forSegmentAtIndex:2];
    
    self.smileView.navigationDelegate = self;
    
    [self setupCollections];
}

- (NSString*) getBrouillonExtract {
    int BROUILON_EXTRACT_LENGTH = 60;
    NSString *first20Char = nil;
    NSRange r1 = [self.sBrouillon rangeOfString:@"[quotemsg="];
    NSRange r2 = [self.sBrouillon rangeOfString:@"[/quotemsg]"];
    if (r1.location != NSNotFound && r2.location != NSNotFound) { // Test is quoted message to remove first quote
        if (r2.location + r2.length + BROUILON_EXTRACT_LENGTH <= self.sBrouillon.length ) {
            first20Char = [self.sBrouillon substringWithRange:NSMakeRange(r2.location + r2.length, BROUILON_EXTRACT_LENGTH)];
            first20Char = [first20Char stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            first20Char = [NSString stringWithFormat:@"[quotemsg(...)\n%@(...)",first20Char];
        }
        else {
            first20Char = [self.sBrouillon substringWithRange:NSMakeRange(r2.location + r2.length, self.sBrouillon.length - r2.location - r2.length )];
            first20Char = [first20Char stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            first20Char = [NSString stringWithFormat:@"[quotemsg(...)\n%@",first20Char];
        }
    }
    else
    {
        if (self.sBrouillon.length > BROUILON_EXTRACT_LENGTH) {
            first20Char = [self.sBrouillon substringToIndex:BROUILON_EXTRACT_LENGTH];
            first20Char = [first20Char stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            first20Char = [NSString stringWithFormat:@"%@(...)",first20Char];
        }
        else {
            first20Char = self.sBrouillon;
            first20Char = [first20Char stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    first20Char = [NSString stringWithFormat:@"\"%@\"",first20Char];
    return first20Char;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)initData { //- (void)viewDidLoad {
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    NSString *tempHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"smileybase" ofType:@"html"] encoding:NSUTF8StringEncoding error:NULL];
    
    tempHTML = [tempHTML stringByReplacingOccurrencesOfString:@"iosversion" withString:@"ios7"];
    
    [self.smileView loadHTMLString:[tempHTML stringByReplacingOccurrencesOfString:@"%SMILEYCUSTOM%"
                                                                       withString:[NSString stringWithFormat:@"<div id='smileperso'>%@</div>",
                                                                                   self.smileyCustom]] baseURL:baseURL];
    
    
    self.formSubmit = [NSString stringWithFormat:@"%@/bddpost.php", [k ForumURL]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(smileyReceived:) name:@"smileyReceived" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadProgress:) name:@"uploadProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageReceived:) name:@"imageReceived" object:nil];
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
    v.backgroundColor = [ThemeColors addMessageBackgroundColor:[[ThemeManager sharedManager] theme]];
    [self.commonTableView setTableFooterView:v];
    [self.rehostTableView setTableFooterView:v];
    
    float headerWidth = self.view.bounds.size.width;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, headerWidth, 90+50)];
    
    Theme theme = [[ThemeManager sharedManager] theme];
    
    UIButton* newPhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [newPhotoBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [newPhotoBtn.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [newPhotoBtn setTitle:@"  Caméra" forState:UIControlStateNormal];
    newPhotoBtn.frame = CGRectMake(headerWidth*0/2+10, 5, headerWidth*1/2 - 20, 50);
    [newPhotoBtn addTarget:self action:@selector(uploadNewPhoto:) forControlEvents:UIControlEventTouchUpInside];
    newPhotoBtn.layer.cornerRadius = 15;
    newPhotoBtn.layer.borderWidth = 1;
    newPhotoBtn.layer.borderColor = [ThemeColors tintColor].CGColor;
    newPhotoBtn.clipsToBounds = YES;
    
    UIButton* oldPhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [oldPhotoBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [oldPhotoBtn.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [oldPhotoBtn setTitle:@"  Photos" forState:UIControlStateNormal];
    oldPhotoBtn.frame = CGRectMake(headerWidth*1/2 + 12, 5, headerWidth*1/2 - 20, 50);
    [oldPhotoBtn addTarget:self action:@selector(uploadExistingPhoto:) forControlEvents:UIControlEventTouchUpInside];
    oldPhotoBtn.layer.cornerRadius = 15;
    oldPhotoBtn.layer.borderWidth = 1;
    oldPhotoBtn.layer.borderColor = [ThemeColors tintColor].CGColor;
    oldPhotoBtn.clipsToBounds = YES;

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"rehost_use_link"] == nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:bbcodeImageWithLink forKey:@"rehost_use_link"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"rehost_resize_before_upload"] == nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:1200 forKey:@"rehost_resize_before_upload"];
    }

    // Segmented control for BBCode url type
    NSArray *itemArray = [NSArray arrayWithObjects: @"Image et lien", @"Image sans lien", @"Lien seul", nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    //segmentedControl.frame = CGRectMake(headerWidth*1/4, 56, headerWidth*3/4-3, 30);
    segmentedControl.frame = CGRectMake(3, 10 + 56, headerWidth-6, 29);
    [segmentedControl addTarget:self action:@selector(segmentedControlValueDidChange:) forControlEvents:UIControlEventValueChanged];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"rehost_use_link"] == bbcodeImageWithLink) {
        segmentedControl.selectedSegmentIndex = 0;
    } else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"rehost_use_link"] == bbcodeImageNoLink) {
        segmentedControl.selectedSegmentIndex = 1;
    } else {
        segmentedControl.selectedSegmentIndex = 2;
    }
    
    if (@available(iOS 13.0, *)) {
        [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [ThemeColors tintColor:[[ThemeManager sharedManager] theme]], NSFontAttributeName: [UIFont systemFontOfSize:13]} forState:UIControlStateNormal];
        [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [ThemeColors cellBorderColor:[[ThemeManager sharedManager] theme]], NSFontAttributeName: [UIFont systemFontOfSize:13]} forState:UIControlStateDisabled];
        [segmentedControl setSelectedSegmentTintColor:[ThemeColors tabBackgroundColor:[[ThemeManager sharedManager] theme]]];
    }

    // Segmented control for BBCode url type
    float largeurLabel = 150;
    UILabel* lblMaxSize = [[UILabel alloc] initWithFrame:CGRectMake(5, 10 + 56 + 40, largeurLabel, 29)];
    [lblMaxSize setText:@"Dimensions maximales :"];
    [lblMaxSize setTextAlignment:NSTextAlignmentLeft];
    [lblMaxSize setFont:[UIFont systemFontOfSize:14]];
    [lblMaxSize setNumberOfLines:1];

    [oldPhotoBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [oldPhotoBtn.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [oldPhotoBtn setTitle:@"  Photos" forState:UIControlStateNormal];

    NSArray *itemArraySize = [NSArray arrayWithObjects: @"1200", @"1000", @"800", @"600", nil];
    UISegmentedControl *segmentedControlSize = [[UISegmentedControl alloc] initWithItems:itemArraySize];
    //segmentedControl.frame = CGRectMake(headerWidth*1/4, 56, headerWidth*3/4-3, 30);
    segmentedControlSize.frame = CGRectMake(largeurLabel, 10 + 56 + 40, headerWidth-6-largeurLabel, 29);
    [segmentedControlSize addTarget:self action:@selector(segmentedControlResizeValueDidChange:) forControlEvents:UIControlEventValueChanged];
    segmentedControlSize.selectedSegmentIndex = 0;
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"rehost_resize_before_upload"] == 1000) {
        segmentedControlSize.selectedSegmentIndex = 1;
    } else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"rehost_resize_before_upload"] == 800) {
        segmentedControlSize.selectedSegmentIndex = 2;
    } else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"rehost_resize_before_upload"] == 600) {
        segmentedControlSize.selectedSegmentIndex = 3;
    } else {
        segmentedControlSize.selectedSegmentIndex = 0;
    }
    
    if (@available(iOS 13.0, *)) {
        [segmentedControlSize setTitleTextAttributes:@{NSForegroundColorAttributeName: [ThemeColors tintColor:[[ThemeManager sharedManager] theme]], NSFontAttributeName: [UIFont systemFontOfSize:13]} forState:UIControlStateNormal];
        [segmentedControlSize setTitleTextAttributes:@{NSForegroundColorAttributeName: [ThemeColors cellBorderColor:[[ThemeManager sharedManager] theme]], NSFontAttributeName: [UIFont systemFontOfSize:13]} forState:UIControlStateDisabled];
        [segmentedControlSize setSelectedSegmentTintColor:[ThemeColors tabBackgroundColor:[[ThemeManager sharedManager] theme]]];
    }

    
    // Label
    UILabel *bbcodeLabel = [[UILabel alloc]initWithFrame:CGRectMake(3, 56, headerWidth*1/4, 30)];
    bbcodeLabel.text = @"Copier le lien";
    bbcodeLabel.font = [UIFont systemFontOfSize:14.0f];
    bbcodeLabel.numberOfLines = 1;
    bbcodeLabel.backgroundColor = [UIColor clearColor];
    bbcodeLabel.textColor = [ThemeColors tintColor:theme];

    
    UIView *borderT = [[UIView alloc] initWithFrame:CGRectMake(0, 0, headerWidth, 1.0f)];
    UIView *borderM = [[UIView alloc] initWithFrame:CGRectMake(0, 10 + 50, headerWidth, 1.0f)];
    UIView *borderB = [[UIView alloc] initWithFrame:CGRectMake(0, 10 + 90, headerWidth, 1.0f)];
    UIView *borderB2 = [[UIView alloc] initWithFrame:CGRectMake(0, 10 + 90+40, headerWidth, 1.0f)];
    UIView *border = [[UIView alloc] initWithFrame:CGRectMake(headerWidth*1/2, 0, 1, 60)];

    [oldPhotoBtn setImage:[ThemeColors tintImage:[UIImage imageNamed:@"Folder-32"] withTheme:theme] forState:UIControlStateNormal];
    [oldPhotoBtn setImage:[ThemeColors tintImage:[UIImage imageNamed:@"Folder-32"] withTheme:theme] forState:UIControlStateHighlighted];

    [newPhotoBtn setImage:[ThemeColors tintImage:[UIImage imageNamed:@"Camera-32"] withTheme:theme] forState:UIControlStateNormal];
    [newPhotoBtn setImage:[ThemeColors tintImage:[UIImage imageNamed:@"Camera-32"] withTheme:theme] forState:UIControlStateHighlighted];
    
    [newPhotoBtn setTitleColor:[ThemeColors tintColor:theme] forState:UIControlStateNormal];
    [newPhotoBtn setTitleColor:[ThemeColors tintColor:theme] forState:UIControlStateHighlighted];
    
    [oldPhotoBtn setTitleColor:[ThemeColors tintColor:theme] forState:UIControlStateNormal];
    [oldPhotoBtn setTitleColor:[ThemeColors tintColor:theme] forState:UIControlStateHighlighted];

    newPhotoBtn.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin);
    oldPhotoBtn.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin);

    border.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    borderB.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    borderB2.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    borderT.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    borderM.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    
    [headerView addSubview:newPhotoBtn];
    [headerView addSubview:oldPhotoBtn];
    [headerView addSubview:segmentedControl];
    [headerView addSubview:segmentedControlSize];
    [headerView addSubview:lblMaxSize];

    [border setBackgroundColor:[ThemeColors cellBorderColor:theme]];
    [borderB setBackgroundColor:[ThemeColors cellBorderColor:theme]];
    [borderB2 setBackgroundColor:[ThemeColors cellBorderColor:theme]];
    [borderT setBackgroundColor:[ThemeColors cellBorderColor:theme]];
    [borderM setBackgroundColor:[ThemeColors cellBorderColor:theme]];

    [headerView addSubview:border];
    [headerView addSubview:borderB];
    [headerView addSubview:borderB2];
    [headerView addSubview:borderT];
    [headerView addSubview:borderM];
    
    UIView* progressView = [[UIView alloc] initWithFrame:CGRectZero];
    progressView.frame = CGRectMake(0, 0, headerWidth, 50.f);
    
    progressView.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    progressView.backgroundColor = [UIColor whiteColor];
    progressView.tag = 12345;
    [progressView setHidden:YES];
    UIView* subProgressView = [[UIView alloc] initWithFrame:CGRectZero];
    subProgressView.frame = CGRectMake(0, 0, 50.f, 50.f);
    
    subProgressView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin);
    subProgressView.backgroundColor = [UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0];
    subProgressView.tag = 54321;
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGRect frame = spinner.frame;
    
    spinner.autoresizingMask =(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    
    frame.origin.x = (subProgressView.frame.size.width-frame.size.width)/2;
    frame.origin.y = (subProgressView.frame.size.height-frame.size.height)/2;
    spinner.frame = frame;
    [spinner startAnimating];
    [subProgressView addSubview:spinner];
    [progressView addSubview:subProgressView];
    [headerView addSubview:progressView];
    
    [self.rehostTableView setTableHeaderView:headerView];
        
    // Observe keyboard hide and show notifications to resize the text view appropriately.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    //[segmentControler setEnabled:YES forSegmentAtIndex:0];
    //[segmentControler setEnabled:YES forSegmentAtIndex:1];

    // MULTIS
    MultisManager *manager = [MultisManager sharedManager];
    NSDictionary *mainCompte = [manager getMainCompte];
    [self onSelectedCompteChange:mainCompte];
    selectCompte.layer.cornerRadius = selectCompte.frame.size.width / 2;
    selectCompte.clipsToBounds = YES;
    selectCompte.layer.borderWidth = 1.0f;
    selectCompte.layer.borderColor = [ThemeColors tintColor:theme].CGColor;
    selectCompte.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [selectCompte addTarget:self action:@selector(selectCompteFn:) forControlEvents:UIControlEventTouchUpInside];
    selectCompte.enabled = ![[arrayInputData objectForKey:@"cat"] isEqualToString:@"prive"]; // Disable account switching for MP
    selectCompte.hidden = [[[MultisManager sharedManager] getComtpes] count] < 2;
}

#pragma mark -
#pragma mark ScrollView delegate methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //NSLog(@"scrollViewWillBeginDragging");
    self.isDragging = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    //NSLog(@"scrollViewDidEndDragging");
    if (!decelerate) {
        self.isDragging = NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //NSLog(@"scrollViewDidScroll");
    //self.scrollViewer.contentOffset = CGPointMake(self.scrollViewer.contentOffset.x, self.scrollViewer.contentOffset.y + 20);
    if (![self.textView isFirstResponder] && !self.isDragging) {
        //	//NSLog(@"contentOffset 1");
        self.textView.contentOffset = CGPointMake(0, self.offsetY);
    }
    
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    //NSLog(@"scrollViewWillBeginDecelerating");
    
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //NSLog(@"scrollViewDidEndDecelerating");
    self.isDragging = NO;
    
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;
{
    //NSLog(@"scrollViewDidEndScrollingAnimation");
    
    //[self.textView scrollRangeToVisible:self.textView.selectedRange];
    if (![self.textView isFirstResponder] && !self.isDragging) {
        //NSLog(@"contentOffset 2");
        
        self.textView.contentOffset = CGPointMake(0, self.offsetY);
    }
    
    
}

#pragma mark -
#pragma mark Responding to keyboard events

- (void)textViewDidChange:(UITextView *)ftextView
{
    if ([ftextView text].length > 0) {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    
    CGRect line = [ftextView caretRectForPosition:ftextView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height
    - ( ftextView.contentOffset.y + ftextView.bounds.size.height - ftextView.contentInset.bottom - ftextView.contentInset.top ) + self.offsetY;
    
    if ( overflow > 0 ) {
        //NSLog(@"overflow %f", overflow);
        // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = ftextView.contentOffset;
        
        //NSLog(@"offset %@", NSStringFromCGPoint(offset));
        offset.y += overflow + 7; // leave 7 pixels margin
        
        
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2 animations:^{
            [ftextView setContentOffset:offset];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    NSLog(@"viewWillAppear");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VisibilityChanged" object:@"SHOW"];
    
    [super viewWillAppear:animated];
    
    if(self.lastSelectedRange.location != NSNotFound)
    {
        self.textView.selectedRange = lastSelectedRange;
    }
    
    self.view.backgroundColor = self.loadingView.backgroundColor = self.accessoryView.backgroundColor = self.textView.backgroundColor = self.commonTableView.backgroundColor = self.rehostTableView.backgroundColor = [ThemeColors addMessageBackgroundColor:[[ThemeManager sharedManager] theme]];
    [[ThemeManager sharedManager] applyThemeToTextField:self.textFieldSmileys];
    self.loadingViewLabel.textColor = [ThemeColors cellTextColor:[[ThemeManager sharedManager] theme]];
    self.loadingViewIndicator.activityIndicatorViewStyle = [ThemeColors activityIndicatorViewStyle];
    self.textView.textColor = [ThemeColors textColor:[[ThemeManager sharedManager] theme]];
    NSInteger iSizeTextReply = [[NSUserDefaults standardUserDefaults] integerForKey:@"size_text_reply"];
    [self.textView setFont:[UIFont systemFontOfSize:iSizeTextReply]];
    
    [self.rehostTableView reloadData];
    [self.commonTableView reloadData];

    if (self.segmentControler.tintColor == [UIColor whiteColor]) {

    } else {
        [self segmentToBlue];
    }
    
    Theme theme = [[ThemeManager sharedManager] theme];
    [self.btnToolbarImage  setImage:[ThemeColors tintImage:[UIImage imageNamed:@"photogallery2"] withTheme:theme] forState:UIControlStateNormal];
    [self.btnToolbarImage setImage:[ThemeColors tintImage:[UIImage imageNamed:@"photogallery2"] withTheme:theme] forState:UIControlStateHighlighted];
    [self.btnToolbarGIF  setImage:[ThemeColors tintImage:[UIImage imageNamed:@"gif"] withTheme:theme] forState:UIControlStateNormal];
    [self.btnToolbarGIF setImage:[ThemeColors tintImage:[UIImage imageNamed:@"gif"] withTheme:theme] forState:UIControlStateHighlighted];
    [self.btnToolbarSmiley setImage:[ThemeColors tintImage:[UIImage imageNamed:@"redface"] withTheme:theme] forState:UIControlStateNormal];
    [self.btnToolbarSmiley setImage:[ThemeColors tintImage:[UIImage imageNamed:@"redface"] withTheme:theme] forState:UIControlStateHighlighted];
    [self.btnToolbarUndo setImage:[ThemeColors tintImage:[UIImage imageNamed:@"undo-redo"] withTheme:theme] forState:UIControlStateNormal];
    [self.btnToolbarUndo setImage:[ThemeColors tintImage:[UIImage imageNamed:@"undo-redo"] withTheme:theme] forState:UIControlStateHighlighted];
    [self.btnToolbarRedo setImage:[ThemeColors tintImage:[UIImage imageNamed:@"undo"] withTheme:theme] forState:UIControlStateNormal];
    [self.btnToolbarRedo setImage:[ThemeColors tintImage:[UIImage imageNamed:@"undo"] withTheme:theme] forState:UIControlStateHighlighted];

    [self.btnToolbarImage addTarget:self action:@selector(actionImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnToolbarGIF addTarget:self action:@selector(actionGIF:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnToolbarSmiley addTarget:self action:@selector(actionSmiley:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnToolbarUndo addTarget:self action:@selector(actionUndo:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnToolbarRedo addTarget:self action:@selector(actionRedo:) forControlEvents:UIControlEventTouchUpInside];

    [self.view endEditing:YES];
    self.textView.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
    self.textFieldTitle.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
    self.textFieldTo.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
    self.textFieldCat.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
    self.textFieldSmileys.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
    [self.navigationController.navigationBar setTranslucent:NO];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.sBrouillonUtilise = NO;
    // Popup brouillon (partout sauf en mode edition)
    if (self.sBrouillon && self.sBrouillon.length > 0) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Utiliser le brouillon ?" message:[self getBrouillonExtract]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* actionYes = [UIAlertAction actionWithTitle:@"Oui" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self.textView setText:self.sBrouillon];
                                                              self.sBrouillonUtilise = YES;
                                                              [self.navigationItem.rightBarButtonItem setEnabled:YES];
                                                          }];
        UIAlertAction* actionNo = [UIAlertAction actionWithTitle:@"Non" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) { }];
        UIAlertAction* actionDel = [UIAlertAction actionWithTitle:@"Supprimer" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) { [self modifyBrouillon:@""]; }];
        
        [alert addAction:actionYes];
        [alert addAction:actionNo];
        [alert addAction:actionDel];

        [self presentViewController:alert animated:YES completion:nil];
        [[ThemeManager sharedManager] applyThemeToAlertController:alert];
    }
}

-(void)setupResponder {
    if (self.haveTo && ![[textFieldTo text] length]) {
        self.textFieldTo.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
        [self.textFieldTo becomeFirstResponder];
    }
    else if (self.haveTitle) {
        self.textFieldTitle.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
        [self.textFieldTitle becomeFirstResponder];
    }
    else {
        self.textView.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
        [self.textView becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    //NSLog(@"viewWillDisappear");
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
    
}

/* for iOS6 support */

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"landscape_mode"] isEqualToString:@"all"]) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [_popover dismissPopoverAnimated:YES];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    // Return YES for supported orientations
    // Get user preference
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *enabled = [defaults stringForKey:@"landscape_mode"];
    
    if (![enabled isEqualToString:@"none"]) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)cancel {
    //NSLog(@"cancel %@", self.formSubmit);
    
    if (self.smileView.alpha != 0) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.smileView setAlpha:0];
        
        //[self.segmentControler setAlpha:1];
        [self.btnToolbarImage setHidden:NO];
        [self.btnToolbarGIF setHidden:NO];
        [self.btnToolbarSmiley setHidden:NO];
        [self.btnToolbarUndo setHidden:NO];
        [self.btnToolbarRedo setHidden:NO];
        [self.segmentControlerPage setAlpha:0];
        
        [UIView commitAnimations];
        
        [self.textView becomeFirstResponder];
        
        [self segmentToBlue];
        
        //NSLog(@"====== 666666");
    }
    else if (self.commonTableView.alpha != 0) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.commonTableView setAlpha:0];
        
        //[self.segmentControler setAlpha:1];
        [self.btnToolbarImage setHidden:NO];
        [self.btnToolbarGIF setHidden:NO];
        [self.btnToolbarSmiley setHidden:NO];
        [self.btnToolbarUndo setHidden:NO];
        [self.btnToolbarRedo setHidden:NO];
        [self.segmentControlerPage setAlpha:0];
        
        [UIView commitAnimations];
        
        [self.textView becomeFirstResponder];
        
        [self segmentToBlue];
        
        //NSLog(@"====== 777777");
    }
    else if (self.rehostTableView.alpha != 0) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.rehostTableView setAlpha:0];
        
        //[self.segmentControler setAlpha:1];
        [self.btnToolbarImage setHidden:NO];
        [self.btnToolbarGIF setHidden:NO];
        [self.btnToolbarSmiley setHidden:NO];
        [self.btnToolbarUndo setHidden:NO];
        [self.btnToolbarRedo setHidden:NO];

        [self.segmentControlerPage setAlpha:0];
        
        [UIView commitAnimations];
        
        [self.textView becomeFirstResponder];
        
        [self segmentToBlue];
        
        //NSLog(@"====== 777777");
    }
    else {
        if ([self.textView text].length > 0 && !self.isDeleteMode) {
            NSString *alertTitle = @"Enregistrer le texte comme brouillons ?";
            NSString *messageBrouillon=nil;
            BOOL remplacerBrouillon = NO;
            if (self.sBrouillon.length > 0) {
                alertTitle = @"Remplacer le brouillon ?";
                messageBrouillon = [self getBrouillonExtract];
                remplacerBrouillon = YES;
            }
            
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                           message:messageBrouillon
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"Oui" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self modifyBrouillon:[self.textView text]];
                                                                      [self finishMe];
                                                                  }];
            UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"Non" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                    if (!remplacerBrouillon) [self modifyBrouillon:@""];
                                                                      [self finishMe];
                                                                  }];
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {
                                                                     [self.textView becomeFirstResponder];
                                                                 }];

            [alert addAction:yesAction];
            [alert addAction:noAction];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:^{}];
            [[ThemeManager sharedManager] applyThemeToAlertController:alert];
        }
        else {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VisibilityChanged" object:nil];
    [self.delegate addMessageViewControllerDidFinish:self];
        }
    }
}

- (void)modifyBrouillon:(NSString*) sNewText {
    self.sBrouillon = sNewText;
    [[NSUserDefaults standardUserDefaults] setObject:sNewText forKey:@"brouillon"];
}

-(void)resignAll {
    [self.textView endEditing:YES];
    [self.textFieldSmileys endEditing:YES];
    [self.textFieldTitle endEditing:YES];
    [self.textFieldTo endEditing:YES];
    [self.view endEditing:YES];
}

-(void)finishMe {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VisibilityChanged" object:nil];
    [self.delegate addMessageViewControllerDidFinish:self];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && alertView.tag == 666) {
        [self finishMe];
    }
    else if (buttonIndex == 0 && alertView.tag == 666) {
        [self.textView becomeFirstResponder];
    }
}

-(bool)isDeleteMode {
    NSLog(@"IS DELETE? IN");
    return NO;
}

- (IBAction)done {
    NSLog(@"formSubmit:%@", self.formSubmit);
    
    ASIFormDataRequest  *arequest =
    [[ASIFormDataRequest  alloc]  initWithURL:[NSURL URLWithString:self.formSubmit]];
    //delete
    NSString *key;
    for (key in self.arrayInputData) {
        if ([key isEqualToString:@"allowvisitor"] || [key isEqualToString:@"have_sondage"] || [key isEqualToString:@"sticky"] || [key isEqualToString:@"sticky_everywhere"]) {
            if ([[self.arrayInputData objectForKey:key] isEqualToString:@"1"]) {
                [arequest setPostValue:[self.arrayInputData objectForKey:key] forKey:key];
                NSLog(@"POST: >%@< : >%@<", key, [self.arrayInputData objectForKey:key]);
            }
        }
        else if ([key isEqualToString:@"delete"]) {
            if ([self isDeleteMode]) {
                [arequest setPostValue:@"1" forKey:key];
            }
        }
        else if ([key isEqualToString:@"pseudo"]) {
                [arequest setPostValue:[selectedCompte objectForKey:PSEUDO_DISPLAY_KEY] forKey:@"pseudo"];
                NSLog(@"POST: >%@< : >%@<", @"pseudo", [selectedCompte objectForKey:PSEUDO_DISPLAY_KEY]);
        }else if ([key isEqualToString:@"hash_check"]) {
            if([selectedCompte objectForKey:HASH_KEY]){
                [arequest setPostValue:[selectedCompte objectForKey:HASH_KEY] forKey:@"hash_check"];
                NSLog(@"POST: >%@< : >%@<", @"hash_check", [selectedCompte objectForKey:HASH_KEY]);
            }else{
                [arequest setPostValue:[[HFRplusAppDelegate sharedAppDelegate] hash_check] forKey:@"hash_check"];
                NSLog(@"POST: >%@< : >%@<", @"hash_check", [[HFRplusAppDelegate sharedAppDelegate] hash_check]);

                // Set hash_check for compte
                [[MultisManager sharedManager] setHashForCompte:selectedCompte andHash:[[HFRplusAppDelegate sharedAppDelegate] hash_check]];
            }
        }
        else {
            [arequest setPostValue:[self.arrayInputData objectForKey:key] forKey:key];
            NSLog(@"POST: >%@< : >%@<", key, [self.arrayInputData objectForKey:key]);
        }
    }
    
    NSString* txtTW = [[textView text] removeEmoji];
    txtTW = [txtTW stringByReplacingOccurrencesOfString:@"\n" withString:@"\r\n"];
    
    [arequest setPostValue:txtTW forKey:@"content_form"];
    NSLog(@"POST: >%@< : >%@<", @"content_form", txtTW);
    if (self.haveTitle) {
        [arequest setPostValue:[textFieldTitle text] forKey:@"sujet"];
        NSLog(@"POST: >%@< : >%@<", @"sujet", [textFieldTitle text]);
    }
    if (self.haveCategory) {
        [arequest setPostValue:[textFieldCat text] forKey:@"subcat"];
        NSLog(@"POST: >%@< : >%@<", @"subcat", [textFieldCat text]);
    }
    if (self.haveTo) {
        [arequest setPostValue:[textFieldTo text] forKey:@"dest"];
        NSLog(@"POST: >%@< : >%@<", @"dest", [textFieldTo text]);
    }
    
    // Set selected compte cookies
    MultisManager *manager = [MultisManager sharedManager];
    
    [arequest setUseCookiePersistence:NO];
    [arequest setRequestCookies:[selectedCompte objectForKey:COOKIES_KEY]];
    [arequest startSynchronous];
    
        if ([arequest error]) {
        [HFRAlertView DisplayOKAlertViewWithTitle:@"Ooops !" andMessage:@"Erreur de connexion..."];
        }
        else if ([arequest safeResponseString])
        {
        @try {
            // Set main compte cookies
            [[MultisManager sharedManager] forceCookiesForCompte:[[MultisManager sharedManager] getMainCompte]];
            
            NSError * error = nil;
            HTMLParser *myParser = [[HTMLParser alloc] initWithString:[arequest safeResponseString] error:&error];
            HTMLNode * bodyNode = [myParser body]; //Find the body tag
            HTMLNode * messagesNode = [bodyNode findChildWithAttribute:@"class" matchingName:@"hop" allowPartial:NO]; //Get all the <img alt="" />
            
            if ([messagesNode findChildTag:@"a"] || [messagesNode findChildTag:@"input"]) {
                [HFRAlertView DisplayOKAlertViewWithTitle:[[messagesNode contents] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] andMessage:nil];
            }
            else {
                // On efface automatiquement le brouillon quand il a été utilisé et que le post du message est OK
                if (self.sBrouillonUtilise) {
                    [self modifyBrouillon:@""];
                }
                
                [self resignAll];
                self.statusMessage = [[messagesNode contents] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                [self setRefreshAnchor:@""];
                NSArray * urlArray;

                // On regarde si on doit pas positionner le scroll sur un topic
                if ([self isDeleteMode]) {
                    //recup de l'ID du message supprimé pour positionner le scroll.
                    urlArray = [((QuoteMessageViewController *)self).urlQuote arrayOfCaptureComponentsMatchedByRegex:@"numreponse=([0-9]+)&"];
                }
                else {
                    urlArray = [[arequest safeResponseString] arrayOfCaptureComponentsMatchedByRegex:@"<meta http-equiv=\"Refresh\" content=\"[^#]+([^\"]*)\" />"];
                }
                
                if (urlArray.count > 0) {
                    if ([[[urlArray objectAtIndex:0] objectAtIndex:1] length] > 0) {
                        [self setRefreshAnchor:[[urlArray objectAtIndex:0] objectAtIndex:1]];
                    }
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"VisibilityChanged" object:nil];
                [self.delegate addMessageViewControllerDidFinishOK:self];
            }
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
            [HFRAlertView DisplayOKAlertViewWithTitle:@"Ooops !" andMessage:@"Erreur de réponse du serveur. Votre message a peut être été posté malgré tout."];
        }
        @finally {}
    }
    
}

-(void)segmentToWhite {
    self.segmentControler.tintColor = [UIColor whiteColor];
    self.segmentControlerPage.tintColor = [UIColor whiteColor];
}

-(void)segmentToBlue {
    if (@available(iOS 13.0, *)) {
        [self.segmentControler setTitleTextAttributes:@{NSForegroundColorAttributeName: [ThemeColors tintColor:[[ThemeManager sharedManager] theme]], NSFontAttributeName: [UIFont systemFontOfSize:13]} forState:UIControlStateNormal];
        [self.segmentControler setTitleTextAttributes:@{NSForegroundColorAttributeName: [ThemeColors cellBorderColor:[[ThemeManager sharedManager] theme]], NSFontAttributeName: [UIFont systemFontOfSize:13]} forState:UIControlStateDisabled];
        [self.segmentControlerPage setTitleTextAttributes:@{NSForegroundColorAttributeName: [ThemeColors tintColor:[[ThemeManager sharedManager] theme]], NSFontAttributeName: [UIFont systemFontOfSize:13]} forState:UIControlStateNormal];
        [self.segmentControlerPage setTitleTextAttributes:@{NSForegroundColorAttributeName: [ThemeColors cellBorderColor:[[ThemeManager sharedManager] theme]], NSFontAttributeName: [UIFont systemFontOfSize:13]} forState:UIControlStateDisabled];
        [self.segmentControler setSelectedSegmentTintColor:[ThemeColors tintColor:[[ThemeManager sharedManager] theme]]];
        [self.segmentControlerPage setSelectedSegmentTintColor:[ThemeColors tintColor:[[ThemeManager sharedManager] theme]]];
    } else {
        self.segmentControler.tintColor = self.segmentControlerPage.tintColor = [ThemeColors tintColor:[[ThemeManager sharedManager] theme]];
    }
}

- (void)actionImage:(id)sender
{
    if ([self.collectionImages isHidden]) {
        [self.collectionImages setHidden:NO];
    }
    else {
        [self.collectionImages setHidden:YES];
    }
    /*
    if (self.rehostTableView.alpha == 0.0) {
        [textView resignFirstResponder];
        [textFieldSmileys resignFirstResponder];
        NSRange newRange = textView.selectedRange;
        newRange.length = 0;
        textView.selectedRange = newRange;
        
        [self.rehostTableView setHidden:NO];
        [self segmentToBlue];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.smileView setAlpha:0];
        [self.commonTableView setAlpha:0];
        [self.rehostTableView setAlpha:1];
        
        //[self.segmentControler setAlpha:0];
        [self.btnToolbarImage setHidden:YES];
        [self.btnToolbarSmiley setHidden:YES];
        [self.btnToolbarUndo setHidden:YES];
        [self.btnToolbarRedo setHidden:YES];

        [self.segmentControlerPage setAlpha:1];
        
        [UIView commitAnimations];
    }
    else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.rehostTableView setAlpha:0];
        [UIView commitAnimations];
        [self.textView becomeFirstResponder];
        
        [self segmentToBlue];
    }
     */
}

- (void)actionGIF:(id)sender
{
    /*
    GiphyViewController *giphy = [[GiphyViewController alloc]init ] ;
    giphy.layout = GPHGridLayoutWaterfall;
    giphy.theme = GPHThemeLight;
    giphy.rating = GPHRatingTypeRatedPG13;
    giphy.delegate = self;
    giphy.showConfirmationScreen = true ;
    [giphy setMediaConfigWithTypes: [ [NSMutableArray alloc] initWithObjects:
                                     @(GPHContentTypeGifs),@(GPHContentTypeStickers), @(GPHContentTypeText),@(GPHContentTypeEmoji), nil] ];
    [self presentViewController:giphy animated:true completion:nil];*/
}

- (void)actionSmiley:(id)sender
{
    if ([self.collectionSmileys isHidden]) {
        [self.collectionSmileys reloadData];
        [self.collectionSmileys setHidden:NO];
    }
    else {
        if (!self.bSearchSmileysAvailable) {
            [self.collectionSmileys setHidden:YES];
        }
        else { // Search smiley available
            if (self.bSearchSmileysActivated) {
                self.bSearchSmileysActivated = NO;
                [self.collectionSmileys reloadData];
            }
            else {
                [self.collectionSmileys setHidden:YES];
            }
        }
    }
/*
    if (self.smileView.alpha == 0.0) {
        
        NSString *doubleSmileysCSS = @"";
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"size_smileys"] isEqualToString:@"double"]) {
            doubleSmileysCSS = @"#smileperso img.smile {max-height:60px;min-height: 30px;} #smileperso .button {height:60px;min-width:45px;} #smileperso .button img {max-height:60px;}";
        }
        
        [self.smileView evaluateJavaScript:[NSString stringWithFormat:@"\
                                            $('head link[rel=\"stylesheet\"]').last().after('<style>%@%@</style>');\
                                            ", [ThemeColors smileysCss:[[ThemeManager sharedManager] theme]], doubleSmileysCSS]
                         completionHandler:nil];
        
        self.loaded = NO;
        [textView resignFirstResponder];
        [textFieldSmileys resignFirstResponder];
        NSRange newRange = textView.selectedRange;
        newRange.length = 0;
        textView.selectedRange = newRange;
        
        [self.smileView setHidden:NO];
        [self segmentToWhite];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.commonTableView setAlpha:0];
        [self.rehostTableView setAlpha:0];
        
        [self.smileView setAlpha:1];
        //[self.segmentControler setAlpha:0];
        [self.btnToolbarImage setHidden:YES];
        [self.btnToolbarSmiley setHidden:YES];
        [self.btnToolbarUndo setHidden:YES];
        [self.btnToolbarRedo setHidden:YES];

        [self.segmentControlerPage setAlpha:1];
        
        [UIView commitAnimations];
    }
    else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.smileView setAlpha:0];
        [UIView commitAnimations];
        // [(UISegmentedControl *)sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
        [self.textView becomeFirstResponder];
        
        [self segmentToBlue];
    }
 */
}

- (IBAction)actionUndo:(id)sender
{

}

- (IBAction)actionRedo:(id)sender
{

}


// To delete
- (IBAction)segmentFilterAction:(id)sender
{
    
    // The segmented control was clicked, handle it here
    
    //NSLog(@"Segment clicked: %d", [(UISegmentedControl *)sender selectedSegmentIndex]);
    
    //[(UISegmentedControl *)[self.navigationItem.titleView.subviews objectAtIndex:0] setUserInteractionEnabled:NO];
    if (sender == self.segmentControler) {
        switch ([(UISegmentedControl *)sender selectedSegmentIndex]) {
            case 0:
            {
                if (self.smileView.alpha == 0.0) {
                    
                    NSString *doubleSmileysCSS = @"";
                    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"size_smileys"] isEqualToString:@"double"]) {
                        doubleSmileysCSS = @"#smileperso img.smile {max-height:60px;min-height: 30px;} #smileperso .button {height:60px;min-width:45px;} #smileperso .button img {max-height:60px;}";
                    }
                    
                    [self.smileView evaluateJavaScript:[NSString stringWithFormat:@"\
                                                        $('head link[rel=\"stylesheet\"]').last().after('<style>%@%@</style>');\
                                                        ", [ThemeColors smileysCss:[[ThemeManager sharedManager] theme]], doubleSmileysCSS]
                                     completionHandler:nil];
                    
                    self.loaded = NO;
                    [textView resignFirstResponder];
                    [textFieldSmileys resignFirstResponder];
                    NSRange newRange = textView.selectedRange;
                    newRange.length = 0;
                    textView.selectedRange = newRange;
                    
                    [self.smileView setHidden:NO];
                    [self segmentToWhite];
                    
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.2];
                    [self.commonTableView setAlpha:0];
                    [self.rehostTableView setAlpha:0];
                    
                    [self.smileView setAlpha:1];
                    //[self.segmentControler setAlpha:0];
                    [self.btnToolbarImage setHidden:YES];
                    [self.btnToolbarGIF setHidden:YES];
                    [self.btnToolbarSmiley setHidden:YES];
                    [self.btnToolbarUndo setHidden:YES];
                    [self.btnToolbarRedo setHidden:YES];

                    [self.segmentControlerPage setAlpha:1];
                    
                    [UIView commitAnimations];
                }
                else {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.2];
                    [self.smileView setAlpha:0];
                    [UIView commitAnimations];
                    [(UISegmentedControl *)sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                    [self.textView becomeFirstResponder];
                    
                    [self segmentToBlue];
                }
                break;
            }
            case 1:
            {
                if (self.rehostTableView.alpha == 0.0) {
                    [textView resignFirstResponder];
                    [textFieldSmileys resignFirstResponder];
                    NSRange newRange = textView.selectedRange;
                    newRange.length = 0;
                    textView.selectedRange = newRange;
                    
                    [self.rehostTableView setHidden:NO];
                    [self segmentToBlue];
                    
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.2];
                    [self.smileView setAlpha:0];
                    [self.commonTableView setAlpha:0];
                    [self.rehostTableView setAlpha:1];
                    
                    //[self.segmentControler setAlpha:0];
                    [self.btnToolbarImage setHidden:YES];
                    [self.btnToolbarGIF setHidden:YES];
                    [self.btnToolbarSmiley setHidden:YES];
                    [self.btnToolbarUndo setHidden:YES];
                    [self.btnToolbarRedo setHidden:YES];

                    [self.segmentControlerPage setAlpha:1];
                    
                    [UIView commitAnimations];
                }
                else {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.2];
                    [self.rehostTableView setAlpha:0];
                    [UIView commitAnimations];
                    [(UISegmentedControl *)sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                    [self.textView becomeFirstResponder];
                    
                    [self segmentToBlue];
                }
                
                break;
            }
            case 2:
            {
                [self.textView setText:self.sBrouillon];
            }
            default:
                break;
        }
    }
    else if (sender == self.segmentControlerPage) {
        switch ([(UISegmentedControl *)sender selectedSegmentIndex]) {
                
            case 0:
                //NSLog(@"previous");
                [self loadSmileys:--self.smileyPage];
                break;
            case 1:
            {
                [self.smileView evaluateJavaScript:@"$('#container').css('display');" completionHandler:^(id result, NSError*  error) {
                    if (error == nil && result != nil && [[NSString stringWithFormat:@"%@", result] isEqualToString:@"none"]) {
                        [self.smileView evaluateJavaScript:@"$('#container').show();$('#container_ajax').hide();$('#container_ajax').html('');" completionHandler:nil];
                        [self.segmentControlerPage setEnabled:NO forSegmentAtIndex:0];
                        [self.segmentControlerPage setEnabled:NO forSegmentAtIndex:2];
                        [self.segmentControlerPage setTitle:@"Annuler" forSegmentAtIndex:1];
                        
                        [self.smileView evaluateJavaScript:[NSString stringWithFormat:@"$('head > style').remove();"] completionHandler:nil];
                    }
                    else {
                        [self cancel];
                    }
                }];
                
                break;
            }
                
            case 2:
                //NSLog(@"next");
                [self loadSmileys:++self.smileyPage];
                break;
            default:
                break;
        }
    }
    
    
}


#pragma mark -
#pragma mark TextView Mod

- (void) smileyReceived: (NSNotification *) notification {
    //NSLog(@"%@", notification);
    
    // When the accessory view button is tapped, add a suitable string to the text view.
    NSMutableString *text = [textView.text mutableCopy];
    
    //NSLog(@"%d - %d", text.length, lastSelectedRange.location);
    
    if (!lastSelectedRange.location) {
        lastSelectedRange = NSMakeRange(0, 0);
    }
    
    if (text.length < lastSelectedRange.location) {
        NSLog(@"sdsdsd");
        lastSelectedRange.location = text.length;
    }
    
    [text insertString:[notification object] atIndex:lastSelectedRange.location];
    
    lastSelectedRange.location += [[notification object] length];
    
    textView.text = text;
    
    self.loaded = YES;
    
    [self textViewDidChange:self.textView];
    
}

- (void) imageReceived: (NSNotification *) notification {
    //NSLog(@"%@", notification);
    
    // When the accessory view button is tapped, add a suitable string to the text view.
    NSMutableString *text = [textView.text mutableCopy];
    
    //NSLog(@"%d - %d", text.length, lastSelectedRange.location);
    
    if (!lastSelectedRange.location) {
        lastSelectedRange = NSMakeRange(0, 0);
    }
    
    if (text.length < lastSelectedRange.location) {
        lastSelectedRange.location = text.length;
    }
    
    
    [text insertString:[notification object] atIndex:lastSelectedRange.location];
    
    lastSelectedRange.location += [[notification object] length];
    
    lastSelectedRange.location += [text length];
    lastSelectedRange.length = 0;
    
    textView.text = text;
    
    [self cancel];
    
    [self textViewDidChange:self.textView];
    
}


- (void) didSelectSmile:(NSString *)smile {
    
    smile = [NSString stringWithFormat:@" %@ ", smile]; // ajout des espaces avant/aprés le smiley.
    
    //NSLog(@"didSelectSmile");
    
    //STATS RECHERCHES
    // Recherche Smileys utilises
    if (self.textFieldSmileys.text.length >= 3) {
        NSNumber *val;
        if ((val = [self.usedSearchDict valueForKey:self.textFieldSmileys.text])) {
            //NSLog(@"existe %@", val);
            [self.usedSearchDict setObject:[NSNumber numberWithInt:[val intValue]+1] forKey:self.textFieldSmileys.text];
        }
        else {
            //NSLog(@"nouveau");
            [self.usedSearchDict setObject:[NSNumber numberWithInt:1] forKey:self.textFieldSmileys.text];
            
        }
        
        //NSLog(@"%@", self.usedSearchDict);
        
        NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *usedSmilieys = [[NSString alloc] initWithString:[directory stringByAppendingPathComponent:USED_SMILEYS_FILE]];
        
        [self.usedSearchDict writeToFile:usedSmilieys atomically:YES];
        
        //NSLog(@"usedSearchDict AFTER SAVE %@", self.usedSearchDict);
        // Recherche Smileys utilises
    }
    
    NSMutableString *text = [textView.text mutableCopy];
    
    //NSLog(@"%@ - %d - %d", smile, text.length, lastSelectedRange.location);
    
    [text insertString:smile atIndex:lastSelectedRange.location];
    
    lastSelectedRange.location += [smile length];
    lastSelectedRange.length = 0;
    
    textView.text = text;
    
    
    self.loaded = YES;
    [self textViewDidChange:self.textView];
    
    
    
    NSString *jsString = @"";
    jsString = [jsString stringByAppendingString:@"$(\".selected\").each(function (i) {\
                $(this).delay(800).removeClass('selected');\
                });"];
    
    [self.smileView evaluateJavaScript:jsString completionHandler:nil];
    [self cancel];
}

#pragma mark -
#pragma mark Text view delegate methods

- (BOOL)textViewShouldBeginEditing:(UITextView *)aTextView {
    //NSLog(@"textViewShouldBeginEditing");
    
    if(lastSelectedRange.location != NSNotFound)
    {
        textView.selectedRange = lastSelectedRange;
    }
    
    
    return YES;
    
    /*
     You can create the accessory view programmatically (in code), in the same nib file as the view controller's main view, or from a separate nib file. This example illustrates the latter; it means the accessory view is loaded lazily -- only if it is required.
     */
    
    if (textView.inputAccessoryView == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"AccessoryView" owner:self options:nil];
        // Loading the AccessoryView nib file sets the accessoryView outlet.
        textView.inputAccessoryView = accessoryView;
        
        // After setting the accessory view for the text view, we no longer need a reference to the accessory view.
        self.accessoryView = nil;
    }
    
    return YES;
}


- (BOOL)textViewShouldEndEditing:(UITextView *)aTextView {
    //NSLog(@"textViewShouldEndEditing");
    
    if(self.loaded)
    {
        //NSLog(@"textViewShouldEndEditing NO");
        self.loaded = NO;
        return NO;
    }
    
    self.lastSelectedRange = textView.selectedRange;
    
    [textView resignFirstResponder];
    //NSLog(@"textViewShouldEndEditing YES");
    
    return YES;
}

#pragma mark -
#pragma mark Responding to keyboard events

- (void)keyboardWillShow:(NSNotification *)notification {
    NSLog(@"keyboardWillShow ADD %@", notification);

    NSDictionary *userInfo = [notification userInfo];
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertedKeyboardRect = [self.view convertRect:keyboardRect fromView:self.view.window];

    CGRect safeAreaFrame = CGRectInset(self.view.safeAreaLayoutGuide.layoutFrame, 0, -self.additionalSafeAreaInsets.bottom);
    CGRect intersection = CGRectIntersection(safeAreaFrame, convertedKeyboardRect);

//    self.bottomGuide.constant = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(convertedKeyboardRect);
  //  [self.accessoryView setNeedsUpdateConstraints];

    NSLog(@"Bottom Constant %@", NSStringFromCGRect(intersection));

    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];

    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, intersection.size.height, 0);
    [self.view layoutIfNeeded];
    //[self.accessoryView updateConstraintsIfNeeded];

    [UIView commitAnimations];

}

- (void)keyboardWillHide:(NSNotification *)notification {
    //NSLog(@"keyboardWillHide ADD");
    
    [self keyboardWillShow:notification];

}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //NSLog(@"textFieldDidBeginEditing %@", textField);
    
    //NSLog(@"textFieldDidBeginEditing BEGIN %@", self.usedSearchDict);
    
    if (textField != textFieldSmileys) {
        //[segmentControler setEnabled:NO forSegmentAtIndex:0];
        //[segmentControler setEnabled:NO forSegmentAtIndex:1];
        [self.btnToolbarImage setEnabled:NO];
        [self.btnToolbarGIF setEnabled:NO];
        [self.btnToolbarSmiley setEnabled:NO];
        [self.btnToolbarUndo setEnabled:NO];
        [self.btnToolbarRedo setEnabled:NO];

        [textFieldSmileys setEnabled:NO];
    }
    else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.smileView setAlpha:0];
        [self.rehostTableView setAlpha:0];
        
        //[self.segmentControler setAlpha:1];
        [self.btnToolbarImage setHidden:NO];
        [self.btnToolbarGIF setHidden:NO];
        [self.btnToolbarSmiley setHidden:NO];
        [self.btnToolbarUndo setHidden:NO];
        [self.btnToolbarRedo setHidden:NO];

        [self.segmentControlerPage setAlpha:0];
        
        [UIView commitAnimations];
        
        if (self.usedSearchDict.count > 0) {
            
            
            
            [self textFieldSmileChange:self.textFieldSmileys]; //on affiche les recherches
            
            [self.commonTableView reloadData];
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            [self.commonTableView setAlpha:1];
            [UIView commitAnimations];
            
            [self segmentToBlue];
            
            //NSLog(@"======= 5555");
        }
        
        
    }
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //NSLog(@"textFieldDidEndEditing %@", textField);
    
    //[segmentControler setEnabled:YES forSegmentAtIndex:0];
    //[segmentControler setEnabled:YES forSegmentAtIndex:1];
    [self.btnToolbarImage setEnabled:YES];
    [self.btnToolbarGIF setEnabled:YES];
    [self.btnToolbarSmiley setEnabled:YES];
    [self.btnToolbarUndo setEnabled:YES];
    [self.btnToolbarRedo setEnabled:YES];

    [textFieldSmileys setEnabled:YES];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //NSLog(@"textFieldShouldReturn");
    
    //[textField resignFirstResponder];
    if (textField == self.textFieldTo) {
        [self.textFieldTitle becomeFirstResponder];
    }
    else if (textField == self.textFieldTitle)
    {
        [self.textView becomeFirstResponder];
    }
    else if (textField == self.textFieldSmileys)
    {
        if (self.textFieldSmileys.text.length < 3) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Saisir 3 caractères minimum !"
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else {
            /*
            if (self.smileView.alpha == 0.0) {
                // BUG pas de selection ///
                self.loaded = NO;
                [textView resignFirstResponder];
                NSRange newRange = textView.selectedRange;
                newRange.length = 0;
                textView.selectedRange = newRange;
                
                [self.smileView setHidden:NO];
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.2];
                [self.smileView setAlpha:1];
                [UIView commitAnimations];
                
                [self segmentToWhite];
                
                //NSLog(@"====== 1111");
            }
            
            [self.commonTableView setAlpha:0];
            
            [textFieldSmileys resignFirstResponder];*/
            [self fetchSmileys];
            /*
             [self.smileView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"\
             $.ajax({ url: '%@/message-smi-mp-aj.php?config=hfr.inc&findsmilies=%@',\
             success: function(data){\
             $('#container').hide();\
             $('#container_ajax').html(data);\
             $('#container_ajax img').addSwipeEvents().bind('tap', function(evt, touch) { $(this).addClass('selected'); window.location = 'oijlkajsdoihjlkjasdosmile://'+$.base64.encode(this.alt); });\
             }\
             \
             });", [k ForumURL], self.textFieldSmileys.text]];
             */
        }
    }
    return NO;
    
}
/*- (BOOL)textFieldShouldClear:(UITextField *)textField
 {
	NSLog(@"textFieldShouldClear %@", textField.text);
 
	
	return YES;
 
 }*/
-(IBAction)textFieldSmileChange:(id)sender
{
    //NSLog(@"textFieldSmileChange %@", [(UITextField *)sender text]);
    if ([(UITextField *)sender text].length > 0) {
        NSString* sText = [(UITextField *)sender text];
        sText = [sText stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
        sText = [sText stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        @try {
            NSPredicate * predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"SELF contains[c] '%@'", sText]];
            self.usedSearchSortedArray = (NSMutableArray *)[[self.usedSearchDict allKeys] filteredArrayUsingPredicate:predicate];
        [self.commonTableView reloadData];
        }
        @catch (NSException* exception) {
            NSLog(@"exception %@", exception);
            [HFRAlertView DisplayOKAlertViewWithTitle:@"Erreur de saisie !" andMessage:[NSString stringWithFormat:@"%@", [exception reason]]];
            [(UITextField *)sender setText:@""];
        }
        //NSLog(@"usedSearchSortedArray %@", usedSearchSortedArray);
    }
    else {
        self.usedSearchSortedArray = (NSMutableArray *)[[self.usedSearchDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [self.commonTableView reloadData];
        //NSLog(@"usedSearchSortedArray %@", usedSearchSortedArray);
    }
    
    if (self.usedSearchSortedArray.count == 0) {
        [self.commonTableView setHidden:YES];
        /*
         UILabel *labelTitle = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 480, 44)] autorelease];
         labelTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
         
         [labelTitle setFont:[UIFont systemFontOfSize:14.0]];
         [labelTitle setAdjustsFontSizeToFitWidth:NO];
         [labelTitle setLineBreakMode:NSLineBreakByTruncatingTail];
         //[labelTitle setBackgroundColor:[UIColor blueColor]];
         [labelTitle setTextAlignment:NSTextAlignmentCenter];
         [labelTitle setHighlightedTextColor:[UIColor whiteColor]];
         [labelTitle setTag:999];
         [labelTitle setText:@"Pas de résultats"];
         [labelTitle setTextColor:[UIColor blackColor]];
         [labelTitle setNumberOfLines:0];
         //[label setOpaque:YES];
         
         [self.commonTableView setTableFooterView:labelTitle];
         */
    }
    else {
        [self.commonTableView setHidden:NO];
        
        //[self.commonTableView setTableFooterView:nil];
    }
}

#pragma mark -
#pragma mark Data lifecycle

- (void)cancelFetchContent
{
    [self.request cancel];
    [self setRequest:nil];
    
}

- (void)fetchSmileys
{
    NSString *sTextSmileys = [NSString stringWithFormat:@"+%@", [[self.textFieldSmileys.text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@" +"]];
    NSMutableArray* smileyList = [[SmileyCache shared] getSmileyListForText:sTextSmileys];
    if (smileyList) {
        self.smileyArray = smileyList;
        [self performSelectorInBackground:@selector(loadSmileys) withObject:nil];
    }
    else {
        [ASIHTTPRequest setDefaultTimeOutSeconds:kTimeoutMini];
        NSString * encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                         NULL,
                                                                                                         (CFStringRef)sTextSmileys,
                                                                                                         NULL,
                                                                                                         (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                         kCFStringEncodingUTF8 ));
        
        [self setRequestSmile:[ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/message-smi-mp-aj.php?config=hfr.inc&findsmilies=%@", [k ForumURL], encodedString]]]];
        [requestSmile setDelegate:self];
        
        [requestSmile setDidStartSelector:@selector(fetchSmileContentStarted:)];
        [requestSmile setDidFinishSelector:@selector(fetchSmileContentComplete:)];
        [requestSmile setDidFailSelector:@selector(fetchSmileContentFailed:)];
        
        //[self.smileView evaluateJavaScript:@"$('#container').hide();$('#container_ajax').show();$('#container_ajax').html('<div class=\"loading\"><span class=\"spinner\">&#xe800;</span> Recherche en cours...</div>');" completionHandler:nil];
        [requestSmile startAsynchronous];
    }
}

- (void)fetchSmileContentStarted:(ASIHTTPRequest *)theRequest
{
    NSLog(@"fetchSmileContentStarted %@", theRequest);
}

- (void)fetchSmileContentComplete:(ASIHTTPRequest *)theRequest
{
    NSLog(@"fetchSmileContentComplete %@", theRequest);
    //Traitement des smileys (to Array)
    [self.smileyArray removeAllObjects]; //RaZ

    /*
    [self.segmentControlerPage setTitle:@"Smilies" forSegmentAtIndex:1];*/
    
    //NSDate *thenT = [NSDate date]; // Create a current date
    
    HTMLParser * myParser = [[HTMLParser alloc] initWithString:[theRequest safeResponseString] error:NULL];
    HTMLNode * smileNode = [myParser doc]; //Find the body tag
    
    NSArray * tmpImageArray =  [smileNode findChildTags:@"img"];
    
    
    for (HTMLNode * imgNode in tmpImageArray) { //Loop through all the tags
        [self.smileyArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[imgNode getAttributeNamed:@"src"], [imgNode getAttributeNamed:@"alt"], nil] forKeys:[NSArray arrayWithObjects:@"source", @"code", nil]]];
    }
    //NSLog(@"%@", self.smileyArray);
    
    if (self.smileyArray.count == 0) {
        //[self.textFieldSmileys becomeFirstResponder];
        //[self.smileView evaluateJavaScript:@"$('#container').show();$('#container_ajax').hide();$('#container_ajax').html('');" completionHandler:nil];
        [HFRAlertView DisplayOKAlertViewWithTitle:nil andMessage:@"Aucun résultat !"];
        return;
    }
    
    //[self.collectionSmileys reloadData];
    self.bSearchSmileysAvailable = YES;
    self.bSearchSmileysActivated = YES;
    [self loadSmileys:0];
    //[self loadSmileys:smileyPage];
    
    //NSDate *nowT = [NSDate date]; // Create a current date
    
    //NSLog(@"SMILEYS Parse Time elapsed Total		: %f", [nowT timeIntervalSinceDate:thenT]);
    [self cancelFetchContent];
}

- (void)fetchSmileContentFailed:(ASIHTTPRequest *)theRequest
{
    [self cancelFetchContent];
}

-(void)loadSmileys:(int)page;
{
    /*
    self.smileyPage = page;
    [self.smileView evaluateJavaScript:[NSString stringWithFormat:@"\
                                                            $('#container').hide();\
                                                            $('#container_ajax').show();\
                                                            $('#container_ajax').html('<div class=\"loading\"><span class=\"spinner\">&#xe800;</span> Page n˚%d...</div>');\
                                                            ", page + 1] completionHandler:nil];
    */
    [self performSelectorInBackground:@selector(loadSmileys) withObject:nil];
    
}

-(void)loadSmileys;
{
    @autoreleasepool {
        
        [[SmileyCache shared] handleSmileyArray:self.smileyArray forCollection:self.collectionSmileys];
        /*
        int page = self.smileyPage;
        
        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *diskCachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"SmileCache"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath])
        {
            //NSLog(@"createDirectoryAtPath");
            [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:NULL];
        }
        else {
            //NSLog(@"pas createDirectoryAtPath");
        }
        
        int doubleSmileys = 1;
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"size_smileys"] isEqualToString:@"double"]) {
            doubleSmileys = 2;
        }
        
        int smilePerPage = 40/doubleSmileys;
        float surface = [UIScreen mainScreen].bounds.size.height*[UIScreen mainScreen].bounds.size.width;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            if (surface > 250000) {
                smilePerPage = roundf(55/doubleSmileys);
            }
            else if (surface > 180000) {
                smilePerPage = roundf(45/doubleSmileys);
            }
        }
        
        
        //NSLog(@"SMILEYS %f = %d", surface, smilePerPage);
        
        //i4 153600
        //i5 181760
        //i6 250125
        NSArray *localsmileyArray = [[NSArray alloc] initWithArray:self.smileyArray copyItems:true];
        
        
        int firstSmile = page * smilePerPage;
        int lastSmile = MIN([localsmileyArray count], (page + 1) * smilePerPage);
        //NSLog(@"%d to %d", firstSmile, lastSmile);
        
        int i;
        
        NSString *tmpHTML = @"";
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        
        for (i = firstSmile; i < lastSmile; i++) { //Loop through all the tags
            NSString *filename = [[[localsmileyArray objectAtIndex:i] objectForKey:@"source"] stringByReplacingOccurrencesOfString:@"http://forum-images.hardware.fr/" withString:@""];
            filename = [filename stringByReplacingOccurrencesOfString:@"https://forum-images.hardware.fr/" withString:@""];
            filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
            filename = [filename stringByReplacingOccurrencesOfString:@" " withString:@"-"];
            
            NSString *key = [diskCachePath stringByAppendingPathComponent:filename];
            
            //NSLog(@"url %@", [[self.smileyArray objectAtIndex:i] objectForKey:@"source"]);
            //NSLog(@"key %@", key);
            
            if (![fileManager fileExistsAtPath:key])
            {
                //NSLog(@"dl %@", key);
                
                [fileManager createFileAtPath:key contents:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [[[localsmileyArray objectAtIndex:i] objectForKey:@"source"] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]]] attributes:nil];
            }
            
            
            tmpHTML = [tmpHTML stringByAppendingString:[NSString stringWithFormat:@"<img class=\"smile\" src=\"%@\" alt=\"%@\"/>", key, [[localsmileyArray objectAtIndex:i] objectForKey:@"code"]]];
            
        }
        
        
        tmpHTML = [tmpHTML stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
        
        [self performSelectorOnMainThread:@selector(showSmileResults:) withObject:tmpHTML waitUntilDone:YES];
        
        //Pagination
        //if (firstSmile > 0 || lastSmile < [self.smileyArray count]) {
        //NSLog(@"pagination needed");
        */
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self.segmentControler setAlpha:0];
            [self.btnToolbarImage setHidden:NO];
            [self.btnToolbarGIF setHidden:NO];
            [self.btnToolbarSmiley setHidden:NO];
            [self.btnToolbarUndo setHidden:NO];
            [self.btnToolbarRedo setHidden:NO];
            [self.collectionSmileys setHidden:NO];
/*
            [self.segmentControlerPage setAlpha:1];

            if (firstSmile > 0) {
                    [self.segmentControlerPage setEnabled:YES forSegmentAtIndex:0];
            }
            else {
                [self.segmentControlerPage setEnabled:NO forSegmentAtIndex:0];
            }
            
            if (lastSmile < [localsmileyArray count]) {
                [self.segmentControlerPage setEnabled:YES forSegmentAtIndex:2];
            }
            else {
                [self.segmentControlerPage setEnabled:NO forSegmentAtIndex:2];
            }*/
        });
        
        //}
        
        
    }
}

-(void)showSmileResults:(NSString *)tmpHTML {
    
    //NSLog(@"showSmileResults");
    
    NSString *doubleSmileysCSS = @"";
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"size_smileys"] isEqualToString:@"double"]) {
        doubleSmileysCSS = @"#container_ajax img.smile, #smileperso img.smile {max-height:60px;min-height: 30px;}.button {height:60px;min-width:45px;}.button img {max-height:60px;}";
    }
    
    
    [self.smileView evaluateJavaScript:[NSString stringWithFormat:@"\
                                                            $('#container').hide();\
                                                            $('#container_ajax').show();\
                                                            $('#container_ajax').html('%@');\
                                                            var hammertime2 = $('#container_ajax img').hammer({ hold_timeout: 0.000001 }); \
                                                            hammertime2.on('touchstart touchend', function(ev) {\
                                                            if(ev.type === 'touchstart'){\
                                                            $(this).addClass('selected');\
                                                            }\
                                                            if(ev.type === 'touchend'){\
                                                            $(this).removeClass('selected');\
                                                            window.location = 'oijlkajsdoihjlkjasdosmile://internal?query='+encodeURIComponent(this.alt).replace(/\\(/g, '%%28').replace(/\\)/g, '%%29');\
                                                            }\
                                                            });\
                                                            $('head link[rel=\"stylesheet\"]').last().after('<style>%@%@</style>');\
                                                            ", tmpHTML, [ThemeColors smileysCss:[[ThemeManager sharedManager] theme]],doubleSmileysCSS] completionHandler:nil];
}

#pragma mark -
#pragma mark Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == commonTableView) {
        return 35.0f;
    }
    else {
        return 100.0f;
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    //NSLog(@"NB Section %d", arrayDataID.count);
    
    return 1;
}
/* (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
 {
	return @"Recherche(s)";
 }
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //NSLog(@"%@", self.usedSearchDict);
    
    if (tableView == commonTableView) {
        return self.usedSearchSortedArray.count;
    }
    else {
        return self.rehostImagesSortedArray.count;
    }
    
    
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (tableView == commonTableView) {
        
        
        static NSString *CellIdentifier = @"Cell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            //NSLog(@"mew cell");
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = [self.usedSearchSortedArray objectAtIndex:indexPath.row];
        [[ThemeManager sharedManager] applyThemeToCell:cell];
        return cell;
        
    }
    else {
        
        
        static NSString *CellRehostIdentifier = @"RehostCell";
        
        RehostCell *cell = (RehostCell *)[tableView dequeueReusableCellWithIdentifier:CellRehostIdentifier];
        
        if (cell == nil)
        {
            
            NSArray *nib=[[NSBundle mainBundle] loadNibNamed:CellRehostIdentifier owner:self options:nil];
            
            cell = [nib objectAtIndex:0];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        
        [cell configureWithRehostImage:[rehostImagesSortedArray objectAtIndex:indexPath.row]];
        [[ThemeManager sharedManager] applyThemeToCell:cell];
        
        return cell;
        
    }
    
    
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == commonTableView) {
        self.textFieldSmileys.text = [self.usedSearchSortedArray objectAtIndex:indexPath.row];
        [self textFieldShouldReturn:self.textFieldSmileys];
        [self.commonTableView deselectRowAtIndexPath:self.commonTableView.indexPathForSelectedRow animated:NO];
    }
    else {
        
        [self.rehostTableView deselectRowAtIndexPath:self.rehostTableView.indexPathForSelectedRow animated:NO];
        
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete && tableView == rehostTableView)
    {
        NSLog(@"DELTE REHOST");
        RehostImage*rehostImage = [self.rehostImagesSortedArray objectAtIndex:indexPath.row];
        NSLog(@"rehostImage %@", rehostImage.nolink_full);
        
        [self.rehostImagesArray removeObjectIdenticalTo:rehostImage];
        
        NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *rehostImages = [[NSString alloc] initWithString:[directory stringByAppendingPathComponent:REHOST_IMAGE_FILE]];
        NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:self.rehostImagesArray];
        [savedData writeToFile:rehostImages atomically:YES];
        
        self.rehostImagesSortedArray =  [NSMutableArray arrayWithArray:[[self.rehostImagesArray reverseObjectEnumerator] allObjects]];
        
        [self.rehostTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
    }
}
#pragma mark - Collection Smileys Default and Images

static CGFloat fCellSize = 0.7;
static CGFloat fCellImageSize = 1;


- (void) setupCollections
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"commonsmile" ofType:@"plist"];
    self.dicCommonSmileys = [NSMutableArray arrayWithContentsOfFile:plistPath];

    // Collection Smileys defaults
    [self.collectionSmileys setHidden:YES];
    self.collectionSmileys.backgroundColor = UIColor.clearColor;

    [self.collectionSmileys registerClass:[RehostCollectionCell class] forCellWithReuseIdentifier:@"RehostCollectionCellId"];

    [self.collectionSmileys  setDataSource:self];
    [self.collectionSmileys  setDelegate:self];

    // Collection Image
    [self.collectionImages setHidden:YES];
    self.collectionImages.backgroundColor = UIColor.clearColor;

    [self.collectionImages registerClass:[RehostCollectionCell class] forCellWithReuseIdentifier:@"RehostCollectionCellId"];

    [self.collectionImages  setDataSource:self];
    [self.collectionImages  setDelegate:self];

   // [self.view addSubview:self.collectionImages];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    RehostCollectionCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RehostCollectionCellId" forIndexPath:indexPath];
    if (collectionView == self.collectionSmileys) {
        /*
         // Default smileys
        NSMutableDictionary* dic = self.dicCommonSmileys[indexPath.row];
        NSString* sSmileyResource = dic[@"resource"];
        UIImage* image = [UIImage imageNamed:sSmileyResource];
        CGFloat l = 50; // Largeur cellule
        CGFloat w = image.size.width;
        CGFloat h = image.size.height;
        NSLog(@"Image %d : %@", (int)indexPath.row, sSmileyResource);
        if (cell.previewImage == nil) {
            cell.previewImage = [[UIImageView alloc] initWithFrame:CGRectMake(l/2-w/2, l/2-h/2, w, h)];
            [cell addSubview:cell.previewImage];
        }
        [cell.previewImage setImage:image];
        cell.previewImage.clipsToBounds = NO;

        cell.layer.borderWidth = 1.0f;
        cell.layer.borderColor = [ThemeColors tintColor].CGColor;
        cell.layer.cornerRadius = 5;
        cell.layer.masksToBounds = true;

        return cell;*/
        UIImage* image = [[SmileyCache shared] getImageForIndex:(int)indexPath.row];
        if (image == nil) {
            NSLog(@"IMAGE for %d", (int)indexPath.row);
            image = [UIImage imageNamed:@"19-gear"];
        }
        else {
            NSLog(@"Nothing yet for %d", (int)indexPath.row);
        }

        CGFloat ch = cell.bounds.size.height;
        CGFloat cw = cell.bounds.size.width;
        CGFloat w = image.size.width*fCellImageSize;
        CGFloat h = image.size.height*fCellImageSize;
        
        if (cell.previewImage == nil) {
            cell.previewImage = [[UIImageView alloc] initWithFrame:CGRectMake(cw/2-w/2, ch/2-h/2, w, h)];
            [cell addSubview:cell.previewImage];
        }
        else {
            cell.previewImage.frame = CGRectMake(cw/2-w/2, ch/2-h/2, w, h);
        }
        cell.previewImage.clipsToBounds = NO;
        cell.previewImage.layer.masksToBounds = true;

        cell.layer.borderColor = [ThemeColors cellBorderColor].CGColor;
        cell.layer.backgroundColor = [UIColor whiteColor].CGColor;
        cell.layer.borderWidth = 1.0f;
        cell.layer.cornerRadius = 5;
        cell.layer.masksToBounds = true;
        
        [cell.previewImage setImage:image];

        /*
        NSString* sImageUrl = [[self.smileyArray objectAtIndex:indexPath.row] objectForKey:@"source"];
        NSLog(@"Loading %d - url %@", (int)indexPath.row, sImageUrl);
        NSURL *url = [NSURL URLWithString:[sImageUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@":/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-"]]];
        NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        RehostCollectionCell *updateCell = (id)[collectionView cellForItemAtIndexPath:indexPath];
                        if (updateCell) {
                            [cell.previewImage setImage:image];
                            NSLog(@"---> LOADED %d", (int)indexPath.row);
                        }
                    });
                }
            }
        }];
        [task resume];
        */
        return cell;

        /*
        }
        else {
            [cell configureWithIcon:[UIImage imageNamed:@"19-gear"] border:5];
            NSString* sImageUrl = [[self.smileyArray objectAtIndex:indexPath.row] objectForKey:@"source"];
            NSURL *url = [NSURL URLWithString:sImageUrl];
            NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (data) {
                    UIImage *image = [UIImage imageWithData:data];
                    if (image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            RehostCollectionCell *updateCell = (id)[collectionView cellForItemAtIndexPath:indexPath];
                            if (updateCell) {
                                [cell configureWithIcon:image border:5];
                            }
                        });
                    }
                }
            }];
            [task resume];
            return cell;
         */
        
    }
    else {
        if (indexPath.row == 0) {
            [cell configureWithIcon:[UIImage imageNamed:@"Camera-32"] border:15];
            cell.layer.borderWidth = 1.0f;
            cell.layer.borderColor = [ThemeColors tintColor].CGColor;
        } else {
            [cell configureWithRehostImage:[rehostImagesSortedArray objectAtIndex:indexPath.row - 1]];
        }
        cell.layer.cornerRadius = 5;
        cell.layer.masksToBounds = true;

        return cell;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.collectionSmileys) {
        return self.smileyArray.count;
        /*if (self.smileyArray.count > 0) { // default smileys
            return self.smileyArray.count;
        }
        else {*/
//            return self.dicCommonSmileys.count;
        //}
    }
    else {
        return self.rehostImagesSortedArray.count + 1;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.collectionSmileys) {
        /*
        UIImage* image = [[SmileyCache shared] getImageForIndex:(int)indexPath.row];
        if (image == nil) {
            NSLog(@"IMAGE for %d", (int)indexPath.row);
            image = [UIImage imageNamed:@"19-gear"];
        }
        else {
            NSLog(@"Nothing yet for %d", (int)indexPath.row);
        }

        CGFloat w = MAX(MIN(70,image.size.width), 50);
         */
        //return CGSizeMake(w, 50);
        return CGSizeMake(70*fCellSize, 50*fCellSize);
    }
    else {
        return CGSizeMake(60, 60);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (collectionView == self.collectionSmileys) {
        return UIEdgeInsetsMake(2, 2, 0, 0);
    }
    else {
        return UIEdgeInsetsMake(0, 2, 0, 0);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    if (collectionView == self.collectionSmileys) {
        return 1.0;
    }
    else {
        return 1.0;
    }
}

#pragma mark - Rehost
- (void) uploadProgress: (NSNotification *) notification {
    // NSLog(@"notif %@", notification);
    
    float progressFloat = [[[notification object] valueForKey:@"progress"] floatValue];
    
    if (progressFloat > 0) {
        if (progressFloat == 2) {
            RehostImage* rehostImage = (RehostImage *)[[notification object] objectForKey:@"rehostImage"];
            
            [self.rehostImagesArray addObject:rehostImage];
            
            NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *rehostImages = [[NSString alloc] initWithString:[directory stringByAppendingPathComponent:REHOST_IMAGE_FILE]];
            
            NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:self.rehostImagesArray];
            [savedData writeToFile:rehostImages atomically:YES];
            
            self.rehostImagesSortedArray =  [NSMutableArray arrayWithArray:[[self.rehostImagesArray reverseObjectEnumerator] allObjects]];
            [self.rehostTableView reloadData];
            
            
        }
        else {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1];
            [[[self.rehostTableView tableHeaderView] viewWithTag:12345] setHidden:NO];
            
            [[[self.rehostTableView tableHeaderView] viewWithTag:12345] setAlpha:1];
            
            
            [UIView commitAnimations];
            
            UIView* progressView = [[self.rehostTableView tableHeaderView] viewWithTag:54321];
            CGRect globalFrame = [progressView superview].frame;
            CGRect progressFrame = progressView.frame;
            
            progressFrame.size.width = progressFloat * globalFrame.size.width;
            
            progressView.frame = progressFrame;
            progressView.superview.backgroundColor = [ThemeColors addMessageBackgroundColor:[[ThemeManager sharedManager] theme]];
            progressView.backgroundColor = [ThemeColors tintColor:[[ThemeManager sharedManager] theme]];
            
            if (progressFloat == 1) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.5];
                
                [[[self.rehostTableView tableHeaderView] viewWithTag:12345] setAlpha:0];
                
                
                [UIView commitAnimations];
                
                
            }
        }
        
        
    }
    else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        
        [[[self.rehostTableView tableHeaderView] viewWithTag:12345] setAlpha:0];
        
        [UIView commitAnimations];
    }
}



- (void)uploadNewPhoto:(id)sender {
    //NSLog(@"uploadNewPhoto");
    [self showImagePicker:UIImagePickerControllerSourceTypeCamera withSender:sender];
}

- (void)uploadExistingPhoto:(id)sender {
    //NSLog(@"uploadExistingPhoto");
    [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary withSender:sender];
}

-(void)segmentedControlValueDidChange:(UISegmentedControl *)segment {
    switch (segment.selectedSegmentIndex) {
        case 0:{
            [[NSUserDefaults standardUserDefaults] setInteger:bbcodeImageWithLink forKey:@"rehost_use_link"];
            break;}
        case 1:{
            [[NSUserDefaults standardUserDefaults] setInteger:bbcodeImageNoLink forKey:@"rehost_use_link"];
            break;}
        case 2:{
            [[NSUserDefaults standardUserDefaults] setInteger:bbcodeLinkOnly forKey:@"rehost_use_link"];
            break;}
    }
}

-(void)segmentedControlResizeValueDidChange:(UISegmentedControl *)segment {
    switch (segment.selectedSegmentIndex) {
        case 0:{
            [[NSUserDefaults standardUserDefaults] setInteger:1200 forKey:@"rehost_resize_before_upload"];
            break;}
        case 1:{
            [[NSUserDefaults standardUserDefaults] setInteger:1000 forKey:@"rehost_resize_before_upload"];
            break;}
        case 2:{
            [[NSUserDefaults standardUserDefaults] setInteger:800 forKey:@"rehost_resize_before_upload"];
            break;}
        case 3:{
            [[NSUserDefaults standardUserDefaults] setInteger:600 forKey:@"rehost_resize_before_upload"];
            break;}
        case 4:{
            [[NSUserDefaults standardUserDefaults] setInteger:400 forKey:@"rehost_resize_before_upload"];
            break;}
    }
}


- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType withSender:(UIButton *)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:sourceType])
    {
        HFRUIImagePickerController *picker = [[HFRUIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = NO;
        picker.sourceType = sourceType;
        picker.modalPresentationStyle = UIModalPresentationFullScreen;

        
        if ([self respondsToSelector:@selector(traitCollection)] && [HFRplusAppDelegate sharedAppDelegate].window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact){
            
            [self presentViewController:picker animated:YES completion:^{
                //NSLog(@"présenté");
            }];
        }
        else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.popover = nil;
            UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:picker];
            [popover presentPopoverFromRect:sender.frame inView:[self.rehostTableView tableHeaderView] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            self.popover = popover;
        } else {
            [self presentViewController:picker animated:YES completion:^{
                //NSLog(@"présenté");
            }];
            //[self presentModalViewController:picker animated:YES];
        }
    }
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
    NSLog(@"imagePickerControllerDidCancel");
    if ([self respondsToSelector:@selector(traitCollection)] && [HFRplusAppDelegate sharedAppDelegate].window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact){
        
        [picker dismissModalViewControllerAnimated:YES];
        
    }
    else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [_popover dismissPopoverAnimated:YES];
    }
    else
    {
        [picker dismissModalViewControllerAnimated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"didFinishPickingMediaWithInfo %@", info);
    
    [self imagePickerControllerDidCancel:picker];
    
    RehostImage *rehostImage = [[RehostImage alloc] init];
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    [rehostImage upload:image];
    
    //[self dismissViewControllerAnimated:YES completion:^{
    //  NSLog(@"dismissed!");
    //}];
    //    [self imagePickerControllerDidCancel:picker];
    
}

#pragma mark -
#pragma mark Multis


- (void)selectCompteFn:(id)sender {
    NSLog(@"SELECT");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    NSArray *comptes = [[MultisManager sharedManager] getComtpes];
    for (int j =0 ; j<comptes.count; j++)
    {
        NSString *titleString = [comptes[j] objectForKey:PSEUDO_DISPLAY_KEY];
        UIAlertAction * action = [UIAlertAction actionWithTitle:titleString style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self onSelectCompte:j];
        }];
        [alert addAction:action];
    }
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    
    [alert setValue:[[NSAttributedString alloc] initWithString:@"Choisir un compte"
                                                    attributes:@{
                                                                 NSForegroundColorAttributeName: [ThemeColors placeholderColor:[[ThemeManager sharedManager] theme]]
                                                                 }
                     ] forKey:@"attributedTitle"];
    

    [self presentViewController:alert animated:YES completion:nil];
    [[ThemeManager sharedManager] applyThemeToAlertController:alert];
}

- (void)onSelectCompte:(int)index{
    NSArray *comptes = [[MultisManager sharedManager] getComtpes];
    [self onSelectedCompteChange:[comptes objectAtIndex:index]];
}

- (void)onSelectedCompteChange:(NSDictionary *)newSelectedCompte {
    MultisManager *manager = [MultisManager sharedManager];
    selectedCompte = newSelectedCompte;
    [selectCompte setImage:[manager getAvatarForCompte:selectedCompte] forState:UIControlStateNormal];
}



#pragma mark -
#pragma mark Memory

- (void)viewDidUnload {
    NSLog(@"viewDidUnload ADD");
    
    [super viewDidUnload];
    
    self.loadingView = nil;	
    
    self.textView.delegate = nil;
    self.textView = nil;
    
    self.formSubmit = nil;
    self.refreshAnchor = nil;
    self.accessoryView = nil;
    
    [self.smileView stopLoading];
    self.smileView.navigationDelegate = nil;
    self.smileView = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	
    
    self.segmentControler = nil;
    
    self.textFieldTitle = nil;
    self.textFieldTo = nil;
    
    self.commonTableView = nil;
    self.rehostTableView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];

}

- (void)dealloc {
    NSLog(@"dealloc ADD");
    
    [textView resignFirstResponder];
    [self viewDidUnload];
    
    [request cancel];
    [request setDelegate:nil];
    
    [requestSmile cancel];
    [requestSmile setDelegate:nil];
    [self.rehostImagesArray removeAllObjects];
    [self.rehostImagesSortedArray removeAllObjects];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"smileyReceived" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"uploadProgress" object:nil];
    
    self.delegate = nil;
    
    
    
    
    
}

@end
