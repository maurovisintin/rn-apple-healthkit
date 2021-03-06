//
//  RCTAppleHealthKit+Methods_Workout.m
//  RCTAppleHealthKit
//
//  Created by Ahmed Fathy Ghazy on 4/27/18.
//  Copyright © 2018 Greg Wilson. All rights reserved.
//

#import "RCTAppleHealthKit+Methods_Workout.h"
#import "RCTAppleHealthKit+Utils.h"
#import "RCTAppleHealthKit+Queries.h"

@implementation RCTAppleHealthKit (Methods_Workout)

- (void)workout_get:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:[NSDate date]];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    void (^completion)(NSArray *results, NSError *error);
    
    completion = ^(NSArray *results, NSError *error) {
        if(results){
            callback(@[[NSNull null], results]);
            return;
        } else {
            NSString *errMsg = [NSString stringWithFormat:@"Error getting samples: %@", error];
            NSLog(errMsg);
            callback(@[RCTMakeError(errMsg, nil, nil)]);
            return;
        }
    };
    
    [self fetchWorkoutForPredicate: predicate
                         ascending:ascending
                             limit:limit
                        completion:completion];
}

-(void)workout_save: (NSDictionary *)input callback: (RCTResponseSenderBlock)callback {
    HKWorkoutActivityType type = [RCTAppleHealthKit hkWorkoutActivityTypeFromOptions:input key:@"type" withDefault:HKWorkoutActivityTypeOther];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:nil];
    NSTimeInterval duration = [RCTAppleHealthKit doubleFromOptions:input key:@"duration" withDefault:(NSTimeInterval)0];
    HKQuantity *totalEnergyBurned = [RCTAppleHealthKit hkQuantityFromOptions:input valueKey:@"energyBurned" unitKey:@"energyBurnedUnit"];
    HKQuantity *totalDistance = [RCTAppleHealthKit hkQuantityFromOptions:input valueKey:@"distance" unitKey:@"distanceUnit"];
    
    
    HKWorkout *workout = [
                          HKWorkout workoutWithActivityType:type startDate:startDate endDate:endDate workoutEvents:nil totalEnergyBurned:totalEnergyBurned totalDistance:totalDistance metadata: nil
                          ];
    
    void (^completion)(BOOL success, NSError *error);
    
    completion = ^(BOOL success, NSError *error){
        if(!success) {
            
            NSLog(@"An error occured saving the workout %@. The error was: %@.", workout, error);
            callback(@[RCTMakeError(@"An error occured saving the workout", error, nil)]);
            return;
        }
        callback(@[[NSNull null], [[workout UUID] UUIDString]]);
    };
    
    [self.healthStore saveObject:workout withCompletion:completion];
    
}

- (void)workout_delete:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{

    //HKWorkoutActivityType *workoutType = [HKWorkoutActivityType getStringToWorkoutActivityTypeDictionary:HKWorkoutActivityTypeOther];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:[NSDate date]];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];

    // the predicate used to execute the query
    NSPredicate *queryPredicate = [HKSampleQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];

    // prepare the query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:[HKObjectType workoutType] predicate:queryPredicate limit:100 sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error.description);
            callback(@[[NSNull null], @false]);
        } else {
            int size = [results count];
            if (size > 0) {
                NSLog(@"Successfully retreived samples");

                // now that we retrieved the samples, we can delete it/them
                [self.healthStore deleteObject:[results firstObject] withCompletion:^(BOOL success, NSError * _Nullable error) {
                    if(success){
                        callback(@[[NSNull null], @true]);
                        return;
                    } else {
                        NSLog(@"error deleting workout: %@", error);
                                callback(@[RCTMakeError(@"error deleting workout", nil, nil)]);
                                return;
                    }
                }];
            } else {
                callback(@[[NSNull null], @true]);
            }
        }
    }];

    // last but not least, execute the query
    [self.healthStore executeQuery:query];
}

@end
