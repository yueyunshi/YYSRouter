//
//  GFRouter.h
//  GFRouoter
//
//  Created by 岳云石 on 2017/7/3.
//  Copyright © 2017年 岳云石. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, GFRouteType) {
    GFRouteTypeNone = 0,
    GFRouteTypeViewController = 1,
    GFRouteTypeBlock = 2
};

typedef void (^GFRouterBlock)(NSDictionary *params);

typedef id (^GFReturnValueBlock)(NSDictionary *params); //待返回值的bolck

typedef void(^GFCallBackBlock)(id value);

typedef void (^GFRouterBlockWithCallBack)(NSDictionary *params,GFCallBackBlock callBack);

@interface GFRouter : NSObject

+ (instancetype)shared;
#pragma mark -- url-class 注册 调用

- (void)map:(NSString *)route toControllerClass:(Class)controllerClass;
//- (UIViewController *)match:(NSString *)route __attribute__((deprecated));
//根据url调起
//- (UIViewController *)matchController:(NSString *)route;
//根据url调起并传参
- (UIViewController *)matchController:(NSString *)route paramDict:(NSDictionary *)paramDict;

#pragma mark-- 普通url-block 注册调用

- (void)map:(NSString *)route toBlock:(GFRouterBlock)block;
- (id)callBlock:(NSString *)route paramDict:(NSDictionary *)paramDict;

#pragma mark-- 带返回值url-block 注册调用

- (void)mapWithReturnValue:(NSString *)route toBlock:(GFReturnValueBlock)block;
- (id)callBlockWithReturnValue:(NSString *)route paramDict:(NSDictionary *)paramDict;

#pragma mark-- 带回调url-block 注册调用

- (void)mapBlockWithCallBack:(NSString *)route toBlock:(GFRouterBlockWithCallBack)block;
- (void)callBlock:(NSString *)route paramDict:(NSDictionary *)paramDict callBackBlock:(GFCallBackBlock)callBackBlock;
//- (GFRouterBlock)matchBlock:(NSString *)route;

#pragma other

- (GFRouteType)canRoute:(NSString *)route;
- (void)pushToTargetVC:(UIViewController *)vcNext;

@end

/*
 参数字典
 */

@interface UIViewController (GFRouter)

@property (nonatomic, strong) NSDictionary *GFParams;

- (void)configPropertyWithDict:(NSDictionary *)dict;
@end

