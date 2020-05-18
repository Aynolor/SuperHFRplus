//
//  FavoritesTableViewController.m
//  HFRplus
//
//  Created by FLK on 05/07/10.
//

#import "HFRplusAppDelegate.h"

#import "FavoritesTableViewController.h"
#import "MessagesTableViewController.h"

#import "HTMLParser.h"
#import	"RegexKitLite.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

#import "ShakeView.h"

#import "Topic.h"
#import "Forum.h"
#import "Catcounter.h"
#import "FavoriteCell.h"
#import "FavoriteCellView.h"

#import "Favorite.h"
#import "UIImage+Resize.h"
#import "UIImage+BezierPath.h"

#import "AKSingleSegmentedControl.h"
#import "TopicsTableViewController.h"
#import "ForumCellView.h"

#import "UIScrollView+SVPullToRefresh.h"
#import "PullToRefreshErrorViewController.h"
#import "ThemeManager.h"
#import "ThemeColors.h"
#import "OfflineStorage.h"
#import "MultisManager.h"
#import "FilterPostsQuotes.h"
#import "MPStorage.h"

#define SECTION_CAT_VISIBLE 0
#define SECTION_CAT_HIDDEN 1


@implementation FavoritesTableViewController
@synthesize pressedIndexPath, favoritesTableView, loadingView, showAll;
@synthesize arrayData, arrayNewData, arrayTopics, arrayCategories, arrayCategoriesHidden, arrayCategoriesVisibleOrder, arrayCategoriesHiddenOrder; //v2 remplace arrayData, arrayDataID, arrayDataID2, arraySection
@synthesize messagesTableViewController, errorVC;
@synthesize request;
@synthesize reloadOnAppear, status, statusMessage, maintenanceView, topicActionAlert, filterPostsQuotes;

#pragma mark -
#pragma mark Data lifecycle

-(void) showAll:(id)sender {
    if (self.showAll) {
        self.showAll = NO;
        self.editCategoriesList = NO;
        [self.favoritesTableView setEditing:NO animated:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationItem.leftBarButtonItem setBackgroundImage:[ThemeColors imageFromColor:[UIColor clearColor]] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            /*[self.navigationItem.leftBarButtonItem setBackgroundImage:[ThemeColors imageFromColor:[UIColor clearColor]] forState:UIControlStateNormal barMetrics:UIBarMetricsCompact];
            */

            //On réaffiche le header
            if (self.childViewControllers.count > 0) {
                [self.favoritesTableView setTableHeaderView:((PullToRefreshErrorViewController *)[self.childViewControllers objectAtIndex:0]).view];
            }
        });
        [self.navigationItem.rightBarButtonItem setBackgroundImage:[ThemeColors imageFromColor:[UIColor clearColor]] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
        
        // Right button: Edit cat -> refresh
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    }
    else {
        self.showAll = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationItem.leftBarButtonItem setBackgroundImage:[ThemeColors imageFromColor:[ThemeColors tintLightColor]] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [self.navigationItem.rightBarButtonItem setBackgroundImage:[ThemeColors imageFromColor:[ThemeColors tintLightColor]] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            // Right button: Refresh -> Edit categories

            UIImage *buttonImage = [UIImage imageNamed:@"icon_list_bullets"];
            UIImage *buttonImageLandscape = [UIImage imageNamed:@"icon_list_bullets"];
            UIBarButtonItem *editCatBtn = [[UIBarButtonItem alloc] initWithImage:buttonImage
                                                             landscapeImagePhone:buttonImageLandscape
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(editCategoriesList:)];
            self.navigationItem.rightBarButtonItem = editCatBtn;
            [self.favoritesTableView setTableHeaderView:nil];
        });
    }

    if (![self.favoritesTableView isHidden]) {
        [self.favoritesTableView reloadData];
    }
    
}


-(void) editCategoriesList:(id)sender
{
    if (self.editCategoriesList)
    {
        self.editCategoriesList = NO;
    }
    else  // Activable que si au moins 1 catégories
    {
        //if (self.arrayCategories.count >= 1)
        //{
            self.editCategoriesList = YES;
        //}
        // Sinon on reste non éditable
    }
    [self.favoritesTableView setEditing:self.editCategoriesList animated:YES];
    [self.favoritesTableView reloadData];
}
- (void)cancelFetchContent
{
    //[self.favoritesTableView.pullToRefreshView stopAnimating];
    [request cancel];
}

- (void)fetchContent
{
    NSLog(@"fetchContent");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger vos_sujets = [defaults integerForKey:@"vos_sujets"];

    if (self.showAll) {
        [self showAll:nil];
    }
    
	[ASIHTTPRequest setDefaultTimeOutSeconds:kTimeoutMini];
	self.status = kIdle;
    
    switch (vos_sujets) {
        case 0:
            [self setRequest:[ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/forum1f.php?owntopic=1", [k ForumURL]]]]];
            break;
        case 1:
            [self setRequest:[ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/forum1f.php?owntopic=3", [k ForumURL]]]]];
            break;
        default:
            [self setRequest:[ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/forum1f.php?owntopic=1", [k ForumURL]]]]];
            break;
    }
    
	[request setDelegate:self];

	[request setDidStartSelector:@selector(fetchContentStarted:)];
	[request setDidFinishSelector:@selector(fetchContentComplete:)];
	[request setDidFailSelector:@selector(fetchContentFailed:)];
	
	[request startAsynchronous];
}

- (void)fetchContentStarted:(ASIHTTPRequest *)theRequest
{
    NSLog(@"fetchContentStarted");
	//Bouton Stop

	self.navigationItem.rightBarButtonItem = nil;	
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelFetchContent)];
	self.navigationItem.rightBarButtonItem = segmentBarItem;

    //[self.favoritesTableView.pullToRefreshView stopAnimating];

    /*
	[self.maintenanceView setHidden:YES];
	[self.favoritesTableView setHidden:YES];
	[self.loadingView setHidden:NO];	
     */
}

- (void)fetchContentComplete:(ASIHTTPRequest *)theRequest
{
    NSLog(@"fetchContentComplete");

	//Bouton Reload
	self.navigationItem.rightBarButtonItem = nil;
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
    @try {
        [self loadDataInTableView:[theRequest responseData]];
        
        [self.arrayData removeAllObjects];
        //[self.arrayTopics removeAllObjects];

        self.arrayData = [NSMutableArray arrayWithArray:self.arrayNewData];
        
        [self.arrayNewData removeAllObjects];
        
        [self.favoritesTableView reloadData];
        
        [self.favoritesTableView.pullToRefreshView stopAnimating];
        [self.favoritesTableView.pullToRefreshView setLastUpdatedDate:[NSDate date]];
    }
    @catch(NSException* e) {
        [self fetchContentFailed:theRequest];
    }
    @finally {}
}

- (void)fetchContentFailed:(ASIHTTPRequest *)theRequest
{
    NSLog(@"fetchContentFailed");

	//Bouton Reload
	self.navigationItem.rightBarButtonItem = nil;
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	
    [self.maintenanceView setText:@"oops :o"];
    
    [self.favoritesTableView.pullToRefreshView stopAnimating];

    // Popup retry
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Ooops !" message:[theRequest.error localizedDescription]  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) { [self cancelFetchContent]; }];
    UIAlertAction* actionRetry = [UIAlertAction actionWithTitle:@"Réessayer" style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) { [self.favoritesTableView triggerPullToRefresh]; }];
    [alert addAction:actionCancel];
    [alert addAction:actionRetry];
    
    [self presentViewController:alert animated:YES completion:nil];
    [[ThemeManager sharedManager] applyThemeToAlertController:alert];
}

#pragma mark - PullTableViewDelegate

-(void)reset {
	[self.arrayData removeAllObjects];
	
	[self.favoritesTableView reloadData];
}
//-- V2

#pragma mark -
#pragma mark View lifecycle

-(void)loadDataInTableView:(NSData *)contentData
{
    NSLog(@"loadDataInTableView");
    
    [self.arrayCategories removeAllObjects];
    [self.arrayCategoriesHidden removeAllObjects];
    
	HTMLParser * myParser = [[HTMLParser alloc] initWithData:contentData error:NULL];
	HTMLNode * bodyNode = [myParser body];

	if (![bodyNode getAttributeNamed:@"id"]) {
        NSDictionary *notif;
        
		if ([[[bodyNode firstChild] tagName] isEqualToString:@"p"]) {
            
            notif = [NSDictionary dictionaryWithObjectsAndKeys:   [NSNumber numberWithInt:kMaintenance], @"status",
                     [[[bodyNode firstChild] contents] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], @"message", nil];

		}
        else {
            notif = [NSDictionary dictionaryWithObjectsAndKeys:   [NSNumber numberWithInt:kNoAuth], @"status",
                     [[[bodyNode findChildWithAttribute:@"class" matchingName:@"hop" allowPartial:NO] contents] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], @"message", nil];
            
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusChangedNotification object:self userInfo:notif];

		return;		
	}
		
	//MP
	BOOL needToUpdateMP = NO;
	HTMLNode *MPNode = [bodyNode findChildOfClass:@"none"]; //Get links for cat	
	NSArray *temporaryMPArray = [MPNode findChildTags:@"td"];
	
	if (temporaryMPArray.count == 3) {
		
		NSString *regExMP = @"[^.0-9]+([0-9]{1,})[^.0-9]+";			
		NSString *myMPNumber = [[[temporaryMPArray objectAtIndex:1] allContents] stringByReplacingOccurrencesOfRegex:regExMP
																										  withString:@"$1"];
		
		[[HFRplusAppDelegate sharedAppDelegate] updateMPBadgeWithString:myMPNumber];
	}
	else {
		needToUpdateMP = YES;
	}
	//MP
	
	//v1
    /*
    NSArray *temporaryTopicsArray = [bodyNode findChildrenWithAttribute:@"class" matchingName:@"sujet ligne_booleen" allowPartial:YES]; //Get topics for cat
    
	if (temporaryTopicsArray.count == 0) {

        NSLog(@"kNoResults");
        
        NSDictionary *notif = [NSDictionary dictionaryWithObjectsAndKeys:   [NSNumber numberWithInt:kNoResults], @"status",
                 @"Aucun nouveau message", @"message", nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusChangedNotification object:self userInfo:notif];

	}*/
	
	//hash_check
	HTMLNode *hash_check = [bodyNode findChildWithAttribute:@"name" matchingName:@"hash_check" allowPartial:NO];
	[[HFRplusAppDelegate sharedAppDelegate] setHash_check:[hash_check getAttributeNamed:@"value"]];
	//NSLog(@"hash_check %@", [hash_check getAttributeNamed:@"value"]);
	
    //v2
	HTMLNode *tableNode = [bodyNode findChildWithAttribute:@"class" matchingName:@"main" allowPartial:NO]; //Get favs for cat
	NSArray *temporaryFavoriteArray = [tableNode findChildTags:@"tr"];
    
    BOOL first = YES;
    Favorite *aFavorite;
    NSLog(@"run");
    int iOrder = 0;
    NSMutableArray* tmpArrayCategories = [[NSMutableArray alloc] init];
    NSMutableArray* tmpTopics = [[NSMutableArray alloc] init];
    NSMutableArray* tmpArrayCategoriesHidden = [[NSMutableArray alloc] init];
    BOOL catOrderIsEmpty = NO;
    if (self.arrayCategoriesVisibleOrder.count + self.arrayCategoriesHiddenOrder.count== 0)
    {
        catOrderIsEmpty = YES;
    }
    
    //Loop through all the tags
    for (HTMLNode * trNode in temporaryFavoriteArray)
    {
        if ([[trNode className] rangeOfString:@"fondForum1fCat"].location != NSNotFound)
        {
            if (!first) {
                if ([self.arrayCategoriesVisibleOrder containsObject:aFavorite.forum.aID])
                {
                    // On rajoute la catégorie si elle est visible à la liste des sujets (cat  + topics)
                    if (aFavorite.topics.count > 0)
                    {
                        //[self.arrayNewData addObject:aFavorite];
                        [self addFavorite:aFavorite into:self.arrayNewData andTopicsInto:tmpTopics];
                    }
                    
                    // On rajoute la catégorie dans la liste des catégories visibles
                    [tmpArrayCategories addObject:aFavorite];
                }
                else
                {
                    // On rajoute la catégorie dans la liste des catégories NON visibles
                    [tmpArrayCategoriesHidden addObject:aFavorite];
                }
            }

            aFavorite = [[Favorite alloc] init];
            [aFavorite parseNode:trNode];
            
            // First time: simply store default order from forum
            if (catOrderIsEmpty)
            {
                aFavorite.order = [NSNumber numberWithInt:iOrder];
                iOrder++;
                // Store the order
                [self.arrayCategoriesVisibleOrder addObject:aFavorite.forum.aID];

            }
            else // Next times: use the order stored
            {
                NSUInteger iOrderStored = [self.arrayCategoriesVisibleOrder indexOfObject:aFavorite.forum.aID];
                if (iOrderStored == NSNotFound)
                {
                    NSUInteger iOrderStoredHidden = [self.arrayCategoriesHiddenOrder indexOfObject:aFavorite.forum.aID];
                    if (iOrderStoredHidden == NSNotFound)
                    {
                        // La cat n'est trouvée nulle part: il s'agit d'une nouvelle cat. A caser à la fin des catégories visibles
                        aFavorite.order = [NSNumber numberWithInteger:self.arrayCategoriesVisibleOrder.count];
                        [self.arrayCategoriesVisibleOrder addObject:aFavorite.forum.aID];
                    }
                    else
                    {
                        aFavorite.order = [NSNumber numberWithUnsignedInteger:iOrderStoredHidden];
                    }
                }
                else
                {
                    aFavorite.order = [NSNumber numberWithUnsignedInteger:iOrderStored];
                    // Just in case, clean arrayCategoriesVisibleOrder
                    if ([self.arrayCategoriesHiddenOrder indexOfObject:aFavorite.forum.aID] != NSNotFound)
                        [self.arrayCategoriesHiddenOrder removeObject:aFavorite.forum.aID];
                }
            }
            
            //NSLog(@"Favorite order: aID=%@, order=%@", aFavorite.forum.aID, aFavorite.order);
            first = NO;
        }
        else if ([[trNode className] rangeOfString:@"ligne_booleen"].location != NSNotFound) {
            //NSLog(@"TOPIC // ROW");
            //NSLog(@"Topic node %@", rawContentsOfNode([trNode _node], [myParser _doc]));

            [aFavorite addTopicWithNode:trNode];
        }
        else {
            //NSLog(@"ELSE");
        }
    }
    NSLog(@"run2");
    if (!first)
    {
        if ([self.arrayCategoriesVisibleOrder containsObject:aFavorite.forum.aID])
        {
            // On rajoute la catégorie si elle est visible à la liste des sujets (cat  + topics)
            if (aFavorite.topics.count > 0)
            {
                //[self.arrayNewData addObject:aFavorite];
                [self addFavorite:aFavorite into:self.arrayNewData andTopicsInto:tmpTopics];
            }
            
            // On rajoute la catégorie dans la liste des catégories visibles
            [tmpArrayCategories addObject:aFavorite];
        }
        else
        {
            // On rajoute la catégorie dans la liste des catégories NON visibles
            [tmpArrayCategoriesHidden addObject:aFavorite];
        }
    }
    
    // Save arrayCategoriesOrder to user defaults
    [[NSUserDefaults standardUserDefaults] setObject:self.arrayCategoriesVisibleOrder forKey:@"arrayCategoriesVisibleOrder"];
    [[NSUserDefaults standardUserDefaults] setObject:self.arrayCategoriesHiddenOrder forKey:@"arrayCategoriesHiddenOrder"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Reorder favorites
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"order" ascending:YES selector:@selector(compare:)];
    tmpArrayCategories = (NSMutableArray *)[tmpArrayCategories sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    self.arrayCategories = [NSMutableArray arrayWithArray:tmpArrayCategories];
    self.arrayCategoriesHidden = [NSMutableArray arrayWithArray:tmpArrayCategoriesHidden];

    NSMutableArray* tmpArrayNewData = [[NSMutableArray alloc] init];
    tmpArrayNewData = [NSMutableArray arrayWithArray:self.arrayNewData];
    tmpArrayNewData = (NSMutableArray *)[tmpArrayNewData sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    self.arrayNewData = [NSMutableArray arrayWithArray:tmpArrayNewData];

    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey: @"dDateOfLastPost" ascending:NO selector:@selector(compare:)];
    self.arrayTopics = (NSMutableArray *)[tmpTopics sortedArrayUsingDescriptors: [NSMutableArray arrayWithObject:sortDescriptorDate]];
    
    
    if (([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"] && self.arrayNewData.count == 0) || // Mode classique avec catégories
         self.arrayTopics.count == 0) // Mode sans les categories
    {
        NSDictionary *notif = [NSDictionary dictionaryWithObjectsAndKeys:   [NSNumber numberWithInt:kNoResults], @"status",
                               @"Aucun nouveau message", @"message", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusChangedNotification object:self userInfo:notif];
    }

    if (self.status != kNoResults) {
        
        NSDictionary *notif = [NSDictionary dictionaryWithObjectsAndKeys:   [NSNumber numberWithInt:kComplete], @"status", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusChangedNotification object:self userInfo:notif];
    }
}

- (void)addFavorite:(Favorite*)fav into:(NSMutableArray*)arrayDataLocal andTopicsInto:(NSMutableArray*)arrayTopicsLocal
{
    [arrayDataLocal addObject:fav];
    for (Topic* topic in fav.topics)
    {
        [arrayTopicsLocal addObject:topic];
    }
}

-(NSString*)wordAfterString:(NSString*)searchString inString:(NSString*)selfString
{
    NSRange searchRange, foundRange, foundRange2, resultRange;//endRange
	
    foundRange = [selfString rangeOfString:searchString];
    //endRange = [selfString rangeOfString:@"&subcat"];
	
    if ((foundRange.length == 0) ||
        (foundRange.location == 0))
    {
        // searchString wasn't found or it was found first in the string
        return @"";
    }
    // start search before the found string
    //searchRange = NSMakeRange(foundRange.location, endRange.location-foundRange.location);
	
	searchRange.location = foundRange.location;
	searchRange.length = foundRange.length + 4;
	
	//NSLog (@"URLS: %@", selfString);
	//NSLog (@"URLS: %@", arrayFavs3);
	
	foundRange2 = [selfString rangeOfString:@"&" options:NSBackwardsSearch range:searchRange];
	
	
    resultRange = NSMakeRange(foundRange.location+foundRange.length, foundRange2.location-foundRange.location-foundRange.length);
	
    return [selfString substringWithRange:resultRange];
}

-(void)OrientationChanged
{
    if (topicActionAlert) {
        [topicActionAlert dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (self.navigationController.visibleViewController == self) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            UIView *btn;
            UIView *btn2;
            
            UIInterfaceOrientation o = [[UIApplication sharedApplication] statusBarOrientation];
            
            if (UIDeviceOrientationIsLandscape(o)) {
                NSLog(@"LAND IPHONE");
                btn = [self.navigationController.navigationBar viewWithTag:238];
                btn2 = [self.navigationController.navigationBar viewWithTag:237];
            }
            else {
                btn = [self.navigationController.navigationBar viewWithTag:237];
                btn2 = [self.navigationController.navigationBar viewWithTag:238];
            }
            
            [btn2 setHidden:YES];
            [btn setHidden:NO];
            
            CGRect frame = btn.frame;

            if (UIDeviceOrientationIsLandscape(o)) {
                frame.origin.y = (32 - frame.size.height)/2;
            }
            else {
                frame.origin.y = (44 - frame.size.height)/2;
            }
        }
    }
}

-(void)LoginChanged:(NSNotification *)notification {
    NSLog(@"loginChanged %@", notification);

    self.reloadOnAppear = YES;
}

-(void)StatusChanged:(NSNotification *)notification {
    
    if ([[notification object] class] != [self class]) {
        //NSLog(@"KO");
        return;
    }
    
    NSDictionary *notif = [notification userInfo];
    
    self.status = [[notif valueForKey:@"status"] intValue];
    
    //NSLog(@"StatusChanged %d = %u", self.childViewControllers.count, self.status);

    //on vire l'eventuel header actuel
    if (self.childViewControllers.count > 0) {
        [[self.childViewControllers objectAtIndex:0] removeFromParentViewController];
        self.favoritesTableView.tableHeaderView = nil;
    }
    
    if (self.status == kComplete || self.status == kIdle) {
        //NSLog(@"COMPLETE %d", self.childViewControllers.count);

    }
    else {
        self.errorVC = [[PullToRefreshErrorViewController alloc] initWithNibName:nil bundle:nil andDico:notif];
        [self addChildViewController:self.errorVC];
        
        self.favoritesTableView.tableHeaderView = self.errorVC.view;
        [self.errorVC sizeToFit];
        [self.errorVC applyTheme];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    return [super initWithCoder:aDecoder];
}

- (void)viewDidLoad {
	//NSLog(@"viewDidLoad ftv");
    [super viewDidLoad];

	self.title = @"Favoris";
    self.showAll = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    UINib *nib = [UINib nibWithNibName:@"ForumCellView" bundle:nil];
    [self.favoritesTableView registerNib:nib forCellReuseIdentifier:@"ForumCellID"];
    UINib *nib2 = [UINib nibWithNibName:@"FavoriteCellView" bundle:nil];
    [self.favoritesTableView registerNib:nib2 forCellReuseIdentifier:@"FavoriteCellID"];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OrientationChanged)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(StatusChanged:)
                                                 name:kStatusChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(LoginChanged:)
                                                 name:kLoginChangedNotification
                                               object:nil];
    
    
    
	// reload
    UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    //UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"categories"] style:UIBarButtonItemStyleBordered target:self action:@selector(reload)];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
    
    // showAll
    UIImage *buttonImage = [UIImage imageNamed:@"all_categories"];
    UIImage *buttonImageLandscape = [UIImage imageNamed:@"all_categories_land"];
    UIBarButtonItem *allBtn = [[UIBarButtonItem alloc] initWithImage:buttonImage
                                                 landscapeImagePhone:buttonImageLandscape
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(showAll:)];

    self.navigationItem.leftBarButtonItem = allBtn;

    //Supprime les lignes vides à la fin de la liste
    self.favoritesTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    
	[(ShakeView*)self.view setShakeDelegate:self];
	
    self.arrayData = [[NSMutableArray alloc] init];
    self.arrayTopics = [[NSMutableArray alloc] init];
    self.arrayNewData = [[NSMutableArray alloc] init];
    self.arrayCategories = [[NSMutableArray alloc] init];

    // Get cat order from user default if present
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([[[defaults dictionaryRepresentation] allKeys] containsObject:@"arrayCategoriesVisibleOrder"]) {
        self.arrayCategoriesVisibleOrder = [[defaults arrayForKey:@"arrayCategoriesVisibleOrder"] mutableCopy];
    } else {
        // If not, create en empty array
        self.arrayCategoriesVisibleOrder = [[NSMutableArray alloc] init];
    }
    
    // Get cat hidden list from user default if present
    if ([[[defaults dictionaryRepresentation] allKeys] containsObject:@"arrayCategoriesHiddenOrder"]) {
        self.arrayCategoriesHiddenOrder = [[defaults arrayForKey:@"arrayCategoriesHiddenOrder"] mutableCopy];
    } else {
        // If not, create en empty array
        self.arrayCategoriesHiddenOrder = [[NSMutableArray alloc] init];
    }
        
	self.statusMessage = [[NSString alloc] init];
	
	//NSLog(@"viewDidLoad %d", self.arrayDataID.count);

    // setup pull-to-refresh
    
    __weak FavoritesTableViewController *self_ = self;

    [self.favoritesTableView addPullToRefreshWithActionHandler:^{
        //NSLog(@"=== BEGIN");
        [self_ fetchContent];
        //NSLog(@"=== END");
    }];
    
    [self.favoritesTableView triggerPullToRefresh];
    
    //[self fetchContent];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	//[self.view becomeFirstResponder];
    
    Theme theme = [[ThemeManager sharedManager] theme];
    self.view.backgroundColor = self.favoritesTableView.backgroundColor = self.maintenanceView.backgroundColor = self.loadingView.backgroundColor = self.favoritesTableView.pullToRefreshView.backgroundColor = [ThemeColors greyBackgroundColor:theme];
    if (self.errorVC) {
        [self.errorVC applyTheme];
    }
    self.favoritesTableView.separatorColor = [ThemeColors cellBorderColor:theme];
    self.favoritesTableView.pullToRefreshView.arrowColor = [ThemeColors cellTextColor:theme];
    self.favoritesTableView.pullToRefreshView.textColor = [ThemeColors cellTextColor:theme];
    self.favoritesTableView.pullToRefreshView.activityIndicatorViewStyle = [ThemeColors activityIndicatorViewStyle];
    
    UIButton *btn = (UIButton *)[self.navigationController.navigationBar viewWithTag:237];
    UIButton *btn2 = (UIButton *)[self.navigationController.navigationBar viewWithTag:238];
    
    if(btn){
        UIImage *img = btn.imageView.image;
        UIImage *bg = [UIImage imageNamed:@"lightBlue.png"];
        UIImage *timg = [ThemeColors tintImage:img withTheme:theme];
        UIImage *tbg = [ThemeColors tintImage:bg withColor:[ThemeColors tintLightColor]];

        [btn setImage:timg forState:UIControlStateNormal];
        [btn setImage:timg forState:UIControlStateSelected];
        [btn setImage:timg forState:UIControlStateHighlighted];
        [btn setBackgroundImage:tbg forState:UIControlStateSelected];
        [btn setBackgroundImage:tbg forState:UIControlStateHighlighted];
    }
    
    if(btn2){
        UIImage *img = btn2.imageView.image;
        UIImage *bg = [UIImage imageNamed:@"lightBlue.png"];
        UIImage *timg = [ThemeColors tintImage:img withTheme:theme];
        UIImage *tbg = [ThemeColors tintImage:bg withColor:[ThemeColors tintLightColor]];
        
        [btn2 setImage:timg forState:UIControlStateNormal];
        [btn2 setImage:timg forState:UIControlStateSelected];
        [btn2 setImage:timg forState:UIControlStateHighlighted];
        [btn2 setBackgroundImage:tbg forState:UIControlStateSelected];
        [btn2 setBackgroundImage:tbg forState:UIControlStateHighlighted];
    }

    if (self.showAll) {
        [self.navigationItem.leftBarButtonItem setBackgroundImage:[ThemeColors imageFromColor:[ThemeColors tintLightColor]] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    }
    
	if (self.messagesTableViewController) {
		//NSLog(@"viewWillAppear Favorites Table View Dealloc MTV");
		
		self.messagesTableViewController = nil;
	}
    
    if (self.pressedIndexPath) 
    {
		self.pressedIndexPath = nil;
    }
    
    if (favoritesTableView.indexPathForSelectedRow) {
        [favoritesTableView deselectRowAtIndexPath:favoritesTableView.indexPathForSelectedRow animated:NO];
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    
        UIInterfaceOrientation o = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIDeviceOrientationIsLandscape(o)) {
            [[self.navigationController.navigationBar viewWithTag:237] setHidden:YES];
            [[self.navigationController.navigationBar viewWithTag:238] setHidden:NO];
        }
        else
        {
            [[self.navigationController.navigationBar viewWithTag:237] setHidden:NO];
            [[self.navigationController.navigationBar viewWithTag:238] setHidden:YES];
        }
    }
    else {
        [[self.navigationController.navigationBar viewWithTag:237] setHidden:NO];
    }
    
    
    if (self.reloadOnAppear) {
        [self reload];
        self.reloadOnAppear = NO;
    }
    
    [self.favoritesTableView reloadData];
    
    
}
- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];

    [[self.navigationController.navigationBar viewWithTag:237] setHidden:YES];
    [[self.navigationController.navigationBar viewWithTag:238] setHidden:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[self.view resignFirstResponder];
    
    if (!self.filterPostsQuotes) {
        self.filterPostsQuotes = [[FilterPostsQuotes alloc] init];
    }
    [self.filterPostsQuotes checkPostsAndQuotesForAllTopics:self.arrayData andVC:self];
    //Mode sans cat : [self.filterPostsQuotes checkPostsAndQuotesForTopics:self.arrayTopics andVC:self];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
	//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)loadCatForSection:(int)section {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger vos_sujets = [defaults integerForKey:@"vos_sujets"];
    
    TopicsTableViewController *aView;
    
    switch (vos_sujets) {
        case 0:
            aView = [[TopicsTableViewController alloc] initWithNibName:@"TopicsTableViewController" bundle:nil flag:2];
            aView.forumFlag1URL = [[[arrayCategories objectAtIndex:section] forum] aURL];
            break;
        case 1:
            aView = [[TopicsTableViewController alloc] initWithNibName:@"TopicsTableViewController" bundle:nil flag:1];
            aView.forumFavorisURL = [[[arrayCategories objectAtIndex:section] forum] aURL];
            break;
        default:
            aView = [[TopicsTableViewController alloc] initWithNibName:@"TopicsTableViewController" bundle:nil flag:2];
            aView.forumFlag1URL = [[[arrayCategories objectAtIndex:section] forum] aURL];
            break;
    }
    
	aView.forumName = [[[arrayCategories objectAtIndex:section] forum] aTitle];
    
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Retour"
                                     style: UIBarButtonItemStyleBordered
                                    target:nil
                                    action:nil];
    
    self.navigationItem.backBarButtonItem.title = @" ";
    [self.navigationController pushViewController:aView animated:YES];
}

- (void)loadCatForType:(id)sender {
    
    
    //NSLog(@"loadCatForType %d", [sender tag]);
    int section = [sender tag];
    
    [self loadCatForSection:section];

    
}

#pragma mark -
#pragma mark Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.showAll) {
        return 44;
    }
    else {
        return 50;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // Hide sections for the list of categories
    if (self.showAll) {
        if (self.editCategoriesList) {
            return HEIGHT_FOR_HEADER_IN_SECTION;
        } else {
            return 0;
        }
        return 0;
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"])// for default favorite view
    {
        if ([[self.arrayData objectAtIndex:section] topics].count > 0) {
            return HEIGHT_FOR_HEADER_IN_SECTION;
        }
    }
    else
    {
        return HEIGHT_FOR_HEADER_IN_SECTION;
    }
    return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    /*if (self.arrayData.count > 0)
    {*/
        //On récupère la section (forum)
    CGFloat curWidth = self.view.frame.size.width;
    NSString* titleSection = nil;
    if (self.editCategoriesList) {
        if (section == 0) titleSection = @"Catégories visibles";
        if (section == 1) titleSection = @"Catégories masquées";
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"]) // Mode classique avec catégories)
    {
        if (self.arrayData.count > 0) {
            Forum *tmpForum = [[self.arrayData objectAtIndex:section] forum];
            titleSection = [tmpForum.aTitle uppercaseString];
        }
    }
    else
    {
        titleSection = @"Toutes catégories";
    }
    
    //UIView globale
    UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0,0,curWidth,HEIGHT_FOR_HEADER_IN_SECTION)];
    customView.backgroundColor = [ThemeColors headSectionBackgroundColor];
    customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    //UIImageView de fond
    UIView* borderView = [[UIView alloc] initWithFrame:CGRectMake(0,0,curWidth,1/[[UIScreen mainScreen] scale])];
    borderView.backgroundColor = [UIColor colorWithRed:158/255.0f green:158/255.0f blue:114/162.0f alpha:0.7];
    
    //[customView addSubview:borderView];
    
    UIView* borderView2 = [[UIView alloc] initWithFrame:CGRectMake(0,HEIGHT_FOR_HEADER_IN_SECTION-1/[[UIScreen mainScreen] scale],curWidth,1/[[UIScreen mainScreen] scale])];
    borderView2.backgroundColor = [UIColor colorWithRed:158/255.0f green:158/255.0f blue:114/162.0f alpha:0.7];

    //UIButton clickable pour accéder à la catégorie
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, curWidth, HEIGHT_FOR_HEADER_IN_SECTION)];
    if (!self.editCategoriesList && [self.arrayCategories count] > 0 && [[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"]) {
        [button setTag:[self.arrayCategories indexOfObject:[self.arrayData objectAtIndex:section]]];
    }
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];

    [button setTitleColor:[ThemeColors headSectionTextColor] forState:UIControlStateNormal];
    [button setTitle:titleSection forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(2, 10, 0, 0)];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [customView addSubview:button];
    
    if (!self.showAll && [[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"]) {
        [button addTarget:self action:@selector(loadCatForType:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    button.translatesAutoresizingMaskIntoConstraints = NO;
    UILayoutGuide *guide = customView.safeAreaLayoutGuide;
    //Trailing
    NSLayoutConstraint *trailing =[NSLayoutConstraint
                                   constraintWithItem:button
                                   attribute:NSLayoutAttributeTrailing
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:guide
                                   attribute:NSLayoutAttributeTrailing
                                   multiplier:1.0f
                                   constant:0.f];

    //Leading

    NSLayoutConstraint *leading = [NSLayoutConstraint
                                   constraintWithItem:button
                                   attribute:NSLayoutAttributeLeading
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:guide
                                   attribute:NSLayoutAttributeLeading
                                   multiplier:1.0f
                                   constant:0.f];

    //Bottom
    NSLayoutConstraint *bottom =[NSLayoutConstraint
                                 constraintWithItem:button
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                 toItem:customView
                                 attribute:NSLayoutAttributeBottom
                                 multiplier:1.0f
                                 constant:0.f];

    NSLayoutConstraint *top =[NSLayoutConstraint
                                 constraintWithItem:button
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                 toItem:customView
                                 attribute:NSLayoutAttributeTop
                                 multiplier:1.0f
                                 constant:0.f];

    [customView addSubview:button];
    
    [customView addConstraint:trailing];
    [customView addConstraint:leading];
    [customView addConstraint:bottom];
    [customView addConstraint:top];

    return customView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (self.showAll) {
        if (self.editCategoriesList) {
            return 2;
        }
        else
        {
            return 1;
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"]) // Mode classique avec catégories
    {
        return self.arrayData.count;
    }
    else
    {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	//NSLog(@"%d", section);
	//NSLog(@"titleForHeaderInSection %d %@", section, [[self.arrayNewData objectAtIndex:section] aTitle]);
    if (self.showAll) {
        if (section == 0)
        {
            return @"Catégories visibles";
        }
        else
        {
            return @"Catégories masquées";
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"]) // Mode classique avec catégories
    {
        return [[[self.arrayData objectAtIndex:section] forum] aTitle];
    }
    else
    {
        return @"Toutes catgéries";
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (self.showAll) {
        if (self.editCategoriesList)
        {
            if (section == SECTION_CAT_VISIBLE)
            {
                return self.arrayCategories.count;
            }
            if (section == SECTION_CAT_HIDDEN)
            {
                return self.arrayCategoriesHidden.count;
            }
        }
        else
        {
            return self.arrayCategories.count;
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"]) // Mode classique avec catégories
    {
        return [[self.arrayData objectAtIndex:section] topics].count;
    }
    else
    {
        return self.arrayTopics.count;
    }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.showAll) {
        static NSString *CellIdentifier = @"ForumCellID";
        
        ForumCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        Favorite* fav = nil;
        if (indexPath.section == 0)
        {
            fav = [arrayCategories objectAtIndex:indexPath.row];
        }
        else
        {
            fav = [arrayCategoriesHidden objectAtIndex:indexPath.row];
        }
        // Configure the cell...
        cell.titleLabel.text = [NSString stringWithFormat:@"%@", fav.forum.aTitle];
        [cell.catImage setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", [fav.forum getImageFromID]]]];

        cell.flagLabel.text = @"";
        
        //cell.flagLabel.font = [UIFont boldSystemFontOfSize:17];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        [cell setShowsReorderControl:YES];
        return cell;
    }
    else {
        FavoriteCellView *cell = (FavoriteCellView *)[tableView dequeueReusableCellWithIdentifier:@"FavoriteCellID"];
        cell.isFavoriteDisabled = NO;
        
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc]
                                                             initWithTarget:self action:@selector(handleLongPress:)];
        [cell addGestureRecognizer:longPressRecognizer];

        Topic *tmpTopic = nil;
        if ([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"]) // Mode classique avec catégories
        {
            tmpTopic = [self getTopicAtIndexPath:indexPath];
        }
        else // mode SANS catégories
        {
            tmpTopic = [self.arrayTopics objectAtIndex:indexPath.row];
            NSLog(@"Topic sans cat, row=%ld",indexPath.row);
        }

        
        if ([[MPStorage shared] isSuperFavorite:tmpTopic.postID]) {
            cell.isSuperFavorite = YES;
        } else {
            cell.isSuperFavorite = NO;
        }

        // Configure the cell...
        UIFont *font1 = [UIFont boldSystemFontOfSize:13.0f];
        if ([tmpTopic isViewed]) {
            font1 = [UIFont systemFontOfSize:13.0f];
        }
        NSDictionary *arialDict = [NSDictionary dictionaryWithObject: font1 forKey:NSFontAttributeName];
        NSMutableAttributedString *aAttrString1 = [[NSMutableAttributedString alloc] initWithString:[tmpTopic aTitle] attributes: arialDict];
        
        UIFont *font2 = [UIFont fontWithName:@"fontello" size:15];
        
        NSMutableAttributedString *finalString = [[NSMutableAttributedString alloc]initWithString:@""];
        
        if (tmpTopic.isClosed) {
            UIColor *fontcC = [UIColor colorWithHex:@"#4A4A4A" alpha:1.0];
            NSDictionary *arialDict2c = [NSDictionary dictionaryWithObjectsAndKeys:font2, NSFontAttributeName, fontcC, NSForegroundColorAttributeName, nil];
            NSMutableAttributedString *aAttrString2C = [[NSMutableAttributedString alloc] initWithString:@" " attributes: arialDict2c];
            [finalString appendAttributedString:aAttrString2C];
        }
        
        [finalString appendAttributedString:aAttrString1];
        [cell.labelTitle setAttributedText:finalString];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger vos_sujets = [defaults integerForKey:@"vos_sujets"];
        NSString* sPoll = @"";
        if (tmpTopic.isPoll) {
            sPoll = @" \U00002263";
        }
        NSString* sOffline = @"";
        if ([[OfflineStorage shared] isOfflineTopic:tmpTopic]) {
            sOffline = @" \U000025CF";
        }

        switch (vos_sujets) {
            case 0:
                [cell.labelMessageNumber setText:[NSString stringWithFormat:@"%@ ⚑%@ %d/%d", sOffline, sPoll, [tmpTopic curTopicPage], [tmpTopic maxTopicPage]]];
                break;
            case 1:
                [cell.labelMessageNumber setText:[NSString stringWithFormat:@"%@ ★%@ %d/%d", sOffline, sPoll, [tmpTopic curTopicPage], [tmpTopic maxTopicPage]]];
                break;
            default:
                [cell.labelMessageNumber setText:[NSString stringWithFormat:@"%@ ⚑%@ %d/%d", sOffline, sPoll, [tmpTopic curTopicPage], [tmpTopic maxTopicPage]]];
                break;
        }
        
        // Badge
        int iPageNumber = [tmpTopic maxTopicPage] - [tmpTopic curTopicPage];
        if (iPageNumber == 0) {
            cell.labelBadge.clipsToBounds = YES;
            cell.labelBadge.layer.cornerRadius = 20 / 2;
            [cell.labelBadge setText:@""];
            cell.labelBadge.backgroundColor = [UIColor clearColor];
            cell.labelBadgeWidth.constant = 0;
        } else {
            int iWidth = 16;
            if (iPageNumber < 10) {
                iWidth = 16;
            } else if (iPageNumber < 100) {
                iWidth = 23;
            } else if (iPageNumber < 1000) {
                iWidth = 30;
            } else if (iPageNumber <= 9999) {
                iWidth = 38;
            } else if (iPageNumber > 9999) {
                iPageNumber = 9999;
                iWidth = 38;
            }
            cell.labelBadge.clipsToBounds = YES;
            cell.labelBadge.layer.cornerRadius = 16 / 2;
            [cell.labelBadge setText:[NSString stringWithFormat:@"%d", iPageNumber]];
            cell.labelBadgeWidth.constant = iWidth;
        }
        
        [cell setShowsReorderControl:NO];
        
        // Posteur + date
        [cell.labelDate setText:[NSString stringWithFormat:@"%@ - %@", [tmpTopic aAuthorOfLastPost], [tmpTopic aDateOfLastPost]]];

        [cell applyTheme];
        
        return cell;
    }
}

- (void)checkPostsAndQuotesForAllTopics {
    NSMutableArray *cells = [[NSMutableArray alloc] init];
    for (NSInteger j = 0; j < [self.favoritesTableView numberOfSections]; ++j)
    {
        for (NSInteger i = 0; i < [self.favoritesTableView numberOfRowsInSection:j]; ++i)
        {
            // Check for posts for topic with callback in case cell needs to be updated
            // Unable search in ViewWillDisapear
            [cells addObject:[self.favoritesTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]]];
        }
    }
    
    if (!self.filterPostsQuotes) {
        self.filterPostsQuotes = [[FilterPostsQuotes alloc] init];
    }
    [self.filterPostsQuotes checkPostsAndQuotesForAllTopics:self.arrayData andVC:self];

}



- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    // Only when displaying all CATs
    if (self.showAll) {
        if (tableView == self.favoritesTableView)
        {
            Favorite *favFrom = nil;
            if (sourceIndexPath.section == SECTION_CAT_VISIBLE)
            {
                favFrom = [arrayCategories objectAtIndex:sourceIndexPath.row];
            }
            else
            {
                favFrom = [arrayCategoriesHidden objectAtIndex:sourceIndexPath.row];
            }

            NSLog(@"Moving fav %@ from %ld.%ld to %ld.%ld", favFrom.forum.aID, sourceIndexPath.section, sourceIndexPath.row, destinationIndexPath.section, destinationIndexPath.row);
            NSMutableArray *copyArrayCategories = [arrayCategories mutableCopy];
            NSMutableArray *copyArrayCategoriesHidden = [arrayCategoriesHidden mutableCopy];
            
            if (sourceIndexPath.section == SECTION_CAT_VISIBLE)
            {
                if (copyArrayCategories.count <= 1)
                {
                    // Popup retry
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Ooops !" message: @"Petit malin ! Au moins une catégorie doit être visible."
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                                         handler:^(UIAlertAction * action) { }];
                    [alert addAction:actionOK];
                    [self presentViewController:alert animated:YES completion:nil];
                    [[ThemeManager sharedManager] applyThemeToAlertController:alert];
                    [self.favoritesTableView reloadData];
                    return;
                }
                [copyArrayCategories removeObjectAtIndex:sourceIndexPath.row];
            }
            else
            {
                [copyArrayCategoriesHidden removeObjectAtIndex:sourceIndexPath.row];
            }
            
            if (destinationIndexPath.section == SECTION_CAT_VISIBLE) // Section visible
            {
                [copyArrayCategories insertObject:favFrom atIndex:destinationIndexPath.row];
            }
            else // Section masqués
            {
                [copyArrayCategoriesHidden insertObject:favFrom atIndex:destinationIndexPath.row];
                [self.arrayCategoriesHiddenOrder insertObject:favFrom.forum.aID atIndex:destinationIndexPath.row];
            }
            
            [self.arrayCategoriesVisibleOrder removeAllObjects];
            [self.arrayCategoriesHiddenOrder removeAllObjects];

            // Store the updated order
            int iOrder = 0;
            for (id fav in copyArrayCategories)
            {
                ((Favorite *)fav).order = [NSNumber numberWithInt: iOrder];
                NSLog(@"(Reordering) Favorite visible new order: aID=%@, order=%@ (%@)", ((Favorite *)fav).forum.aID, ((Favorite *)fav).order, ((Favorite *)fav).forum.aTitle);
                [self.arrayCategoriesVisibleOrder addObject: ((Favorite *)fav).forum.aID];
                iOrder ++;
            }
            iOrder = 0;
            for (id fav in copyArrayCategoriesHidden)
            {
                ((Favorite *)fav).order = [NSNumber numberWithInt: iOrder];
                NSLog(@"(Reordering) Favorite hidden new order: aID=%@, order=%@  (%@)", ((Favorite *)fav).forum.aID, ((Favorite *)fav).order, ((Favorite *)fav).forum.aTitle);
                [self.arrayCategoriesHiddenOrder addObject: ((Favorite *)fav).forum.aID];
                iOrder ++;
            }
            
            // Save to user defaults
            [[NSUserDefaults standardUserDefaults] setObject:self.arrayCategoriesVisibleOrder forKey:@"arrayCategoriesVisibleOrder"];
            [[NSUserDefaults standardUserDefaults] setObject:self.arrayCategoriesHiddenOrder forKey:@"arrayCategoriesHiddenOrder"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            
            self.arrayCategories = copyArrayCategories;
            self.arrayCategoriesHidden = copyArrayCategoriesHidden;

            [self.favoritesTableView reloadData];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.showAll)
    {
        return UITableViewCellEditingStyleNone;
    }
    else if (!self.showAll)
    {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView: (UITableView *) tableView canMoveRowAtIndexPath: (NSIndexPath *) indexPath
{
    // Only when displaying all CATs in edit mode
    if (self.showAll && self.editCategoriesList) {
        return YES;
    }
    
    return NO;
}

- (BOOL) tableView: (UITableView *) tableView canEditRowAtIndexPath: (NSIndexPath *) indexPath
{
    // Only when displaying all CATs in edit mode
    if (self.showAll && self.editCategoriesList) {
        return YES;
    }
    else if (!self.showAll)
    {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark Table view delegate

- (Topic*)getTopicAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"])// for default favorite view
        return [[[self.arrayData objectAtIndex:[indexPath section]] topics] objectAtIndex:[indexPath row]];
    
    return [self.arrayTopics objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.showAll)
    {
        [self loadCatForSection:indexPath.row];
    }
    else {
        Topic *aTopic = [self getTopicAtIndexPath:indexPath];
            
        MessagesTableViewController *aView = [[MessagesTableViewController alloc] initWithNibName:@"MessagesTableViewController" bundle:nil andUrl:[aTopic aURL] displaySeparator:YES];
        self.messagesTableViewController = aView;
        
        //setup the URL
        self.messagesTableViewController.topicName = [aTopic aTitle];
        
        //NSLog(@"push message liste");
        [self pushTopic];
    }
}

-(void)handleLongPress:(UILongPressGestureRecognizer*)longPressRecognizer {
	if (longPressRecognizer.state == UIGestureRecognizerStateBegan) {
		CGPoint longPressLocation = [longPressRecognizer locationInView:self.favoritesTableView];
		self.pressedIndexPath = [[self.favoritesTableView indexPathForRowAtPoint:longPressLocation] copy];

        if (topicActionAlert != nil) {
            topicActionAlert = nil;
        }
        NSMutableArray *arrayActionsMessages = [NSMutableArray array];
        [arrayActionsMessages addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"la dernière page", @"lastPageAction", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];
        [arrayActionsMessages addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"la dernière réponse", @"lastPostAction", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];
        [arrayActionsMessages addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"la page numéro...", @"chooseTopicPage", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];
        [arrayActionsMessages addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Copier le lien", @"copyLinkAction", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];

        /* Evol onglet sticky (gardée au cas où)
        [arrayActionsMessages addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Nouvel onglet", @"newTabBar", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]]; */


        topicActionAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        for( NSDictionary *dico in arrayActionsMessages) {
            [topicActionAlert addAction:[UIAlertAction actionWithTitle:[dico valueForKey:@"title"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                if ([self respondsToSelector:NSSelectorFromString([dico valueForKey:@"code"])])
                {
                    //[self performSelector:];
                    [self performSelectorOnMainThread:NSSelectorFromString([dico valueForKey:@"code"]) withObject:nil waitUntilDone:NO];
                }
                else {
                    NSLog(@"CRASH not respondsToSelector %@", [dico valueForKey:@"code"]);
                    
                    [self performSelectorOnMainThread:NSSelectorFromString([dico valueForKey:@"code"]) withObject:nil waitUntilDone:NO];
                }
            }]];
        }
        
        // Super favorites handling
        Topic *tmpTopic = [self getTopicAtIndexPath:self.pressedIndexPath];
        UIAlertAction* uiAction = [UIAlertAction actionWithTitle:@"Super favori" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self setTopicSuperFavoriteWithIndex:self.pressedIndexPath];
        }];
        
        if ([[MPStorage shared] isSuperFavorite:tmpTopic.postID]) {
            [uiAction setValue:@true forKey:@"checked"];
        }
        
        [topicActionAlert addAction:uiAction];
        
        // Offline favorites handling
        UIAlertAction* uiActionOffline = [UIAlertAction actionWithTitle:@"Favori hors ligne" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self setTopicOfflineFavoriteWithIndex:self.pressedIndexPath];
        }];
        if ([[OfflineStorage shared] isOfflineTopic:tmpTopic])
        {
            [uiActionOffline setValue:@true forKey:@"checked"];
        }
        [topicActionAlert addAction:uiActionOffline];
        
        // Check quotes
        UIAlertAction* uiActionCheckQuotes = [UIAlertAction actionWithTitle:@"Filtrer les posts" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self checkPostsAndQuotesForTopicIndex:self.pressedIndexPath];
        }];
        [topicActionAlert addAction:uiActionCheckQuotes];
        

        CGPoint longPressLocation2 = [longPressRecognizer locationInView:[[[HFRplusAppDelegate sharedAppDelegate] splitViewController] view]];
        CGRect origFrame = CGRectMake( longPressLocation2.x, longPressLocation2.y, 1, 1);
        
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            // Can't use UIAlertActionStyleCancel in dark theme : https://stackoverflow.com/a/44606994/1853603
            UIAlertActionStyle cancelButtonStyle = [[ThemeManager sharedManager] theme] == ThemeDark ? UIAlertActionStyleDefault : UIAlertActionStyleCancel;
            [topicActionAlert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:cancelButtonStyle handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }]];
        } else {
            // Required for UIUserInterfaceIdiomPad
            topicActionAlert.popoverPresentationController.sourceView = [[[HFRplusAppDelegate sharedAppDelegate] splitViewController] view];
            topicActionAlert.popoverPresentationController.sourceRect = origFrame;
            topicActionAlert.popoverPresentationController.backgroundColor = [ThemeColors alertBackgroundColor:[[ThemeManager sharedManager] theme]];
        }
        
        [self presentViewController:topicActionAlert animated:YES completion:nil];
        [[ThemeManager sharedManager] applyThemeToAlertController:topicActionAlert];
		
	}
}

-(void)lastPageAction{
    NSIndexPath *indexPath = pressedIndexPath;
    Topic *tmpTopic = [self getTopicAtIndexPath:indexPath];
    
    MessagesTableViewController *aView = [[MessagesTableViewController alloc] initWithNibName:@"MessagesTableViewController" bundle:nil andUrl:[tmpTopic aURLOfLastPage]];
    self.messagesTableViewController = aView;
    
    self.messagesTableViewController.topicName = [tmpTopic aTitle];
    
    [self pushTopic];
    
    //NSLog(@"url pressed last page: %@", [[arrayData objectAtIndex:theRow] lastPageUrl]);
}

-(void)lastPostAction{
    NSIndexPath *indexPath = pressedIndexPath;
    Topic *tmpTopic = [self getTopicAtIndexPath:indexPath];
    
    MessagesTableViewController *aView = [[MessagesTableViewController alloc] initWithNibName:@"MessagesTableViewController" bundle:nil andUrl:[tmpTopic aURLOfLastPost]];
    self.messagesTableViewController = aView;
    
    self.messagesTableViewController.topicName = [tmpTopic aTitle];
    
    [self pushTopic];
    
    //NSLog(@"url pressed last post: %@", [[arrayData objectAtIndex:pressedIndexPath.row] lastPostUrl]);
}

-(void)copyLinkAction {
    
    NSIndexPath *indexPath = pressedIndexPath;
    Topic *tmpTopic = [self getTopicAtIndexPath:indexPath];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [NSString stringWithFormat:@"%@%@", [k RealForumURL], [tmpTopic aURLOfFirstPage]];
    
 
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString * message = [[NSMutableAttributedString alloc] initWithString:@"Lien copié dans le presse-papiers"];
    [message addAttribute:NSForegroundColorAttributeName value:[ThemeColors textColor:[[ThemeManager sharedManager] theme]] range:(NSRange){0, [message.string length]}];
    [alert setValue:message forKey:@"attributedMessage"];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
    [[ThemeManager sharedManager] applyThemeToAlertController:alert];
}


- (void)pushTopic {
    if (([self respondsToSelector:@selector(traitCollection)] && [HFRplusAppDelegate sharedAppDelegate].window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) ||
        [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ||
        [[HFRplusAppDelegate sharedAppDelegate].detailNavigationController.topViewController isMemberOfClass:[BrowserViewController class]]) {
        
        self.navigationItem.backBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@" "
                                         style: UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
        
        [self.navigationController pushViewController:messagesTableViewController animated:YES];
    }
    else {
        [[[[[HFRplusAppDelegate sharedAppDelegate] splitViewController] viewControllers] objectAtIndex:1] popToRootViewControllerAnimated:NO];
        
        [[[HFRplusAppDelegate sharedAppDelegate] detailNavigationController] setViewControllers:[NSMutableArray arrayWithObjects:messagesTableViewController, nil] animated:YES];
        
        if ([messagesTableViewController.splitViewController respondsToSelector:@selector(displayModeButtonItem)]) {
            NSLog(@"PUSH ADD BTN");
            [[HFRplusAppDelegate sharedAppDelegate] detailNavigationController].viewControllers[0].navigationItem.leftBarButtonItem = messagesTableViewController.splitViewController.displayModeButtonItem;
            [[HFRplusAppDelegate sharedAppDelegate] detailNavigationController].viewControllers[0].navigationItem.leftItemsSupplementBackButton = YES;
        }
        
    }
    
    [self setTopicViewed];
    
    // Close left panel on ipad in portrait mode
    [[HFRplusAppDelegate sharedAppDelegate] hidePrimaryPanelOnIpad];

}

-(void)setTopicViewed {
    
	if (self.favoritesTableView.indexPathForSelectedRow && self.arrayData.count > 0) {

        NSIndexPath *path = self.favoritesTableView.indexPathForSelectedRow;
        [[self getTopicAtIndexPath:path] setIsViewed:YES];

        //NSArray* rowsToReload = [NSArray arrayWithObjects:self.favoritesTableView.indexPathForSelectedRow, nil];
        //[self.favoritesTableView reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
        
		[self.favoritesTableView reloadData];
        
	}
    else if (pressedIndexPath && self.arrayData.count > 0)
    {
        NSIndexPath *path = self.pressedIndexPath;
        [[self getTopicAtIndexPath:path] setIsViewed:YES];

        //NSArray* rowsToReload = [NSArray arrayWithObjects:self.pressedIndexPath, nil];
        //[self.favoritesTableView reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];

        [self.favoritesTableView reloadData];
    }
    
}

-(void)setTopicViewedWithIndex:(NSIndexPath *)indexPath {
    if(self.arrayData.count > 0){
        // Go to URL in BG
        Topic *tmpTopic = [self getTopicAtIndexPath:indexPath];
        NSURL *topicLastPage =  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [k ForumURL], [tmpTopic aURLOfLastPage]]];
        ASIHTTPRequest * req = [ASIHTTPRequest requestWithURL:topicLastPage];
        [req startAsynchronous];
        
        [self.favoritesTableView setEditing:NO animated:NO];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            // Update internal data
            if ([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"]) // Mode classique avec catégories
            {
                [[[self.arrayData objectAtIndex:indexPath.section] topics] removeObjectAtIndex:indexPath.row];
                [self.favoritesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                if ([[self.arrayData objectAtIndex:indexPath.section] topics].count == 0) {
                    [self.favoritesTableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
            else // mode SANS catégories
            {
                NSMutableArray *copyArrayTopics = [self.arrayTopics mutableCopy];
                [copyArrayTopics removeObjectAtIndex:indexPath.row];
                self.arrayTopics = copyArrayTopics;
                [self.favoritesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                if (self.arrayTopics.count == 0) {
                    [self reload];
                }
            }
            
            // Update view
        });
    
    }
}

-(void)setTopicSuperFavoriteWithIndex:(NSIndexPath *)indexPath {
    Topic *tmpTopic = [self getTopicAtIndexPath:indexPath];
    [self.favoritesTableView setEditing:NO animated:NO];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mpstorage_active"]) {
        }
        // Go to URL in BG
        if ([[MPStorage shared] isSuperFavorite:tmpTopic.postID])  {
            NSLog(@"Topic is NO more favorite %d", tmpTopic.postID);
            if ([[MPStorage shared] removeSuperFavoriteSynchronous:tmpTopic.postID]) {
                tmpTopic.isSuperFavorite = NO;
            }
        }
        else {
            NSLog(@"Topic is super favorite %d", tmpTopic.postID);
            if ([[MPStorage shared] addSuperFavoriteSynchronous:tmpTopic.postID]) {
                tmpTopic.isSuperFavorite = YES;
            }
        }
        [self.favoritesTableView reloadData];
    });
}

-(void)setTopicOfflineFavoriteWithIndex:(NSIndexPath *)indexPath {
    Topic *tmpTopic = [self getTopicAtIndexPath:indexPath];
    [self.favoritesTableView setEditing:NO animated:NO];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // Go to URL in BG
        [[OfflineStorage shared] toggleOfflineTopics:tmpTopic];
        [self.favoritesTableView reloadData];
    });
}


-(void)checkPostsAndQuotesForTopicIndex:(NSIndexPath *)indexPath {
    Topic *topic = [self getTopicAtIndexPath:indexPath];
    if (!self.filterPostsQuotes) {
        self.filterPostsQuotes = [[FilterPostsQuotes alloc] init];
    }
    [self.filterPostsQuotes checkPostsAndQuotesForTopic:topic andVC:self];
}

-(void) addProgressBar {
    self.alertProgress = [UIAlertController alertControllerWithTitle:@"Téléchargement des topics" message:@"0%" preferredStyle:UIAlertControllerStyleAlert];
    [self.alertProgress addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];

    UIView *alertView = self.alertProgress.view;

    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
    self.progressView.progress = 0.0;
    self.progressView.translatesAutoresizingMaskIntoConstraints = false;
    [alertView addSubview:self.progressView];


    NSLayoutConstraint *bottomConstraint = [self.progressView.bottomAnchor constraintEqualToAnchor:alertView.bottomAnchor];
    [bottomConstraint setActive:YES];
    bottomConstraint.constant = -45; // How to constraint to Cancel button?

    [[self.progressView.leftAnchor constraintEqualToAnchor:alertView.leftAnchor] setActive:YES];
    [[self.progressView.rightAnchor constraintEqualToAnchor:alertView.rightAnchor] setActive:YES];

    [self presentViewController:self.alertProgress animated:true completion:nil];
}

#pragma mark -
#pragma mark chooseTopicPage

-(void)chooseTopicPage {
    //NSLog(@"chooseTopicPage Favs");

    NSIndexPath *indexPath = self.pressedIndexPath;
    Topic *tmpTopic = [self getTopicAtIndexPath:indexPath];
    
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil
                                                                              message: nil
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString * message = [[NSMutableAttributedString alloc] initWithString:@"Aller à la page"];
    [message addAttribute:NSForegroundColorAttributeName value:[ThemeColors textColor:[[ThemeManager sharedManager] theme]] range:(NSRange){0, [message.string length]}];
    [alertController setValue:message forKey:@"attributedTitle"];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [NSString stringWithFormat:@"(numéro entre 1 et %d)", [tmpTopic maxTopicPage]];
        [[ThemeManager sharedManager] applyThemeToTextField:textField];
        textField.textAlignment = NSTextAlignmentCenter;
        textField.delegate = self;
        [textField addTarget:self action:@selector(textFieldTopicDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
        textField.keyboardType = UIKeyboardTypeNumberPad;
        
    }];

    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSArray * textfields = alertController.textFields;
        UITextField * pagefield = textfields[0];
        int number = [[pagefield text] intValue];
        [self goToPage:number];

    }]];
     [alertController addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                                           style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [alertController dismissViewControllerAnimated:YES completion:nil];
                                                       }]];
    
    [[ThemeManager sharedManager] applyThemeToAlertController:alertController];
    [self presentViewController:alertController animated:YES completion:^{
        if([[ThemeManager sharedManager] theme] == ThemeDark){
            for (UIView* textfield in alertController.textFields) {
                UIView *container = textfield.superview;
                UIView *effectView = container.superview.subviews[0];
                
                if (effectView && [effectView class] == [UIVisualEffectView class]){
                    container.backgroundColor = [UIColor clearColor];
                    [effectView removeFromSuperview];
                }
            }
        }
    }];
}

/* Evol onglet sticky (gardée au cas où)
-(void)newTabBar {
    // First, create your view controller
    //ProfileVC *profile = loadViewController(TabbarSB, VC_Profile);
    Topic *aTopic = [self getTopicAtIndexPath:self.pressedIndexPath];
    NSString * newUrl = [[aTopic aURL] stringByRemovingAnchor];
    MessagesTableViewController *aView = [[MessagesTableViewController alloc] initWithNibName:@"MessagesTableViewController" bundle:nil andUrl:newUrl];

    // then embed it to a navigation controller
    // this is not required, only if you need it
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:aView];
    nav.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelFetchContent)];
     
    // Get viewControllers array and add navigation controller
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.tabBarController.viewControllers];
    [viewControllers insertObject:nav atIndex:2];
    
    // Set back the array
    [self.tabBarController setViewControllers:viewControllers animated:YES];
    
    // Switch to this new tab
    [self.tabBarController setSelectedIndex:2];
}*/

-(void)goToPage:(int)number {
    Topic *aTopic = [self getTopicAtIndexPath:self.pressedIndexPath];
    
    NSString * newUrl = [aTopic aURL];
    
    //NSLog(@"newUrl %@", newUrl);
    
    //On remplace le numéro de page dans le titre
    NSString *regexString  = @".*page=([^&]+).*";
    NSRange   matchedRange;// = NSMakeRange(NSNotFound, 0UL);
    NSRange   searchRange = NSMakeRange(0, newUrl.length);
    NSError  *error2        = NULL;
    //int numPage;
    
    matchedRange = [newUrl rangeOfRegex:regexString options:RKLNoOptions inRange:searchRange capture:1L error:&error2];
    
    if (matchedRange.location == NSNotFound) {
        NSRange rangeNumPage =  [newUrl rangeOfCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] options:NSBackwardsSearch];
        //NSLog(@"New URL %@", [newUrl stringByReplacingCharactersInRange:rangeNumPage withString:[NSString stringWithFormat:@"%d", number]]);
        newUrl = [newUrl stringByReplacingCharactersInRange:rangeNumPage withString:[NSString stringWithFormat:@"%d", number]];
        //self.pageNumber = [[self.forumUrl substringWithRange:rangeNumPage] intValue];
    }
    else {
        //NSLog(@"New URL %@", [newUrl stringByReplacingCharactersInRange:matchedRange withString:[NSString stringWithFormat:@"%d", number]]);
        newUrl = [newUrl stringByReplacingCharactersInRange:matchedRange withString:[NSString stringWithFormat:@"%d", number]];
        //self.pageNumber = [[self.forumUrl substringWithRange:matchedRange] intValue];
        
    }
    
    newUrl = [newUrl stringByRemovingAnchor];
    
    MessagesTableViewController *aView = [[MessagesTableViewController alloc] initWithNibName:@"MessagesTableViewController" bundle:nil andUrl:newUrl];
    self.messagesTableViewController = aView;
    
    //setup the URL
    self.messagesTableViewController.topicName = [aTopic aTitle];
    
    //NSLog(@"push message liste");
    [self pushTopic];
}

-(void)textFieldTopicDidChange:(id)sender {
	//NSLog(@"textFieldDidChange %d %@", [[(UITextField *)sender text] intValue], sender);	
	
    NSIndexPath *indexPath = self.pressedIndexPath;
    Topic *tmpTopic = [self getTopicAtIndexPath:indexPath];

	if ([[(UITextField *)sender text] length] > 0) {
		int val; 
		if ([[NSScanner scannerWithString:[(UITextField *)sender text]] scanInt:&val]) {
			//NSLog(@"int %d %@ %@", val, [(UITextField *)sender text], [NSString stringWithFormat:@"%d", val]);
			
			if (![[(UITextField *)sender text] isEqualToString:[NSString stringWithFormat:@"%d", val]]) {
				//NSLog(@"pas int");
				[sender setText:[NSString stringWithFormat:@"%d", val]];
			}
			else if ([[(UITextField *)sender text] intValue] < 1) {
				//NSLog(@"ERROR WAS %d", [[(UITextField *)sender text] intValue]);
				[sender setText:[NSString stringWithFormat:@"%d", 1]];
				//NSLog(@"ERROR NOW %d", [[(UITextField *)sender text] intValue]);
				
			}
			else if ([[(UITextField *)sender text] intValue] > [tmpTopic maxTopicPage]) {
				//NSLog(@"ERROR WAS %d", [[(UITextField *)sender text] intValue]);
				[sender setText:[NSString stringWithFormat:@"%d", [tmpTopic maxTopicPage]]];
				//NSLog(@"ERROR NOW %d", [[(UITextField *)sender text] intValue]);
				
			}	
			else {
				//NSLog(@"OK");
			}
		}
		else {
			[sender setText:@""];
		}
		
		
	}
}

#pragma mark -
#pragma mark Delete

-(void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!showAll)
    {
        // If row is deleted, remove it from the list.
        if (editingStyle == UITableViewCellEditingStyleDelete)
        {
            
            ASIFormDataRequest  *arequest =
            [[ASIFormDataRequest  alloc]  initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/modo/manageaction.php?config=hfr.inc&cat=0&type_page=forum1f&moderation=0", [k ForumURL]]]];
            //delete

            //NSLog(@"%@", [[HFRplusAppDelegate sharedAppDelegate] hash_check]);
            
            [arequest setPostValue:[[HFRplusAppDelegate sharedAppDelegate] hash_check] forKey:@"hash_check"];
            [arequest setPostValue:@"-1" forKey:@"topic1"];
            [arequest setPostValue:@"-1" forKey:@"topic_statusno1"];
            [arequest setPostValue:@"message_forum_delflags" forKey:@"action_reaction"];
            
            [arequest setPostValue:@"forum1f" forKey:@"type_page"];

            Topic *tmpTopic = [self getTopicAtIndexPath:indexPath];
            
            [arequest setPostValue:[NSString stringWithFormat:@"%d", [tmpTopic postID]] forKey:@"topic0"];
            [arequest setPostValue:[NSString stringWithFormat:@"%d", [tmpTopic catID]] forKey:@"valuecat0"];
            
            [arequest setPostValue:@"hardwarefr" forKey:@"valueforum0"];
            [arequest startAsynchronous];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey :@"sujets_avec_cat"])// for default favorite view
            {
                [[[self.arrayData objectAtIndex:indexPath.section] topics] removeObjectAtIndex:indexPath.row];
                [self.favoritesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                if ([[self.arrayData objectAtIndex:indexPath.section] topics].count == 0) {
                    [self.favoritesTableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
            else
            {
                NSMutableArray *copyArrayTopics = [self.arrayTopics mutableCopy];
                [copyArrayTopics removeObjectAtIndex:indexPath.row];
                self.arrayTopics = copyArrayTopics;
                [self.favoritesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                if (self.arrayTopics.count == 0) {
                    [self reload];
                }
            }
        }
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *markReadAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self setTopicViewedWithIndex:indexPath];
    }];

    markReadAction.image = [UIImage checkmarkImage];
    markReadAction.backgroundColor = [ThemeColors tintColor:[[ThemeManager sharedManager] theme]];
    /*
    UIContextualAction *markSuperFavorite = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Super Fav" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self setTopicSuperFavoriteWithIndex:indexPath];
    }];
    
    //markSuperFavorite.image = [UIImage checkmarkImage];
    markSuperFavorite.backgroundColor = [UIColor colorWithRed:255/255.0 green:205/255.0 blue:40/255.0 alpha:1.0];
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[markReadAction, markSuperFavorite]];*/
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[markReadAction]];
    return config;
}

#pragma mark -
#pragma mark Reload

-(void)reload
{
	[self reload:NO];
}

-(void)reload:(BOOL)shake
{
	if (!shake) {

	}

    [self.favoritesTableView triggerPullToRefresh];

//	[self fetchContent];
}


-(void) shakeHappened:(ShakeView*)view
{
	if (![request inProgress]) {
		
		[self reload:YES];		
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
	self.loadingView = nil;
	self.favoritesTableView = nil;
	self.maintenanceView = nil;
	
	[super viewDidUnload];
}

- (void)dealloc {
	//NSLog(@"dealloc ftv");

	[self viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoginChangedNotification object:nil];

	[request cancel];
	[request setDelegate:nil];

	
    

}


@end

