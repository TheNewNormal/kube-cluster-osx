//
//  VMManager.h
//  Kube-Cluster
//
//  Created by Brandon Evans on 2015-10-28.
//  Copyright © 2015 Rimantas Mocevicius. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VMStatus) {
    VMStatusDown = 0,
    VMStatusUp = 1
};

@interface VMManager : NSObject

@property (NS_NONATOMIC_IOSONLY, readonly) VMStatus checkVMStatus;
- (void)start;
- (void)halt;
- (void)kill;
- (void)updateKubernetes;
- (void)updateKubernetesVersion;
- (void)updateClients;
- (void)restoreFleetUnits;
- (void)changeReleaseChannel;
- (void)changeNodesRAM;
- (void)destroy;
- (void)install;
- (void)runShell;
- (void)runSSHMaster;
- (void)runSSHNode1;
- (void)runSSHNode2;
- (NSString*)getAppVersionGithub;

@end
