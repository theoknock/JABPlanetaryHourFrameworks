//
//  PlanetaryHourGPUCalculator.m
//  JABPlanetaryHourFrameworks
//
//  Created by Xcode Developer on 5/26/19.
//

#import "PlanetaryHourGPUCalculator.h"
#import "PlanetaryHourDataSource.h"
#import <CoreMedia/CoreMedia.h>

#if !defined(_STRINGIFY)
#define __STRINGIFY( _x )   # _x
#define _STRINGIFY( _x )   __STRINGIFY( _x )
#endif

const unsigned int arrayLength = 1 << 8;
const unsigned int bufferSize = arrayLength * sizeof(float);

@implementation PlanetaryHourGPUCalculator

@synthesize planetaryHourDataSourceDelegate = _planetaryHourDataSourceDelegate;

- (void)setPlanetaryHourDataSourceDelegate:(id<PlanetaryHourDataSourceLogDelegate>)planetaryHourDataSourceDelegate
{
    if ([planetaryHourDataSourceDelegate conformsToProtocol:@protocol(PlanetaryHourDataSourceLogDelegate)])
        _planetaryHourDataSourceDelegate = planetaryHourDataSourceDelegate;
}

- (id<PlanetaryHourDataSourceLogDelegate>)planetaryHourDataSourceDelegate
{
    return _planetaryHourDataSourceDelegate;
}

static PlanetaryHourGPUCalculator *calculation = NULL;
+ (nonnull PlanetaryHourGPUCalculator *)calculation
{
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
                      if (!calculation)
                      {
                          calculation = [[self alloc] init];
                      }
                  });
    
    return calculation;
}

typedef NSString *(^StringifyArrayOfIncludes)(NSArray <NSString *> *includes);
static NSString *(^stringifyHeaderFileNamesArray)(NSArray <NSString *> *) = ^(NSArray <NSString *> *includes) {
    NSMutableString *importStatements = [NSMutableString new];
    [includes enumerateObjectsUsingBlock:^(NSString * _Nonnull include, NSUInteger idx, BOOL * _Nonnull stop) {
        [importStatements appendString:@"#include <"];
        [importStatements appendString:include];
        [importStatements appendString:@">\n"];
    }];
    
    return [NSString new];
};

typedef NSString *(^StringifyArrayOfHeaderFileNames)(NSArray <NSString *> *headerFileNames);
static NSString *(^stringifyIncludesArray)(NSArray *) = ^(NSArray *headerFileNames) {
    NSMutableString *importStatements = [NSMutableString new];
    [headerFileNames enumerateObjectsUsingBlock:^(NSString * _Nonnull headerFileName, NSUInteger idx, BOOL * _Nonnull stop) {
        [importStatements appendString:@"#import "];
        [importStatements appendString:@_STRINGIFY("")];
        [importStatements appendString:headerFileName];
        [importStatements appendString:@_STRINGIFY("")];
        [importStatements appendString:@"\n"];
    }];
    
    return [NSString new];
};

//- (NSString *)shader
//{
//    // To-do: write a block that creates a string of stringified import statements from an array of strings of header files
//    NSString *includes = stringifyIncludesArray(@[@"metal_stdlib"]);
//    //    NSString *imports  = stringifyHeaderFileNamesArray(@[@"ShaderTypes.h"]);
//    NSString *code     = [NSString stringWithFormat:@"%s",
//                          _STRINGIFY(
//                                     using namespace metal;
//
//                                     constant int Y [[ function_constant(0) ]];
//                                     constant int M [[ function_constant(1) ]];
//                                     constant int D [[ function_constant(2) ]];
//
//                                     kernel void JulianDayNumberFromDate(device unsigned int *julianDayNumber [[ buffer(3) ]],
//                                                                         uint id [[ thread_position_in_grid ]])
//                                     {
//                                         julianDayNumber[id] = static_cast<unsigned int>((1461 * (Y + 4800 + (M - 14)/12))/4 + (367 * (M - 2 - 12 * ((M - 14)/12)))/12 - (3 * ((Y + 4900 + (M - 14)/12)/100))/4 + D - 32075);
//                                     }
//
//                                     )];
//
//    return [NSString stringWithFormat:@"%@\n%@", includes, /*imports,*/ code];
//
//}

- (NSString *)shader
{
    // To-do: write a block that creates a string of stringified import statements from an array of strings of header files
    NSString *includes = stringifyIncludesArray(@[@"metal_stdlib"]);
    //    NSString *imports  = stringifyHeaderFileNamesArray(@[@"ShaderTypes.h"]);
    NSString *code     = [NSString stringWithFormat:@"%s",
                          _STRINGIFY(
                                     using namespace metal;
                                     
                                     kernel void add(device const float* in1,
                                                     device const float* in2,
                                                     device float*  out [[ buffer(2) ]],
                                                     uint id [[ thread_position_in_grid ]])
                                     {
                                         out[id] = in1[id] + in2[id];
                                     }
                                     
                                     )];
    
    return [NSString stringWithFormat:@"%@\n%@", includes, /*imports,*/ code];
}

- (instancetype)init
{
    if (self == [super init])
    {
        self->loggerQueue = dispatch_queue_create_with_target("Logger queue", DISPATCH_QUEUE_SERIAL, dispatch_get_main_queue());
        self->taskQueue = dispatch_queue_create_with_target("Task queue", DISPATCH_QUEUE_SERIAL, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        self->metalDevice = MTLCreateSystemDefaultDevice();
        self->metalDefaultLibrary = [metalDevice newDefaultLibrary];
        self->metalCommandQueue = [metalDevice newCommandQueue];
        
        __autoreleasing NSError *error = nil;
        NSString* librarySrc = [self shader];
        if (!librarySrc) {
            [NSException raise:@"Failed to read shaders" format:@"%@", [error localizedFailureReason]];
        }
        
        self->metalDefaultLibrary = [self->metalDevice newLibraryWithSource:librarySrc options:nil error:&error];
        if (!self->metalDefaultLibrary) {
            [NSException raise:@"Failed to compile shaders" format:@"%@", [error localizedDescription]];
        }
        
        double time = executionTimeInterval(^{
            [[self->metalDefaultLibrary functionNames] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSLog(@"%lu\t%@", idx, obj);
                if ([obj isEqualToString:@"add"])
                {
                    NSDate *date = [NSDate date];
                    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    
                    for (int day = 0; day < 1; day++)
                    {
                        [date dateByAddingTimeInterval:day * 86400];
                        NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
                        const int Y = components.year;
                        const int M = components.month;
                        const int D = components.day;
                        //
                        MTLFunctionConstantValues *constantValues = [MTLFunctionConstantValues new];
                        [constantValues setConstantValue:&Y type:MTLDataTypeInt atIndex:0];
                        [constantValues setConstantValue:&M type:MTLDataTypeInt atIndex:1];
                        [constantValues setConstantValue:&D type:MTLDataTypeInt atIndex:2];
                        
                        //                        [self->metalDefaultLibrary newFunctionWithName:obj
                        //                                                        constantValues:constantValues
                        //                                                     completionHandler:^(id<MTLFunction>  _Nullable function, NSError * _Nonnull error) {
                        //                                                         if (error) {
                        //                                                             NSLog(@"Error: %@", error.description);
                        //                                                         } else {
                        self->metalKernelFunction = [self->metalDefaultLibrary newFunctionWithName:obj];
                        @try {
                            __autoreleasing NSError *error = nil;
                            __autoreleasing MTLComputePipelineReflection *reflection = nil;
                            self->metalPipelineState = [self->metalDevice newComputePipelineStateWithFunction:self->metalKernelFunction options:MTLPipelineOptionArgumentInfo reflection:&reflection error:&error];
                            id<MTLCommandBuffer> metalCommandBuffer = self->metalCommandQueue.commandBuffer;
                            id<MTLComputeCommandEncoder> commandEncoder = [metalCommandBuffer computeCommandEncoder];
                            [commandEncoder setComputePipelineState:self->metalPipelineState];
                            
                            id<MTLBuffer> bufferIn1 = [self->metalDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
                            id<MTLBuffer> bufferIn2 = [self->metalDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
                            id<MTLBuffer> bufferOut = [self->metalDevice newBufferWithLength:bufferSize options:MTLResourceCPUCacheModeWriteCombined];
                            
                            float *buffer_in1 = [bufferIn1 contents];
                            float *buffer_in2 = [bufferIn2 contents];
//                            float *buffer_out = [bufferOut contents];
                            for (unsigned long index = 0; index < arrayLength; index++)
                            {
                                buffer_in1[index] = 1.0;
                                buffer_in2[index] = 2.0;
//                                buffer_out[index] = 4.0;
                            }
                            
                            [commandEncoder setBuffer:bufferIn1 offset:0 atIndex:0];
                            [commandEncoder setBuffer:bufferIn2 offset:0 atIndex:1];
                            [commandEncoder setBytes:[bufferOut contents] length:bufferSize atIndex:2];// setBuffer:bufferOut offset:0 atIndex:2];
                            
                            NSUInteger threadExecutionWidth = self->metalPipelineState.threadExecutionWidth;
                            MTLSize threadsPerThreadGroup = MTLSizeMake(threadExecutionWidth, 1, 1);
                            MTLSize threadGroups = MTLSizeMake(1 / threadsPerThreadGroup.width, 1, 1);
                            [commandEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadsPerThreadGroup];
                            
                            [commandEncoder endEncoding];
                            [metalCommandBuffer commit];
                            [metalCommandBuffer waitUntilCompleted];
                            
                            float *buffer_1 = [bufferIn1 contents];
                            float *buffer_2 = [bufferIn2 contents];
                            void *buffer_3 = malloc(bufferSize);
                            NSData *data = [NSData dataWithBytes:[bufferOut contents] length:bufferSize];
                            [data getBytes:[bufferOut contents] length:bufferSize];
                            for (unsigned long index = 0; index < arrayLength; index++)
                            {
                                NSLog(@"%f + %f = %f", buffer_1[index], buffer_2[index], ((float *)[bufferOut contents])[index]);
                            }
                            
                            [reflection.arguments enumerateObjectsUsingBlock:^(MTLArgument * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                NSLog(@"%lu", (unsigned long)obj.type );
                            }];
                            
                            //                                                                     NSData *calculation = [NSData dataWithBytesNoCopy:[bufferOut contents] length:[bufferOut length] freeWhenDone:FALSE];
                            //                                                                     NSLog(@"%d\t|\t%s", day, [bufferOut contents]);g
                            // 2458631 is today's Julian Day Number
                            //                                                                 }];
                        } @catch (NSException *exception) {
                            //                                                                 [self.planetaryHourDataSourceDelegate log:@"PlanetaryHourGPUCalculator" entry:[NSString stringWithFormat:@"Error:\t%@\nException:\t%@", error.description, exception.description] status:LogEntryTypeError];
                        } @finally {
                            
                        }
                        //                                                         }
                        //                                                     }];
                    }
                    //
                }
            }];
        });
        
        [self.planetaryHourDataSourceDelegate log:@"PlanetaryHourGPUCalculator" entry:[NSString stringWithFormat:@"Time: %f", time] status:LogEntryTypeEvent];
    }
    
    return self;
}

static Float64 (^executionTimeInterval)(dispatch_block_t) = ^(dispatch_block_t block)
{
    CMTime start = CMClockGetTime(CMClockGetHostTimeClock());
    block();
    CMTime end   = CMClockGetTime(CMClockGetHostTimeClock());
    
    return CMTimeGetSeconds(CMTimeSubtract(end, start));
};

@end










