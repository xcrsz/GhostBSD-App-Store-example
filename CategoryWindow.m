#import "CategoryWindow.h"

@interface CategoryWindow () <NSTableViewDataSource, NSTableViewDelegate>
@end

@implementation CategoryWindow

@synthesize window, categoryTable, categories, delegate;

- (id)init
{
    self = [super init];
    if (self) {
        categories = [[NSMutableArray alloc] init];
        [self loadCategories];
    }
    return self;
}

- (void)loadCategories
{
    // Popular software categories with descriptions
    NSArray *categoryData = @[
        @{@"name": @"multimedia", @"display": @"Multimedia", @"description": @"Audio, video, and media applications"},
        @{@"name": @"www", @"display": @"Web Browsers", @"description": @"Web browsers and internet tools"},
        @{@"name": @"editors", @"display": @"Text Editors", @"description": @"Text and code editors"},
        @{@"name": @"graphics", @"display": @"Graphics", @"description": @"Image editing and graphics software"},
        @{@"name": @"games", @"display": @"Games", @"description": @"Games and entertainment software"},
        @{@"name": @"devel", @"display": @"Development", @"description": @"Programming tools and IDEs"},
        @{@"name": @"sysutils", @"display": @"System Utilities", @"description": @"System administration tools"},
        @{@"name": @"security", @"display": @"Security", @"description": @"Security and encryption tools"},
        @{@"name": @"net", @"display": @"Network", @"description": @"Network utilities and tools"},
        @{@"name": @"math", @"display": @"Mathematics", @"description": @"Mathematical software and calculators"},
        @{@"name": @"science", @"display": @"Science", @"description": @"Scientific applications and tools"},
        @{@"name": @"databases", @"display": @"Databases", @"description": @"Database software and tools"},
        @{@"name": @"archivers", @"display": @"Archivers", @"description": @"Compression and archive tools"},
        @{@"name": @"emulators", @"display": @"Emulators", @"description": @"System and console emulators"},
        @{@"name": @"finance", @"display": @"Finance", @"description": @"Financial and accounting software"},
        @{@"name": @"ftp", @"display": @"FTP", @"description": @"FTP clients and servers"},
        @{@"name": @"irc", @"display": @"Chat/IRC", @"description": @"Chat clients and IRC software"},
        @{@"name": @"mail", @"display": @"Email", @"description": @"Email clients and mail servers"},
        @{@"name": @"news", @"display": @"News", @"description": @"News readers and RSS clients"},
        @{@"name": @"print", @"display": @"Printing", @"description": @"Printing and document tools"}
    ];
    
    [categories removeAllObjects];
    [categories addObjectsFromArray:categoryData];
}

- (void)showCategoryWindow
{
    if (window) {
        [window makeKeyAndOrderFront:nil];
        return;
    }
    
    // Create category selection window
    window = [[NSWindow alloc] initWithContentRect:NSMakeRect(200, 200, 500, 400)
                                        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask
                                          backing:NSBackingStoreBuffered
                                            defer:NO];
    [window setTitle:@"Select Category"];
    [window setMinSize:NSMakeSize(400, 300)];
    
    // Create title label
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 360, 460, 24)];
    [titleLabel setStringValue:@"Choose a software category to browse:"];
    [titleLabel setBezeled:NO];
    [titleLabel setDrawsBackground:NO];
    [titleLabel setEditable:NO];
    [titleLabel setFont:[NSFont boldSystemFontOfSize:14]];
    [[window contentView] addSubview:titleLabel];
    
    // Create scroll view and table
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 60, 460, 290)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:NSBezelBorder];
    
    categoryTable = [[NSTableView alloc] initWithFrame:[scrollView bounds]];
    [categoryTable setDataSource:self];
    [categoryTable setDelegate:self];
    [categoryTable setAllowsMultipleSelection:NO];
    
    // Create table columns
    NSTableColumn *nameColumn = [[NSTableColumn alloc] initWithIdentifier:@"name"];
    [nameColumn setTitle:@"Category"];
    [nameColumn setWidth:150];
    [nameColumn setMinWidth:100];
    [nameColumn setMaxWidth:200];
    
    NSTableColumn *descColumn = [[NSTableColumn alloc] initWithIdentifier:@"description"];
    [descColumn setTitle:@"Description"];
    [descColumn setWidth:290];
    [descColumn setMinWidth:200];
    
    [categoryTable addTableColumn:nameColumn];
    [categoryTable addTableColumn:descColumn];
    
    [scrollView setDocumentView:categoryTable];
    [[window contentView] addSubview:scrollView];
    
    // Create buttons
    NSButton *selectButton = [[NSButton alloc] initWithFrame:NSMakeRect(400, 20, 80, 30)];
    [selectButton setTitle:@"Select"];
    [selectButton setBezelStyle:NSRoundedBezelStyle];
    [selectButton setTarget:self];
    [selectButton setAction:@selector(selectCategory:)];
    [selectButton setKeyEquivalent:@"\r"]; // Enter key
    [[window contentView] addSubview:selectButton];
    
    NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(310, 20, 80, 30)];
    [cancelButton setTitle:@"Cancel"];
    [cancelButton setBezelStyle:NSRoundedBezelStyle];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancelSelection:)];
    [cancelButton setKeyEquivalent:@"\033"]; // Escape key
    [[window contentView] addSubview:cancelButton];
    
    // Set double-click action
    [categoryTable setDoubleAction:@selector(selectCategory:)];
    
    [window center];
    [window makeKeyAndOrderFront:nil];
    
    // Cleanup
    [titleLabel release];
    [scrollView release];
    [nameColumn release];
    [descColumn release];
    [selectButton release];
    [cancelButton release];
}

- (void)selectCategory:(id)sender
{
    NSInteger selectedRow = [categoryTable selectedRow];
    if (selectedRow < 0) {
        NSRunAlertPanel(@"No Selection", @"Please select a category first.", @"OK", nil, nil);
        return;
    }
    
    NSDictionary *categoryInfo = [categories objectAtIndex:selectedRow];
    NSString *categoryName = [categoryInfo objectForKey:@"name"];
    
    [window orderOut:nil];
    
    if (delegate && [delegate respondsToSelector:@selector(categoryWindow:didSelectCategory:)]) {
        [delegate categoryWindow:self didSelectCategory:categoryName];
    }
}

- (void)cancelSelection:(id)sender
{
    [window orderOut:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [categories count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *categoryInfo = [categories objectAtIndex:row];
    
    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        return [categoryInfo objectForKey:@"display"];
    } else if ([[tableColumn identifier] isEqualToString:@"description"]) {
        return [categoryInfo objectForKey:@"description"];
    }
    
    return @"";
}

#pragma mark - Table View Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    // Optional: Could show more details about selected category here
}

- (void)dealloc
{
    [window release];
    [categoryTable release];
    [categories release];
    [super dealloc];
}

@end
