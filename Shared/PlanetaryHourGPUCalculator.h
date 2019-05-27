//
//  PlanetaryHourGPUCalculator.h
//  JABPlanetaryHourFrameworks
//
//  Created by Xcode Developer on 5/26/19.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "PlanetaryHourDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlanetaryHourGPUCalculator : NSObject
{
    @private
    id<MTLDevice> metalDevice;
    id<MTLLibrary> metalDefaultLibrary;
    id<MTLCommandQueue> metalCommandQueue;
    
    id<MTLFunction> metalKernelFunction;
    id<MTLComputePipelineState> metalPipelineState;
    
    id<MTLBuffer> metalBufferIn;
    id<MTLBuffer> metalBufferOut;
}

+ (nonnull PlanetaryHourGPUCalculator *)calculation;

@property (weak, nonatomic) id<PlanetaryHourDataSourceLogDelegate> planetaryHourDataSourceDelegate;


@end

NS_ASSUME_NONNULL_END
