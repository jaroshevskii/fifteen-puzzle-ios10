#import "PuzzleBoardView.h"

static UIColor *PuzzleRGB(uint8_t r, uint8_t g, uint8_t b) {
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:1.0];
}
static UIColor *PuzzleDarkPurple(void) { return PuzzleRGB(112, 31, 126); } // raylib DARKPURPLE
static UIColor *PuzzleOrange(void) { return PuzzleRGB(255, 161, 0); }      // raylib ORANGE

@implementation PuzzleBoardView {
    int _grid;
    NSMutableArray<UIView *> *_cells;
    void (^_tileTap)(int);
}

- (instancetype)initWithFrame:(CGRect)frame tileTap:(void (^)(int index))tileTap {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = PuzzleDarkPurple();
        _tileTap = [tileTap copy];
        _cells = [NSMutableArray array];
    }
    return self;
}

- (CGFloat)cellSize {
    return self.bounds.size.width / (CGFloat)_grid;
}

- (CGRect)rectForIndex:(int)index {
    const CGFloat s = [self cellSize];
    return CGRectMake(index % _grid * s, index / _grid * s, s, s);
}

- (void)rebuildCellsForGrid:(int)grid {
    for (UIView *cell in _cells) {
        [cell removeFromSuperview];
    }
    [_cells removeAllObjects];
    _grid = grid;
    for (int i = 0; i < grid * grid; ++i) {
        UIView *cell = [[UIView alloc] initWithFrame:[self rectForIndex:i]];
        cell.backgroundColor = [UIColor blackColor];
        [self addSubview:cell];
        [_cells addObject:cell];
    }
}

- (void)layoutCellsAnimated:(BOOL)animate {
    void (^layout)(void) = ^{
        for (int i = 0; i < (int)_cells.count; ++i) {
            _cells[i].frame = [self rectForIndex:i];
        }
    };
    if (animate) {
        [UIView animateWithDuration:0.12 delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:layout completion:nil];
    } else {
        layout();
    }
}

- (void)setTiles:(const int *)tiles grid:(int)grid animate:(BOOL)animate {
    if (grid != _grid || _cells.count == 0) {
        [self rebuildCellsForGrid:grid];
    } else {
        [self layoutCellsAnimated:NO];
    }

    for (int i = 0; i < (int)_cells.count; ++i) {
        UIView *cell = _cells[i];
        for (UIView *sub in cell.subviews) {
            [sub removeFromSuperview];
        }
        const CGRect body = CGRectInset(cell.bounds, 2.0, 2.0);
        if (tiles[i] == 0) {
            UIView *inner = [[UIView alloc] initWithFrame:body];
            inner.backgroundColor = PuzzleDarkPurple();
            [cell addSubview:inner];
        } else {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = body;
            button.backgroundColor = PuzzleOrange();
            button.tag = i;
            [button setTitle:[NSString stringWithFormat:@"%d", tiles[i]]
                    forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            const CGFloat size = round(body.size.height * 0.5);
            button.titleLabel.font = [UIFont systemFontOfSize:size weight:UIFontWeightBold];
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            button.titleLabel.minimumScaleFactor = 0.5;
            [button addTarget:self action:@selector(tileTapped:)
             forControlEvents:UIControlEventTouchUpInside];
            [cell addSubview:button];
        }
    }

    [self layoutCellsAnimated:animate];
}

- (void)tileTapped:(UIButton *)sender {
    if (_tileTap) {
        _tileTap((int)sender.tag);
    }
}

@end