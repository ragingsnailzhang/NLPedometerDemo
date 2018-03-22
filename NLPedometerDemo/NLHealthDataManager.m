//
//  NLHealthDataManager.m
//  NLPedometerDemo
//
//  Created by yj_zhang on 2018/3/20.
//  Copyright © 2018年 yj_zhang. All rights reserved.
//

#import "NLHealthDataManager.h"

static NSString* const NLStepsDB = @"NLStepData.db";


@interface NLHealthDataManager()

@property (nonatomic, strong) HKHealthStore *healthStore;

@property (nonatomic, strong) LKDBHelper *stepDBHelper;

@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, copy) void (^resultBlock)(BOOL res);



@end


@implementation NLHealthDataManager

static NLHealthDataManager *manager = nil;

+(NLHealthDataManager *)shareHealthDataManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[NLHealthDataManager alloc]init];
    });
    return manager;
}

//MARK:获取健康权限
-(void)getHealthDataAvailableWith:(void(^)(BOOL res))result{
    self.resultBlock = [result copy];
    //查看healthKit在设备上是否可用，iPad上不支持HealthKit
    if (![HKHealthStore isHealthDataAvailable]) {
        result(NO);
    }
    
    //创建healthStore对象
    self.healthStore = [[HKHealthStore alloc]init];
    //设置需要获取的权限 这里仅设置了步数
    HKObjectType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSSet *healthSet = [NSSet setWithObjects:stepType,nil];
    
    //从健康应用中获取权限
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            //获取步数后我们调用获取步数的方法
            [self readStepCountStep];
        }
        else{
            NSLog(@"获取步数权限失败");
            self.resultBlock(NO);
        }
    }];
}
//MARK: 读取步数 查询数据
- (void)readStepCountStep{
    //查询采样信息
    HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //NSSortDescriptor来告诉healthStore怎么样将结果排序
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    //获取当前时间
    NSDate *now = [NSDate date];
    NSCalendar *calender = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponent = [calender components:unitFlags fromDate:now];
    int hour = (int)[dateComponent hour];
    int minute = (int)[dateComponent minute];
    int second = (int)[dateComponent second];
    NSDate *nowDay = [NSDate dateWithTimeIntervalSinceNow:  - (hour*3600 + minute * 60 + second) ];
    //时间结果与想象中不同是因为它显示的是0区
    NSLog(@"今天%@",nowDay);
    NSDate *nextDay = [NSDate dateWithTimeIntervalSinceNow:  - (hour*3600 + minute * 60 + second)  + 86400];
    NSLog(@"明天%@",nextDay);
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:nowDay endDate:nextDay options:(HKQueryOptionNone)];
    
    /*查询的基类是HKQuery，这是一个抽象类，能够实现每一种查询目标，这里我们需要查询的步数是一个HKSample类所以对应的查询类是HKSampleQuery。下面的limit参数传1表示查询最近一条数据，查询多条数据只要设置limit的参数值就可以了*/
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:predicate limit:0 sortDescriptors:@[start,end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        if(error){
            
        }else{
            NSInteger steps = 0;
            NSMutableArray *muArr = [NSMutableArray array];

            for (HKQuantitySample *quantitySample in results) {
                if ([quantitySample.metadata[@"HKWasUserEntered"]intValue] == 1) {//来自用户修改
                    //丢弃用户添加数据
                }else{
                    HKQuantity *quantity = quantitySample.quantity;
                    HKUnit *countUnit = [HKUnit countUnit];
                    double count = [quantity doubleValueForUnit:countUnit];
                    
                    NLStepModel *model = [NLStepModel new];
                    model.isUpload = 0;
                    model.userid = kUserId;
                    model.startTime = [[NSNumber numberWithDouble:[quantitySample.startDate timeIntervalSince1970]] integerValue];
                    model.endTime = [[NSNumber numberWithDouble:[quantitySample.endDate timeIntervalSince1970]] integerValue];
                    model.count = count;
                    [muArr addObject:model];
                    //插入数据库
                    [self insertDataWithModel:model];
                    steps += count;
                }
            }
            self.resultBlock(YES);
        }
    }];
    
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}

//MARK: LKDBHelper数据库
- (NSString *)filePath{
    if (!_filePath){
        // document目录下
        NSArray *documentArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *document = [documentArray objectAtIndex:0];
        _filePath = [document stringByAppendingPathComponent:NLStepsDB];
    }

    return _filePath;
}
-(LKDBHelper *)stepDBHelper{
    if (_stepDBHelper == nil) {
        _stepDBHelper = [[LKDBHelper alloc]initWithDBPath:self.filePath];
    }
    return _stepDBHelper;
}
//插入数据
-(void)insertDataWithModel:(NLStepModel *)model{
    
    NSString *where = [NSString stringWithFormat:@"startTime = '%ld'",(long)model.startTime];
    NSString *orderBy = [NSString stringWithFormat:@"startTime desc"];
    
    NSMutableArray *resultArr = [self.stepDBHelper search:[NLStepModel class] where:where orderBy:orderBy offset:0 count:100];
    if (resultArr == nil || resultArr.count == 0) {
        BOOL result = [self.stepDBHelper insertToDB:model];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result == YES) {
                NSLog(@"插入成功");
            }else{
                NSLog(@"插入失败");
            }
        });
    }
}
//更新数据
-(void)updataDataWithModel:(NLStepModel *)model{
    
    NSString *where = [NSString stringWithFormat:@"startTime = '%ld' and userid = %@",model.startTime,model.userid];
    NSString *orderBy = [NSString stringWithFormat:@"startTime desc"];
    
    [self.stepDBHelper search:[NLStepModel class] where:where orderBy:orderBy offset:0 count:100 callback:^(NSMutableArray * _Nullable array) {
        if (array && 0 != array.count){
            for (NLStepModel *stepModel in array) {
                model.rowid = stepModel.rowid;
                [self.stepDBHelper updateToDB:model where:where callback:^(BOOL result) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (result == YES) {
                            NSLog(@"更新成功");
                        }else{
                            NSLog(@"更新失败");
                        }
                    });
                }];
            }
        }
    }];
}

//查询今天数据
-(void)searchTodayDataWithResArray:(void(^)(NSMutableArray *resArr))resArray{
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSUIntegerMax fromDate:[NSDate date]];
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    NSTimeInterval ts = (double)(int)[[calendar dateFromComponents:components] timeIntervalSince1970];
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:ts];
    NSTimeZone* zone = [NSTimeZone timeZoneWithName:@"Asia/Beijing"];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
    //今明时间凌晨00:00
    NSInteger todayZero = [[NSNumber numberWithDouble:[localeDate timeIntervalSince1970]] integerValue];
    NSInteger tomorrowZero = todayZero + 86400;
    //根据时间查询
    NSString *where = [NSString stringWithFormat:@"endTime <= '%ld' and endTime >= '%ld' and userid = %@",(long)tomorrowZero,(long)todayZero,kUserId];
    NSString *orderBy = [NSString stringWithFormat:@"endTime desc"];
    
    [self.stepDBHelper search:[NLStepModel class] where:where orderBy:orderBy offset:0 count:100 callback:resArray];
}

        

@end
