#import "PasswordPanel.h"

@implementation PasswordPanel

@synthesize panel, passwordField, completion;

- (void)showPasswordPanelWithTitle:(NSString *)title 
                           message:(NSString *)message
                        completion:(PasswordCompletion)completionBlock
{
    NSLog(@"DEBUG: PasswordPanel showPasswordPanelWithTitle called");
    NSLog(@"DEBUG: Title: %@", title);
    NSLog(@"DEBUG: Message: %@", message);
    
    self.completion = completionBlock;
    
    NSLog(@"DEBUG: Creating password panel window");
    self.panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(300, 300, 450, 140)
                                           styleMask:NSTitledWindowMask
                                             backing:NSBackingStoreBuffered
                                               defer:NO];
    [self.panel setTitle:title];
    NSLog(@"DEBUG: Panel created: %@", self.panel);
    
    NSTextField *promptLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 100, 410, 20)];
    [promptLabel setStringValue:message];
    [promptLabel setBezeled:NO];
    [promptLabel setDrawsBackground:NO];
    [promptLabel setEditable:NO];
    [promptLabel setFont:[NSFont systemFontOfSize:12]];
    [[self.panel contentView] addSubview:promptLabel];
    
    // Add a "Password:" label above the field
    NSTextField *passwordLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 75, 80, 18)];
    [passwordLabel setStringValue:@"Password:"];
    [passwordLabel setBezeled:NO];
    [passwordLabel setDrawsBackground:NO];
    [passwordLabel setEditable:NO];
    [passwordLabel setFont:[NSFont systemFontOfSize:11]];
    [[self.panel contentView] addSubview:passwordLabel];
    
    // Remove placeholder text and make field cleaner
    self.passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(20, 50, 410, 24)];
    // Don't set placeholder - just leave it empty
    [[self.panel contentView] addSubview:self.passwordField];
    
    NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(350, 10, 80, 30)];
    [okButton setTitle:@"OK"];
    [okButton setBezelStyle:NSRoundedBezelStyle];
    [okButton setTarget:self];
    [okButton setAction:@selector(okClicked:)];
    [okButton setKeyEquivalent:@"\r"]; // Enter key
    [[self.panel contentView] addSubview:okButton];
    
    NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(260, 10, 80, 30)];
    [cancelButton setTitle:@"Cancel"];
    [cancelButton setBezelStyle:NSRoundedBezelStyle];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancelClicked:)];
    [cancelButton setKeyEquivalent:@"\033"]; // Escape key
    [[self.panel contentView] addSubview:cancelButton];
    
    // Focus on the password field
    [self.panel makeFirstResponder:self.passwordField];
    
    NSLog(@"DEBUG: About to show modal password panel");
    [NSApp runModalForWindow:self.panel];
    NSLog(@"DEBUG: Modal dialog finished");
    
    [promptLabel release];
    [passwordLabel release];
    [okButton release];
    [cancelButton release];
}

- (void)okClicked:(id)sender
{
    NSLog(@"DEBUG: OK button clicked");
    NSString *password = [self.passwordField stringValue];
    NSLog(@"DEBUG: Password length: %lu", (unsigned long)[password length]);
    [self closePanel];
    if (self.completion) {
        NSLog(@"DEBUG: Calling completion block with password");
        self.completion(password, NO);
    }
}

- (void)cancelClicked:(id)sender
{
    NSLog(@"DEBUG: Cancel button clicked");
    [self closePanel];
    if (self.completion) {
        NSLog(@"DEBUG: Calling completion block - cancelled");
        self.completion(nil, YES);
    }
}

- (void)closePanel
{
    NSLog(@"DEBUG: Closing password panel");
    [NSApp stopModal];
    [self.panel orderOut:nil];
}

- (void)dealloc
{
    [panel release];
    [passwordField release];
    [completion release];
    [super dealloc];
}

@end
