// JSKTimerView.h
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

#import <UIKit/UIKit.h>

/**
 `JSKTimerView` is a custom UIView class which represents a simple, self-contained timer.
 */
@interface JSKTimerView : UIView
    
/**
 The current timer progress with a range between 0 and 1
 */
@property (nonatomic, assign) CGFloat progress;

/**
 Whether or not the timer is currently running
 */
@property (readonly, nonatomic, getter=isRunning) BOOL running;

/**
 Whether or not the timer has naturally finished
 
 @warning Setting timerProgress to zero will not set finished to true
 */
@property (readonly, nonatomic, getter=isFinished) BOOL finished;

/**
 Executed when time ends
 */
@property (nonatomic, copy) void (^completionBlock)() ;
    
///-----------------------------------------------------------
/// @name Customization
///-----------------------------------------------------------

/**
 The text font of the UILabel with the time remaining
 */
@property (nonatomic, readwrite) UIFont *labelFont;
    
/**
 The text color of the UILabel with the time remaining
 */
@property (nonatomic, readwrite) UIColor *labelTextColor;
    
/**
 The text color of the progress background arc
 */
@property (nonatomic, strong) UIColor *progressBackgroundColor;
/**
 The text color of the progress arc
 */
@property (nonatomic, strong) UIColor *progressColor;

///-----------------------------------------------------------
/// @name Timer Methods
///-----------------------------------------------------------

/**
 Sets the duration of the timer and updates the progress to 1.
 
 @param durationInSeconds The number of seconds the timer is set for.
 
 @warning This does *not* start the timer
 */
- (void)setTimerWithDuration:(NSInteger)durationInSeconds remainingTime:(NSInteger)remainingTime;

/**
 Starts the timer.
 */
- (void)startTimer;

/**
 Pauses the timer.
 
 @note Start the timer again with `startTimer`.
 */
- (void)pauseTimer;

/**
 Stops the timer.
 
 @note This animates the remaining seconds to zero.
 */
- (void)stopTimer;

/**
 Resets the timer to the original duration.
 */
- (void)resetTimer;

/**
 Resets the timer to the original duration and starts it.
 */
- (void)restartTimer;

///-----------------------------------------------------------
/// @name Accessor Methods
///-----------------------------------------------------------

/**
 The remaining number of seconds left in the timer
 */
- (NSInteger)remainingDurationInSeconds;

/**
 The start number of seconds in the timer
 */
- (NSInteger)totalDurationInSeconds;

@end
