#import <AppKit/AppKit.h>

@protocol CategoryWindowDelegate;

@interface CategoryWindow : NSObject

@property (nonatomic, retain) NSWindow *window;
@property (nonatomic, retain) NSTableView *categoryTable;
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, assign) id<CategoryWindowDelegate> delegate;

- (void)showCategoryWindow;
- (void)loadCategories;

@end

@protocol CategoryWindowDelegate <NSObject>

- (void)categoryWindow:(CategoryWindow *)categoryWindow didSelectCategory:(NSString *)category;

@end
