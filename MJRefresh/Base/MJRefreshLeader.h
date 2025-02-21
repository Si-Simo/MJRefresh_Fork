//
//  MJRefreshLeader.h
//  MJRefresh
//
//  Created by 张帅 on 2025/2/20.
//  Copyright © 2025 小码哥. All rights reserved.
//
#if __has_include(<MJRefresh/MJRefreshComponent.h>)
#import <MJRefresh/MJRefreshComponent.h>
#else
#import "MJRefreshComponent.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface MJRefreshLeader : MJRefreshComponent

/** 创建leader*/
+ (instancetype)leaderWithRefreshingBlock:(MJRefreshComponentAction)refreshingBlock;
/** 创建leader */
+ (instancetype)leaderWithRefreshingTarget:(id)target refreshingAction:(SEL)action;

/** 忽略多少scrollView的contentInset的left */
@property (assign, nonatomic) CGFloat ignoredScrollViewContentInsetLeft;

/** 默认是关闭状态, 如果遇到 CollectionView 的动画异常问题可以尝试打开 */
@property (nonatomic) BOOL isCollectionViewAnimationBug;

@end

NS_ASSUME_NONNULL_END
