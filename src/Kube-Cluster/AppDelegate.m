//
//  AppDelegate.m
//  Kube-Cluster for macOS
//
//  Created by Rimantas on 03/06/2015.
//  Copyright (c) 2015 Rimantas Mocevicius. All rights reserved.
//

#import "AppDelegate.h"
#import "VMManager.h"
#import "NSURL+KubeCluster.h"

@interface AppDelegate ()

@property (nonatomic, strong) VMManager *vmManager;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;

    self.vmManager = [[VMManager alloc] init];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    (self.statusItem).menu = self.statusMenu;
    (self.statusItem).image = [NSImage imageNamed:@"StatusItemIcon"];
    [self.statusItem setHighlightMode:YES];

    // get resourcePath
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"App resource path: '%@'", resourcePath);
    
    NSString *dmgPath = @"/Volumes/Kube-Cluster/Kube-Cluster.app/Contents/Resources";
    NSLog(@"DMG resource path: '%@'", dmgPath);
    
    // check resourcePath and exit the App if it runs from the dmg
    if ( [resourcePath isEqual: dmgPath] ) {
        // show alert message
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"DmgAlertMessage", nil)];
        NSString *infoText = NSLocalizedString(@"DmgAlertInformativeText", nil);
        [self alertWithMessage:message infoText:infoText];
        
        // show quitting App message
        [self notifyUserWithTitle:NSLocalizedString(@"QuittingNotificationTitle", nil) text:nil];
        
        // exiting App
        [[NSApplication sharedApplication] terminate:self];
    }
    
    
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSURL ks_homeURL].path isDirectory:&isDir] && isDir) {
        // write down App's resource path a file
        [resourcePath writeToURL:[NSURL ks_resourcePathURL] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        // write down App's version a file
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [version writeToURL:[NSURL ks_appVersionURL] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        [self.vmManager checkVMStatus];
    }
    else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert setMessageText:NSLocalizedString(@"NotSetupAlertMessage", nil)];
        [alert setInformativeText:NSLocalizedString(@"NotSetupAlertInformativeText", nil)];
        alert.alertStyle = NSWarningAlertStyle;

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked
            [self initialInstall:self];
        }
        else {
            // Cancel clicked
            [self alertWithMessage:NSLocalizedString(@"SetupAlertMessage", nil) infoText:NSLocalizedString(@"SetupAlertInformativeText", nil)];
        }
    }
}

#pragma mark - Menu Items

- (IBAction)Start:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown: {
            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:[NSURL ks_homeURL].path isDirectory:&isDir] && isDir) {
                [self notifyUserWithTitle:NSLocalizedString(@"WillSetupNotificationTitle", nil) text:NSLocalizedString(@"WillSetupNotificationMessage", nil)];
                [self.vmManager start];
            }
            else {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [alert setMessageText:NSLocalizedString(@"NotSetupAlertMessage", nil)];
                [alert setInformativeText:NSLocalizedString(@"NotSetupAlertInformativeText", nil)];
                alert.alertStyle = NSWarningAlertStyle;

                if ([alert runModal] == NSAlertFirstButtonReturn) {
                    // OK clicked
                    [self initialInstall:self];
                }
                else {
                    // Cancel clicked
                    [self alertWithMessage:NSLocalizedString(@"SetupAlertMessage", nil) infoText:NSLocalizedString(@"SetupAlertInformativeText", nil)];
                }
            }

            break;
        }

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateRunning", nil)];
            break;
    }
}

- (IBAction)Stop:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateAlreadyOff", nil)];
            break;
        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateWillStop", nil)];
            [self.vmManager halt];
            [self notifyUserWithText:NSLocalizedString(@"VMStateStopping", nil)];

            VMStatus vmStatusCheck = VMStatusUp;
            while (vmStatusCheck == VMStatusUp) {
                vmStatusCheck = [self.vmManager checkVMStatus];
                if (vmStatusCheck == VMStatusDown) {
                    [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
                    break;
                }
                else {
                    [self.vmManager kill];
                }
            }
            break;
    }
}

- (IBAction)Restart:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateWillReload", nil)];
            [self.vmManager reload];
            break;
    }
}

- (IBAction)update_k8s:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithTitle:NSLocalizedString(@"KubernetesUpdateNotificationTitle", nil) text:NSLocalizedString(@"KubernetedUpdateNotificationMessage", nil)];
            [self.vmManager updateKubernetes];
            break;
    }
}

- (IBAction)update_k8s_version:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;
        case VMStatusUp:
            [self notifyUserWithTitle:NSLocalizedString(@"KubernetesUpdateNotificationTitle", nil) text:NSLocalizedString(@"KubernetesVersionChangeNotificationMessage", nil)];
            [self.vmManager updateKubernetesVersion];
            break;
    }
}

- (IBAction)updates:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"ClientsWillBeUpdatedNotificationMessage", nil)];
            [self.vmManager updateClients];
            break;
    }
}

- (IBAction)restoreFleetUnits:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];
    
    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;
            
        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"RestoreFleetUnitsNotificationMessage", nil)];
            [self.vmManager restoreFleetUnits];
            break;
    }
}


- (IBAction)fetchLatestISO:(id)sender {
    [self notifyUserWithText:NSLocalizedString(@"ISOImageWillBeUpdatedNotificationMessage", nil)];
    [self.vmManager updateISO];
}

- (IBAction)changeReleaseChannel:(id)sender {
    [self notifyUserWithText:NSLocalizedString(@"ReleaseChannelChangeNotificationMessage", nil)];
    [self.vmManager changeReleaseChannel];
}


- (IBAction)changeNodesRAM:(id)sender {
    [self notifyUserWithText:NSLocalizedString(@"NodesRamChangeNotificationMessage", nil)];
    [self.vmManager changeNodesRAM];
}


- (IBAction)changeSudoPassword:(id)sender {
    [self notifyUserWithText:NSLocalizedString(@"SudoPasswordChangeNotificationMessage", nil)];
    [self.vmManager changeSudoPassword];
}


- (IBAction)destroy:(id)sender {
    [self notifyUserWithText:NSLocalizedString(@"VMStateWillDestroy", nil)];
    [self.vmManager destroy];
    VMStatus status = [self.vmManager checkVMStatus];
    switch (status) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateStopped", nil)];
            break;
        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateRunning", nil)];
            break;
    }
}


- (IBAction)initialInstall:(id)sender {
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSURL ks_homeURL].path isDirectory:&isDir] && isDir) {
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"HomeFolderExistsAlertInformativeText", nil), [NSURL ks_homeURL].path];
        [self alertWithMessage:NSLocalizedString(@"AppName", nil) infoText:msg];
    }
    else {
        NSLog(@"Folder does not exist: '%@'", [NSURL ks_homeURL]);
        [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL ks_envURL] withIntermediateDirectories:YES attributes:nil error:nil];

        NSString *resourcePath = [NSBundle mainBundle].resourcePath;
        [resourcePath writeToURL:[NSURL ks_resourcePathURL] atomically:YES encoding:NSUTF8StringEncoding error:nil];

        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [version writeToURL:[NSURL ks_appVersionURL] atomically:YES encoding:NSUTF8StringEncoding error:nil];

        [self.vmManager install];
    }
}

- (IBAction)About:(id)sender {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"AboutAlertMessage", nil), version];
    NSString *infoText = NSLocalizedString(@"AboutInformativeText", nil);

    [self alertWithMessage:message infoText:infoText];
}


- (IBAction)runShell:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"ShellWillOpenNotificationMessage", nil)];
            [self.vmManager runShell];
            break;
    }
}

- (IBAction)runSshMaster:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"SSHShellWillOpenNotificationMessage", nil)];
            [self.vmManager runSSHMaster];
            break;
    }
}

- (IBAction)runSshNode1:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];
    
    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;
            
        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"SSHShellWillOpenNotificationMessage", nil)];
            [self.vmManager runSSHNode1];
            break;
    }
}

- (IBAction)runSshNode2:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];
    
    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;
            
        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"SSHShellWillOpenNotificationMessage", nil)];
            [self.vmManager runSSHNode2];
            break;
    }
}


- (IBAction)fleetUI:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp: {
            NSString *vmIP = [NSString stringWithContentsOfURL:[NSURL ks_masterIpAddressURL] encoding:NSUTF8StringEncoding error:nil];
            NSString *url = [NSString stringWithFormat:@"http://%@:3000", vmIP];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
            break;
        }
    }
}

- (IBAction)KubernetesUI:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp: {
            NSString *vmIP = [NSString stringWithContentsOfURL:[NSURL ks_masterIpAddressURL] encoding:NSUTF8StringEncoding error:nil];
            NSString *url = [NSString stringWithFormat:@"http://%@:8080/ui", vmIP];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
            break;
        }
    }
}


- (IBAction)Kubedash:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];
    
    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;
            
        case VMStatusUp: {
            NSString *vmIP = [NSString stringWithContentsOfURL:[NSURL ks_masterIpAddressURL] encoding:NSUTF8StringEncoding error:nil];
            NSString *url = [NSString stringWithFormat:@"http://%@:8080/api/v1/proxy/namespaces/kube-system/services/kubedash", vmIP];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
            break;
        }
    }
}


- (IBAction)quit:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateWillStop", nil)];
            [self.vmManager halt];
            [self notifyUserWithText:NSLocalizedString(@"VMStateStopping", nil)];

            VMStatus vmStatusCheck = VMStatusUp;
            while (vmStatusCheck == VMStatusUp) {
                vmStatusCheck = [self.vmManager checkVMStatus];
                if (vmStatusCheck == VMStatusDown) {
                    [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
                    break;
                }
                else {
                    [self.vmManager kill];
                }
            }
            break;
    }

    [self notifyUserWithTitle:NSLocalizedString(@"QuittingNotificationTitle", nil) text:nil];

    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

#pragma mark - Helpers

- (void)notifyUserWithTitle:(NSString *_Nullable)title text:(NSString *_Nullable)text {
    NSUserNotification *notification = [[NSUserNotification alloc] init];

    notification.title = title;
    notification.informativeText = text;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)notifyUserWithText:(NSString *_Nullable)text {
    [self notifyUserWithTitle:NSLocalizedString(@"AppName", nil) text:text];
}

- (void)alertWithMessage:(NSString *)message infoText:(NSString *)infoText {
    NSAlert *alert = [[NSAlert alloc] init];

    alert.alertStyle = NSInformationalAlertStyle;
    alert.messageText = message;
    alert.informativeText = infoText;
    [alert runModal];
}

@end
