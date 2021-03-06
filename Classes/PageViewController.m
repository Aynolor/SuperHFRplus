//
//  PageViewController.m
//  HFRplus
//
//  Created by FLK on 10/10/10.
//

#import "HFRplusAppDelegate.h"
#import "PageViewController.h"
#import "MessagesTableViewController.h"
#import "ThemeColors.h"
#import "ThemeManager.h"
#import "OfflineStorage.h"

@implementation PageViewController
@synthesize previousPageUrl, nextPageUrl;
@synthesize currentUrl, originalUrl, currentOfflineTopic, pageNumber;
@synthesize firstPageNumber, lastPageNumber;
@synthesize firstPageUrl, lastPageUrl;
@synthesize filterPostsQuotes;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
		
		self.nextPageUrl = [[NSString alloc] init];
		self.previousPageUrl = [[NSString alloc] init];
		
		self.firstPageUrl = [[NSString alloc] init];
		self.lastPageUrl = [[NSString alloc] init];
        self.currentOfflineTopic = nil;
        self.filterPostsQuotes = nil;
        self.originalUrl = nil;
    }
    return self;
}

- (BOOL)isModeOffline {
    if (self.currentOfflineTopic == nil) {
        return NO;
    }
    return YES;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
	//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)viewWillAppear:(BOOL)animated   {
    [super viewWillAppear:animated];
    [self setThemeColors:[[ThemeManager sharedManager] theme]];
}

-(void)setThemeColors:(Theme)theme{
    
    UILabel *titleView = (UILabel *)[self navigationItem].titleView;
    if([titleView respondsToSelector:@selector(setTextColor:)]){
        [titleView setTextColor:[ThemeColors titleTextAttributesColor:theme]];
    }
}

-(void)choosePage {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Aller à la page"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = [NSString stringWithFormat:@"(numéro entre %d et %d)", [self firstPageNumber], [self lastPageNumber]];
        textField.textAlignment = NSTextAlignmentCenter;
        [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.keyboardAppearance = UIKeyboardAppearanceDefault;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.delegate = self;
        [[ThemeManager sharedManager] applyThemeToTextField:textField];
        textField.keyboardAppearance = [ThemeColors keyboardAppearance:[[ThemeManager sharedManager] theme]];
    }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                         }];
    
    [alert addAction:cancelAction];
    
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self gotoPageNumber:[[alert.textFields[0] text] intValue]];
                                                          }];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
    for (UIView* textfield in alert.textFields) {
        UIView *container = textfield.superview;
        UIView *effectView = container.superview.subviews[0];
        
        if (effectView && [effectView class] == [UIVisualEffectView class]){
            container.backgroundColor = [UIColor clearColor];
            [effectView removeFromSuperview];
        }
    }

    [[ThemeManager sharedManager] applyThemeToAlertController:alert];
}




- (void)goToPage:(NSString *)pageType;
{
	//NSLog(@"gotoPageNumber %@", pageType);

	
	if ([pageType isEqualToString:@"begin"]) {
		[self firstPage:nil];
	}
	else if ([pageType isEqualToString:@"end"]) {
		[self lastPage:nil];
	}
	else if ([pageType isEqualToString:@"next"]) {
		[self nextPage:nil];
	}
	else if ([pageType isEqualToString:@"previous"]) {
		[self previousPage:nil];
	}	
	else if ([pageType isEqualToString:@"choose"]) {
		[self choosePage];
	}
    else if ([pageType isEqualToString:@"submitsearch"]) {
        if ([self respondsToSelector:@selector(searchSubmit:)]) {
            [self searchSubmit:nil];
        }
    }
    else if ([pageType isEqualToString:@"filterPostsQuotesNext"]) {
        [self filterPostsQuotesNext:nil];
    }
}

-(void)gotoPageNumber:(int)number{
	//NSLog(@"gotoPageNumber %d", number);
	
	if (!number) {
		return;
	}
	
    if ([self isModeOffline]) {
        self.currentOfflineTopic.curTopicPage = number;
        // Update offline flag
        if (self.currentOfflineTopic.curTopicPageLoaded < self.currentOfflineTopic.curTopicPage) {
            self.currentOfflineTopic.curTopicPageLoaded = self.currentOfflineTopic.curTopicPage;
            [[OfflineStorage shared] updateOfflineTopic:self.currentOfflineTopic];
        }
        [self fetchContent];
    } else {
        NSString *newUrl = [NSString stringWithString:self.currentUrl];
        
        //On remplace le numéro de page dans le titre
        NSString *regexString  = @".*page=([^&]+).*";
        NSRange   matchedRange;// = NSMakeRange(NSNotFound, 0UL);
        NSRange   searchRange = NSMakeRange(0, self.currentUrl.length);
        NSError  *error2        = NULL;
        //int numPage;
        
        matchedRange = [self.currentUrl rangeOfRegex:regexString options:RKLNoOptions inRange:searchRange capture:1L error:&error2];
        
        if (matchedRange.location == NSNotFound) {
            NSRange rangeNumPage =  [[self currentUrl] rangeOfCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] options:NSBackwardsSearch];
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
        
        self.currentUrl = newUrl;
        [self fetchContent];
    }
}

-(void)textFieldDidChange:(id)sender {
	//NSLog(@"textFieldDidChange %d %@", [[(UITextField *)sender text] intValue], sender);	
	
	
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
				[sender setText:[NSString stringWithFormat:@"%d", [self firstPageNumber]]];
				//NSLog(@"ERROR NOW %d", [[(UITextField *)sender text] intValue]);
				
			}
			else if ([[(UITextField *)sender text] intValue] > [self lastPageNumber]) {
				//NSLog(@"ERROR WAS %d", [[(UITextField *)sender text] intValue]);
				[sender setText:[NSString stringWithFormat:@"%d", [self lastPageNumber]]];
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

-(void)nextPage:(id)sender {
    if ([self isModeOffline]) {
        if (self.currentOfflineTopic.curTopicPage < self.currentOfflineTopic.maxTopicPageLoaded) {
            self.currentOfflineTopic.curTopicPage++;
            // Update offline flag
            if (self.currentOfflineTopic.curTopicPageLoaded < self.currentOfflineTopic.curTopicPage) {
                self.currentOfflineTopic.curTopicPageLoaded = self.currentOfflineTopic.curTopicPage;
                [[OfflineStorage shared] updateOfflineTopic:self.currentOfflineTopic];
            }
            [self fetchContent];
        }
    } else {
        self.currentUrl = self.nextPageUrl;
        [self fetchContent];
    }
}
-(void)previousPage:(id)sender {
    if ([self isModeOffline]) {
        if (self.currentOfflineTopic.curTopicPage > self.currentOfflineTopic.minTopicPageLoaded) {
            self.currentOfflineTopic.curTopicPage--;
            [self fetchContent];
        }
    } else {
        self.currentUrl = self.previousPageUrl;
        
        if ([[self class] isSubclassOfClass:[MessagesTableViewController class]]) {
            [self fetchContent:kNewMessageFromNext];

        }
        else {
            [self fetchContent];
        }
    }
}
- (IBAction)searchSubmit:(UIBarButtonItem *)sender {
    
}

- (IBAction)filterPostsQuotesNext:(UIBarButtonItem *)sender {
}

- (void)fetchContent:(int)from {
    
}

-(void)firstPage {
    [self firstPage:nil];
}
-(void)lastPage {
    [self lastPage:nil];
}
-(void)firstPage:(id)sender {
    if ([self isModeOffline]) {
        self.currentOfflineTopic.curTopicPage = self.currentOfflineTopic.minTopicPageLoaded;
        [self fetchContent];
    } else {
        if(self.firstPageUrl.length > 0) self.currentUrl = self.firstPageUrl;
        [self fetchContent];
    }
}
-(void)lastPage:(id)sender {
    if ([self isModeOffline]) {
        self.currentOfflineTopic.curTopicPage = self.currentOfflineTopic.maxTopicPageLoaded;
        // Update offline flag
        if (self.currentOfflineTopic.curTopicPageLoaded < self.currentOfflineTopic.curTopicPage) {
            self.currentOfflineTopic.curTopicPageLoaded = self.currentOfflineTopic.curTopicPage;
            [[OfflineStorage shared] updateOfflineTopic:self.currentOfflineTopic];
        }
        [self fetchContent];
    } else {
        if(self.lastPageUrl.length > 0) self.currentUrl = self.lastPageUrl;
        [self fetchContent];
    }
}

-(void)lastAnswer {
	if(self.lastPageUrl.length > 0) self.currentUrl = [NSString stringWithFormat:@"%@#bas", self.lastPageUrl];
	[self fetchContent];	
}


- (void)didPresentAlertView:(UIAlertView *)alertView
{
	NSLog(@"didPresentAlertView PT %@", alertView);
	
	if (([alertView tag] == 666)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
    }
	else if (([alertView tag] == 668)) {
		//NSLog(@"keud");
	}
    /* TO DELETE
    else if (([alertView tag] == 6666) || ([alertView tag] == kAlertBlackListOK)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
    }
    else if ([alertView tag] == kAlertPasteBoardOK) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
    }
	*/
	
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	//NSLog(@"willDismissWithButtonIndex PT %@", alertView);
    
	if (([alertView tag] == 668)) {

	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSLog(@"clickedButtonAtIndex PT %@ index : %ld", alertView, (long)buttonIndex);
    
	if (buttonIndex == 1 && alertView.tag == 667) {
		[self fetchContent];
	}
	else if (buttonIndex == 1 && alertView.tag == 668) {
		[self gotoPageNumber:[[[alertView textFieldAtIndex:0] text] intValue]];
    }
    else if (buttonIndex == 0 && alertView.tag == 770) {
        NSLog(@"BIM");
        //[self.navigationController popViewControllerAnimated:YES];
        //[self gotoPageNumber:[[[alertView textFieldAtIndex:0] text] intValue]];
    }
    else if (buttonIndex == 1 && alertView.tag == 770) {
        NSLog(@"BAM");
        if ([self isKindOfClass:[MessagesTableViewController class]]) {
            [(MessagesTableViewController *)self.navigationController.topViewController toggleSearch:YES];
        }
        //[self gotoPageNumber:[[[alertView textFieldAtIndex:0] text] intValue]];
    }
}

@end
