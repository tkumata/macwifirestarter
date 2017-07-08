//
//  AppDelegate.m
//  WiFirestarter
//
//  Created by KUMATA Tomokatsu on 3/8/15.
//  Copyright (c) 2015 KUMATA Tomokatsu. All rights reserved.
//

#import "AppDelegate.h"
#include <arpa/inet.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenuItem *statusMenu;

@end

@implementation AppDelegate {
    NSStatusItem *_statusItem;
    NSString *titleString;
    NSString *command;
    NSTimer *myTimer;
    
    float interval;
    float pingTime;
    float pingResponseTime;
    
    NSString *ifaceName;
    int displayNoSleep;
    int debugMode;
    
    NSImage *imageWifiOK;
    NSImage *imageWifiNG;
    NSImage *imageWifiNoTimer;
    
    int restarting;
}

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification {
    // Insert code here to initialize your application
    interval = 10.0f;    // interval, second
    pingTime = 100.0f;   // response, mili second
    displayNoSleep = 1;
    debugMode = 0;
    pingResponseTime = 0;
    restarting = 0;
    
    imageWifiOK = [NSImage imageNamed:@"wifiok"];
    [imageWifiOK setTemplate:YES];
    imageWifiNG = [NSImage imageNamed:@"wifing"];
    imageWifiNoTimer = [NSImage imageNamed:@"wifinotimer"];
    
    //
    NSLog(@"WiFirestarter started.");
    
    // Set Menu
    [self setupStatusItem];

    //
    // First Check
    [self checkNetwork];
    
    // Event - receive sleep signal
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification
                                                             object: nil];
    // Event - receive wake signal
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification
                                                             object: nil];
    // Set Timer
    myTimer = [NSTimer scheduledTimerWithTimeInterval: interval
                                               target: self
                                             selector: @selector(timerCall:)
                                             userInfo: nil
                                              repeats: YES];
}

- (void)applicationWillTerminate: (NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Timer

- (void)timerCall: (NSTimer *)timer {
    if (displayNoSleep == 1) {
        [self checkNetwork];
    }
}

#pragma mark - When receive sleep notification on Mac

- (void)receiveSleepNote: (NSNotification *)note {
    NSLog(@"%@", [note name]);
    displayNoSleep = 0;
    
    // Stop timer
    [myTimer invalidate];
}

#pragma mark - When receive wake up notification on Mac

- (void)receiveWakeNote: (NSNotification *)note {
    NSLog(@"%@", [note name]);
    displayNoSleep = 1;
    
    // MARK: Start timer again
    if (interval != 0) {
        [self checkNetwork];
        myTimer = [NSTimer scheduledTimerWithTimeInterval: interval
                                                   target: self
                                                 selector: @selector(timerCall:)
                                                 userInfo: nil
                                                  repeats: YES];
    }
}

#pragma mark - Set init statusbar items

- (void)setupStatusItem {
    // Get interface
    ifaceName = [self getIFname];
    
    // Get version
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [info objectForKey: @"CFBundleShortVersionString"];
    
    // Submenu 2
    NSMenu *submenu2 = [[NSMenu alloc] init];
    [submenu2 addItemWithTitle: @"2000 ms"
                        action: @selector(pingResThreshold:)
                 keyEquivalent: @""];
    [submenu2 addItemWithTitle: @"1500 ms"
                        action: @selector(pingResThreshold:)
                 keyEquivalent: @""];
    [submenu2 addItemWithTitle: @"1000 ms"
                        action: @selector(pingResThreshold:)
                 keyEquivalent: @""];
    [submenu2 addItemWithTitle: @"100 ms"
                        action: @selector(pingResThreshold:)
                 keyEquivalent: @""];
    
    // Submenu 1
    NSMenu *submenu = [[NSMenu alloc] init];
    [submenu addItemWithTitle: @"300 sec"
                       action: @selector(interval:)
                keyEquivalent: @""];
    [submenu addItemWithTitle: @"120 sec"
                       action: @selector(interval:)
                keyEquivalent: @""];
    [submenu addItemWithTitle: @"20 sec"
                       action: @selector(interval:)
                keyEquivalent: @""];
    [submenu addItemWithTitle: @"10 sec"
                       action: @selector(interval:)
                keyEquivalent: @""];
    [submenu addItemWithTitle: @"No Repeat"
                       action: @selector(norepeat)
                keyEquivalent: @""];
    
    // Main Menu
    NSMenu *menu = [[NSMenu alloc] init];
    // Show version
    [menu addItemWithTitle: [NSString stringWithFormat: @"Version: %@", version]
                    action: nil
             keyEquivalent: @""];
    // Show Wi-Fi Interface
    [menu addItemWithTitle: [NSString stringWithFormat: @"Wi-Fi Interface: %@", ifaceName]
                    action: nil
             keyEquivalent: @""];
    // Show ping response time
    [menu addItemWithTitle: [NSString stringWithFormat: @"ICMP Response: %5.1f ms", pingResponseTime]
                    action: nil
             keyEquivalent: @""];
    // Show Last checking date time
    [menu addItemWithTitle: @"Last Date:"
                    action: nil
             keyEquivalent: @""];
    // Separator
    [menu addItem: [NSMenuItem separatorItem]];
    // Submenu Checking interval
    [menu setSubmenu: submenu forItem: [menu addItemWithTitle: @"Interval ICMP Request"
                                                       action: nil
                                                keyEquivalent: @""]];
    // Submenu 2 Threshold ICMP response time
    [menu setSubmenu: submenu2 forItem: [menu addItemWithTitle: @"Threshold ICMP Response"
                                                        action: nil
                                                 keyEquivalent: @""]];
    // Manual Checking
    [menu addItemWithTitle: @"ICMP Reqquest Now"
                    action: @selector(checkNetwork)
             keyEquivalent: @""];
    // Manual restart
    if (ifaceName != NULL) {
        [menu addItemWithTitle: [NSString stringWithFormat: @"Turn Wi-Fi(%@) Off/On", ifaceName]
                        action: @selector(RestartWiFi)
                 keyEquivalent: @"r"];
    } else {
        [menu addItemWithTitle: @"Wi-Fi interface not found."
                        action: nil
                 keyEquivalent: @""];
    }
    // for debug mode
    [menu addItemWithTitle: @"for AppleSeed User"
                    action: @selector(debugmode)
             keyEquivalent: @""];
    // Separator
    [menu addItem: [NSMenuItem separatorItem]];
    // Quit App
    [menu addItemWithTitle: @"Quit WiFirestarter"
                    action: @selector(terminate:)
             keyEquivalent: @"q"];
    
    // Make menu in statusbar
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
    _statusItem = [systemStatusBar statusItemWithLength: NSVariableStatusItemLength];
    [_statusItem setImage: imageWifiOK];
    [_statusItem setEnabled: YES];
    [_statusItem setHighlightMode: YES];
    [_statusItem setMenu: menu];
}

#pragma mark - Check Wi-Fi connection by ICMP

- (void)checkNetwork {
    // Get last checking date
    NSDate *checkingTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *datetimeStr = [dateFormatter stringFromDate: checkingTime];
    
    // Apply last date to menu
    [_statusItem.menu removeItemAtIndex: 3];
    [_statusItem.menu insertItemWithTitle: [NSString stringWithFormat: @"Last Date: %@", datetimeStr]
                                   action: nil
                            keyEquivalent: @""
                                  atIndex: 3];
    
    if (restarting == 0) {
        // Get Wi-Fi interface name
        ifaceName = [self getIFname];
        
        if (ifaceName == NULL) {
            // Not found interface
            [_statusItem.menu removeItemAtIndex: 1];
            [_statusItem.menu insertItemWithTitle: @"Wi-Fi interface not found."
                                           action: nil
                                    keyEquivalent: @""
                                          atIndex: 1];
        } else {
            // Found interface
            [_statusItem.menu removeItemAtIndex: 1];
            [_statusItem.menu insertItemWithTitle: [NSString stringWithFormat: @"Wi-Fi Interface: %@", ifaceName]
                                           action: nil
                                    keyEquivalent: @""
                                          atIndex: 1];
        }
        
        // Get default route address
        NSString *defaultRouterAddr = [self getDefaultRouter];
        
        //
        if ([self isValidIPAddress: defaultRouterAddr] == 1) {
            // Get ICMP response time
            pingResponseTime = [self getICMPresponse: defaultRouterAddr];
            
            // Change menu item
            [_statusItem.menu removeItemAtIndex: 2];
            [_statusItem.menu insertItemWithTitle: [NSString stringWithFormat: @"ICMP Response: %5.1f ms", pingResponseTime]
                                           action: nil
                                    keyEquivalent: @""
                                          atIndex: 2];
            
            // Processing
            if (pingResponseTime > 0 && pingResponseTime <= pingTime) {
                // Wi-Fi OK
                [_statusItem setImage: imageWifiOK];
//                NSLog(@"ICMP response OK: %f ms, %@", pingResponseTime, defaultRouterAddr);
            } else {
                // Wi-Fi NG
                [_statusItem setImage: imageWifiNG];
//                NSLog(@"ICMP response NG: %f ms, %@", pingResponseTime, defaultRouterAddr);
                
                if (debugMode == 0) {
                    // Normal mode
                    
                    // Restart Wi-Fi
                    [self RestartWiFi];
                    
                    // Notification
                    NSUserNotification *myNotification = [[NSUserNotification alloc] init];
                    myNotification.title = @"ICMP No Response";
                    myNotification.informativeText = @"Wi-Fi has been restarted.";
                    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification: myNotification];
                } else {
                    // Debug mode for AppleSeed User
                    
                    // CLI command for debug.
                    NSString *s = [NSString stringWithFormat:@"tell application \"Terminal\" to do script \"sudo /usr/libexec/airportd msglevel 0x0000000200000101 && sudo tcpdump -i %@ -s 0 -w ~/Desktop/DumpFile.pcap & sudo /System/Library/Frameworks/SystemConfiguration.framework/Resources/get-mobility-info & sudo sysdiagnose\"", ifaceName];
                    NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
                    [as executeAndReturnError: nil];
                    
                    // Stop timer
                    [myTimer invalidate];
                    
                    // Notification
                    NSUserNotification *myNotification = [[NSUserNotification alloc] init];
                    myNotification.title = @"ICMP No Response";
                    myNotification.informativeText = @"Timer is stoped. Please select interval from menu.";
                    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification: myNotification];
                }
            }
        } else {
            // Not found default route.
            NSLog(@"default route not found. %@", defaultRouterAddr);
        }
    }
    
    titleString = @"";
}

#pragma mark - Turn on/off Wi-Fi manually via statusbar

- (void)RestartWiFi {
    restarting = 1;
    [_statusItem setImage: imageWifiOK];
    
    // turn off
    NSString *cmdOff = [NSString stringWithFormat: @"networksetup -setairportpower %@ off", ifaceName];
    execShell(cmdOff);
    
    // turn on
    NSString *cmdOn = [NSString stringWithFormat: @"networksetup -setairportpower %@ on", ifaceName];
    execShell(cmdOn);
    
    restarting = 0;
}

#pragma mark - Set interval from menu

- (void)interval: (id)sender {
    interval = [self getInterval: sender];
    [myTimer invalidate];
    [_statusItem setImage: imageWifiOK];
    myTimer = [NSTimer scheduledTimerWithTimeInterval: interval
                                               target: self
                                             selector: @selector(timerCall:)
                                             userInfo: nil
                                              repeats: YES];
    NSLog(@"Changing ICMP request interval: %5.1f sec", interval);
}

- (void)norepeat {
    interval = 0;
    [myTimer invalidate];
    [_statusItem setImage: imageWifiNoTimer];
    NSLog(@"Changing ICMP request interval: No Repeat");
}

#pragma mark - Set ping response threshold from menu

- (void)pingResThreshold: (id)sender {
    pingTime = [self getThreshold: sender];
    NSLog(@"Changing ICMP response threshold: %6.1f ms", pingTime);
}

#pragma mark - for AppleSeed user

- (void)debugmode {
    if (debugMode == 0) {
        debugMode = 1;
        NSLog(@"Debug mode ON.");
    } else {
        debugMode = 0;
        NSLog(@"Debug mode OFF.");
    }
}

#pragma mark - Put checking mark on menu and sub menu

- (BOOL)validateMenuItem: (NSMenuItem *)menuItem {
    // Interval
    if ([[menuItem title] isEqual: @"300 sec"] && [menuItem action] == @selector(interval:)) {
        if (interval == 300.f) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }
    
    if ([[menuItem title] isEqual: @"120 sec"] && [menuItem action] == @selector(interval:)) {
        if (interval == 120.f) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }
    
    if ([[menuItem title] isEqual: @"20 sec"] && [menuItem action] == @selector(interval:)) {
        if (interval == 20.f) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }
    
    if ([[menuItem title] isEqual: @"10 sec"] && [menuItem action] == @selector(interval:)) {
        if (interval == 10.f) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }
    
    if ([menuItem action] == @selector(norepeat)) {
        if (interval == 0) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }
    
    // Response threshold
    if ([[menuItem title] isEqual: @"2000 ms"] && [menuItem action] == @selector(pingResThreshold:)) {
        if (pingTime == 2000) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }

    if ([[menuItem title] isEqual: @"1500 ms"] && [menuItem action] == @selector(pingResThreshold:)) {
        if (pingTime == 1500) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }
    
    if ([[menuItem title] isEqual: @"1000 ms"] && [menuItem action] == @selector(pingResThreshold:)) {
        if (pingTime == 1000) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }
    
    if ([[menuItem title] isEqual: @"100 ms"] && [menuItem action] == @selector(pingResThreshold:)) {
        if (pingTime == 100) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }
    
    // Debug mode
    if ([menuItem action] == @selector(debugmode)) {
        if (debugMode == 1) {
            [menuItem setState: NSOnState];
        } else {
            [menuItem setState: NSOffState];
        }
    }
    
    return YES;
}

#pragma mark - Get ICMP response time

- (float)getICMPresponse: defaultRouterAddr {
    // Get ping response
    NSString *cmd = [NSString stringWithFormat: @"ping -c 3 %@ | grep 'round-trip' | awk -F'/' '{print $5}'", defaultRouterAddr];
    NSString *output = execShell(cmd);
    
    return output.floatValue;
}

#pragma mark - Get interface name on Mac

- (NSString *)getIFname {
    NSString *ret = execShell(@"networksetup -listallhardwareports | grep -i 'wi-fi' -A 1 | grep -i device | awk '{print $2}' | head -1");
    
    return ret;
}

#pragma mark - Get IP address of default route (WiFi AP or BB router IP address)

- (NSString *)getDefaultRouter {
    NSString *output = execShell(@"netstat -nr | grep -i default | awk '{print $2}' | head -1");
    output = [output stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return output;
}

#pragma mark - Get interval from sub menu

- (float)getInterval: (id)sender {
    NSMenuItem *mi = (NSMenuItem *)sender;
    NSString *tmp = (NSString *)mi.title;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @" sec"
                                                                           options: NSRegularExpressionCaseInsensitive
                                                                             error: nil];
    NSString *tmp2 = [regex stringByReplacingMatchesInString: tmp
                                                     options: 0
                                                       range: NSMakeRange(0, [tmp length])
                                                withTemplate: @""];
    float ret = tmp2.floatValue;
    
    return ret;
}

#pragma mark - Get threshold from sub menu

- (float)getThreshold: (id)sender {
    NSMenuItem *mi = (NSMenuItem *)sender;
    NSString *tmp = (NSString *)mi.title;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @" ms"
                                                                           options: NSRegularExpressionCaseInsensitive
                                                                             error: nil];
    NSString *tmp2 = [regex stringByReplacingMatchesInString: tmp
                                                     options: 0
                                                       range: NSMakeRange(0, [tmp length])
                                                withTemplate: @""];
    float ret = tmp2.floatValue;
    
    return ret;
}

#pragma mark - Validation IP address

- (BOOL)isValidIPAddress: (NSString *)ip {
    const char *utf8 = [ip UTF8String];
    
    struct in_addr dst;
    int success = inet_pton(AF_INET, utf8, &(dst.s_addr));
    if (success != 1) {
        // Check valid IPv6.
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, utf8, &dst6);
    }
    
    return (success == 1);
}

#pragma mark - Attribute statusbar strings

NSMutableAttributedString *attrString(NSString *str) {
    NSMutableAttributedString *initAttrStr;
    initAttrStr = [[NSMutableAttributedString alloc] initWithString: str];
    [initAttrStr addAttribute: NSFontAttributeName
                        value: [NSFont systemFontOfSize: 9.0f]
                        range: NSMakeRange(0, [initAttrStr length])];
//    [initAttrStr addAttribute:NSFontAttributeName
//                        value:[NSFont fontWithName:@"Lucida Grande" size:9.0f]
//                        range:NSMakeRange(0, [initAttrStr length])];
    return initAttrStr;
}

#pragma mark - Exec shell command pseudo function

NSString *execShell(NSString *command) {
    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipe = [[NSPipe alloc] init];
    
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments: [NSArray arrayWithObjects: @"-c", command, nil]];
    
    [task setStandardOutput: pipe];
    [task launch];
    
    NSFileHandle *handle = [pipe fileHandleForReading];
    NSData *data = [handle readDataToEndOfFile];
    NSString *result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    result = [result stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return result;
}

//
//
//

#pragma mark - Core Data stack

//@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
//@synthesize managedObjectModel = _managedObjectModel;
//@synthesize managedObjectContext = _managedObjectContext;
//
//- (NSURL *)applicationDocumentsDirectory {
//    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.example.kmt.WiFirestarter" in the user's Application Support directory.
//    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
//    return [appSupportURL URLByAppendingPathComponent:@"com.example.kmt.WiFirestarter"];
//}
//
//- (NSManagedObjectModel *)managedObjectModel {
//    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
//    if (_managedObjectModel) {
//        return _managedObjectModel;
//    }
//	
//    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"WiFirestarter" withExtension:@"momd"];
//    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
//    return _managedObjectModel;
//}
//
//- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
//    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
//    if (_persistentStoreCoordinator) {
//        return _persistentStoreCoordinator;
//    }
//    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
//    BOOL shouldFail = NO;
//    NSError *error = nil;
//    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
//    
//    // Make sure the application files directory is there
//    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
//    if (properties) {
//        if (![properties[NSURLIsDirectoryKey] boolValue]) {
//            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
//            shouldFail = YES;
//        }
//    } else if ([error code] == NSFileReadNoSuchFileError) {
//        error = nil;
//        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
//    }
//    
//    if (!shouldFail && !error) {
//        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"OSXCoreDataObjC.storedata"];
//        if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
//            coordinator = nil;
//        }
//        _persistentStoreCoordinator = coordinator;
//    }
//    
//    if (shouldFail || error) {
//        // Report any error we got.
//        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
//        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
//        if (error) {
//            dict[NSUnderlyingErrorKey] = error;
//        }
//        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
//        [[NSApplication sharedApplication] presentError:error];
//    }
//    return _persistentStoreCoordinator;
//}
//
//- (NSManagedObjectContext *)managedObjectContext {
//    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
//    if (_managedObjectContext) {
//        return _managedObjectContext;
//    }
//    
//    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
//    if (!coordinator) {
//        return nil;
//    }
//    _managedObjectContext = [[NSManagedObjectContext alloc] init];
//    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
//
//    return _managedObjectContext;
//}
//
//#pragma mark - Core Data Saving and Undo support
//
//- (IBAction)saveAction:(id)sender {
//    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
//    if (![[self managedObjectContext] commitEditing]) {
//        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
//    }
//    
//    NSError *error = nil;
//    if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
//        [[NSApplication sharedApplication] presentError:error];
//    }
//}
//
//- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
//    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
//    return [[self managedObjectContext] undoManager];
//}
//
//- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
//    // Save changes in the application's managed object context before the application terminates.
//    
//    if (!_managedObjectContext) {
//        return NSTerminateNow;
//    }
//    
//    if (![[self managedObjectContext] commitEditing]) {
//        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
//        return NSTerminateCancel;
//    }
//    
//    if (![[self managedObjectContext] hasChanges]) {
//        return NSTerminateNow;
//    }
//    
//    NSError *error = nil;
//    if (![[self managedObjectContext] save:&error]) {
//
//        // Customize this code block to include application-specific recovery steps.              
//        BOOL result = [sender presentError:error];
//        if (result) {
//            return NSTerminateCancel;
//        }
//
//        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
//        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
//        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
//        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert setMessageText:question];
//        [alert setInformativeText:info];
//        [alert addButtonWithTitle:quitButton];
//        [alert addButtonWithTitle:cancelButton];
//
//        NSInteger answer = [alert runModal];
//        
//        if (answer == NSAlertFirstButtonReturn) {
//            return NSTerminateCancel;
//        }
//    }
//
//    return NSTerminateNow;
//}

@end
