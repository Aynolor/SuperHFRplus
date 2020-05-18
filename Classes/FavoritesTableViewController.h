//
//  FavoritesTableViewController.h
//  HFRplus
//
//  Created by FLK on 05/07/10.
//

#import <UIKit/UIKit.h>

@class MessagesTableViewController;
@class PullToRefreshErrorViewController;
@class ASIHTTPRequest, FilterPostsQuotes;


@interface FavoritesTableViewController : UIViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate> {
	IBOutlet UITableView *favoritesTableView;
	IBOutlet UIView *loadingView;

    NSMutableArray *arrayData;
    NSMutableArray *arrayTopics;
    NSMutableArray *arrayNewData;
    NSMutableArray *arrayCategories;
    NSMutableArray *arrayCategoriesHidden;
    NSMutableArray *arrayCategoriesVisibleOrder;
    NSMutableArray *arrayCategoriesHiddenOrder;

	MessagesTableViewController *messagesTableViewController;
    PullToRefreshErrorViewController *errorVC;
    
	NSIndexPath *pressedIndexPath;

	ASIHTTPRequest *request;
	
    bool reloadOnAppear;
	STATUS status;
	NSString *statusMessage;
	IBOutlet UILabel *maintenanceView;	
    
    UIAlertController   *topicActionAlert;
    
    BOOL showAll;
    BOOL editCategoriesList;
}

@property (nonatomic, strong) IBOutlet UITableView *favoritesTableView;
@property (nonatomic, strong) IBOutlet UIView *loadingView;

@property (nonatomic, strong) UIAlertController *topicActionAlert;

@property (nonatomic, strong) NSMutableArray *arrayData;
@property (nonatomic, strong) NSMutableArray *arrayTopics;
@property (nonatomic, strong) NSMutableArray *arrayNewData;
@property (nonatomic, strong) NSMutableArray *arrayCategories;
@property (nonatomic, strong) NSMutableArray *arrayCategoriesHidden;
@property (nonatomic, strong) NSMutableArray *arrayCategoriesVisibleOrder; // Ordre des catégories visibles: liste de Favorite.forum.aID (identifiant de catégorie)
@property (nonatomic, strong) NSMutableArray *arrayCategoriesHiddenOrder; // Ordre des catégories masquées: liste de Favorite.forum.aID (identifiant de catégorie)

@property (nonatomic, strong) MessagesTableViewController *messagesTableViewController;
@property (nonatomic, strong) PullToRefreshErrorViewController *errorVC;
@property (nonatomic, strong) FilterPostsQuotes* filterPostsQuotes;

@property BOOL showAll;
@property BOOL editCategoriesList;

@property bool reloadOnAppear;
@property STATUS status;
@property (nonatomic, strong) NSString *statusMessage;
@property (nonatomic, strong) IBOutlet UILabel *maintenanceView;
@property (nonatomic, strong) UIAlertController *alertProgress;
@property (nonatomic, strong) UIProgressView *progressView;
-(NSString*)wordAfterString:(NSString*)searchString inString:(NSString*)selfString;

@property (nonatomic, strong) NSIndexPath *pressedIndexPath;

@property (strong, nonatomic) ASIHTTPRequest *request;

-(void)loadDataInTableView:(NSData*)contentData;
-(void)reset;
-(void)reload:(BOOL)shake;
-(void)reload;

- (void)setTopicViewed;
- (void)pushTopic;

- (void)chooseTopicPage;
-(void) updateProgressBarWithPercent:(float)fPercent andMessage:(NSString*)sMessage;

@end
