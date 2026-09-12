#import "ConfettiView.h"

typedef struct {
    CGFloat x, y, vx, vy;
    UIColor *color;
} Particle;

@implementation ConfettiView {
    CADisplayLink *_link;
    Particle *_particles;
    NSUInteger _count;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)dealloc {
    if (_particles) free(_particles);
    [_link invalidate];
}

static UIColor *PaletteColor(NSUInteger index) {
    static UIColor *palette[6];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        palette[0] = [UIColor colorWithRed:255 / 255.0 green:161 / 255.0 blue:0
                                     alpha:1.0]; // ORANGE
        palette[1] = [UIColor colorWithRed:0 green:228 / 255.0 blue:48 / 255.0
                                     alpha:1.0]; // GREEN
        palette[2] = [UIColor colorWithRed:102 / 255.0 green:191 / 255.0 blue:255 / 255.0
                                     alpha:1.0]; // SKYBLUE
        palette[3] = [UIColor colorWithRed:255 / 255.0 green:203 / 255.0 blue:0
                                     alpha:1.0]; // GOLD
        palette[4] = [UIColor colorWithRed:255 / 255.0 green:109 / 255.0 blue:194 / 255.0
                                     alpha:1.0]; // PINK
        palette[5] = [UIColor colorWithRed:135 / 255.0 green:60 / 255.0 blue:190 / 255.0
                                     alpha:1.0]; // VIOLET
    });
    return palette[index % 6];
}

- (void)startRain {
    if (_particles) {
        free(_particles);
        _particles = NULL;
    }
    _count = 160;
    _particles = calloc(_count, sizeof(Particle));
    const CGFloat width = self.bounds.size.width;
    for (NSUInteger i = 0; i < _count; ++i) {
        _particles[i].x = (CGFloat)arc4random_uniform((uint32_t)MAX((NSInteger)width, 1));
        _particles[i].y = -(CGFloat)arc4random_uniform(400);
        _particles[i].vx = (CGFloat)(arc4random_uniform(81) - 40);
        _particles[i].vy = (CGFloat)arc4random_uniform(201) + 120;
        _particles[i].color = PaletteColor(arc4random_uniform(6));
    }
    if (!_link) {
        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(step:)];
        [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    _link.paused = NO;
    [self setNeedsDisplay];
}

- (void)stopRain {
    _link.paused = YES;
    if (_particles) {
        free(_particles);
        _particles = NULL;
        _count = 0;
    }
    [self setNeedsDisplay];
}

- (void)step:(CADisplayLink *)link {
    const CGFloat height = self.bounds.size.height;
    const CGFloat width = self.bounds.size.width;
    const CGFloat dt = 1.0 / 60.0;
    for (NSUInteger i = 0; i < _count; ++i) {
        _particles[i].x += _particles[i].vx * dt;
        _particles[i].y += _particles[i].vy * dt;
        if (_particles[i].y > height) {
            _particles[i].y = -(CGFloat)arc4random_uniform(200);
            _particles[i].x = (CGFloat)arc4random_uniform((uint32_t)MAX((NSInteger)width, 1));
        }
    }
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!_particles) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    for (NSUInteger i = 0; i < _count; ++i) {
        CGContextSetFillColorWithColor(ctx, _particles[i].color.CGColor);
        CGContextFillRect(ctx, CGRectMake(_particles[i].x, _particles[i].y, 6.0, 6.0));
    }
}

@end