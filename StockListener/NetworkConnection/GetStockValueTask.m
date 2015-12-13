//
//  UserLoginTask.m
//  SmartHome
//
//  Created by LiGuozhen on 15-2-4.
//  Copyright (c) 2015年 LiGuozhen. All rights reserved.
//

#import "GetStockValueTask.h"
#import <CommonCrypto/CommonDigest.h>
#import "StockPlayerManager.h"
#import "StockInfo.h"
#import "DatabaseHelper.h"

#define ENABLE_TEST

@interface GetStockValueTask()

@property (nonatomic, strong) NSMutableString* ids;
#ifdef ENABLE_TEST
@property (nonatomic, strong) NSArray* arrayTest;
#endif
@end

@implementation GetStockValueTask

-(id) initWithStock:(StockInfo*) info {
    if ((self = [super init]) != nil) {
        self.ids = [[NSMutableString alloc] init];
        [self.ids appendString:info.sid];
#ifdef ENABLE_TEST
        self.arrayTest = [[NSArray alloc] initWithObjects:@"27.47", @"27.47", @"27.96", @"28.23", @"28.38", @"28.5", @"28.45", @"28.15", @"27.66", @"27.95", @"27.22", @"26.84", @"26", @"25.75", @"24.76", @"25", @"25.5", @"26", @"27", nil];
#endif
    }
    return self;
}

-(id) initWithStocks:(NSArray*) infos {
    if ((self = [super init]) != nil) {
        self.ids = [[NSMutableString alloc] init];
        for (StockInfo* info in infos) {
            [self.ids appendFormat:@"%@,", info.sid];
        }
        #ifdef ENABLE_TEST
        self.arrayTest = [[NSArray alloc] initWithObjects:@"27.47", @"27.1", @"27.96", @"28.23", @"28.38", @"28.5", @"28.45", @"28.15", @"27.66", @"27.95", @"27.22", @"26.84", @"26", @"25.75", @"24.76", @"25", @"25.5", @"26", @"27", nil];
        #endif
    }
    return self;
}

-(void) run {
    [self post:self.ids];
}


-(void) calculateStep:(StockInfo*)info andNewPrice:(float)newPrice {
    if (info.price == 0 || info.price == newPrice) {
        info.step = 0;
        info.speed = 0;
        return;
    }
    float speed = (newPrice - info.price) / info.price;
    speed*=100;
    if (info.speed == 0) {
        info.step = 1;
    } else {
        float rt0 = info.speed < 0 ? info.speed * -1 : info.speed;
        float rt1 = speed < 0 ? speed * -1 : speed;
        float tmpDrt = rt1 / rt0;
        
        float t = tmpDrt * info.step;
        if (((int)(t*10) % 10) >= 5) {
            t += 1;
        }
        info.step = t;
    }
    if (info.step <= 0) {
        info.step = 1;
    }
    if (info.step > 5) {
        info.step = 5;
    }

    info.speed = speed;
}

-(void) parseValueForSina:(NSString*)str {
    if (str == nil) {
        return;
    }

    NSRange range = [str rangeOfString:@"var hq_str_"];
    if (range.location == NSNotFound) {
        return;
    }
    NSRange equalRange = [str rangeOfString:@"="];
    if (equalRange.location == NSNotFound) {
        return;
    }
    NSRange sIDRange = NSMakeRange(range.location + range.length, equalRange.location - range.length - range.location);
    
    NSString* sid = [str substringWithRange:sIDRange];
    
    range.location = sIDRange.location + sIDRange.length + 2;
    NSString* subStr = [str substringFromIndex:range.location];
    NSArray* array = [subStr componentsSeparatedByString:@","];
    if ([array count] < 32) {
        return;
    }

    StockInfo* info = [[DatabaseHelper getInstance] getInfoById:sid];
    if (info == nil) {
        return;
    }
    info.lastDayPrice = [[array objectAtIndex:2] floatValue];
    if (info.lastDayPrice == 0) {
        return;
    }
    info.name = [array objectAtIndex:0];
    info.openPrice = [[array objectAtIndex:1] floatValue];
    info.lastDayPrice = [[array objectAtIndex:2] floatValue];
    float newPrice = [[array objectAtIndex:3] floatValue];
    info.todayHighestPrice = [[array objectAtIndex:4] floatValue];
    info.todayLoestPrice = [[array objectAtIndex:5] floatValue];
    info.dealCount = [[array objectAtIndex:8] longValue];
    info.dealTotalMoney = [[array objectAtIndex:9] floatValue];
    
    info.buyOneCount = [[array objectAtIndex:10] longValue];
    info.buyOnePrice = [[array objectAtIndex:11] floatValue];
    info.buyTwoCount = [[array objectAtIndex:12] longValue];
    info.buyTwoPrice = [[array objectAtIndex:13] floatValue];
    info.buyThreeCount = [[array objectAtIndex:14] longValue];
    info.buyThreePrice = [[array objectAtIndex:15] floatValue];
    info.buyFourCount = [[array objectAtIndex:16] longValue];
    info.buyFourPrice = [[array objectAtIndex:17] floatValue];
    info.buyFiveCount = [[array objectAtIndex:18] longValue];
    info.buyFivePrice = [[array objectAtIndex:19] floatValue];
    info.sellOneCount = [[array objectAtIndex:20] longValue];
    info.sellOnePrice = [[array objectAtIndex:21] floatValue];
    info.sellTwoCount = [[array objectAtIndex:22] longValue];
    info.sellTwoPrice = [[array objectAtIndex:23] floatValue];
    info.sellThreeCount = [[array objectAtIndex:24] longValue];
    info.sellThreePrice = [[array objectAtIndex:25] floatValue];
    info.sellFourCount = [[array objectAtIndex:26] longValue];
    info.sellFourPrice = [[array objectAtIndex:27] floatValue];
    info.sellFiveCount = [[array objectAtIndex:28] longValue];
    info.sellFivePrice = [[array objectAtIndex:29] floatValue];
    
    info.updateDay = [array objectAtIndex:30];
    info.updateTime = [array objectAtIndex:31];
    info.changeRate = (newPrice - info.lastDayPrice) / info.lastDayPrice;
#ifdef ENABLE_TEST
    static int count =0;
    count = count % [self.arrayTest count];
    newPrice = [[self.arrayTest objectAtIndex:count] floatValue];
    count++;
    info.changeRate = (newPrice - 27.51) / 27.51;
#endif
    if (info.price <= 0) {
        info.price = newPrice;
        info.step = 0;
        info.speed = 0;
    } else {
        [self calculateStep:info andNewPrice:newPrice];
        info.price = newPrice;
    }
}

-(void) onComplete:(NSString *)data {
    if ([self.ids length] == 0) {
        return;
    }
    
    NSArray* array = [data componentsSeparatedByString:@";"];
    if ([array count] == 0) {
        return;
    }
    for (NSString* str in array) {
        [self parseValueForSina:str];
    }

    if (self.delegate) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate onStockValuesRefreshed];
        });
    }
    if (self.onCompleteBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            StockInfo* info = [[DatabaseHelper getInstance] getInfoById:self.ids];
            self.onCompleteBlock(info);
        });
    }
}

@end