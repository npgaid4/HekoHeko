//
//  AppDelegate.m
//  HekoHeko
//
//  Created by 坂根英治 on 2021/04/24.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *statusMenu;


@end

@implementation AppDelegate
{
    NSStatusItem *_statusItem;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self setupStatusItem];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

/*
 
 */
- (void)setupStatusItem {
    
    NSArray *menuNames = [self getWindowList];
    
    if(menuNames){
        for(int i = 0;i < menuNames.count;i++){
            NSLog(@"%u %@",i, menuNames[i]);
            NSMenuItem *menuItem = [[NSMenuItem alloc]initWithTitle:menuNames[i] action:nil keyEquivalent:@""];
            [self.statusMenu insertItem:menuItem atIndex:[self.statusMenu numberOfItems] - 1];
        }

    }
    
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
    _statusItem = [systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.button.title = @"HekoHeko";
    _statusItem.button.image = [NSImage imageNamed:@"heko3"];
    [_statusItem setMenu:self.statusMenu];
}
/*
 現在起動しているアプリ名の一覧を取得する
 */
- (NSArray*)getWindowList {
    NSMutableArray *windowNames = [[NSMutableArray alloc]init];
    
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
    // デスクトップに表示されている全Windowからアプリ名を取得する
    for(int i = 0; i < CFArrayGetCount(windowList);i++){
        CFDictionaryRef window = CFArrayGetValueAtIndex(windowList, i);

        CFStringRef name = CFDictionaryGetValue(window, kCGWindowOwnerName);
        if(name){
            if(kCFCompareEqualTo == CFStringCompare(name, CFSTR("Dock"), kCFCompareCaseInsensitive)){
                continue;
            }
            
            if(kCFCompareEqualTo == CFStringCompare(name, CFSTR("Window Server"), kCFCompareCaseInsensitive)){
                continue;
            }
        }

        // windows表示されてないと思うアプリを排除する。
        NSNumber* walpha = CFDictionaryGetValue(window, kCGWindowAlpha);
        int ai = walpha.intValue;
        if(ai == 0){
            continue;
        }
        
        CFDictionaryRef bounds = CFDictionaryGetValue(window, kCGWindowBounds);

        CGRect cgr;
        if(CGRectMakeWithDictionaryRepresentation(bounds, &cgr)){
            if((cgr.size.width < 100) || (cgr.size.height < 100)){
                continue;
            }
        }
        
        NSNumber *wid = CFDictionaryGetValue(window, kCGWindowNumber);
        CGImageRef cap = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, wid.unsignedIntValue, kCGWindowImageDefault);
        
        if(CGImageGetWidth(cap) < 1){
            continue;
        }
        if(CGImageGetHeight(cap) < 1){
            continue;
        }
        
        if(name){
            [windowNames addObject:(NSString*)CFBridgingRelease(name)];
        }
    }
    return windowNames;
}
@end
