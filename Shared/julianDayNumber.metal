//
//  juliandaynumber.metal
//  JABPlanetaryHourFrameworks
//
//  Created by Xcode Developer on 5/26/19.
//

#include <metal_stdlib>
using namespace metal;

kernel void julianDayNumber(const device float *Y [[ buffer(0) ]],
                            const device float *M [[ buffer(1) ]],
                            const device float *D [[ buffer(2) ]],
                            device unsigned int *julianDayNumber [[ buffer(3) ]],
                            uint id [[ thread_position_in_grid ]])
{
    julianDayNumber[id] = static_cast<unsigned int>((1461 * (Y[id] + 4800 + (M[id] - 14)/12))/4 + (367 * (M[id] - 2 - 12 * ((M[id] - 14)/12)))/12 - (3 * ((Y[id] + 4900 + (M[id] - 14)/12)/100))/4 + D[id] - 32075);
}


