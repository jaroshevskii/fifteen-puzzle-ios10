#import <Foundation/Foundation.h>

@interface AppSettings : NSObject
@property (nonatomic) BOOL isSoundEnabled;
@property (nonatomic) NSInteger lastBoardSize;
@property (nonatomic, copy) NSString *playerName;
@property (nonatomic) BOOL autoResume;
+ (instancetype)sharedSettings;
- (void)save;
@end