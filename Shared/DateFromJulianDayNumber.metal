//
//  dateFromJulianDayNumber.metal
//  JABPlanetaryHourFrameworks
//
//  Created by Xcode Developer on 5/26/19.
//

#include <metal_stdlib>
using namespace metal;

kernel void DateFromJulianDayNumber(const device float *julianDay [[ buffer(0) ]],
                                    device unsigned int *Y [[ buffer(1) ]],
                                    device unsigned int *M [[ buffer(2) ]],
                                    device unsigned int *D [[ buffer(3) ]],
                                    device unsigned int *H [[ buffer(4) ]],
                                    device unsigned int *N [[ buffer(5) ]],
                                    device unsigned int *S [[ buffer(6) ]],
                                    uint id [[ thread_position_in_grid ]])
{
    int julianDayNumber = (int)floor(julianDay[id]);
    int J = floor(julianDayNumber + 0.5);
    int j = J + 32044;
    int g = j / 146097;
    int dg = j - (j/146097) * 146097;
    int c = (dg / 36524 + 1) * 3 / 4;
    int dc = dg - c * 36524;
    int b = dc / 1461;
    int db = dc - (dc/1461) * 1461;
    int a = (db / 365 + 1) * 3 / 4;
    int da = db - a * 365;
    int y = g * 400 + c * 100 + b * 4 + a;
    int m = (da * 5 + 308) / 153 - 2;
    int d = da - (m + 4) * 153 / 5 + 122;
    Y[id] = static_cast<unsigned int>(y - 4800 + (m + 2) / 12);
    M[id] = static_cast<unsigned int>((m+2) - ((m+2)/12) * 12) + 1;
    D[id] = static_cast<unsigned int>(d + 1);
    float timeValue = ((julianDay[id] - floor(julianDay[id])) + 0.5) * 24;
    H[id] = (int)floor(timeValue);
    float minutes = (timeValue - floor(timeValue)) * 60;
    N[id] = (int)floor(minutes);
    S[id] = (int)((minutes - floor(minutes)) * 60);
}


