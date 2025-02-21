//
//  MJRefreshNormalLeader.h
//  MJRefresh
//
//  Created by kinarobin on 2020/5/3.
//  Copyright © 2020 小码哥. All rights reserved.
//

#if __has_include(<MJRefresh/MJRefreshStateLeader.h>)
#import <MJRefresh/MJRefreshStateLeader.h>
#else
#import "MJRefreshStateLeader.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface MJRefreshNormalLeader : MJRefreshStateLeader

@property (weak, nonatomic, readonly) UIImageView *arrowView;

@end

NS_ASSUME_NONNULL_END
