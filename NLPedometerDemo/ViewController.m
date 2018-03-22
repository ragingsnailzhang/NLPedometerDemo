//
//  ViewController.m
//  NLPedometerDemo
//
//  Created by yj_zhang on 2018/3/20.
//  Copyright © 2018年 yj_zhang. All rights reserved.
//

#import "ViewController.h"
#import "NLHealthDataManager.h"

@interface ViewController ()

@property (nonatomic,strong) UILabel *stepsLable;

@property (nonatomic,assign) NSInteger stepCount;

@property (nonatomic,strong) UIButton *account1Btn;

@property (nonatomic,strong) UIButton *account2Btn;

@property (nonatomic,strong) UIButton *updateBtn;

@property (nonatomic,strong) NSMutableArray *stepArr;

@end

static NSString * const accont1 = @"54284";

static NSString * const accont2 = @"55679";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initViews];
}

//MARK:initViews
-(void)initViews{
    self.stepsLable = [[UILabel alloc]init];
    self.stepsLable.textColor = [UIColor blackColor];
    [self.view addSubview:self.stepsLable];
    
    [self.stepsLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    self.account1Btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.account1Btn setTitle:accont1 forState:UIControlStateNormal];
    [self.account1Btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.account1Btn setTitleColor:[UIColor greenColor] forState:UIControlStateSelected];
    self.account1Btn.backgroundColor = [UIColor redColor];
    self.account1Btn.tag = 100;
    [self.account1Btn addTarget:self action:@selector(accountClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.account1Btn];
    
    [self.account1Btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view).offset(100);
        make.left.equalTo(self.view).offset(50);
        make.size.mas_equalTo(CGSizeMake(100, 40));
    }];
    
    self.account2Btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.account2Btn setTitle:accont2 forState:UIControlStateNormal];
    [self.account2Btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.account2Btn setTitleColor:[UIColor greenColor] forState:UIControlStateSelected];
    self.account2Btn.backgroundColor = [UIColor redColor];
    self.account2Btn.tag = 200;
    [self.account2Btn addTarget:self action:@selector(accountClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.account2Btn];
    
    [self.account2Btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(100);
        make.right.equalTo(self.view).offset(-50);
        make.size.mas_equalTo(CGSizeMake(100, 40));

    }];
    
    self.updateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.updateBtn setTitle:@"更新上传" forState:UIControlStateNormal];
    [self.updateBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.updateBtn.backgroundColor = [UIColor redColor];
    [self.updateBtn addTarget:self action:@selector(updateClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.updateBtn];
    
    [self.updateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-200);
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(100, 40));
        
    }];
}

//MARK:Action
-(void)accountClick:(UIButton *)sender{
    sender.selected = YES;
    if (sender.tag == 100) {
        [[NSUserDefaults standardUserDefaults]setObject:accont1 forKey:@"userid"];
        self.account2Btn.selected = !self.account1Btn.selected;
    }else if (sender.tag == 200){
        [[NSUserDefaults standardUserDefaults]setObject:accont2 forKey:@"userid"];
        self.account1Btn.selected = !self.account2Btn.selected;
    }
    
    [self searchTodayStepData];
}

-(void)updateClick{
    //模拟上传成功
    for (NLStepModel *model in self.stepArr) {
        model.isUpload = YES;
        [[NLHealthDataManager shareHealthDataManager]updataDataWithModel:model];
    }
}

//MARK:查询今天计步数据
-(void)searchTodayStepData{
    
    [[NLHealthDataManager shareHealthDataManager]getHealthDataAvailableWith:^(BOOL res) {
        if (res == YES) {
            __weak __typeof(&*self)weakSelf = self;
            [[NLHealthDataManager shareHealthDataManager] searchTodayDataWithResArray:^(NSMutableArray *resArr) {
                
                weakSelf.stepArr = resArr;
                NSInteger stepCount = 0;
                for (NLStepModel *model in resArr) {
                    stepCount += model.count;
                }
                weakSelf.stepCount = stepCount;
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.stepsLable.text = [NSString stringWithFormat:@"账户:%@->步数:%ld",kUserId, (long)weakSelf.stepCount];
                });
            }];
        }else{
            NSLog(@"获取步数权限失败/不允许");
        }
    }];
    
    
}


@end
