//
//  MJRefreshLeader.m
//  MJRefresh
//
//  Created by 张帅 on 2025/2/20.
//  Copyright © 2025 小码哥. All rights reserved.
//

#import "MJRefreshLeader.h"
#import "UIView+MJExtension.h"
#import "UIScrollView+MJRefresh.h"
#import "UIScrollView+MJExtension.h"

NSString * const MJRefreshLeaderRefreshing2IdleBoundsKey = @"MJRefreshLeaderRefreshing2IdleBounds";
NSString * const MJRefreshLeaderRefreshingBoundsKey = @"MJRefreshLeaderRefreshingBounds";

@interface MJRefreshLeader() <CAAnimationDelegate>

@property (assign, nonatomic) NSInteger lastRefreshCount;

@property (assign, nonatomic) CGFloat lastLeftDelta;

@end

@implementation MJRefreshLeader

#pragma mark - 构造方法
+ (instancetype)leaderWithRefreshingBlock:(MJRefreshComponentAction)refreshingBlock {
    MJRefreshLeader *cmp = [[self alloc] init];
    cmp.refreshingBlock = refreshingBlock;
    cmp.backgroundColor = [UIColor redColor];
    return cmp;
}

+ (instancetype)leaderWithRefreshingTarget:(id)target refreshingAction:(SEL)action {
    MJRefreshLeader *cmp = [[self alloc] init];
    [cmp setRefreshingTarget:target refreshingAction:action];
    cmp.backgroundColor = [UIColor redColor];
    return cmp;
}

#pragma mark - 覆盖父类的方法
- (void)prepare {
    [super prepare];
    
}

- (void)placeSubviews {
    [super placeSubviews];
    // 设置y值(当自己的高度发生改变了，肯定要重新调整Y值，所以放到placeSubviews方法中设置y值)
    self.mj_h = _scrollView.mj_h;
    // 设置高度
    self.mj_w = MJRefreshTrailWidth;
    self.mj_x = - self.mj_w - self.ignoredScrollViewContentInsetLeft;
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    [super scrollViewContentOffsetDidChange:change];
    
    // 在刷新的refreshing状态
    if (self.state == MJRefreshStateRefreshing) {
        [self resetInset];
        return;
    }
    
    // 跳转到下一个控制器时，contentInset可能会变
    _scrollViewOriginalInset = self.scrollView.mj_inset;
    
    // 当前的contentOffset
    CGFloat offsetX = self.scrollView.mj_offsetX;
    // 头部控件刚好出现的offsetY
    CGFloat happenOffsetX = - self.scrollViewOriginalInset.left;
    
    // 如果是向上滚动到看不见头部控件，直接返回
    // >= -> >
    if (offsetX > happenOffsetX) return;
    
    // 普通 和 即将刷新 的临界点
    CGFloat normal2pullingOffsetX = happenOffsetX - self.mj_w;
    CGFloat pullingPercent = (happenOffsetX - offsetX) / self.mj_w;
    
    if (self.scrollView.isDragging) { // 如果正在拖拽
        self.pullingPercent = pullingPercent;
        if (self.state == MJRefreshStateIdle && offsetX < normal2pullingOffsetX) {
            // 转为即将刷新状态
            self.state = MJRefreshStatePulling;
        } else if (self.state == MJRefreshStatePulling && offsetX >= normal2pullingOffsetX) {
            // 转为普通状态
            self.state = MJRefreshStateIdle;
        }
    } else if (self.state == MJRefreshStatePulling) {// 即将刷新 && 手松开
        // 开始刷新
        [self beginRefreshing];
    } else if (pullingPercent < 1) {
        self.pullingPercent = pullingPercent;
    }
}

- (void)setState:(MJRefreshState)state {
    MJRefreshCheckState
    // 根据状态做事情
    if (state == MJRefreshStateIdle) {
        if (oldState != MJRefreshStateRefreshing) return;
        [self headerEndingAction];
    } else if (state == MJRefreshStateRefreshing) {
        [self headerRefreshingAction];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        // 设置支持水平弹簧效果
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.alwaysBounceVertical = NO;
    }
}

- (void)resetInset {
    // sectionheader停留解决
    CGFloat insetL = -self.scrollView.mj_offsetX > _scrollViewOriginalInset.left ? - self.scrollView.mj_offsetX : _scrollViewOriginalInset.left;
    insetL = insetL > self.mj_w + _scrollViewOriginalInset.left ? self.mj_w + _scrollViewOriginalInset.left : insetL;
    self.lastLeftDelta = _scrollViewOriginalInset.left - insetL;
    // 避免 CollectionView 在使用根据 Autolayout 和 内容自动伸缩 Cell, 刷新时导致的 Layout 异常渲染问题
    if (fabs(self.scrollView.mj_insetL - insetL) > FLT_EPSILON) {
        self.scrollView.mj_insetL = insetL;
    }
}

- (void)headerEndingAction {
    // 默认使用 UIViewAnimation 动画
    if (!self.isCollectionViewAnimationBug) {
        // 恢复inset和offset
        [UIView animateWithDuration:self.slowAnimationDuration animations:^{
            self.scrollView.mj_insetL += self.lastLeftDelta;
            
            if (self.endRefreshingAnimationBeginAction) {
                self.endRefreshingAnimationBeginAction();
            }
            // 自动调整透明度
            if (self.isAutomaticallyChangeAlpha) self.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.pullingPercent = 0.0;
            
            if (self.endRefreshingCompletionBlock) {
                self.endRefreshingCompletionBlock();
            }
        }];
        
        return;
    }
    
    /**
     这个解决方法的思路出自 https://github.com/CoderMJLee/MJRefresh/pull/844
     修改了用+ [UIView animateWithDuration: animations:]实现的修改contentInset的动画
     fix issue#225 https://github.com/CoderMJLee/MJRefresh/issues/225
     另一种解法 pull#737 https://github.com/CoderMJLee/MJRefresh/pull/737
     
     同时, 处理了 Refreshing 中的动画替换.
    */
    
    // 由于修改 Inset 会导致 self.pullingPercent 联动设置 self.alpha, 故提前获取 alpha 值, 后续用于还原 alpha 动画
    CGFloat viewAlpha = self.alpha;
    
    self.scrollView.mj_insetL += self.lastLeftDelta;
    // 禁用交互, 如果不禁用可能会引起渲染问题.
    self.scrollView.userInteractionEnabled = NO;

    //CAAnimation keyPath 不支持 contentInset 用Bounds的动画代替
    CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    boundsAnimation.fromValue = [NSValue valueWithCGRect:CGRectOffset(self.scrollView.bounds, self.lastLeftDelta, 0)];
    boundsAnimation.duration = self.slowAnimationDuration;
    //在delegate里移除
    boundsAnimation.removedOnCompletion = NO;
    boundsAnimation.fillMode = kCAFillModeBoth;
    boundsAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    boundsAnimation.delegate = self;
    [boundsAnimation setValue:MJRefreshLeaderRefreshing2IdleBoundsKey forKey:@"identity"];

    [self.scrollView.layer addAnimation:boundsAnimation forKey:MJRefreshLeaderRefreshing2IdleBoundsKey];
    
    if (self.endRefreshingAnimationBeginAction) {
        self.endRefreshingAnimationBeginAction();
    }
    // 自动调整透明度的动画
    if (self.isAutomaticallyChangeAlpha) {
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = @(viewAlpha);
        opacityAnimation.toValue = @(0.0);
        opacityAnimation.duration = self.slowAnimationDuration;
        opacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.layer addAnimation:opacityAnimation forKey:@"MJRefreshHeaderRefreshing2IdleOpacity"];

        // 由于修改了 inset 导致, pullingPercent 被设置值, alpha 已经被提前修改为 0 了. 所以这里不用置 0, 但为了代码的严谨性, 不依赖其他的特殊实现方式, 这里还是置 0.
        self.alpha = 0;
    }
}

- (void)headerRefreshingAction {
    // 默认使用 UIViewAnimation 动画
    if (!self.isCollectionViewAnimationBug) {
        [UIView animateWithDuration:self.fastAnimationDuration animations:^{
            if (self.scrollView.panGestureRecognizer.state != UIGestureRecognizerStateCancelled) {
                CGFloat left = self.scrollViewOriginalInset.left + self.mj_w + self.ignoredScrollViewContentInsetLeft;
                // 增加滚动区域left
                self.scrollView.mj_insetL = left;
                // 设置滚动位置
                CGPoint offset = self.scrollView.contentOffset;
                offset.x = -left;
                [self.scrollView setContentOffset:offset animated:NO];
            }
        } completion:^(BOOL finished) {
            [self executeRefreshingCallback];
        }];
        return;
    }
    
    if (self.scrollView.panGestureRecognizer.state != UIGestureRecognizerStateCancelled) {
        CGFloat left = self.scrollViewOriginalInset.left + self.mj_w + self.ignoredScrollViewContentInsetLeft;
        // 禁用交互, 如果不禁用可能会引起渲染问题.
        self.scrollView.userInteractionEnabled = NO;

        // CAAnimation keyPath不支持 contentOffset 用Bounds的动画代替
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        CGRect bounds = self.scrollView.bounds;
        bounds.origin.x = -left;
        boundsAnimation.fromValue = [NSValue valueWithCGRect:self.scrollView.bounds];
        boundsAnimation.toValue = [NSValue valueWithCGRect:bounds];
        boundsAnimation.duration = self.fastAnimationDuration;
        //在delegate里移除
        boundsAnimation.removedOnCompletion = NO;
        boundsAnimation.fillMode = kCAFillModeBoth;
        boundsAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        boundsAnimation.delegate = self;
        [boundsAnimation setValue:MJRefreshLeaderRefreshingBoundsKey forKey:@"identity"];
        [self.scrollView.layer addAnimation:boundsAnimation forKey:MJRefreshLeaderRefreshingBoundsKey];
    } else {
        [self executeRefreshingCallback];
    }
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    NSString *identity = [anim valueForKey:@"identity"];
    if ([identity isEqualToString:MJRefreshLeaderRefreshing2IdleBoundsKey]) {
        self.pullingPercent = 0.0;
        self.scrollView.userInteractionEnabled = YES;
        if (self.endRefreshingCompletionBlock) {
            self.endRefreshingCompletionBlock();
        }
    } else if ([identity isEqualToString:MJRefreshLeaderRefreshingBoundsKey]) {
        // 避免出现 end 先于 Refreshing 状态
        if (self.state != MJRefreshStateIdle) {
            CGFloat left = self.scrollViewOriginalInset.left + self.mj_w + self.ignoredScrollViewContentInsetLeft;
            self.scrollView.mj_insetL = left;
            // 设置最终滚动位置
            CGPoint offset = self.scrollView.contentOffset;
            offset.x = -left;
            [self.scrollView setContentOffset:offset animated:NO];
         }
        self.scrollView.userInteractionEnabled = YES;
        [self executeRefreshingCallback];
    }
    
    if ([self.scrollView.layer animationForKey:MJRefreshLeaderRefreshing2IdleBoundsKey]) {
        [self.scrollView.layer removeAnimationForKey:MJRefreshLeaderRefreshing2IdleBoundsKey];
    }
    
    if ([self.scrollView.layer animationForKey:MJRefreshLeaderRefreshingBoundsKey]) {
        [self.scrollView.layer removeAnimationForKey:MJRefreshLeaderRefreshingBoundsKey];
    }
}

#pragma mark . 链式语法部分 .

- (instancetype)linkTo:(UIScrollView *)scrollView {
    scrollView.mj_leader = self;
    return self;
}

- (void)setIgnoredScrollViewContentInsetLeft:(CGFloat)ignoredScrollViewContentInsetLeft {
    _ignoredScrollViewContentInsetLeft = ignoredScrollViewContentInsetLeft;
    
    self.mj_x = - self.mj_w - _ignoredScrollViewContentInsetLeft;
}

#pragma mark - 刚好看到上拉刷新控件时的contentOffset.x
- (CGFloat)happenOffsetX {
    CGFloat deltaW = [self widthForContentBreakView];
    if (deltaW > 0) {
        return deltaW - self.scrollViewOriginalInset.left;
    } else {
        return - self.scrollViewOriginalInset.left;
    }
}

#pragma mark 获得scrollView的内容 超出 view 的宽度
- (CGFloat)widthForContentBreakView {
    CGFloat w = self.scrollView.frame.size.width - self.scrollViewOriginalInset.right - self.scrollViewOriginalInset.left;
    return self.scrollView.contentSize.width - w;
}

@end
