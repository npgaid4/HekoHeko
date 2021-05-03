//
//  AppDelegate.m
//  HekoHeko
//
//  Created by 坂根英治 on 2021/04/24.
//

#import "AppDelegate.h"
#import "Wins.h"

#define MAX_DISPLAYS 32
#define MINUTES 60.0

@interface AppDelegate () <NSMenuDelegate>
@property (weak) IBOutlet NSMenu *statusMenu;


@end

@implementation AppDelegate


// インスタンス変数
{
    NSStatusItem *_statusItem;
    NSMutableArray<Wins*> *wins;
    NSInteger enableIndex;
    CGDirectDisplayID displays[MAX_DISPLAYS];
    NSTimer *tm;
    unsigned int timerMinutes;
    NSTextField *label;
    CGPoint movePoint;
    BOOL isTimer;
    NSSwitch *timerOnOff;
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    timerMinutes = 1;
    isTimer = YES;
    [self setupStatusItem];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)stopTimer:(NSMenuItem *)sender {
    if([tm isValid]){
        [tm invalidate];
        isTimer = NO;
    }
}

/*
 menu を選択したとき実行される関数
 */
- (void)menuAction:(NSMenuItem*)sender {
    // meunのチェックマークを消す
    NSArray *menuitems = self.statusMenu.itemArray;
    for(id n in menuitems){
        [n setState:NSControlStateValueOff];
    }
 
    [sender state] == NSControlStateValueOn ? [sender setState:NSControlStateValueOff]: [sender setState:NSControlStateValueOn];

    enableIndex = [self.statusMenu indexOfItem:sender];
    CGRect window = wins[enableIndex].bounds;
    CGFloat mX = CGRectGetMidX(window);
    CGFloat mY = CGRectGetMidY(window);
    unsigned int displayCount;
    CGGetActiveDisplayList(MAX_DISPLAYS, displays, &displayCount);
    NSLog(@"x %f y %f",mX,mY);
    
    movePoint.x = mX;
    movePoint.y = mY;
    
}

-(void)moveCursor {
    int moveCount = 2;
    
    CGEventRef ourEvent = CGEventCreate(NULL);
    CGPoint currentPoint = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    NSLog(@"Location? x= %f, y = %f", (float)currentPoint.x, (float)currentPoint.y);

    for(int i = 0;i < moveCount;i++){
        CGDisplayMoveCursorToPoint(0, movePoint);
        sleep(1);
        movePoint.x = movePoint.x + 10;
        CGDisplayMoveCursorToPoint(0, movePoint);
        sleep(1);
        movePoint.x = movePoint.x - 10;
    }
    
    CGDisplayMoveCursorToPoint(0, (CGPoint)currentPoint);

    NSLog(@"処理終了");
}

-(void)updateMenuText {
    
}

-(void)getSliderValue:(NSSlider*)sender {
    timerMinutes =  (unsigned int)[sender floatValue];
    NSString *timerText = [[NSString alloc] initWithFormat:@"タイマー値: %d 分", timerMinutes];
    [label setStringValue:timerText];
    
}

-(void)getTimerSwitch:(NSSwitch*)sender {
    if([timerOnOff state] == NSControlStateValueOn){
        [timerOnOff setState:NSControlStateValueOff];
        isTimer = NO;
    }else{
        [timerOnOff setState:NSControlStateValueOn];
        isTimer = YES;
    }
    
}

/*
   ステータスバーに表示するmenuを作成
 */
- (void)setupStatusItem {
    
    wins = [[NSMutableArray alloc]init];
    NSArray *menuNames = [self getWindowList];
 
    
    if(menuNames){
        for(int i = 0;i < menuNames.count;i++){
            NSLog(@"%u %@",i, menuNames[i]);
            NSMenuItem *menuItem = [[NSMenuItem alloc]initWithTitle:[wins[i] appName] action:@selector(menuAction:) keyEquivalent:@""];
            [self.statusMenu insertItem:menuItem atIndex:[self.statusMenu numberOfItems] - 4];
        }

    }
    
    timerOnOff = [[NSSwitch alloc]initWithFrame:NSMakeRect(0, 0, 50, 30)];
    [timerOnOff setState:NSControlStateValueOff];
    [timerOnOff setAction:@selector(getTimerSwitch:)];
    [timerOnOff setEnabled:YES];
    
    NSMenuItem *timerSwitch = [[NSMenuItem alloc]init];
    [timerSwitch setView:timerOnOff];
    [timerSwitch setTarget:self];
    [self.statusMenu insertItem: timerSwitch atIndex:0];
    
    
    
    label = [[NSTextField alloc]initWithFrame:NSMakeRect(0, 0, 120, 20)];
    NSString *timerText = [[NSString alloc] initWithFormat:@"タイマー値: %d 分", timerMinutes];
    [label setStringValue:timerText];
    [label setDrawsBackground:NO];
    [label setBordered:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    
    NSMenuItem *sliderText = [[NSMenuItem alloc]init];

    [sliderText setView:label];
    [self.statusMenu insertItem: sliderText atIndex:[self.statusMenu numberOfItems] - 2];
    
    NSSlider *slider = [[NSSlider alloc]init];
    [slider setFrameSize:NSMakeSize(120, 30)];
    [slider setMinValue:1];
    [slider setMaxValue:5];
    [slider setIntValue:1];
    [slider setNumberOfTickMarks:5];
    [slider setAllowsTickMarkValuesOnly:YES];
    [slider setAction:@selector(getSliderValue:)];
    
    NSMenuItem *sliderMenu = [[NSMenuItem alloc]init];

    [sliderMenu setTitle:@"slider1"];
    [sliderMenu setView:slider];
    
    [self.statusMenu insertItem:sliderMenu atIndex:[self.statusMenu numberOfItems] - 2];
    
    
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
    _statusItem = [systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.button.title = @"HekoHeko";
    _statusItem.button.image = [NSImage imageNamed:@"heko3"];
    [_statusItem setMenu:self.statusMenu];
    [self.statusMenu setDelegate:self];
    
}

-(void)menuDidClose:(NSMenu*)aMenu{
    if([tm isValid]){
        [tm invalidate];
    }
    if(isTimer){
        NSLog(@"タイマー値 %d",timerMinutes);
        tm = [NSTimer timerWithTimeInterval:(timerMinutes * MINUTES) target:self selector:@selector(moveCursor) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:tm forMode:NSRunLoopCommonModes];
    }
}

/*
 現在起動しているアプリ名の一覧を取得する
 */
- (NSArray*)getWindowList {

     
    NSMutableArray *windowNames = [[NSMutableArray alloc]init];
    
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
    // デスクトップに表示されている全Windowからアプリ名を取得する
    for(int i = 0; i < CFArrayGetCount(windowList);i++){

        Wins *winss = [[Wins alloc]init];
        
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
        
        
        // windowが表示されてないと思うアプリを排除する。
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
        
        if(winss){
            [winss setAppName:(NSString*)CFBridgingRelease(name)];
            [winss setBounds:cgr];
            [winss setWindowsid:wid.unsignedIntValue];
            [wins addObject:(Wins*)winss];

        }
        
    }
    return windowNames;
}


@end
