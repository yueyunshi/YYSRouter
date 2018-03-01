//
//  tagetViewController.m
//  GFRouterDemo
//
//  Created by 岳云石 on 2017/7/7.
//  Copyright © 2017年 岳云石. All rights reserved.
//

#import "tagetViewController.h"
#import "ViewController.h"
#import <objc/message.h>
#import "GFRouter.h"
@interface tagetViewController ()

@property(nonatomic,strong) NSString *paramInM;

@end

@implementation tagetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
   
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    //获取参数方法一
    NSLog(@"------------------------获取参数方法一 通过GFParams 可以获取所有参数");
    NSLog(@"%@",self.GFParams);
    
    //获取参数方法二 通过遍历参数列表进行参数赋值 弊端就是 父类的参数无法完成赋值
    NSLog(@"------------------------获取参数方法二 通过遍历参数列表进行参数赋值 弊端就是 父类的参数无法完成赋值");
    NSLog(@"paramInH = %@  paramInM = %@  person.name = %@  person.age = %@",_paramInH,_paramInM,self.person.name,self.person.age);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
