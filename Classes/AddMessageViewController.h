//
//  AddMessageViewController.h
//  HFRplus
//
//  Created by FLK on 16/08/10.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import "ASIHTTPRequest.h"
#import "HFRTextView.h"

@protocol AddMessageViewControllerDelegate;

@interface AddMessageViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, WKNavigationDelegate, WKUIDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource> {
    id <AddMessageViewControllerDelegate> __weak delegate;
    
    //bb
    HFRTextView *textView;
    
    NSMutableDictionary *arrayInputData;
    NSString *formSubmit;
    
    UIView *__weak accessoryView;
    
    NSRange lastSelectedRange;
    
    BOOL loaded; //to load data only once
    BOOL isDragging;
    
    WKWebView *smileView;
    UISegmentedControl *segmentControler;
    UISegmentedControl *segmentControlerPage;
    
    //UIScrollView *scrollViewer;
    UITextField *textFieldSmileys;
    NSMutableArray *smileyArray;
    int smileyPage;
    UITableView *commonTableView;
    NSMutableDictionary *usedSearchDict;
    NSMutableArray *usedSearchSortedArray;
    
    NSString *smileyCustom;
    
    //HFR REHOST
    UITableView *rehostTableView;
    NSMutableArray *rehostImagesArray;
    NSMutableArray* rehostImagesSortedArray;
    
    BOOL haveTitle;
    UITextField *textFieldTitle;
    
    BOOL haveTo;
    UITextField *textFieldTo;
    
    BOOL haveCategory;
    UITextField *textFieldCat;
    
    int offsetY;
    
    IBOutlet UIView *loadingView;
    ASIHTTPRequest *request;
    ASIHTTPRequest *requestSmile;
    
    id _popover;
    NSString *refreshAnchor;
    
    NSString *statusMessage;
    
    NSString *sBrouillon;
    BOOL bBrouillonUtilise;
    BOOL bTexteModifie;
}

@property (nonatomic, strong) IBOutlet UIView *loadingView;
@property (nonatomic, strong) IBOutlet UILabel *loadingViewLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *loadingViewIndicator;

@property (nonatomic, weak) id <AddMessageViewControllerDelegate> delegate;

@property (strong, nonatomic) ASIHTTPRequest *request;
@property (strong, nonatomic) ASIHTTPRequest *requestSmile;

//bb
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property BOOL haveCategory;
@property BOOL haveTitle;
@property BOOL haveTo;
@property (nonatomic, strong) UITextField *textFieldTitle;
@property (nonatomic, strong) UITextField *textFieldTo;
@property (nonatomic, strong) UITextField *textFieldCat;
@property int offsetY;

@property (nonatomic, strong) IBOutlet WKWebView *smileView;
@property (nonatomic, strong) NSString *smileyCustom;

@property (weak, nonatomic) IBOutlet UIButton *btnToolbarImage;
@property (strong, nonatomic) IBOutlet UIButton *btnToolbarGIF;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarSmiley;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarUndo;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentControler;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarRedo;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentControlerPage;
@property (nonatomic, strong) IBOutlet UITextField *textFieldSmileys;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinnerSmileys;
@property (nonatomic, strong) NSMutableArray *smileyArray;
@property int smileyPage;
@property (nonatomic, strong) IBOutlet UITableView *commonTableView;
@property (nonatomic, strong) NSMutableDictionary *usedSearchDict;
@property (nonatomic, strong) NSMutableArray *usedSearchSortedArray;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionImages;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionSmileys;
@property BOOL bSearchSmileysAvailable;
@property BOOL bSearchSmileysActivated;


@property (nonatomic, strong) IBOutlet UITableView *rehostTableView;
@property (nonatomic, strong) NSMutableArray *rehostImagesArray;
@property (nonatomic, strong) NSMutableArray *rehostImagesSortedArray;
@property (nonatomic, strong) NSMutableArray *dicCommonSmileys;

//@property (nonatomic, retain) IBOutlet UIScrollView *scrollViewer;
@property (nonatomic, strong) id popover;
@property (nonatomic, strong) NSString *refreshAnchor;
@property (nonatomic, strong) NSString *statusMessage;


@property (nonatomic, strong) NSMutableDictionary *arrayInputData;
@property (nonatomic, strong) NSString *formSubmit;

@property NSRange lastSelectedRange;
@property BOOL loaded;
@property BOOL isDragging;

@property (nonatomic, weak) IBOutlet UIView *accessoryView;

// MULTIS
@property (nonatomic, weak) IBOutlet UIButton *selectCompte;
@property (nonatomic, strong) NSDictionary *selectedCompte;

// Brouillon
@property (nonatomic, strong) NSString *sBrouillon;
@property (nonatomic) BOOL sBrouillonUtilise;
-(IBAction)cancel;
-(IBAction)done;
-(IBAction)segmentFilterAction:(id)sender;
-(IBAction)textFieldSmileChange:(id)sender;


-(void)fetchSmileys;
-(void)loadSmileys:(int)page;
-(void)didSelectSmile:(NSString *)smile;
-(void)initData;
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
-(void)setupResponder;
-(bool)isDeleteMode;

@end

@protocol AddMessageViewControllerDelegate
- (void)addMessageViewControllerDidFinish:(AddMessageViewController *)controller;
- (void)addMessageViewControllerDidFinishOK:(AddMessageViewController *)controller;
@end
