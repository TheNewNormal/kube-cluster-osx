//
//  VMManager.m
//  Kube-Cluster
//
//  Created by Brandon Evans on 2015-10-28.
//  Copyright © 2015 Rimantas Mocevicius. All rights reserved.
//

#import "VMManager.h"

@implementation VMManager

- (VMStatus)checkVMStatus {
    // check VM status and return the shell script output
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"check_vm_status" ofType:@"command"]];
    //    task.arguments  = @[@"status"];

    NSPipe *pipe;
    pipe = [NSPipe pipe];
    task.standardOutput = pipe;

    NSFileHandle *file;
    file = pipe.fileHandleForReading;

    [task launch];
    [task waitUntilExit];

    NSData *data;
    data = [file readDataToEndOfFile];

    NSString *string;
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Show VMs status:\n%@", string);

    if ([string isEqual:@"VMs are stopped"]) {
        NSLog(@"VMs are Off");
        return VMStatusDown;
    } else {
        NSLog(@"VMs are On");
        return VMStatusUp;
    }
}

- (void)start {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"up.command"]];
}

- (void)halt {
    [self runScript:@"halt" arguments:@""];
}

- (void)kill {
    [self runScript:@"kill_VMs" arguments:@""];
}

- (void)reload {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"reload.command"]];
}

- (void)updateKubernetes {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"update_k8s.command"]];
}

- (void)updateKubernetesVersion {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"update_k8s_version.command"]];
}

- (void)updateClients {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"update_osx_clients_files.command"]];
}

- (void)restoreFleetUnits {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"restore_update_fleet_units.command"]];
}

- (void)runScript:(NSString *)scriptName arguments:(NSString *)arguments {
    NSTask *task = [[NSTask alloc] init];

    task.launchPath = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:scriptName ofType:@"command"]];
    task.arguments = @[ arguments ];
    [task launch];
    [task waitUntilExit];
}

- (void)runApp:(NSString *)appName arguments:(NSString *)arguments {
    // lunch an external App from the mainBundle
    [[NSWorkspace sharedWorkspace] openFile:arguments withApplication:appName];
}

- (void)updateISO {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"fetch_latest_iso.command"]];
}

- (void)changeReleaseChannel {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"change_release_channel.command"]];
}

- (void)changeSudoPassword {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"change_sudo_password.command"]];
}

- (void)destroy {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"destroy.command"]];
}

- (void)install {
    [self runScript:@"kube-cluster-install" arguments:[NSBundle mainBundle].resourcePath];
}

- (void)runShell {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"os_shell.command"]];
}

- (void)runSSHMaster {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"ssh_master.command"]];
}

- (void)runSSHNode1 {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"ssh_node1.command"]];
}

- (void)runSSHNode2 {
    [self runApp:@"iTerm" arguments:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"ssh_node2.command"]];
}

@end
