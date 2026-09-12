#import <UIKit/UIKit.h>

@interface PuzzleBoardView : UIView
- (instancetype)initWithFrame:(CGRect)frame tileTap:(void (^)(int index))tileTap;
- (void)setTiles:(const int *)tiles grid:(int)grid animate:(BOOL)animate;
@end