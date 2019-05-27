//
//  SolarCalculator.metal
//  JABPlanetaryHourFrameworks
//
//  Created by Xcode Developer on 5/26/19.
//

#include <metal_stdlib>
using namespace metal;


kernel void SolarCalculator(device unsigned int *julianDayNumber [[ buffer(0) ]],
                            const device float *latitude [[ buffer(1) ]],
                            const device float *longitude [[ buffer(2) ]],
                            const device float *pi [[ buffer(3) ]],
                            device float *sunrise [[ buffer(4) ]],
                            device float *sunset [[ buffer(5) ]],
                            uint id [[ thread_position_in_grid ]])
{
    float ZenithOfficial = 90.8333;
    float toRadians = pi[id] / 180.0;
    float toDegrees = 180.0 / pi[id];
    
    float JanuaryFirst2000JDN = 2451545.0;
    float westLongitude = longitude[id] * -1.0;
    
    float Nearest = 0.0;
    float ElipticalLongitudeOfSun = 0.0;
    float ElipticalLongitudeRadians = ElipticalLongitudeOfSun * toRadians;
    float MeanAnomoly = 0.0;
    float MeanAnomolyRadians = MeanAnomoly * toRadians;
    float MAprev = -1.0;
    float Jtransit = 0.0;
    
    while (MeanAnomoly != MAprev)
    {
        MAprev = MeanAnomoly;
        Nearest = round(((float)julianDayNumber[id] - JanuaryFirst2000JDN - 0.0009) - (westLongitude/360.0));
        float Japprox = JanuaryFirst2000JDN + 0.0009 + (westLongitude/360.0) + Nearest;
        if (Jtransit != 0.0) {
            Japprox = Jtransit;
        }
        float Ms = (357.5291 + 0.98560028 * (Japprox - JanuaryFirst2000JDN));
        MeanAnomoly = fmod(Ms, 360.0);
        MeanAnomolyRadians = MeanAnomoly * toRadians;
        float EquationOfCenter = (1.9148 * sin(MeanAnomolyRadians)) + (0.0200 * sin(2.0 * (MeanAnomolyRadians))) + (0.0003 * sin(3.0 * (MeanAnomolyRadians)));
        float eLs = (MeanAnomoly + 102.9372 + EquationOfCenter + 180.0);
        ElipticalLongitudeOfSun = fmod(eLs, 360.0);
        ElipticalLongitudeRadians = ElipticalLongitudeOfSun * toRadians;
        if (Jtransit == 0.0) {
            Jtransit = Japprox + (0.0053 * sin(MeanAnomolyRadians)) - (0.0069 * sin(2.0 * ElipticalLongitudeRadians));
        }
    }
    
    float DeclinationOfSun = asin( sin(ElipticalLongitudeRadians) * sin(23.45 * toRadians) ) * toDegrees;
    float DeclinationOfSunRadians = DeclinationOfSun * toRadians;
    
    float H1 = (cos(ZenithOfficial * toRadians) - sin(latitude[id] * toRadians) * sin(DeclinationOfSunRadians));
    float H2 = (cos(latitude[id] * toRadians) * cos(DeclinationOfSunRadians));
    float HourAngle = acos( (H1  * toRadians) / (H2  * toRadians) ) * toDegrees;
    float Jss = JanuaryFirst2000JDN + 0.0009 + ((HourAngle + westLongitude)/360.0) + Nearest;
    float Jset = Jss + (0.0053 * sin(MeanAnomolyRadians)) - (0.0069 * sin(2.0 * ElipticalLongitudeRadians));
    float Jrise = Jtransit - (Jset - Jtransit);
    
    sunset[id]  = static_cast<float>(Jset);
    sunrise[id] = static_cast<float>(Jrise);
}

