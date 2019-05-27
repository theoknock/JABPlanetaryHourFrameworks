//
//  PlanetaryHourGPUCalculator.m
//  JABPlanetaryHourFrameworks
//
//  Created by Xcode Developer on 5/26/19.
//

#import "PlanetaryHourGPUCalculator.h"
#import "PlanetaryHourDataSource.h"

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

- (instancetype)init
{
    if (self == [super init])
    {
        metalDevice = MTLCreateSystemDefaultDevice();
        metalDefaultLibrary = metalDevice.newDefaultLibrary;
        metalCommandQueue = metalDevice.newCommandQueue;
        
        metalKernelFunction = [metalDefaultLibrary newFunctionWithName:@"JulianDayNumberFromDate"];
        MTLComputePipelineDescriptor *computePipeLineDescriptor = nil;
        computePipeLineDescriptor.computeFunction = metalKernelFunction;
        __autoreleasing NSError *error = nil;
        @try {
            metalPipelineState = [metalDevice newComputePipelineStateWithFunction:computePipeLineDescriptor.computeFunction error:&error];
        } @catch (NSException *exception) {
            [self.planetaryHourDataSourceDelegate log:@"PlanetaryHourGPUCalculator" entry:[NSString stringWithFormat:@"Error:\t%@\nException:\t%@", error.description, exception.description] status:LogEntryTypeError];
        } @finally {
            
        }
    
        float byteCountIn = sizeof(float);
        metalBufferIn = [metalDevice newBufferWithLength:byteCountIn options:MTLResourceStorageModeShared];
        float byteCountOut = sizeof(uint);
        metalBufferOut = [metalDevice newBufferWithLength:byteCountOut options:MTLResourceStorageModeShared];
    }
    
    return self;
}

static double (^executionTimeInterval)(dispatch_block_t) = ^(dispatch_block_t block)
{
    double start = NSTimeIntervalSince1970;
    block();
    double end = NSTimeIntervalSince1970;
    
    return end - start;
};

- (void)compute
{
    double time = executionTimeInterval(^{
//        void *bufferInPointer = self->metalBufferIn.contents;
        float inContents = 1.0;
        memcpy(/*bufferInPointer*/ self->metalBufferIn.contents, &inContents, sizeof(float));
//
//        void *bufferOutPointer = self->metalBufferOut.contents;
//        float outContents = 0.0;
//        memcpy(bufferOutPointer, &outContents, sizeof(float));
        
        id<MTLCommandBuffer> metalCommandBuffer = self->metalCommandQueue.commandBuffer;
        id<MTLComputeCommandEncoder> commandEncoder = metalCommandBuffer.computeCommandEncoder;
        
        [commandEncoder setComputePipelineState:self->metalPipelineState];
        [commandEncoder setBuffer:self->metalBufferIn offset:0 atIndex:0];
        [commandEncoder setBuffer:self->metalBufferOut offset:0 atIndex:1];
        
        NSUInteger threadExecutionWidth = self->metalPipelineState.threadExecutionWidth;
        MTLSize threadsPerThreadGroup = MTLSizeMake(threadExecutionWidth, 1, 1);
        MTLSize threadGroups = MTLSizeMake(1 / threadsPerThreadGroup.width, 1, 1);
        [commandEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadsPerThreadGroup];
        
        [commandEncoder endEncoding];
        [metalCommandBuffer commit];
        [metalCommandBuffer waitUntilCompleted];
    });
    
    NSData *calculation = [NSData dataWithBytesNoCopy:metalBufferOut.contents length:1 freeWhenDone:FALSE];
    UInt8 *output       = calloc(1, sizeof(float));
    [calculation getBytes:&output length:1];

    [self.planetaryHourDataSourceDelegate log:@"PlanetaryHourGPUCalculator" entry:[NSString stringWithFormat:@"Output: %s\nTime: %f", output, time] status:LogEntryTypeEvent];
}

@end
