/******************************************************************************
 * Filename  Numberpad.m
 * Project:  Numberpad
 * Purpose:  Class to display a custom Numberpad on an iPhone/iPad and properly handle
 *           the text input.
 * Author:   Rhonnel Francisco
 *
 ******************************************************************************/

#import "NumberPad.h"
#import "UserController.h"

#pragma mark - Private methods

@interface NumberPad ()

@property (nonatomic, weak) UIResponder <UITextInput> *targetTextInput;

@end

#pragma mark - LNNumberpad Implementation

@implementation NumberPad

@synthesize targetTextInput;
@synthesize padView;

#pragma mark - Shared LNNumberpad method

+ (NumberPad *)defaultLNNumberpad {
    static NumberPad *defaultNumberpad = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        defaultNumberpad = [[[NSBundle mainBundle] loadNibNamed:@"NumberPad" owner:self options:nil] objectAtIndex:0];
    });
    
    return defaultNumberpad;
}

#pragma mark - view lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addObservers];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addObservers];
    }
    return self;
}

- (void)addObservers {
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingDidBegin:)
                                                 name:UITextFieldTextDidBeginEditingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingDidBegin:)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingDidEnd:)
                                                 name:UITextFieldTextDidEndEditingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingDidEnd:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidBeginEditingNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidBeginEditingNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidEndEditingNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidEndEditingNotification
                                                  object:nil];
    
    self.targetTextInput = nil;
}

#pragma mark - editingDidBegin/End

- (void)editingDidBegin:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[UIResponder class]])
    {
        if ([notification.object conformsToProtocol:@protocol(UITextInput)]) {
            self.targetTextInput = notification.object;
            return;
        }
    }
    
    self.targetTextInput = nil;
}

- (void)editingDidEnd:(NSNotification *)notification {
    self.targetTextInput = nil;
}

#pragma mark - Keypad IBAction's

// A number (0-9) was just pressed on the number pad
- (IBAction)numberpadNumberPressed:(UIButton *)sender {
    if (self.targetTextInput) {
        NSString *numberPressed  = sender.titleLabel.text;
        if ([numberPressed length] > 0) {
            UITextRange *selectedTextRange = self.targetTextInput.selectedTextRange;
            if (selectedTextRange) {
                [self textInput:self.targetTextInput replaceTextAtTextRange:selectedTextRange withString:numberPressed];
            }
        }
    }
}

// The delete button was just pressed on the number pad
- (IBAction)numberpadDeletePressed:(UIButton *)sender {
    if (self.targetTextInput) {
        UITextRange *selectedTextRange = self.targetTextInput.selectedTextRange;
        if (selectedTextRange) {
            // Calculate the selected text to delete
            UITextPosition  *startPosition  = [self.targetTextInput positionFromPosition:selectedTextRange.start offset:-1];
            if (!startPosition) {
                return;
            }
            UITextPosition  *endPosition    = selectedTextRange.end;
            if (!endPosition) {
                return;
            }
            UITextRange     *rangeToDelete  = [self.targetTextInput textRangeFromPosition:startPosition
                                                                               toPosition:endPosition];
            
            [self textInput:self.targetTextInput replaceTextAtTextRange:rangeToDelete withString:@""];
        }
    }
}

// The clear button was just pressed on the number pad
- (IBAction)numberpadClearPressed:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName: @"setActiveFieldOnClearNotification" object: nil];
    
    if (self.targetTextInput) {
        UITextRange *allTextRange = [self.targetTextInput textRangeFromPosition:self.targetTextInput.beginningOfDocument
                                                                     toPosition:self.targetTextInput.endOfDocument];
        
        [self textInput:self.targetTextInput replaceTextAtTextRange:allTextRange withString:@""];
    }
}

#pragma mark - text replacement routines

// Check delegate methods to see if we should change the characters in range
- (BOOL)textInput:(id <UITextInput>)textInput shouldChangeCharactersInRange:(NSRange)range withString:(NSString *)string {
    if (textInput) {
        if ([textInput isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)textInput;
            if ([textField.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
                if ([textField.delegate textField:textField
                    shouldChangeCharactersInRange:range
                                replacementString:string]) {
                    return YES;
                }
            } else {
                // Delegate does not respond, so default to YES
                return YES;
            }
        } else if ([textInput isKindOfClass:[UITextView class]]) {
            UITextView *textView = (UITextView *)textInput;
            if ([textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                if ([textView.delegate textView:textView
                        shouldChangeTextInRange:range
                                replacementText:string]) {
                    return YES;
                }
            } else {
                // Delegate does not respond, so default to YES
                return YES;
            }
        }
    }
    return NO;
}

// Replace the text of the textInput in textRange with string if the delegate approves
- (void)textInput:(id <UITextInput>)textInput replaceTextAtTextRange:(UITextRange *)textRange withString:(NSString *)string {
    if (textInput) {
        if (textRange) {
            // Calculate the NSRange for the textInput text in the UITextRange textRange:
            int startPos                    = [textInput offsetFromPosition:textInput.beginningOfDocument
                                                                 toPosition:textRange.start];
            int length                      = [textInput offsetFromPosition:textRange.start
                                                                 toPosition:textRange.end];
            NSRange selectedRange           = NSMakeRange(startPos, length);
            
            if ([self textInput:textInput shouldChangeCharactersInRange:selectedRange withString:string]) {
                // Make the replacement:
                [textInput replaceRange:textRange withText:string];
            }
        }
    }
}

@end
