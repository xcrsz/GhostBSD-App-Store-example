#import "PackageManager.h"
#import "Package.h"
#import "SudoManager.h"
#import <Foundation/NSTask.h>

@interface PackageManager ()
@property (nonatomic, retain) NSCache *searchCache;
@property (nonatomic, retain) NSCache *categoryCache;
@property (nonatomic, retain) NSDictionary *metadata;
@property (nonatomic, retain) NSDictionary *categoryMappings;
@end

static PackageManager *sharedInstance = nil;

@implementation PackageManager

@synthesize searchCache, categoryCache, metadata, categoryMappings;

+ (PackageManager *)sharedManager
{
    if (sharedInstance == nil) {
        sharedInstance = [[PackageManager alloc] init];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.searchCache = [[NSCache alloc] init];
        [self.searchCache setCountLimit:100];
        
        self.categoryCache = [[NSCache alloc] init];
        [self.categoryCache setCountLimit:50];
        
        [self setupMetadata];
        [self setupCategoryMappings];
    }
    return self;
}

- (void)setupMetadata
{
    self.metadata = [[NSDictionary alloc] initWithObjectsAndKeys:
                    // Essential application descriptions - clean and simple
                    @"Fast, private and secure web browser from Mozilla", @"firefox-desc",
                    @"Open-source web browser project", @"chromium-desc",
                    @"Full-featured office suite - documents, spreadsheets, presentations", @"libreoffice-desc",
                    @"Fast and lightweight word processor", @"abiword-desc",
                    @"Professional spreadsheet application", @"gnumeric-desc",
                    @"The ultimate media player - plays everything, streams anywhere", @"vlc-desc",
                    @"Professional audio editing software with multi-track recording", @"audacity-desc",
                    @"Professional image editor and photo manipulation software", @"gimp-desc",
                    @"Vector graphics editor for illustrations, logos, and artwork", @"inkscape-desc",
                    @"Feature-rich email client with calendar and contact management", @"thunderbird-desc",
                    @"Modern IRC client with customizable interface", @"hexchat-desc",
                    @"Distributed version control system", @"git-desc",
                    @"Lightweight IDE with syntax highlighting and project management", @"geany-desc",
                    @"Interactive process viewer with real-time system monitoring", @"htop-desc",
                    @"Complete privacy toolkit with encryption and digital signatures", @"gnupg-desc",
                    @"Secure password manager with cross-platform synchronization", @"keepassxc-desc",
                    nil];
}

- (void)setupCategoryMappings
{
    // Simplified category mappings for dynamic category browsing
    self.categoryMappings = @{
        @"www": @[@"firefox", @"chrome", @"chromium", @"opera", @"webkit"],
        @"multimedia": @[@"vlc", @"mplayer", @"mpv", @"audacity", @"ffmpeg"],
        @"graphics": @[@"gimp", @"inkscape", @"krita", @"blender", @"imagemagick"],
        @"editors": @[@"vim", @"emacs", @"nano", @"gedit", @"kate"],
        @"devel": @[@"gcc", @"clang", @"make", @"cmake", @"git"],
        @"games": @[@"0ad", @"wesnoth", @"freeciv", @"supertux"],
        @"sysutils": @[@"htop", @"gparted", @"baobab", @"rsync"],
        @"net": @[@"wget", @"curl", @"openssh", @"putty"],
        @"security": @[@"gnupg", @"keepass", @"veracrypt", @"clamav"],
        @"math": @[@"octave", @"scilab", @"maxima", @"gnuplot"],
        @"science": @[@"avogadro", @"stellarium", @"celestia", @"qgis"],
        @"mail": @[@"thunderbird", @"evolution", @"kmail", @"mutt"],
        @"databases": @[@"mysql", @"postgresql", @"sqlite", @"mongodb"],
        @"archivers": @[@"zip", @"gzip", @"7zip", @"rar"],
        @"finance": @[@"gnucash", @"kmymoney", @"bitcoin", @"electrum"]
    };
}

#pragma mark - FEATURED PACKAGES (Static & Fast)

- (void)getFeaturedPackagesWithCompletion:(PackageSearchCompletion)completion
{
    // Static featured packages - instant loading, no network calls
    NSMutableArray *allPackages = [NSMutableArray array];
    
    // Welcome header removed - now handled in main window
    
    // Web Browsers
    Package *webHeader = [[Package alloc] initWithName:@"_CATEGORY_Web Browsers"
                                            description:@"[WEB] Web Browsers"
                                               iconPath:@""
                                              installed:NO];
    [allPackages addObject:webHeader];
    [webHeader release];
    
    [allPackages addObject:[self createFeaturedPackage:@"firefox"]];
    [allPackages addObject:[self createFeaturedPackage:@"chromium"]];
    
    // Office and Productivity
    Package *officeHeader = [[Package alloc] initWithName:@"_CATEGORY_Office and Productivity"
                                              description:@"[OFFICE] Office and Productivity"
                                                 iconPath:@""
                                                installed:NO];
    [allPackages addObject:officeHeader];
    [officeHeader release];
    
    [allPackages addObject:[self createFeaturedPackage:@"libreoffice"]];
    [allPackages addObject:[self createFeaturedPackage:@"abiword"]];
    [allPackages addObject:[self createFeaturedPackage:@"gnumeric"]];
    
    // Multimedia
    Package *mediaHeader = [[Package alloc] initWithName:@"_CATEGORY_Multimedia"
                                              description:@"[MEDIA] Multimedia"
                                                 iconPath:@""
                                                installed:NO];
    [allPackages addObject:mediaHeader];
    [mediaHeader release];
    
    [allPackages addObject:[self createFeaturedPackage:@"vlc"]];
    [allPackages addObject:[self createFeaturedPackage:@"audacity"]];
    
    // Graphics and Image Tools
    Package *gfxHeader = [[Package alloc] initWithName:@"_CATEGORY_Graphics and Image Tools"
                                            description:@"[GFX] Graphics and Image Tools"
                                               iconPath:@""
                                              installed:NO];
    [allPackages addObject:gfxHeader];
    [gfxHeader release];
    
    [allPackages addObject:[self createFeaturedPackage:@"gimp"]];
    [allPackages addObject:[self createFeaturedPackage:@"inkscape"]];
    
    // Communication
    Package *commHeader = [[Package alloc] initWithName:@"_CATEGORY_Communication"
                                             description:@"[COMM] Communication"
                                                iconPath:@""
                                               installed:NO];
    [allPackages addObject:commHeader];
    [commHeader release];
    
    [allPackages addObject:[self createFeaturedPackage:@"thunderbird"]];
    [allPackages addObject:[self createFeaturedPackage:@"hexchat"]];
    
    // Development Tools
    Package *devHeader = [[Package alloc] initWithName:@"_CATEGORY_Development Tools"
                                            description:@"[DEV] Development Tools"
                                               iconPath:@""
                                              installed:NO];
    [allPackages addObject:devHeader];
    [devHeader release];
    
    [allPackages addObject:[self createFeaturedPackage:@"git"]];
    [allPackages addObject:[self createFeaturedPackage:@"geany"]];
    
    // System Utilities
    Package *sysHeader = [[Package alloc] initWithName:@"_CATEGORY_System Utilities"
                                            description:@"[SYS] System Utilities"
                                               iconPath:@""
                                              installed:NO];
    [allPackages addObject:sysHeader];
    [sysHeader release];
    
    [allPackages addObject:[self createFeaturedPackage:@"htop"]];
    
    // Security and Privacy  
    Package *secHeader = [[Package alloc] initWithName:@"_CATEGORY_Security and Privacy"
                                            description:@"[SEC] Security and Privacy"
                                               iconPath:@""
                                              installed:NO];
    [allPackages addObject:secHeader];
    [secHeader release];
    
    [allPackages addObject:[self createFeaturedPackage:@"gnupg"]];
    [allPackages addObject:[self createFeaturedPackage:@"keepassxc"]];
    
    // Return immediately - lightning fast!
    completion(allPackages, nil);
}

- (Package *)createFeaturedPackage:(NSString *)packageName
{
    NSString *descKey = [NSString stringWithFormat:@"%@-desc", packageName];
    NSString *description = [self.metadata objectForKey:descKey];
    if (!description) {
        description = [NSString stringWithFormat:@"%@ application", packageName];
    }
    
    Package *package = [[Package alloc] initWithName:packageName
                                          description:description
                                             iconPath:@""
                                            installed:NO];
    return [package autorelease];
}

#pragma mark - SEARCH FUNCTIONALITY

- (void)searchPackagesWithTerm:(NSString *)searchTerm completion:(PackageSearchCompletion)completion
{
    if ([searchTerm length] == 0) {
        completion(@[], nil);
        return;
    }
    
    NSArray *cachedResults = [self.searchCache objectForKey:searchTerm];
    if (cachedResults) {
        completion(cachedResults, nil);
        return;
    }
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/sbin/pkg"];
        [task setArguments:@[@"search", searchTerm]];
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        [task launch];
        [task waitUntilExit];
        
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableArray *packages = [NSMutableArray array];
        
        NSArray *lines = [output componentsSeparatedByString:@"\n"];
        for (NSString *line in lines) {
            if ([line length] > 0) {
                // FIXED: Clean package names to avoid description contamination
                NSString *cleanName = [self cleanPackageNameFromSearchResult:line];
                if ([cleanName length] > 0) {
                    NSString *descKey = [NSString stringWithFormat:@"%@-desc", cleanName];
                    Package *package = [[Package alloc] initWithName:cleanName
                                                         description:[self.metadata objectForKey:descKey] ?: @""
                                                            iconPath:@""
                                                           installed:NO];
                    [packages addObject:package];
                    [package release];
                }
            }
        }
        
        [self.searchCache setObject:[packages copy] forKey:searchTerm];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if ([task terminationStatus] == 0) {
                completion(packages, nil);
            } else {
                completion(@[], @"Could not connect to repository. Try running 'sudo pkg update' in terminal.");
            }
        }];
        
        [output release];
        [task release];
    }];
    [queue release];
}

// NEW: Helper method to clean package names from search results
- (NSString *)cleanPackageNameFromSearchResult:(NSString *)searchResultLine
{
    if (!searchResultLine || [searchResultLine length] == 0) {
        return @"";
    }
    
    // Remove any whitespace and newlines
    NSString *cleaned = [searchResultLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // If the line contains multiple spaces or tabs, take only the first part (the actual package name)
    NSArray *components = [cleaned componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([components count] > 0) {
        NSString *firstName = [components objectAtIndex:0];
        // Additional validation - package names shouldn't contain spaces
        if ([firstName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location == NSNotFound &&
            [firstName length] > 0 && [firstName length] < 100) {
            return firstName;
        }
    }
    
    return @"";
}

#pragma mark - CATEGORY BROWSING

- (void)getPackagesByCategory:(NSString *)category completion:(PackageSearchCompletion)completion
{
    NSArray *cachedResults = [self.categoryCache objectForKey:category];
    if (cachedResults) {
        completion(cachedResults, nil);
        return;
    }
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSMutableSet *packageSet = [NSMutableSet set];
        NSArray *keywords = [self.categoryMappings objectForKey:category];
        
        // Strategy 1: Official category search
        NSTask *categoryTask = [[NSTask alloc] init];
        [categoryTask setLaunchPath:@"/usr/sbin/pkg"];
        [categoryTask setArguments:@[@"search", @"-c", category]];
        NSPipe *categoryPipe = [NSPipe pipe];
        [categoryTask setStandardOutput:categoryPipe];
        [categoryTask launch];
        [categoryTask waitUntilExit];
        
        if ([categoryTask terminationStatus] == 0) {
            NSData *categoryData = [[categoryPipe fileHandleForReading] readDataToEndOfFile];
            NSString *categoryOutput = [[NSString alloc] initWithData:categoryData encoding:NSUTF8StringEncoding];
            NSArray *categoryLines = [categoryOutput componentsSeparatedByString:@"\n"];
            
            for (NSString *line in categoryLines) {
                NSString *cleanName = [self cleanPackageNameFromSearchResult:line];
                if ([cleanName length] > 0) {
                    [packageSet addObject:cleanName];
                }
            }
            [categoryOutput release];
        }
        [categoryTask release];
        
        // Strategy 2: Keyword searches (limited for performance)
        if (keywords) {
            NSInteger maxKeywords = MIN([keywords count], 5);
            for (NSInteger i = 0; i < maxKeywords; i++) {
                NSString *keyword = [keywords objectAtIndex:i];
                NSTask *searchTask = [[NSTask alloc] init];
                [searchTask setLaunchPath:@"/usr/sbin/pkg"];
                [searchTask setArguments:@[@"search", keyword]];
                NSPipe *searchPipe = [NSPipe pipe];
                [searchTask setStandardOutput:searchPipe];
                [searchTask setStandardError:[NSPipe pipe]];
                [searchTask launch];
                [searchTask waitUntilExit];
                
                if ([searchTask terminationStatus] == 0) {
                    NSData *searchData = [[searchPipe fileHandleForReading] readDataToEndOfFile];
                    NSString *searchOutput = [[NSString alloc] initWithData:searchData encoding:NSUTF8StringEncoding];
                    NSArray *searchLines = [searchOutput componentsSeparatedByString:@"\n"];
                    
                    for (NSString *line in searchLines) {
                        NSString *cleanName = [self cleanPackageNameFromSearchResult:line];
                        if ([cleanName length] > 0) {
                            [packageSet addObject:cleanName];
                            if ([packageSet count] > 100) break;
                        }
                    }
                    [searchOutput release];
                }
                [searchTask release];
                
                if ([packageSet count] > 100) break;
            }
        }
        
        // Convert to Package objects
        NSArray *sortedPackageNames = [[packageSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
        NSMutableArray *packages = [NSMutableArray array];
        
        for (NSString *packageName in sortedPackageNames) {
            NSString *description = [self generateDescriptionForPackage:packageName inCategory:category];
            Package *package = [[Package alloc] initWithName:packageName
                                                 description:description
                                                    iconPath:@""
                                                   installed:NO];
            [packages addObject:package];
            [package release];
        }
        
        [self.categoryCache setObject:[packages copy] forKey:category];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completion(packages, nil);
        }];
    }];
    [queue release];
}

- (NSString *)generateDescriptionForPackage:(NSString *)packageName inCategory:(NSString *)category
{
    NSString *descKey = [NSString stringWithFormat:@"%@-desc", packageName];
    NSString *metadataDesc = [self.metadata objectForKey:descKey];
    if (metadataDesc) {
        return metadataDesc;
    }
    
    NSDictionary *categoryDescriptions = @{
        @"www": @"Web browser or internet tool",
        @"multimedia": @"Multimedia application",
        @"graphics": @"Graphics and image software",
        @"editors": @"Text or code editor",
        @"games": @"Game or entertainment software",
        @"devel": @"Development tool",
        @"sysutils": @"System utility",
        @"security": @"Security tool",
        @"net": @"Network utility",
        @"math": @"Mathematical software",
        @"science": @"Scientific application",
        @"databases": @"Database software",
        @"archivers": @"Archive and compression tool",
        @"mail": @"Email software",
        @"finance": @"Financial application"
    };
    
    return [categoryDescriptions objectForKey:category] ?: @"Software package";
}

#pragma mark - UPDATE MANAGEMENT

- (void)getAvailableUpdatesWithCompletion:(PackageSearchCompletion)completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        SudoManager *sudoManager = [SudoManager sharedManager];
        
        // Update package database with proper privileges if we have sudo access
        if ([sudoManager hasCachedSudoAccess]) {
            NSLog(@"DEBUG: Updating package database for updates check");
            NSString *updateOutput = nil;
            NSString *updateError = nil;
            [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"update", @"-f"] 
                                     output:&updateOutput 
                                      error:&updateError];
        }
        
        // Now check for available upgrades
        NSTask *upgradeTask = [[NSTask alloc] init];
        [upgradeTask setLaunchPath:@"/usr/sbin/pkg"];
        [upgradeTask setArguments:@[@"upgrade", @"-n"]]; // -n for dry run
        NSPipe *pipe = [NSPipe pipe];
        [upgradeTask setStandardOutput:pipe];
        [upgradeTask setStandardError:[NSPipe pipe]]; // Capture errors too
        [upgradeTask launch];
        [upgradeTask waitUntilExit];
        
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableArray *packages = [NSMutableArray array];
        
        if ([upgradeTask terminationStatus] == 0) {
            NSArray *lines = [output componentsSeparatedByString:@"\n"];
            for (NSString *line in lines) {
                if ([line containsString:@"->"]) {
                    // FIXED: Clean package names from update output
                    NSString *cleanName = [self cleanPackageNameFromSearchResult:line];
                    if ([cleanName length] > 0) {
                        Package *package = [[Package alloc] initWithName:cleanName
                                                             description:@"Update available"
                                                                iconPath:@""
                                                               installed:YES];
                        [packages addObject:package];
                        [package release];
                    }
                }
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completion(packages, nil);
        }];
        
        [upgradeTask release];
        [output release];
    }];
    [queue release];
}

- (void)checkForUpdatesWithCompletion:(void (^)(BOOL updatesAvailable))completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        SudoManager *sudoManager = [SudoManager sharedManager];
        
        // Update package database with proper privileges if we have sudo access
        if ([sudoManager hasCachedSudoAccess]) {
            NSLog(@"DEBUG: Updating package database for updates check");
            NSString *updateOutput = nil;
            NSString *updateError = nil;
            [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"update", @"-f"] 
                                     output:&updateOutput 
                                      error:&updateError];
        }
        
        // Check for available upgrades
        NSTask *upgradeTask = [[NSTask alloc] init];
        [upgradeTask setLaunchPath:@"/usr/sbin/pkg"];
        [upgradeTask setArguments:@[@"upgrade", @"-n"]]; // -n for dry run
        NSPipe *pipe = [NSPipe pipe];
        [upgradeTask setStandardOutput:pipe];
        [upgradeTask setStandardError:[NSPipe pipe]];
        [upgradeTask launch];
        [upgradeTask waitUntilExit];
        
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        BOOL updatesAvailable = ([output containsString:@"->"] || [output containsString:@"upgrade"]);
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completion(updatesAvailable);
        }];
        
        [upgradeTask release];
        [output release];
    }];
    [queue release];
}

#pragma mark - IMPROVED: Package Installation Status Checking

// NEW: Better method to check if a package is installed
- (BOOL)isPackageInstalled:(NSString *)packageName output:(NSString **)output error:(NSString **)error
{
    NSLog(@"DEBUG: Checking installation status for package: %@", packageName);
    
    SudoManager *sudoManager = [SudoManager sharedManager];
    
    // Try multiple approaches to check package installation
    
    // Method 1: Direct pkg info check
    BOOL directCheck = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"info", packageName] 
                                                output:output 
                                                 error:error];
    
    if (directCheck && *output && [*output length] > 0) {
        NSLog(@"DEBUG: Package %@ found via direct check", packageName);
        return YES;
    }
    
    // Method 2: Try without version number if package name contains version
    if ([packageName rangeOfString:@"-"].location != NSNotFound) {
        NSArray *components = [packageName componentsSeparatedByString:@"-"];
        if ([components count] >= 2) {
            // Try with just the base name (remove potential version)
            NSString *baseName = [components objectAtIndex:0];
            NSLog(@"DEBUG: Trying base name: %@", baseName);
            
            BOOL baseCheck = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"info", baseName] 
                                                      output:output 
                                                       error:error];
            
            if (baseCheck && *output && [*output length] > 0) {
                NSLog(@"DEBUG: Package %@ found via base name %@", packageName, baseName);
                return YES;
            }
        }
    }
    
    // Method 3: Use pkg query to search for similar packages
    NSString *queryOutput = nil;
    NSString *queryError = nil;
    BOOL queryCheck = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"query", @"%n-%v", packageName] 
                                               output:&queryOutput 
                                                error:&queryError];
    
    if (queryCheck && queryOutput && [queryOutput length] > 0) {
        NSLog(@"DEBUG: Package %@ found via query: %@", packageName, queryOutput);
        if (output) *output = queryOutput;
        return YES;
    }
    
    // Method 4: Try glob pattern search for packages starting with the name
    NSString *searchPattern = [packageName stringByAppendingString:@"*"];
    NSString *globOutput = nil;
    NSString *globError = nil;
    BOOL globCheck = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"info", @"-g", searchPattern] 
                                              output:&globOutput 
                                               error:&globError];
    
    if (globCheck && globOutput && [globOutput length] > 0) {
        NSLog(@"DEBUG: Package %@ found via glob search: %@", packageName, globOutput);
        if (output) *output = globOutput;
        return YES;
    }
    
    NSLog(@"DEBUG: Package %@ not found by any method", packageName);
    if (error && !*error) {
        *error = [NSString stringWithFormat:@"Package '%@' is not installed", packageName];
    }
    
    return NO;
}

#pragma mark - PACKAGE OPERATIONS

- (void)installPackage:(NSString *)packageName 
              password:(NSString *)password
              progress:(ProgressUpdateBlock)progressBlock
            completion:(PackageOperationCompletion)completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        SudoManager *sudoManager = [SudoManager sharedManager];
        
        // First validate sudo access if we don't have a cached session
        if (![sudoManager hasCachedSudoAccess]) {
            NSString *authError = nil;
            if (![sudoManager validateSudoWithPassword:password error:&authError]) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completion(NO, authError ?: @"Authentication failed");
                }];
                return;
            }
        }
        
        // IMPORTANT: Update package database first with proper privileges
        NSLog(@"DEBUG: Updating package database before installation");
        NSString *updateOutput = nil;
        NSString *updateError = nil;
        BOOL updateSuccess = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"update", @"-f"] 
                                                      output:&updateOutput 
                                                       error:&updateError];
        
        if (!updateSuccess) {
            NSLog(@"WARNING: Package database update failed: %@", updateError);
            // Continue anyway - the package might still be installable
        }
        
        // FIXED: Clean package name before installation
        NSString *cleanPackageName = [self cleanPackageNameFromSearchResult:packageName];
        if ([cleanPackageName length] == 0) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(NO, [NSString stringWithFormat:@"Invalid package name: %@", packageName]);
            }];
            return;
        }
        
        // Check if package is already installed
        NSString *checkOutput = nil;
        NSString *checkError = nil;
        BOOL checkResult = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"info", cleanPackageName] 
                                                    output:&checkOutput 
                                                     error:&checkError];
        
        if (checkResult && checkOutput && [checkOutput length] > 0) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(YES, nil); // Already installed, consider success
            }];
            return;
        }
        
        // Start progress monitoring using NSThread instead of GCD
        if (progressBlock) {
            [NSThread detachNewThreadSelector:@selector(monitorInstallProgressWithBlock:) 
                                     toTarget:self 
                                   withObject:progressBlock];
        }
        
        // Proceed with installation using proper sudo privileges
        NSLog(@"DEBUG: Installing package: %@", cleanPackageName);
        NSString *output = nil;
        NSString *error = nil;
        BOOL installSuccess = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"install", @"-y", cleanPackageName] 
                                                       output:&output 
                                                        error:&error];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (progressBlock) progressBlock(100);
            
            NSString *errorMessage = nil;
            BOOL finalSuccess = installSuccess;
            
            if (!installSuccess) {
                NSLog(@"DEBUG: Installation failed. Error: %@", error);
                
                if ([error containsString:@"already installed"]) {
                    finalSuccess = YES; // Consider already installed as success
                } else if ([error containsString:@"No packages available"]) {
                    errorMessage = [NSString stringWithFormat:@"Package '%@' not found in repositories.", cleanPackageName];
                } else if ([error containsString:@"locked"]) {
                    errorMessage = @"Package database is locked. Another package operation may be running.";
                } else if ([error containsString:@"Insufficient privileges"] || [error containsString:@"privilege"]) {
                    errorMessage = @"Insufficient privileges. Please re-authenticate.";
                } else if ([error containsString:@"repository catalogue"]) {
                    errorMessage = @"Cannot update package repository. Please check your internet connection and try again.";
                } else {
                    errorMessage = [NSString stringWithFormat:@"Installation failed: %@", error ?: @"Unknown error"];
                }
            } else {
                NSLog(@"DEBUG: Package %@ installed successfully", cleanPackageName);
            }
            
            completion(finalSuccess, errorMessage);
        }];
    }];
    [queue release];
}

// Helper method for install progress monitoring
- (void)monitorInstallProgressWithBlock:(ProgressUpdateBlock)progressBlock
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    double currentProgress = 0;
    
    while (currentProgress < 95) {
        currentProgress += 3;
        if (currentProgress > 95) currentProgress = 95;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            progressBlock(currentProgress);
        }];
        
        [NSThread sleepForTimeInterval:0.5];
    }
    
    [pool release];
}

- (void)uninstallPackage:(NSString *)packageName 
                password:(NSString *)password
                progress:(ProgressUpdateBlock)progressBlock
              completion:(PackageOperationCompletion)completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        SudoManager *sudoManager = [SudoManager sharedManager];
        
        // Validate sudo access if needed
        if (![sudoManager hasCachedSudoAccess]) {
            NSString *authError = nil;
            if (![sudoManager validateSudoWithPassword:password error:&authError]) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completion(NO, authError ?: @"Authentication failed");
                }];
                return;
            }
        }
        
        // FIXED: Clean package name before uninstallation
        NSString *cleanPackageName = [self cleanPackageNameFromSearchResult:packageName];
        if ([cleanPackageName length] == 0) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(NO, [NSString stringWithFormat:@"Invalid package name: %@", packageName]);
            }];
            return;
        }
        
        // Check if package is actually installed first
        NSString *checkOutput = nil;
        NSString *checkError = nil;
        BOOL isInstalled = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"info", cleanPackageName] 
                                                    output:&checkOutput 
                                                     error:&checkError];
        
        if (!isInstalled || ![checkOutput length]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(NO, [NSString stringWithFormat:@"Package '%@' is not installed.", cleanPackageName]);
            }];
            return;
        }
        
        // Start progress monitoring using NSThread
        if (progressBlock) {
            [NSThread detachNewThreadSelector:@selector(monitorUninstallProgressWithBlock:) 
                                     toTarget:self 
                                   withObject:progressBlock];
        }
        
        // Proceed with uninstallation using proper sudo privileges
        NSLog(@"DEBUG: Uninstalling package: %@", cleanPackageName);
        NSString *output = nil;
        NSString *error = nil;
        BOOL uninstallSuccess = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"delete", @"-y", cleanPackageName] 
                                                         output:&output 
                                                          error:&error];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (progressBlock) progressBlock(100);
            
            NSString *errorMessage = nil;
            BOOL finalSuccess = uninstallSuccess;
            
            if (!uninstallSuccess) {
                NSLog(@"DEBUG: Uninstallation failed. Error: %@", error);
                
                if ([error containsString:@"not installed"]) {
                    errorMessage = [NSString stringWithFormat:@"Package '%@' is not installed.", cleanPackageName];
                } else if ([error containsString:@"required by"]) {
                    errorMessage = [NSString stringWithFormat:@"Cannot remove '%@': required by other packages.", cleanPackageName];
                } else if ([error containsString:@"Insufficient privileges"] || [error containsString:@"privilege"]) {
                    errorMessage = @"Insufficient privileges. Please re-authenticate.";
                } else {
                    errorMessage = [NSString stringWithFormat:@"Uninstallation failed: %@", error ?: @"Unknown error"];
                }
            } else {
                NSLog(@"DEBUG: Package %@ uninstalled successfully", cleanPackageName);
            }
            
            completion(finalSuccess, errorMessage);
        }];
    }];
    [queue release];
}

// Helper method for uninstall progress monitoring
- (void)monitorUninstallProgressWithBlock:(ProgressUpdateBlock)progressBlock
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    double currentProgress = 0;
    
    while (currentProgress < 95) {
        currentProgress += 4;
        if (currentProgress > 95) currentProgress = 95;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            progressBlock(currentProgress);
        }];
        
        [NSThread sleepForTimeInterval:0.4];
    }
    
    [pool release];
}

- (void)upgradeAllPackagesWithPassword:(NSString *)password
                              progress:(ProgressUpdateBlock)progressBlock
                            completion:(PackageOperationCompletion)completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSTask *beTask = [[NSTask alloc] init];
        [beTask setLaunchPath:@"/usr/bin/sudo"];
        [beTask setArguments:@[@"-S", @"/sbin/bectl", @"create", @"pre-update"]];
        NSPipe *bePipe = [NSPipe pipe];
        [beTask setStandardInput:bePipe];
        [beTask launch];
        [[bePipe fileHandleForWriting] writeData:[password dataUsingEncoding:NSUTF8StringEncoding]];
        [[bePipe fileHandleForWriting] closeFile];
        [beTask waitUntilExit];
        [beTask release];
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/sudo"];
        [task setArguments:@[@"-S", @"/usr/sbin/pkg", @"upgrade", @"-y"]];
        NSPipe *inputPipe = [NSPipe pipe];
        [task setStandardInput:inputPipe];
        [task launch];
        
        [[inputPipe fileHandleForWriting] writeData:[password dataUsingEncoding:NSUTF8StringEncoding]];
        [[inputPipe fileHandleForWriting] closeFile];
        
        __block double progress = 0;
        while ([task isRunning]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                progress += 10;
                if (progressBlock) progressBlock(progress);
            }];
            [NSThread sleepForTimeInterval:0.1];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            BOOL success = ([task terminationStatus] == 0);
            NSString *errorMessage = success ? nil : @"Upgrade failed. Check logs or repository.";
            completion(success, errorMessage);
        }];
        
        [task release];
    }];
    [queue release];
}

- (void)getPackageInfo:(NSString *)packageName completion:(void (^)(NSString *info, NSString *errorMessage))completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        // FIXED: Clean package name before getting info
        NSString *cleanPackageName = [self cleanPackageNameFromSearchResult:packageName];
        if ([cleanPackageName length] == 0) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(nil, [NSString stringWithFormat:@"Invalid package name: %@", packageName]);
            }];
            return;
        }
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/sbin/pkg"];
        [task setArguments:@[@"info", @"-f", cleanPackageName]];
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        [task launch];
        [task waitUntilExit];
        
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if ([task terminationStatus] == 0) {
                completion(output, nil);
            } else {
                completion(nil, @"Package details not available.");
            }
        }];
        
        [output release];
        [task release];
    }];
    [queue release];
}

#pragma mark - IMPROVED: Package Operations (Cached Authentication) - FIXED

// IMPROVED: Enhanced install method with better checking
- (void)installPackageWithoutPassword:(NSString *)packageName
                             progress:(ImprovedProgressUpdateBlock)progressBlock
                           completion:(PackageOperationCompletion)completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        SudoManager *sudoManager = [SudoManager sharedManager];
        
        if (![sudoManager hasCachedSudoAccess]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(NO, @"No valid sudo session. Please authenticate first.");
            }];
            [queue release];
            return;
        }
        
        // IMPROVED: Better package name validation
        NSString *cleanPackageName = [self cleanPackageNameFromSearchResult:packageName];
        if ([cleanPackageName length] == 0) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(NO, [NSString stringWithFormat:@"Invalid package name: %@", packageName]);
            }];
            [queue release];
            return;
        }
        
        NSLog(@"DEBUG: Attempting to install package: %@ (cleaned: %@)", packageName, cleanPackageName);
        
        // IMPROVED: Check if already installed using enhanced method
        NSString *checkOutput = nil;
        NSString *checkError = nil;
        BOOL isInstalled = [self isPackageInstalled:cleanPackageName output:&checkOutput error:&checkError];
        
        if (!isInstalled) {
            // Try with original name if cleaned name fails
            isInstalled = [self isPackageInstalled:packageName output:&checkOutput error:&checkError];
        }
        
        if (isInstalled) {
            NSLog(@"DEBUG: Package %@ is already installed", packageName);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(YES, nil); // Already installed, consider success
            }];
            [queue release];
            return;
        }
        
        if (progressBlock) {
            [NSThread detachNewThreadSelector:@selector(monitorInstallProgressWithImprovedBlock:) 
                                     toTarget:self 
                                   withObject:progressBlock];
        }
        
        NSLog(@"DEBUG: Installing package: %@", cleanPackageName);
        NSString *output = nil;
        NSString *error = nil;
        BOOL installSuccess = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"install", @"-y", cleanPackageName] 
                                                       output:&output 
                                                        error:&error];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (progressBlock) progressBlock(100, @"Installation complete");
            
            NSString *errorMessage = nil;
            BOOL finalSuccess = installSuccess;
            
            if (!installSuccess) {
                NSLog(@"DEBUG: Installation failed for package: %@. Error: %@", cleanPackageName, error);
                
                if ([error containsString:@"already installed"]) {
                    finalSuccess = YES;
                } else if ([error containsString:@"No packages available"] || [error containsString:@"matching"]) {
                    errorMessage = [NSString stringWithFormat:@"Package '%@' not found in repositories.", cleanPackageName];
                } else if ([error containsString:@"locked"]) {
                    errorMessage = @"Package database is locked. Another package operation may be running.";
                } else if ([error containsString:@"insufficient privileges"]) {
                    errorMessage = @"Insufficient privileges. Please re-authenticate.";
                } else {
                    errorMessage = [NSString stringWithFormat:@"Installation failed: %@", error ?: @"Unknown error"];
                }
            } else {
                NSLog(@"DEBUG: Package %@ installed successfully", cleanPackageName);
            }
            
            completion(finalSuccess, errorMessage);
        }];
        
        [queue release];
    }];
}

// IMPROVED: Enhanced uninstall method with better package checking
- (void)uninstallPackageWithoutPassword:(NSString *)packageName
                               progress:(ImprovedProgressUpdateBlock)progressBlock
                             completion:(PackageOperationCompletion)completion
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        SudoManager *sudoManager = [SudoManager sharedManager];
        
        if (![sudoManager hasCachedSudoAccess]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(NO, @"No valid sudo session. Please authenticate first.");
            }];
            [queue release];
            return;
        }
        
        // IMPROVED: Use better package name validation
        NSString *cleanPackageName = [self cleanPackageNameFromSearchResult:packageName];
        if ([cleanPackageName length] == 0) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(NO, [NSString stringWithFormat:@"Invalid package name: %@", packageName]);
            }];
            [queue release];
            return;
        }
        
        NSLog(@"DEBUG: Attempting to uninstall package: %@ (cleaned: %@)", packageName, cleanPackageName);
        
        // IMPROVED: Use enhanced installation checking
        NSString *checkOutput = nil;
        NSString *checkError = nil;
        BOOL isInstalled = [self isPackageInstalled:cleanPackageName output:&checkOutput error:&checkError];
        
        if (!isInstalled) {
            NSLog(@"DEBUG: Package not found, trying original name: %@", packageName);
            // Try with original name if cleaned name fails
            isInstalled = [self isPackageInstalled:packageName output:&checkOutput error:&checkError];
        }
        
        if (!isInstalled) {
            NSLog(@"DEBUG: Package %@ is definitely not installed", packageName);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(NO, [NSString stringWithFormat:@"Package '%@' is not installed.", packageName]);
            }];
            [queue release];
            return;
        }
        
        NSLog(@"DEBUG: Package confirmed installed, proceeding with uninstall");
        
        if (progressBlock) {
            [NSThread detachNewThreadSelector:@selector(monitorUninstallProgressWithImprovedBlock:) 
                                     toTarget:self 
                                   withObject:progressBlock];
        }
        
        // IMPROVED: Try multiple package names for uninstall
        NSString *packageToUninstall = cleanPackageName;
        
        // Extract actual package name from pkg info output if available
        if (checkOutput && [checkOutput length] > 0) {
            NSArray *lines = [checkOutput componentsSeparatedByString:@"\n"];
            for (NSString *line in lines) {
                if ([line hasPrefix:@"Name"]) {
                    NSArray *nameParts = [line componentsSeparatedByString:@":"];
                    if ([nameParts count] >= 2) {
                        NSString *actualName = [[nameParts objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        if ([actualName length] > 0) {
                            packageToUninstall = actualName;
                            NSLog(@"DEBUG: Using actual package name from pkg info: %@", packageToUninstall);
                            break;
                        }
                    }
                }
            }
        }
        
        NSLog(@"DEBUG: Uninstalling package: %@", packageToUninstall);
        NSString *output = nil;
        NSString *error = nil;
        BOOL uninstallSuccess = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"delete", @"-y", packageToUninstall] 
                                                         output:&output 
                                                          error:&error];
        
        // If first attempt fails, try with original package name
        if (!uninstallSuccess && ![packageToUninstall isEqualToString:packageName]) {
            NSLog(@"DEBUG: First uninstall attempt failed, trying with original name: %@", packageName);
            uninstallSuccess = [sudoManager executeSudoCommand:@[@"/usr/sbin/pkg", @"delete", @"-y", packageName] 
                                                        output:&output 
                                                         error:&error];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (progressBlock) progressBlock(100, @"Uninstallation complete");
            
            NSString *errorMessage = nil;
            BOOL finalSuccess = uninstallSuccess;
            
            if (!uninstallSuccess) {
                NSLog(@"DEBUG: Uninstallation failed for package: %@. Error: %@", packageToUninstall, error);
                
                if ([error containsString:@"not installed"]) {
                    errorMessage = [NSString stringWithFormat:@"Package '%@' is not installed.", packageName];
                } else if ([error containsString:@"required by"]) {
                    errorMessage = [NSString stringWithFormat:@"Cannot remove '%@': required by other packages.", packageName];
                } else if ([error containsString:@"insufficient privileges"]) {
                    errorMessage = @"Insufficient privileges. Please re-authenticate.";
                } else {
                    errorMessage = [NSString stringWithFormat:@"Uninstallation failed: %@", error ?: @"Unknown error"];
                }
            } else {
                NSLog(@"DEBUG: Package %@ uninstalled successfully", packageToUninstall);
            }
            
            completion(finalSuccess, errorMessage);
        }];
        
        [queue release];
    }];
}

- (void)monitorInstallProgressWithImprovedBlock:(ImprovedProgressUpdateBlock)progressBlock
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    double currentProgress = 0;
    NSArray *statusMessages = @[
        @"Downloading package...",
        @"Installing files...",
        @"Finalizing installation..."
    ];
    
    NSInteger statusIndex = 0;
    
    while (currentProgress < 95) {
        currentProgress += 5;
        if (currentProgress > 95) currentProgress = 95;
        
        if ((int)currentProgress % 30 == 0 && statusIndex < [statusMessages count] - 1) {
            statusIndex++;
        }
        
        NSString *currentStatus = [statusMessages objectAtIndex:statusIndex];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            progressBlock(currentProgress, currentStatus);
        }];
        
        [NSThread sleepForTimeInterval:0.3];
    }
    
    [pool release];
}

- (void)monitorUninstallProgressWithImprovedBlock:(ImprovedProgressUpdateBlock)progressBlock
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    double currentProgress = 0;
    NSArray *statusMessages = @[
        @"Checking dependencies...",
        @"Removing files...",
        @"Cleaning up..."
    ];
    
    NSInteger statusIndex = 0;
    
    while (currentProgress < 95) {
        currentProgress += 6;
        if (currentProgress > 95) currentProgress = 95;
        
        if ((int)currentProgress % 30 == 0 && statusIndex < [statusMessages count] - 1) {
            statusIndex++;
        }
        
        NSString *currentStatus = [statusMessages objectAtIndex:statusIndex];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            progressBlock(currentProgress, currentStatus);
        }];
        
        [NSThread sleepForTimeInterval:0.2];
    }
    
    [pool release];
}

#pragma mark - Memory Management

- (void)dealloc
{
    [searchCache release];
    [categoryCache release];
    [metadata release];
    [categoryMappings release];
    [super dealloc];
}

@end
