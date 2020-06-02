//
//  SmileyCache.h
//  SuperHFRplus
//
//  Created by Bruno ARENE on 28/05/2020.
//

#ifndef SmileyCache_h
#define SmileyCache_h

#import <Foundation/Foundation.h>

@interface SmileyRequest : NSObject {
}

// TODO: add @property (nonatomic, strong) NSDate* dateLastRequest; 
@property (nonatomic, strong) NSString* sTextSmileys;
@property (nonatomic, strong) NSMutableArray* arrSmileys;

@end


@interface SmileyCache : NSObject {
}

@property (nonatomic, strong) NSMutableArray* arrCurrentSmileyArray;
@property (nonatomic, strong) NSCache* cacheSmileys;
@property (nonatomic, strong) NSCache* cacheSmileyRequests;

+ (SmileyCache *)shared;
- (void)handleSmileyArray:(NSMutableArray*)arrSmileys forCollection:(UICollectionView*) cv;
- (UIImage*) getImageForIndex:(int)index;
- (NSMutableArray*) getSmileyListForText:(NSString*)sTextSmileys;

@end


#endif /* SmileyCache_h */
