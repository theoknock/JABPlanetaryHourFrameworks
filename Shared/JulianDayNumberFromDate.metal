//
//  JulianDayNumberFromDate.metal
//  JABPlanetaryHourFrameworks
//
//  Created by Xcode Developer on 5/26/19.
//

#include <metal_stdlib>
using namespace metal;

constant float Y [[ function_constant(0) ]];
constant float M [[ function_constant(1) ]];
constant float D [[ function_constant(2) ]];

kernel void JulianDayNumberFromDate(device unsigned int *julianDayNumber [[ buffer(3) ]],
                                    uint id [[ thread_position_in_grid ]])
{
    julianDayNumber[id] = static_cast<unsigned int>((1461 * (Y + 4800 + (M - 14)/12))/4 + (367 * (M - 2 - 12 * ((M - 14)/12)))/12 - (3 * ((Y + 4900 + (M - 14)/12)/100))/4 + D - 32075);
}



