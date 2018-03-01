//
//  GFRouter.m
//  GFRouoter
//
//  Created by 岳云石 on 2017/7/3.
//  Copyright © 2017年 岳云石. All rights reserved.
//

#import "GFRouter.h"
#import <objc/message.h>
@interface GFRouter ()
@property (strong, nonatomic) NSMutableDictionary *routes;
@end

@implementation GFRouter
+ (instancetype)shared
{
    static GFRouter *router = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (!router) {
            router = [[self alloc] init];
        }
    });
    return router;
}

#pragma mark -- url-class 注册 调用

- (void)map:(NSString *)route toControllerClass:(Class)controllerClass
{
    /*
     @"/storyView/:userid/"
     得到
     {
     storyView =     {
     ":userid" =         {
     "_" = StoryViewController;
     };
     };
     }
     */
    NSMutableDictionary *subRoutes = [self subRoutesToRoute:route];
    //NSLog(@"self.routs = %@",self.routes);
    subRoutes[@"_"] = controllerClass;
}

- (UIViewController *)matchController:(NSString *)route paramDict:(NSDictionary *)paramDict
{
    NSDictionary *params = [self paramsInRoute:route paramDict:paramDict];
    Class controllerClass = params[@"controller_class"];
    UIViewController *viewController = [[controllerClass alloc] init];
    
    //    id (*typed_msgSend)(id, SEL) = (void *)objc_msgSend;
    //    Class controllerClass = params[@"controller_class"];
    //    id viewController = typed_msgSend(controllerClass,sel_registerName("alloc"));
    //    viewController = typed_msgSend(viewController,sel_registerName("init"));
    //
    //    id viewController = typed_msgSend(controllerClass,@selector(alloc));
    //    viewController = typed_msgSend(viewController,@selector(init));
    
    
    //字典方法赋值
    if ([viewController respondsToSelector:@selector(setGFParams:)]) {
        [viewController performSelector:@selector(setGFParams:)
                             withObject:[params copy]];
    }
    
    //runtime kvc 参数赋值->无法给父类参数赋值
    [viewController configPropertyWithDict:params];
    
    [self pushToTargetVC:viewController];
    
    return viewController;
}

#pragma mark-- 普通url-block 注册调用

- (void)map:(NSString *)route toBlock:(GFRouterBlock)block
{
    NSMutableDictionary *subRoutes = [self subRoutesToRoute:route];
    
    subRoutes[@"_"] = [block copy];
}

- (id)callBlock:(NSString *)route paramDict:(NSDictionary *)paramDict
{
    NSDictionary *params = [self paramsInRoute:route paramDict:paramDict];
    if (!params){
        return nil;
    }
    GFRouterBlock routerBlock = [params[@"block"] copy];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
    [dic addEntriesFromDictionary:paramDict];
    if (routerBlock) {
        routerBlock([dic copy]);
    }
    return nil;
}

#pragma mark-- 带返回值url-block 注册调用

- (void)mapWithReturnValue:(NSString *)route toBlock:(GFReturnValueBlock)block{
    
    NSMutableDictionary *subRoutes = [self subRoutesToRoute:route];
    
    subRoutes[@"_"] = [block copy];
}

// 带返回值的block
- (id)callBlockWithReturnValue:(NSString *)route paramDict:(NSDictionary *)paramDict
{
    NSDictionary *params = [self paramsInRoute:route paramDict:paramDict];
    if (!params){
        return nil;
    }
    
    GFReturnValueBlock routerBlock = [params[@"block"] copy];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
    [dic addEntriesFromDictionary:paramDict];
    
    return routerBlock?routerBlock([dic copy]):nil;
}

#pragma mark-- 带回调url-block 注册调用

//注册带回调的block
- (void)mapBlockWithCallBack:(NSString *)route toBlock:(GFRouterBlockWithCallBack)block{
    NSMutableDictionary *subRoutes = [self subRoutesToRoute:route];
    subRoutes[@"_"] = [block copy];
}

//执行过Block 调用回调block
- (void)callBlock:(NSString *)route paramDict:(NSDictionary *)paramDict callBackBlock:(GFCallBackBlock)callBackBlock{
    NSDictionary *params = [self paramsInRoute:route paramDict:paramDict];
    if (!params){
        return;
    }
    GFRouterBlockWithCallBack routerBlock = [params[@"block"] copy];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
    [dic addEntriesFromDictionary:paramDict];
    
    //如果call 为nil 手动初始化一个block 防止调用崩溃
    if (!callBackBlock) {
        callBackBlock = ^(id value) {
            NSLog(@"你的callbackBlock是空的!!!");
        };
    }
    if (routerBlock) {
        routerBlock([dic copy],[callBackBlock copy]);
    }
    return;
}


- (UIViewController *)matchController:(NSString *)route
{
    NSDictionary *params = [self paramsInRoute:route paramDict:nil];
    
    if (!params) {
        return nil;
    }
    
    Class controllerClass = params[@"controller_class"];
    UIViewController *viewController = [[controllerClass alloc] init];
    
    if ([viewController respondsToSelector:@selector(setGFParams:)]) {
        [viewController performSelector:@selector(setGFParams:)
                             withObject:[params copy]];
    }
    
    [self pushToTargetVC:viewController];
    
    return viewController;
}

- (UIViewController *)match:(NSString *)route
{
    return [self matchController:route];
}

- (GFRouterBlock)matchBlock:(NSString *)route
{
    NSDictionary *params = [self paramsInRoute:route paramDict:nil];
    
    if (!params){
        return nil;
    }
    
    GFRouterBlock routerBlock = [params[@"block"] copy];
    GFRouterBlock returnBlock = ^(NSDictionary *aParams) {
        if (routerBlock) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
            [dic addEntriesFromDictionary:aParams];
            return routerBlock([NSDictionary dictionaryWithDictionary:dic].copy);
        }
    };
    
    return [returnBlock copy];
}






// 获取参数
- (NSDictionary *)paramsInRoute:(NSString *)route paramDict:(NSDictionary *)paramDict
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    params[@"route"] = [self stringFromFilterAppUrlScheme:route];
    /*
     params=
     {
     route = "/storyView/1/?index=3";
     }
     */
    NSMutableDictionary *subRoutes = self.routes;
    NSArray *pathComponents = [self pathComponentsFromRoute:params[@"route"]];
    /*将参数字典*/
    /*
     遍历参数数组
     例：storyView , 1
     遍历参数组
     */
    for (NSString *pathComponent in pathComponents) {
        BOOL found = NO;
        NSArray *subRoutesKeys = subRoutes.allKeys;
        /*
         配置参数 params 字典
         */
        for (NSString *key in subRoutesKeys) {
            if ([subRoutesKeys containsObject:pathComponent]) {
                //找到对应的 path 比如storyView
                found = YES;
                subRoutes = subRoutes[pathComponent];
                break;
            } else if ([key hasPrefix:@":"]) {
                //设置参数
                found = YES;
                subRoutes = subRoutes[key];
                params[[key substringFromIndex:1]] = pathComponent;
                break;
            }
        }
        if (!found) {
            return nil;
        }
    }
    
    /*
     注册-> home/storyView/:str1/:str2
     调用->home/storyView/:str1  str2为必传但是未传值
     调用->home/                 路径未传完整
     判断路径是否完整 必传参数是否完整
     */
    
    //判断参数字典中是否含有参数 (字典中的参数 不一定写在url里面 而是写在参数字典中)
    NSArray * unFoundKeys = [subRoutes allKeys];
    BOOL stopLoop = NO;
    while (!stopLoop) {
        NSArray *keys = [subRoutes allKeys];
        for (NSString *key in keys) {
            if ([key isEqualToString:@"_"]){
                stopLoop = YES;
                break;
            }
            id param = [paramDict objectForKey:[key substringFromIndex:1]];
            
            if (!param){
                stopLoop = YES;
                break;
            }
            
            if (param)
                subRoutes = subRoutes[key];
        }
    }
    
    //参数或路径错误提醒
    unFoundKeys = [subRoutes allKeys];
    for (NSString *key in unFoundKeys){
        if (![key isEqualToString:@"_"]) {
            if ([key hasPrefix:@":"]) {
                NSLog(@"缺失参数 %@ 请补全参数",key);
                return nil;
            }else{
                NSLog(@"缺失路径 %@ 请补全路径",key);
                return nil;
            }
        }
    }
    
    ///home/tab?p=1&p2=2
    // 截取 ？后面的p=1&p2=2 前提是参数按规则拼写  ?p=1&p2=2必须为链接结尾
    NSRange firstRange = [route rangeOfString:@"?"];
    if (firstRange.location != NSNotFound && route.length > firstRange.location + firstRange.length) {
        NSString *paramsString = [route substringFromIndex:firstRange.location + firstRange.length];
        NSArray *paramStringArr = [paramsString componentsSeparatedByString:@"&"];
        for (NSString *paramString in paramStringArr) {
            NSArray *paramArr = [paramString componentsSeparatedByString:@"="];
            if (paramArr.count > 1) {
                NSString *key = [paramArr objectAtIndex:0];
                NSString *value = [paramArr objectAtIndex:1];
                params[key] = value;
            }
        }
    }
    
    //将参数字典中的值导入
    [params addEntriesFromDictionary:[paramDict copy]];
    
    Class class = subRoutes[@"_"];
    if (class_isMetaClass(object_getClass(class))) {
        if ([class isSubclassOfClass:[UIViewController class]]) {
            params[@"controller_class"] = subRoutes[@"_"];
        } else {
            return nil;
        }
    } else {
        if (subRoutes[@"_"]) {
            params[@"block"] = [subRoutes[@"_"] copy];
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:params];
}

#pragma mark - Private

- (NSMutableDictionary *)routes
{
    if (!_routes) {
        _routes = [[NSMutableDictionary alloc] init];
    }
    
    return _routes;
}

- (NSArray *)pathComponentsFromRoute:(NSString *)route
{
    NSMutableArray *pathComponents = [NSMutableArray array];
    NSURL *url = [NSURL URLWithString:[route stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    /*pathComponents 解析路径的组成部分放在数组中
     比如@"/storyView/:userid/"
     解析之后
     ps:/有多个去重只保留一个
     url.path.pathComponents = (
     "/",
     storyView,
     ":userid"
     )
     
     */
    
    //NSLog(@"url.path.pathComponents = %@",url.path.pathComponents);
    for (NSString *pathComponent in url.path.pathComponents) {
        if ([pathComponent isEqualToString:@"/"]) continue;
        //？后见面代表的是 可选参数路  所以url路径到？为止
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:[pathComponent stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return [pathComponents copy];
}

- (NSString *)stringFromFilterAppUrlScheme:(NSString *)string
{
    // filter out the app URL compontents.
    //程序从外部调用进来 过滤掉shceme
    for (NSString *appUrlScheme in [self appUrlSchemes]) {
        if ([string hasPrefix:[NSString stringWithFormat:@"%@:", appUrlScheme]]) {
            
            return [string substringFromIndex:appUrlScheme.length + 2];
        }
    }
    /*GFrouter://storyView/1/?index=3 --> storyView/1/?index=3*/
    return string;
}

- (NSArray *)appUrlSchemes
{
    NSMutableArray *appUrlSchemes = [NSMutableArray array];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    /*  CFBundleURLTypes =     (
     {
     CFBundleTypeRole = Editor;
     CFBundleURLName = GFrouter;
     CFBundleURLSchemes =             (
     GFrouter
     );
     },
     {
     CFBundleTypeRole = Editor;
     CFBundleURLName = GFrouter2;
     CFBundleURLSchemes =             (
     GFrouter2
     );
     }
     );
     */
    
    
    for (NSDictionary *dic in infoDictionary[@"CFBundleURLTypes"]) {
        NSString *appUrlScheme = dic[@"CFBundleURLSchemes"][0];
        [appUrlSchemes addObject:appUrlScheme];
    }
    
    /*
     appUrlSchemes = [@"GFrouter1",@"GFrouter2"];
     */
    return [appUrlSchemes copy];
}

- (NSMutableDictionary *)subRoutesToRoute:(NSString *)route
{
    //pathComponents 解析路径的组成部分放在数组中
    NSArray *pathComponents = [self pathComponentsFromRoute:route];
    
    NSInteger index = 0;
    NSMutableDictionary *subRoutes = self.routes;
    
    //控制路由  避免二次注册
    while (index < pathComponents.count) {
        NSString *pathComponent = pathComponents[index];
        if (![subRoutes objectForKey:pathComponent]) {
            subRoutes[pathComponent] = [[NSMutableDictionary alloc] init];
        }
        subRoutes = subRoutes[pathComponent];
        index++;
    }
    
    //返回一个多层嵌套的字典
    /*{
     storyView =    {
     ":userid" =  {
     };
     };
     }*/
    
    return subRoutes;
}

- (GFRouteType)canRoute:(NSString *)route
{
    NSDictionary *params = [self paramsInRoute:route paramDict:nil];
    
    if (params[@"controller_class"]) {
        return GFRouteTypeViewController;
    }
    
    if (params[@"block"]) {
        return GFRouteTypeBlock;
    }
    
    return GFRouteTypeNone;
}

#pragma mark--当前试图

- (void)pushToTargetVC:(UIViewController *)vcNext{
    
    UIViewController *curretnVC = [self currentActivityViewController:self];
    if ([curretnVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)curretnVC;
        [nav pushViewController:vcNext animated:YES];
    }else{
        [curretnVC.navigationController pushViewController:vcNext animated:YES];
    }
}


- (UIViewController *)currentActivityViewController:(id)target{
    UIViewController * activityViewController = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    
    if (window.windowLevel != UIWindowLevelNormal) {
        
        NSArray * windows = [[UIApplication sharedApplication] windows];
        
        for (UIWindow * tmpWindow in windows) {
            
            if (tmpWindow.windowLevel == UIWindowLevelNormal) {
                
                window = tmpWindow;
                
                break;
            }
            
        }
    }
    
    NSArray * viewsArray = [window subviews];
    
    if (viewsArray.count > 0) {
        
        UIView * frontView = [viewsArray objectAtIndex:0];
        
        id nextResponder = [frontView nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            
            // NSLog(@"+++++++%@",NSStringFromClass([nextResponder class]));
            activityViewController = nextResponder;
            
        }else{
            
            activityViewController = window.rootViewController;
        }
    }
    
    return activityViewController;
    
}

@end

#pragma mark - UIViewController Category

@implementation UIViewController (GFRouter)

static char kAssociatedParamsObjectKey;

- (void)setGFParams:(NSDictionary *)paramsDictionary{
    objc_setAssociatedObject(self, &kAssociatedParamsObjectKey, paramsDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)GFParams
{
    return objc_getAssociatedObject(self, &kAssociatedParamsObjectKey);
}

- (void)configPropertyWithDict:(NSDictionary *)dict{
    
    //获取成员变量 列表
    unsigned int count;
    Ivar *ivarList = class_copyIvarList([self class], &count);
    
    //遍历成员变量列表 从字典中取到value赋值
    for (int i = 0; i<count; i++) {
        //获取实例变量
        Ivar property = ivarList[i];
        //获取实例变量的名字 是带下划线的 所以要去掉下划线 _name->name
        NSString *propertyName = [NSString stringWithUTF8String:ivar_getName(property)];
        propertyName = [propertyName substringFromIndex:1];
        
        //根据示例变量名字作为key 从字典中获取value
        id value = [dict objectForKey:propertyName];
        
        if (value) {
            [self setValue:value forKey:propertyName];
        }
    }
}

/*
 @"@\"NSString\"" -> @"NSString"
 */
#pragma mark -- private
- (NSString *)handleTypeString:(NSString *)typeStr{
    NSRange range = [typeStr rangeOfString:@"\""];
    typeStr = [typeStr substringFromIndex:range.location + range.length];
    range = [typeStr rangeOfString:@"\""];
    typeStr = [typeStr substringToIndex:range.location];
    return typeStr;
}



@end

