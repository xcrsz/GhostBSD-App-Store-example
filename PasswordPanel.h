#import <AppKit/AppKit.h>

typedef void (^PasswordCompletion)(NSString *password, BOOL cancelled);

@interface PasswordPanel : NSObject

@property (nonatomic, retain) NSPanel *panel;
@property (nonatomic, retain) NSSecureTextField *passwordField;
@property (nonatomic, copy) PasswordCompletion completion;

- (void)showPasswordPanelWithTitle:(NSString *)title 
                           message:(NSString *)message
                        completion:(PasswordCompletion)completion;

- (void)closePanel;

@end
