//
//  ViewController.m
//  GFRouterDemo
//
//  Created by 岳云石 on 2017/7/7.
//  Copyright © 2017年 岳云石. All rights reserved.
//

#import "ViewController.h"
#import "GFRouter.h"
#import <objc/message.h>
#import "tagetViewController.h"
static NSMutableArray *dataArray;

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSIndexPath *currentIdxPath;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.title = @"GFRouterDemo";
    [self configRouter];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)configRouter{
    dataArray = [NSMutableArray new];
    GFRouter *router = [GFRouter shared];
    //推出试图无参数
    [router map:@"/target/byPush" toControllerClass:objc_getRequiredClass("tagetViewController")];
    [dataArray addObject:@{@"title":@"推出试图无参数",@"sel":@"pushWithoutParam"}];
    //推出有参数 :param  此参数为必传
    [router map:@"/target/byPushWithParam/:paramInH" toControllerClass:objc_getRequiredClass("tagetViewController")];
    [dataArray addObject:@{@"title":@"推出试图带参数参数在连接中",@"sel":@"pushWithParam1"}];
    [dataArray addObject:@{@"title":@"推出试图带参数参数在参数字典中",@"sel":@"pushWithParam2"}];
    [dataArray addObject:@{@"title":@"必传参数未穿无法跳转",@"sel":@"pushWithParam3"}];
    //block
    [router map:@"/target/byBlock" toBlock:^(NSDictionary *params) {
        tagetViewController *vc = [tagetViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    [dataArray addObject:@{@"title":@"路由调起block模块 可以推出试图或实现功能",@"sel":@"blockRouter1"}];
    [router map:@"/target/byBlockWithParam/:paramInH" toBlock:^(NSDictionary *params) {
        tagetViewController *vc = [tagetViewController new];
        vc.paramInH = params[@"paramInH"];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    [dataArray addObject:@{@"title":@"路由调起block模块 参数使用方式相同",@"sel":@"blockRouter2"}];
    [router mapWithReturnValue:@"/target/returnValueBlockWithParam/:param" toBlock:^id(NSDictionary *params) {
        NSString *str = params[@"param"];
        return str;
    }];
    
    [dataArray addObject:@{@"title":@"路由调起block模块 参数使用方式相同 可以返回值",@"sel":@"blockRouter3"}];
    
    [router mapBlockWithCallBack:@"/target/blockWithCallBack/:param" toBlock:^(NSDictionary *params, GFCallBackBlock callBack) {
        //添加延时操作
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            callBack(params[@"param"]);
        });
    }];
   
    [dataArray addObject:@{@"title":@"路由调起block模块 参数使用方式相同 可以执行回调block",@"sel":@"blockRouter4"}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSDictionary *dict = dataArray[indexPath.row];
    cell.textLabel.text = dict[@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = dataArray[indexPath.row];
    _currentIdxPath = indexPath;
    const char *selName =[dict[@"sel"] UTF8String];
    SEL sel = sel_registerName(selName);
    id (*typed_msgSend)(id, SEL) = (void *)objc_msgSend;
    typed_msgSend(self,sel);

}


#pragma mark---
- (void)pushWithoutParam{
    NSDictionary *dict = dataArray[_currentIdxPath.row];
    NSLog(@"%@",dict[@"title"]);
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    [[GFRouter shared] matchController:@"/target/byPush" paramDict:nil];

}

- (void)pushWithParam1{
    NSDictionary *dict = dataArray[_currentIdxPath.row];
    NSLog(@"%@",dict[@"title"]);
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    [[GFRouter shared] matchController:@"/target/byPushWithParam/参数在连接中" paramDict:nil];
}

- (void)pushWithParam2{
    NSDictionary *dict = dataArray[_currentIdxPath.row];
    NSLog(@"%@",dict[@"title"]);
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    [[GFRouter shared] matchController:@"/target/byPushWithParam?idx=100" paramDict:@{@"paramInH":@"参数在字典中"}];
}

- (void)pushWithParam3{
    NSDictionary *dict = dataArray[_currentIdxPath.row];
    NSLog(@"%@",dict[@"title"]);
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    [[GFRouter shared] matchController:@"/target/byPushWithParam" paramDict:nil];
}

- (void)blockRouter1{
    [[GFRouter shared] callBlock:@"/target/byBlock" paramDict:nil];
}

- (void)blockRouter2{
    [[GFRouter shared] callBlock:@"/target/byBlockWithParam" paramDict:@{@"paramInH":@"block传参"}];
}

- (void)blockRouter3{
   NSString *str = [[GFRouter shared] callBlockWithReturnValue:@"/target/returnValueBlockWithParam" paramDict:@{@"param":@"block传参"}];
    NSLog(@"%@",str);
}

- (void)blockRouter4{
    //    [[GFRouter shared] callBlock:@"/target/blockWithCallBack/调起回调" ];
    [[GFRouter shared] callBlock:@"/target/blockWithCallBack/调起回调" paramDict:nil callBackBlock:^(id value) {
        NSLog(@"value = %@",value);
    }];
    
}
@end
