//
//  NSURL+KubeSolo.h
//  Kube-Cluster
//
//  Created by Brandon Evans on 2015-10-28.
//  Copyright © 2015 Rimantas Mocevicius. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (KubeCluster)

+ (instancetype)ks_homeURL;
+ (instancetype)ks_envURL;
+ (instancetype)ks_resourcePathURL;
+ (instancetype)ks_appVersionURL;
+ (instancetype)ks_masterIpAddressURL;
+ (instancetype)ks_node1IpAddressURL;
+ (instancetype)ks_node2IpAddressURL;
@end
