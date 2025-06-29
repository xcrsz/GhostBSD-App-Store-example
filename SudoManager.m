#import "SudoManager.h"
#import <Foundation/NSTask.h>

static SudoManager *sharedInstance = nil;

@interface SudoManager ()
@property (nonatomic, assign) NSTimeInterval lastSudoTime;
@property (nonatomic, assign) BOOL hasValidSession;
@property (nonatomic, retain) NSString *cachedPassword;
@end

@implementation SudoManager

@synthesize lastSudoTime, hasValidSession, cachedPassword;

+ (SudoManager *)sharedManager
{
    if (sharedInstance == nil) {
        sharedInstance = [[SudoManager alloc] init];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.lastSudoTime = 0;
        self.hasValidSession = NO;
        self.cachedPassword = nil;
    }
    return self;
}

- (BOOL)validateSudoWithPassword:(NSString *)password error:(NSString **)error
{
    NSLog(@"DEBUG: validateSudoWithPassword called");
    
    if (!password || [password length] == 0) {
        NSLog(@"DEBUG: Password is empty");
        if (error) *error = @"Password cannot be empty";
        return NO;
    }
    
    NSLog(@"DEBUG: Creating NSTask for sudo validation");
    NSTask *task = [[NSTask alloc] init];
    
    // Fixed path for GhostBSD/FreeBSD
    NSString *sudoPath = @"/usr/local/bin/sudo";
    NSLog(@"DEBUG: Using sudo path: %@", sudoPath);
    
    // Check if sudo exists at this path
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:sudoPath]) {
        NSLog(@"ERROR: sudo not found at %@", sudoPath);
        if (error) *error = [NSString stringWithFormat:@"sudo not found at %@", sudoPath];
        [task release];
        return NO;
    }
    
    [task setLaunchPath:sudoPath];
    [task setArguments:@[@"-S", @"-v"]]; // -S: read password from stdin, -v: validate
    
    NSPipe *inputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardInput:inputPipe];
    [task setStandardError:errorPipe];
    
    NSLog(@"DEBUG: Launching sudo task");
    [task launch];
    
    // Send password
    NSString *passwordWithNewline = [password stringByAppendingString:@"\n"];
    [[inputPipe fileHandleForWriting] writeData:[passwordWithNewline dataUsingEncoding:NSUTF8StringEncoding]];
    [[inputPipe fileHandleForWriting] closeFile];
    
    NSLog(@"DEBUG: Waiting for sudo task to complete");
    [task waitUntilExit];
    
    int terminationStatus = [task terminationStatus];
    NSLog(@"DEBUG: sudo task completed with status: %d", terminationStatus);
    
    BOOL success = (terminationStatus == 0);
    
    if (success) {
        NSLog(@"DEBUG: sudo validation successful");
        self.lastSudoTime = [[NSDate date] timeIntervalSince1970];
        self.hasValidSession = YES;
        // IMPORTANT: Cache the password for reuse in commands
        if (self.cachedPassword) {
            [self.cachedPassword release];
        }
        self.cachedPassword = [password copy];
    } else {
        NSLog(@"DEBUG: sudo validation failed");
        self.hasValidSession = NO;
        if (self.cachedPassword) {
            [self.cachedPassword release];
            self.cachedPassword = nil;
        }
        
        if (error) {
            NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
            NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
            NSLog(@"DEBUG: sudo error output: %@", errorOutput);
            
            if ([errorOutput containsString:@"incorrect password"] || 
                [errorOutput containsString:@"Sorry, try again"]) {
                *error = @"Incorrect password";
            } else if ([errorOutput containsString:@"not in the sudoers file"]) {
                *error = @"User is not authorized to use sudo";
            } else {
                *error = [NSString stringWithFormat:@"Authentication failed: %@", errorOutput];
            }
            
            [errorOutput release];
        }
    }
    
    [task release];
    return success;
}

- (BOOL)hasCachedSudoAccess
{
    if (!self.hasValidSession || !self.cachedPassword) {
        return NO;
    }
    
    // Check if sudo session has expired (default timeout is 5 minutes = 300 seconds)
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval elapsed = currentTime - self.lastSudoTime;
    
    if (elapsed > 270) { // 4.5 minutes - be conservative
        NSLog(@"DEBUG: Sudo session expired after %.0f seconds", elapsed);
        self.hasValidSession = NO;
        return NO;
    }
    
    return YES;
}

- (BOOL)executeSudoCommand:(NSArray *)arguments 
                    output:(NSString **)output 
                     error:(NSString **)error
{
    if (![self hasCachedSudoAccess]) {
        if (error) *error = @"No valid sudo session. Please authenticate first.";
        return NO;
    }
    
    NSLog(@"DEBUG: Executing sudo command: %@", [arguments componentsJoinedByString:@" "]);
    
    NSTask *task = [[NSTask alloc] init];
    // Fixed path for GhostBSD/FreeBSD
    [task setLaunchPath:@"/usr/local/bin/sudo"];
    
    // CRITICAL FIX: Use cached password instead of -n flag
    // -S reads from stdin, we send the cached password
    NSMutableArray *sudoArgs = [NSMutableArray arrayWithObject:@"-S"];
    [sudoArgs addObjectsFromArray:arguments];
    [task setArguments:sudoArgs];
    
    NSPipe *inputPipe = [NSPipe pipe];
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardInput:inputPipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:errorPipe];
    
    [task launch];
    
    // IMPORTANT: Send cached password to sudo
    if (self.cachedPassword) {
        NSString *passwordWithNewline = [self.cachedPassword stringByAppendingString:@"\n"];
        [[inputPipe fileHandleForWriting] writeData:[passwordWithNewline dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [[inputPipe fileHandleForWriting] closeFile];
    
    [task waitUntilExit];
    
    // Read output
    if (output) {
        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        *output = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"DEBUG: Command output: %@", *output);
    }
    
    // Read error
    if (error) {
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errorOutput = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
        if ([errorOutput length] > 0) {
            *error = errorOutput;
            NSLog(@"DEBUG: Command error: %@", *error);
        }
    }
    
    BOOL success = ([task terminationStatus] == 0);
    NSLog(@"DEBUG: Command completed with status: %d", [task terminationStatus]);
    
    if (success) {
        // Update the timestamp on successful command execution
        self.lastSudoTime = [[NSDate date] timeIntervalSince1970];
    } else {
        // If command failed due to auth issues, clear session
        if (error && *error && ([*error containsString:@"password"] || [*error containsString:@"privilege"])) {
            NSLog(@"DEBUG: Command failed due to auth issues, clearing session");
            self.hasValidSession = NO;
        }
    }
    
    [task release];
    return success;
}

- (void)clearSudoCache
{
    NSLog(@"DEBUG: Clearing sudo cache");
    
    // Kill the sudo timestamp
    NSTask *task = [[NSTask alloc] init];
    // Fixed path for GhostBSD/FreeBSD
    [task setLaunchPath:@"/usr/local/bin/sudo"];
    [task setArguments:@[@"-k"]]; // -k: kill timestamp
    [task launch];
    [task waitUntilExit];
    [task release];
    
    self.hasValidSession = NO;
    self.lastSudoTime = 0;
    
    // Clear cached password
    if (self.cachedPassword) {
        [self.cachedPassword release];
        self.cachedPassword = nil;
    }
}

- (NSTimeInterval)timeRemaining
{
    if (!self.hasValidSession) {
        return 0;
    }
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval elapsed = currentTime - self.lastSudoTime;
    NSTimeInterval remaining = 300 - elapsed; // 5 minutes default timeout
    
    return (remaining > 0) ? remaining : 0;
}

- (void)dealloc
{
    [self clearSudoCache];
    if (cachedPassword) {
        [cachedPassword release];
    }
    [super dealloc];
}

@end
