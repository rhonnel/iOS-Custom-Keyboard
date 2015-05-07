/******************************************************************************
 * Filename  Numberpad.h
 * Project:  Numberpad
 * Purpose:  Class to display a custom Numberpad on an iPhone/iPad and properly handle
 *           the text input.
 * Author:   Rhonnel Francisco
 *
 ******************************************************************************/

#import <UIKit/UIKit.h>

@interface NumberPad : UIView

+ (NumberPad *)defaultLNNumberpad;
@property (nonatomic, retain) IBOutlet UIView *padView;

@end
