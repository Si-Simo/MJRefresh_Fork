//
//  MJRefreshStateLeader.h
//  MJRefresh
//
//  Created by kinarobin on 2020/5/3.
//  Copyright © 2020 小码哥. All rights reserved.
//

#if __has_include(<MJRefresh/MJRefreshLeader.h>)
#import <MJRefresh/MJRefreshLeader.h>
#else
#import "MJRefreshLeader.h"
#endif

NS_ASSUME_NONNULL_BEGIN


@interface MJRefreshStateLeader : MJRefreshLeader

#pragma mark - 状态相关
/** 显示刷新状态的label */
@property (weak, nonatomic, readonly) UILabel *stateLabel;
/** 设置state状态下的文字 */
- (instancetype)setTitle:(NSString *)title forState:(MJRefreshState)state;

@end

NS_ASSUME_NONNULL_END
