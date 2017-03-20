// JSKTimerView.m
//
// Copyright (c) 2015 Joefrey Kibuule
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "JSKTimerView.h"


static CGFloat const kBackgroundLineWidth = 5.0f;
static CGFloat const kProgressLineWidth = 12.0f;
static CGFloat const kMinimalProgressValue = 0.001f;
static NSString * const jsk_progressAnimationKey = @"progressAnimationKey";


@interface JSKTimerView ()

@property (nonatomic, readwrite, getter=isRunning) BOOL running;
@property (nonatomic, readwrite, getter=isFinished) BOOL finished;

@property (nonatomic, assign) NSInteger remainingTimeInSeconds;
@property (nonatomic, assign) NSInteger totalTimeInSeconds;
@property (nonatomic, strong) NSTimer *viewTimer;

@property (nonatomic, strong) UILabel *timerLabel;
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end

@implementation JSKTimerView

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0, 0, 50, 50)];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self initalSetup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self initalSetup];
    }
    
    return self;
}

- (void)initalSetup {
    
    _remainingTimeInSeconds = 0;
    _totalTimeInSeconds = 0;
    
    _running = NO;
    _finished = NO;
    
    if (!_progressColor) {
        _progressColor = [UIColor colorWithRed:51/255.0 green:204/255.0 blue:51/255.0 alpha:1.0];
    }
    if (!_progressBackgroundColor) {
        _progressBackgroundColor = _progressColor;
    }
    
    self.backgroundColor = [UIColor clearColor];
    
    [self createLayer];
    [self createLabel];
    [self createPath];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.progressLayer.frame = self.bounds;
}

- (void)dealloc {
    
    if (_viewTimer != nil) {
        [_viewTimer invalidate];
        _viewTimer = nil;
    }
}
    
#pragma mark - Customization Methods

- (UIFont *)labelFont {
    return self.timerLabel.font;
}

- (void)setLabelFont:(UIFont *)labelFont {
    self.timerLabel.font = labelFont;
}
    
- (UIColor *)labelTextColor {
    return self.timerLabel.textColor;
}
    
- (void)setLabelTextColor:(UIColor *)color {
    self.timerLabel.textColor = color;
}
    
#pragma mark - Timer methods

- (void)setTimerWithDuration:(NSInteger)durationInSeconds {
    self.remainingTimeInSeconds = durationInSeconds;
    self.totalTimeInSeconds = durationInSeconds;
    
    if (self.remainingTimeInSeconds > 0) {
        [self setProgress:1 animated:NO];
    }
    
    [self updateLabelText];
    [self setNeedsDisplay];
}

- (void)startTimer {
    [self startTick];
    
    self.running = YES;
    self.finished = NO;
}

- (void)startTimerWithDuration:(NSInteger)durationInSeconds {
    [self setTimerWithDuration:durationInSeconds];
    
    [self startTimer];
}

- (BOOL)startTimerWithEndDate:(NSDate *)endDate {
    NSDate *currentDate = [NSDate date];
    
    if ([currentDate compare:endDate] == NSOrderedAscending) {
        NSTimeInterval timeInterval = [endDate timeIntervalSinceReferenceDate] - [currentDate timeIntervalSinceReferenceDate];
        timeInterval = round(timeInterval);
        
        if (timeInterval > 1) {
            [self startTimerWithDuration:timeInterval];
            
            return YES;
        }
    }
    
    return NO;
}

- (void)pauseTimer {
    [self invalidateTimer];
    
    self.running = NO;
}

- (void)stopTimer {
    self.remainingTimeInSeconds = 0;
    
    [self pauseTimer];
    
    [self updateLabelText];
    [self updateProgress];
    [self setNeedsDisplay];
}

- (void)resetTimer {
    self.remainingTimeInSeconds = self.totalTimeInSeconds;
    
    [self pauseTimer];
    
    [self updateLabelText];
    [self updateProgress];
    [self setNeedsDisplay];
}

- (void)restartTimer {
    [self resetTimer];
    [self startTimer];
}

#pragma mark - Accessors

- (NSInteger)remainingDurationInSeconds {
    return self.remainingTimeInSeconds;
}

- (NSInteger)totalDurationInSeconds {
    return self.totalTimeInSeconds;
}

#pragma mark - Timer Progress Methods

- (void)setProgress:(CGFloat)progress {
    
    progress = [self sanitizeProgressValue:progress];
    
    if (progress < 1) {
        self.remainingTimeInSeconds = (NSInteger)(self.totalTimeInSeconds * progress);
        [self.progressLayer removeAnimationForKey:jsk_progressAnimationKey];
        
        [self setProgress:progress animated:NO];
    } else {
        [self stopTimer];
    }
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    
    progress = [self sanitizeProgressValue:progress];
    
    if (progress > 0) {
        if (animated) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            animation.fromValue = progress == 0 ? @0 : nil;
            animation.toValue = @(progress);
            animation.duration = 1;
            self.progressLayer.strokeEnd = progress;
            [self.progressLayer addAnimation:animation forKey:jsk_progressAnimationKey];
        } else {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.progressLayer.strokeEnd = progress;
            [CATransaction commit];
        }
    } else {
        self.progressLayer.strokeEnd = 0.0f;
        [self.progressLayer removeAnimationForKey:jsk_progressAnimationKey];
    }
    
    _progress = progress;
    
    [self updateLabelText];
}

#pragma mark - Private Timer Methods

- (void)startTick {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self invalidateTimer];
        
        self.viewTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(tick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.viewTimer forMode:UITrackingRunLoopMode];
    });
}

- (void)tick:(id)sender {
    if (self.remainingTimeInSeconds <= 1) {
        [self stopTimer];
        
        self.finished = YES;
        
        if (self.completionBlock) {
            self.completionBlock();
        }
    } else {
        self.remainingTimeInSeconds -= 1;
        
        [self updateProgress];
    }
    
    [self updateLabelText];
    [self setNeedsDisplay];
}

- (void)invalidateTimer {
    if (self.viewTimer) {
        [self.viewTimer invalidate];
        self.viewTimer = nil;
    }
}

- (CGFloat)sanitizeProgressValue:(CGFloat)progress {
    if (progress > 1) {
        progress = 1;
    } else if (progress < 0) {
        progress = 0;
    }
    
    return progress;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: (%ld of %ld sec remaining)", [super description], (long)self.remainingTimeInSeconds, (long)self.totalTimeInSeconds];
}

#pragma mark - Private Create UI Methods

- (void)createLabel {
    self.timerLabel = [[UILabel alloc] init];
    self.timerLabel.textAlignment = NSTextAlignmentCenter;
    self.timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self updateLabelText];
    [self addSubview:self.timerLabel];
    
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.timerLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:self.timerLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    [self addConstraints:@[centerXConstraint, centerYConstraint]];
}

- (void)createLayer {
    CAShapeLayer *progressLayer = [CAShapeLayer layer];
    progressLayer.fillColor = [[UIColor clearColor] CGColor];
    progressLayer.lineWidth = kProgressLineWidth;
    progressLayer.strokeColor = [self.progressColor CGColor];
    progressLayer.strokeEnd = 0;
    progressLayer.lineCap = kCALineCapRound;
    
    self.progressLayer = progressLayer;
    
    [self.layer addSublayer:progressLayer];
}

- (void)createPath {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.progressLayer.path = [UIBezierPath bezierPathWithArcCenter:center
                                                             radius:self.bounds.size.width / 2 - [self progressInset]
                                                         startAngle:-M_PI_2
                                                           endAngle:-M_PI_2 + 2 * M_PI
                                                          clockwise:YES].CGPath;
}

#pragma mark - Private Update UI Methods

- (void)updateLabelText {
    NSInteger numHours = self.remainingTimeInSeconds / 3600;
    NSInteger numMinutes = (self.remainingTimeInSeconds % 3600) / 60;
    NSInteger numSeconds = self.remainingTimeInSeconds % 60;
    
    if (numHours > 0) {
        self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)numHours, (long)numMinutes, (long)numSeconds];
    } else {
        self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)numMinutes, (long)numSeconds];
    }
}

- (void)updateProgress {
    CGFloat progress = ((CGFloat)(self.remainingTimeInSeconds) / self.totalTimeInSeconds);
    [self setProgress:progress animated:YES];
}

- (void)setProgressColor:(UIColor *)timerProgressColor {
    _progressColor = timerProgressColor;
    
    self.progressLayer.strokeColor = timerProgressColor.CGColor;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, kBackgroundLineWidth);
    CGContextSetStrokeColorWithColor(context, self.progressBackgroundColor.CGColor);
    CGContextStrokeEllipseInRect(context, CGRectInset(self.bounds, [self progressInset], [self progressInset]));
} 

- (CGFloat)progressInset {
    return MAX(kProgressLineWidth, kBackgroundLineWidth) / 2;
}
    
@end
