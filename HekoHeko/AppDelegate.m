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
    unsigned int timerMinutes, previousTimerMinutes;
    NSTextField *label, *menus;
    CGPoint movePoint;
    BOOL isSelectApp;
    NSButton *timerOnOff;
    BOOL isDirty;
    int menuOffset;
    
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    timerMinutes = previousTimerMinutes = 1;
    isSelectApp = NO;
    movePoint.x = 0;
    movePoint.y = 0;
    [self setupStatusItem];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


/*
 menu を選択したとき実行される関数
 */
- (void)menuAction:(NSMenuItem*)sender {
    
    NSMenuItem *prev = [self.statusMenu itemAtIndex:enableIndex];

    if(enableIndex != [self.statusMenu indexOfItem:sender]){
        [prev setState:NSControlStateValueOff];
        [sender setState:NSControlStateValueOn];
        enableIndex = [self.statusMenu indexOfItem:sender];
        CGRect window = wins[enableIndex - menuOffset].bounds;
        CGFloat mX = CGRectGetMidX(window);
        CGFloat mY = CGRectGetMidY(window);
        unsigned int displayCount;
        CGGetActiveDisplayList(MAX_DISPLAYS, displays, &displayCount);
        NSLog(@"x %f y %f",mX,mY);
        
        movePoint.x = mX;
        movePoint.y = mY;
        isSelectApp = YES; // it will change the timer setting.
        [self timerSetting];
    }else{
        [prev setState:NSControlStateValueOff];
        isSelectApp = NO;
        if([tm isValid]){
            [tm invalidate];
            NSLog(@"タイマー停止");
        }

    }
}

-(void)moveCursor {
    int moveCount = 2;
    NSLog(@"タイマー処理開始");
    CGEventRef ourEvent = CGEventCreate(NULL);
    CGPoint currentPoint = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
    
    CGEventRef ourEvent2 = CGEventCreate(NULL);
    CGPoint currentPoint2 = CGEventGetLocation(ourEvent2);
    CFRelease(ourEvent2);
    
    NSLog(@"current1 x = %f y = %f",currentPoint.x,currentPoint.y);
    NSLog(@"current2 x = %f y = %f",currentPoint2.x,currentPoint2.y);

    // mouse が操作されていないときだけやる
    if(currentPoint.x == currentPoint2.x && currentPoint.y == currentPoint2.y){
        NSLog(@"mouse移動 x = %f y = %f",movePoint.x,movePoint.y);
        for(int i = 0;i < moveCount;i++){
            CGDisplayMoveCursorToPoint(0, movePoint);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
            movePoint.x = movePoint.x + 10;
            CGDisplayMoveCursorToPoint(0, movePoint);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
            movePoint.x = movePoint.x - 10;
        }
        
        CGDisplayMoveCursorToPoint(0, (CGPoint)currentPoint);
    }
    NSLog(@"タイマー処理終了");
}


-(void)getSliderValue:(NSSlider*)sender {
    timerMinutes =  (unsigned int)[sender floatValue];

    if(timerMinutes != previousTimerMinutes){
        isDirty = YES;
    }else{
        isDirty = NO; // 前回メニューを閉じたときと同じ値ならタイマー変更しない
    }
    
    NSString *timerText = [[NSString alloc] initWithFormat:@"タイマー値: %d 分", timerMinutes];
    [label setStringValue:timerText];
}

/*
   ステータスバーに表示するmenuを作成
 */
-(void)setupStatusItem {
    
    wins = [[NSMutableArray alloc]init];
    NSArray *menuNames = [self getWindowList];
 
    
    if(menuNames){
        for(int i = 0;i < menuNames.count;i++){
            NSLog(@"%u %@",i, menuNames[i]);
            NSMenuItem *menuItem = [[NSMenuItem alloc]initWithTitle:[wins[i] appName] action:@selector(menuAction:) keyEquivalent:@""];
            [self.statusMenu insertItem:menuItem atIndex:[self.statusMenu numberOfItems] - 2];
        }

    }
    

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
    
    [self.statusMenu insertItem:sliderMenu atIndex:0];
    
    label = [[NSTextField alloc]initWithFrame:NSMakeRect(0, 0, 120, 20)];
    NSString *timerText = [[NSString alloc] initWithFormat:@"タイマー値: %d 分", timerMinutes];
    [label setStringValue:timerText];
    [label setDrawsBackground:NO];
    [label setBordered:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    
    NSMenuItem *sliderText = [[NSMenuItem alloc]init];

    [sliderText setView:label];
    [self.statusMenu insertItem: sliderText atIndex:0];
    //横棒
    [self.statusMenu insertItem:[NSMenuItem separatorItem] atIndex:2];
    
    NSTextField *atxt = [[NSTextField alloc]initWithFrame:NSMakeRect(0, 0, 120, 20)];
    [atxt setStringValue:@"起動中アプリ一覧"];
    [atxt setDrawsBackground:NO];
    [atxt setBordered:NO];
    [atxt setEditable:NO];
    [atxt setSelectable:NO];
    
    NSMenuItem *aText = [[NSMenuItem alloc]init];

    [aText setView:atxt];
    [self.statusMenu insertItem: aText atIndex:3];

    menuOffset = 4; //winsのindexとmenuIndexをあわせるためのアプリ一覧までのoffset数
    
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
    _statusItem = [systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.button.title = @"HekoHeko";
    _statusItem.button.image = [NSImage imageNamed:@"heko3"];
    [_statusItem setMenu:self.statusMenu];
    [self.statusMenu setDelegate:self];
    
}

-(void)timerSetting{
    if([tm isValid]){
        [tm invalidate];
        NSLog(@"タイマー停止");
    }

    NSLog(@"タイマー開始 タイマー値 %d",timerMinutes);
    tm = [NSTimer timerWithTimeInterval:(timerMinutes * MINUTES) target:self selector:@selector(moveCursor) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:tm forMode:NSRunLoopCommonModes];
}

-(void)menuDidClose:(NSMenu*)aMenu{

    if(isDirty && isSelectApp){
        [self timerSetting];
    }
    previousTimerMinutes = timerMinutes;
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
