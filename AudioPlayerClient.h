#import <Foundation/Foundation.h>

@interface AudioPlayerClient : NSObject
+ (instancetype)sharedClient;
- (void)playTick;
@end