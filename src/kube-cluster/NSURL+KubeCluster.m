//
//  NSURL+KubeSolo.m
//  Kube-Cluster
//
//  Created by Brandon Evans on 2015-10-28.
//  Copyright © 2015 Rimantas Mocevicius. All rights reserved.
//

#import "NSURL+KubeCluster.h"

@implementation NSURL (KubeCluster)

+ (instancetype)ks_homeURL {
    return [[NSURL fileURLWithPath:NSHomeDirectory()] URLByAppendingPathComponent:@"kube-cluster/"];
}

+ (instancetype)ks_envURL {
    return [[self ks_homeURL] URLByAppendingPathComponent:@".env/"];
}

+ (instancetype)ks_resourcePathURL {
    return [[self ks_envURL] URLByAppendingPathComponent:@"resouces_path"];
}

+ (instancetype)ks_appVersionURL {
    return [[self ks_envURL] URLByAppendingPathComponent:@"version"];
}

+ (instancetype)ks_masterIpAddressURL {
    return [[self ks_envURL] URLByAppendingPathComponent:@"master_ip_address"];
}

+ (instancetype)ks_node1IpAddressURL {
    return [[self ks_envURL] URLByAppendingPathComponent:@"node1_ip_address"];
}

+ (instancetype)ks_node2IpAddressURL {
    return [[self ks_envURL] URLByAppendingPathComponent:@"node2_ip_address"];
}

@end
