//
//  PlanetaryHourDataSource.m
//  JABPlanetaryHourFrameworkSharedSource
//
//  Created by Xcode Developer on 4/22/19.
//

#import "PlanetaryHourDataSource.h"

#define AVERAGE_SECONDS_PER_DAY 86400.0f
double const ZenithOfficial = 90.8333;
double const toRadians = M_PI / 180;
double const toDegrees = 180 / M_PI;

@implementation PlanetaryHourDataSource

static PlanetaryHourDataSource *data = NULL;
+ (nonnull PlanetaryHourDataSource *)data
{
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
                      if (!data)
                      {
                          data = [[self alloc] init];
                      }
                  });
    
    return data;
}

- (instancetype)init
{
    if (self == [super init])
    {
        
        //        self->_block_queue_event = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
        //        dispatch_source_set_event_handler(self->_block_queue_event, ^{
        //            NSLog(@"block_queue_event");
        //        });
        //        dispatch_resume(self->_block_queue_event);
    }
    
    return self;
}

- (CLLocationManager *)locationManager
{
    __block CLLocationManager *lm = self->_locationManager;
    if (!lm)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            lm = [[CLLocationManager alloc] init];
            lm.desiredAccuracy = kCLLocationAccuracyKilometer;
            lm.distanceFilter  = 100;
            
            if ([lm respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [lm requestWhenInUseAuthorization];
            }
            lm.delegate = self;
            
            self->_locationManager = lm;
        });
    }
    
    return lm;
}

#pragma mark - CLLocationManagerDelegate delegate methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%s\n%@", __PRETTY_FUNCTION__, error.localizedDescription);
    [manager requestLocation];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted)
    {
        NSLog(@"Failure to authorize location services\t%d", status);
        [manager stopUpdatingLocation];
    }
    else
    {
        [manager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    
}

#pragma mark - Planetary hour calculation definitions and enumerations

typedef NS_ENUM(NSUInteger, Day) {
    SUN,
    MON,
    TUE,
    WED,
    THU,
    FRI,
    SAT
};

- (NSString * _Nonnull (^)(Planet))planetSymbolForPlanet
{
    return ^(Planet planet) {
        planet = planet % NUMBER_OF_PLANETS;
        switch (planet) {
            case Sun:
                return @"☉";
                break;
            case Moon:
                return @"☽";
                break;
            case Mars:
                return @"♂︎";
                break;
            case Mercury:
                return @"☿";
                break;
            case Jupiter:
                return @"♃";
                break;
            case Venus:
                return @"♀︎";
                break;
            case Saturn:
                return @"♄";
                break;
            default:
                return @"㊏";
                break;
        }
    };
};

NSString *(^planetAbbreviatedNameForPlanet)(NSString *) = ^(NSString *planetName) {
    if ([planetName isEqualToString:@"Sun"])
        return @"SUN";
    if ([planetName isEqualToString:@"Moon"])
        return @"MOON";
    if ([planetName isEqualToString:@"Mars"])
        return @"MARS";
    if ([planetName isEqualToString:@"Mercury"])
        return @"MERC";
    if ([planetName isEqualToString:@"Jupiter"])
        return @"JPTR";
    if ([planetName isEqualToString:@"Venus"])
        return @"VENS";
    if ([planetName isEqualToString:@"Saturn"])
        return @"STRN";
    else
        return @"SUN";
};


//- (NSDate *)localDateForDate:(NSDate *)date
//{
//    NSCalendar *calendar             = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
//    NSDateComponents *dateComponents = [calendar componentsInTimeZone:[NSTimeZone systemTimeZone] fromDate:date];
//    dateComponents.timeZone          = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
//    dateComponents.calendar          = calendar;
//    NSDate *currentTime              = [calendar dateFromComponents:dateComponents];
//
//    return currentTime;
//}

Planet(^planetForDay)(NSDate * _Nullable) = ^(NSDate * _Nullable date) {
    if (!date) date = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    Planet planet = [calendar component:NSCalendarUnitWeekday fromDate:date] - 1;
    
    return planet;
};

Planet(^planetForHour)(NSDate * _Nullable, NSUInteger) = ^(NSDate * _Nullable date, NSUInteger hour) {
    hour = hour % HOURS_PER_DAY;
    Planet planet = (planetForDay(date) + hour) % NUMBER_OF_PLANETS;
    
    return planet;
};

NSString *(^planetNameForDay)(NSDate * _Nullable) = ^(NSDate * _Nullable date)
{
    Day day = (Day)planetForDay(date);
    switch (day) {
        case SUN:
            return @"Sun";
            break;
        case MON:
            return @"Moon";
            break;
        case TUE:
            return @"Mars";
            break;
        case WED:
            return @"Mercury";
            break;
        case THU:
            return @"Jupiter";
            break;
        case FRI:
            return @"Venus";
            break;
        case SAT:
            return @"Saturn";
            break;
        default:
            break;
    }
};

NSString *(^planetSymbolForDay)(NSDate * _Nullable) = ^(NSDate * _Nullable date) {
    return PlanetaryHourDataSource.data.planetSymbolForPlanet(planetForDay(date));
};

NSString *(^planetNameForHour)(NSDate * _Nullable, NSUInteger) = ^(NSDate * _Nullable date, NSUInteger hour)
{
    switch (planetForHour(date, hour)) {
        case Sun:
            return @"Sun";
            break;
        case Moon:
            return @"Moon";
            break;
        case Mars:
            return @"Mars";
            break;
        case Mercury:
            return @"Mercury";
            break;
        case Jupiter:
            return @"Jupiter";
            break;
        case Venus:
            return @"Venus";
            break;
        case Saturn:
            return @"Saturn";
            break;
        default:
            return @"Sun";
    }
};

NSString *(^planetSymbolForHour)(NSDate * _Nullable, NSUInteger) = ^(NSDate * _Nullable date, NSUInteger hour) {
    return PlanetaryHourDataSource.data.planetSymbolForPlanet(planetForHour(date, hour));
};

typedef NS_ENUM(NSUInteger, PlanetColor) {
    Yellow,
    White,
    Red,
    Brown,
    Orange,
    Green,
    Grey
};

- (UIColor * _Nonnull (^)(NSString * _Nonnull))colorForPlanetSymbol
{
    return ^(NSString *planetarySymbol) {
        if ([planetarySymbol isEqualToString:@"☉"])
            return [UIColor yellowColor];
        else if ([planetarySymbol isEqualToString:@"☽"])
            return [UIColor whiteColor];
        else if ([planetarySymbol isEqualToString:@"♂︎"])
            return [UIColor redColor];
        else if ([planetarySymbol isEqualToString:@"☿"])
            return [UIColor brownColor];
        else if ([planetarySymbol isEqualToString:@"♃"])
            return [UIColor orangeColor];
        else if ([planetarySymbol isEqualToString:@"♀︎"])
            return [UIColor greenColor];
        else if ([planetarySymbol isEqualToString:@"♄"])
            return [UIColor grayColor];
        else
            return [UIColor yellowColor];
    };
};

- (Planet (^)(NSString * _Nonnull))planetForPlanetSymbol
{
    return ^(NSString *planetarySymbol) {
        if ([planetarySymbol isEqualToString:@"☉"])
            return Sun;
        else if ([planetarySymbol isEqualToString:@"☽"])
            return Moon;
        else if ([planetarySymbol isEqualToString:@"♂︎"])
            return Mars;
        else if ([planetarySymbol isEqualToString:@"☿"])
            return Mercury;
        else if ([planetarySymbol isEqualToString:@"♃"])
            return Jupiter;
        else if ([planetarySymbol isEqualToString:@"♀︎"])
            return Venus;
        else if ([planetarySymbol isEqualToString:@"♄"])
            return Saturn;
        else
            return Sun;
    };
};

NSAttributedString *(^attributedPlanetSymbol)(NSString *) = ^(NSString *symbol) {
    NSMutableParagraphStyle *centerAlignedParagraphStyle  = [[NSMutableParagraphStyle alloc] init];
    centerAlignedParagraphStyle.alignment                 = NSTextAlignmentCenter;
    NSDictionary *centerAlignedTextAttributes             = @{NSForegroundColorAttributeName : PlanetaryHourDataSource.data.colorForPlanetSymbol(symbol),
                                                              NSFontAttributeName            : [UIFont systemFontOfSize:48.0 weight:UIFontWeightBold],
                                                              NSParagraphStyleAttributeName  : centerAlignedParagraphStyle};
    
    NSAttributedString *attributedSymbol = [[NSAttributedString alloc] initWithString:symbol attributes:centerAlignedTextAttributes];
    
    return attributedSymbol;
};

- (CLLocation * _Nonnull (^)(CLLocation * _Nullable, NSDate * _Nullable, double, double, double, double, NSTimeInterval, NSUInteger))locatePlanetaryHour
{
    return ^(CLLocation * _Nullable location, NSDate * _Nullable date, double meters_per_second, double meters_per_day, double meters_per_day_hour, double meters_per_night_hour, NSTimeInterval timeOffset, NSUInteger hour)
    {
        MKMapPoint user_location_point = MKMapPointForCoordinate(location.coordinate);
        MKMapPoint planetary_hour_origin = MKMapPointMake(((hour < HOURS_PER_SOLAR_TRANSIT)
                                                           ? user_location_point.x + (meters_per_day_hour * hour)
                                                           : user_location_point.x + (meters_per_day + (meters_per_night_hour * (hour % 12))))
                                                          - (timeOffset * meters_per_second),
                                                          user_location_point.y);
        CLLocationCoordinate2D start_coordinate = MKCoordinateForMapPoint(planetary_hour_origin);
        CLLocation *planetaryHourLocation = [[CLLocation alloc] initWithLatitude:start_coordinate.latitude longitude:start_coordinate.longitude];
        
        return planetaryHourLocation;
    };
};

//struct block_struct {
//    void *block;
//    int param1;
//};

//- (dispatch_queue_t)block_queue
//{
//    __block dispatch_queue_t q = self->_block_queue;
//    if (!q)
//    {
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            q = dispatch_queue_create_with_target("block queue", DISPATCH_QUEUE_CONCURRENT, dispatch_get_main_queue());
//            self->_block_queue = q;
//        });
//    }
//
//    return q;
//}

//@synthesize block_queue = _block_queue, block_queue_event = _block_queue_event;

//-  (dispatch_source_t)block_queue_event
//{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    dispatch_source_t eq = self->_block_queue_event;
//    if (!eq)
//    {
//        eq = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
//        dispatch_source_set_event_handler(eq, ^{
//            NSLog(@"block_queue_event");
//        });
//        dispatch_resume(eq);
//    }
//
//    return eq;
//}

//- (void)block_array
//{
//    block_structure * blk_structure = calloc(1, sizeof(block_structure));
//    blk_structure->blk = block_var;
//    blk_structure->param = 1;
//
//    dispatch_source_merge_data(_block_queue_event, 1);
//
//    NSLog(@"Queuing %d", 1);
//}
//
//- (void)get_blocks
//{
//    const char *index = [[NSString stringWithFormat:@"%d", 1] cStringUsingEncoding:NSUTF8StringEncoding];
//    block_structure * blk_structure = calloc(1, sizeof(block_structure));
//    blk_structure = dispatch_queue_get_specific([self block_queue], (&index));
//    NSLog(@"Dequeuing %@", blk_structure);//, blk_structure->blk(&blk_structure->param));
//}

- (void)solarCyclesForDays:(NSIndexSet *)days planetaryHourData:(NSIndexSet *)data planetaryHours:(NSIndexSet *)hours solarCycleCompletionBlock:(void (^)(NSDictionary<NSNumber *,NSDate *> * _Nonnull))solarCycleCompletionBlock planetaryHourCompletionBlock:(void (^)(NSDictionary<NSNumber *,id> * _Nonnull))planetaryHourCompletionBlock planetaryHoursCompletionBlock:(void (^)(NSArray<NSDictionary<NSNumber *,NSDate *> *> * _Nonnull))planetaryHoursCompletionBlock planetaryHourDataSourceCompletionBlock:(void (^)(NSError * _Nullable))planetaryHourDataSourceCompletionBlock
{
    ^void (void(^solarCycleCompletionBlock)(NSDictionary<NSNumber *, NSDate *> *), NSDate * _Nullable date, CLLocation * _Nullable location, int (^ _Nonnull solarCycleDataProviderDate)(NSDate * _Nonnull), CLLocationCoordinate2D (^ _Nonnull solarCycleDataProviderLocation)(CLLocation * _Nullable), NSDate *(^dateFromJulianDayNumber)(double), NSDictionary<NSNumber *,NSDate *> * _Nonnull (^ _Nonnull solarCycleDataProvider)(int, CLLocationCoordinate2D, NSDate *(^)(double)))
    {
        __block void(^solarCycleDates)(NSDictionary<NSNumber *, NSDate *> *);
        __block NSUInteger currentIndex = days.firstIndex;
        solarCycleDates = ^(NSDictionary<NSNumber *, NSDate *> *incomingTwilightDates)
        {
            //            dispatch_source_merge_data(self->_block_queue_event, 1);
            NSDictionary<NSNumber *, NSDate *> *outgoingTwilightDates = solarCycleDataProvider(solarCycleDataProviderDate([[incomingTwilightDates objectForKey:@(TwilightDateSunset)] dateByAddingTimeInterval:AVERAGE_SECONDS_PER_DAY]), solarCycleDataProviderLocation(location), dateFromJulianDayNumber);
            NSMutableArray<NSDate *> *allDates = [NSMutableArray arrayWithArray:[outgoingTwilightDates allValues]];
            [allDates addObjectsFromArray:[incomingTwilightDates allValues]];
            NSDictionary<NSNumber *, NSDate *> * solarCycle = [NSDictionary dictionaryWithObjects:[[allDates sortedArrayWithOptions:NSSortConcurrent
                                                                                                                    usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                                                                        return (NSComparisonResult)([[(NSDate *)obj1 earlierDate:(NSDate *)obj2] isEqual:(NSDate *)obj1])
                                                                                                                        ? (NSComparisonResult)NSOrderedAscending
                                                                                                                        : (NSComparisonResult)NSOrderedDescending;
                                                                                                                    }]
                                                                                                   subarrayWithRange:NSMakeRange(0, 3)]
                                                                                          forKeys:(NSArray<id<NSCopying>> *)@[@(SolarCycleDateStart),
                                                                                                                              @(SolarCycleDateMid),
                                                                                                                              @(SolarCycleDateEnd)]];
            
            
            //            solarCycleCompletionBlock(solarCycle);
            
            __block NSMutableArray *planetaryHoursData = [[NSMutableArray alloc] initWithCapacity:hours.count];
            
            __block void(^calculatePlanetaryHourData)(NSDictionary<NSNumber *, NSDate *> *);
            __block NSUInteger currentHour = hours.firstIndex;
            calculatePlanetaryHourData = ^(NSDictionary<NSNumber *, NSDate *> *solarCycleData)
            {
                NSTimeInterval transitDuration    = [(currentHour < 12) ? [solarCycleData objectForKey:@(SolarCycleDateMid)] : [solarCycleData objectForKey:@(SolarCycleDateEnd)] timeIntervalSinceDate:(currentHour < 12) ? [solarCycleData objectForKey:@(SolarCycleDateStart)] : [solarCycleData objectForKey:@(SolarCycleDateMid)]];
                NSTimeInterval hourDuration       = (transitDuration / 12);
                NSInteger mod_hour                = currentHour % 12;
                NSTimeInterval startTimeInterval  = hourDuration * mod_hour;
                NSDate *sinceDate                 = (currentHour < 12) ? [solarCycleData objectForKey:@(SolarCycleDateStart)] : [solarCycleData objectForKey:@(SolarCycleDateMid)];
                NSDate *startTime                 = [[NSDate alloc] initWithTimeInterval:startTimeInterval sinceDate:sinceDate];
                NSTimeInterval endTimeInterval    = hourDuration * (mod_hour + 1);
                NSDate *endTime                   = [[NSDate alloc] initWithTimeInterval:endTimeInterval sinceDate:sinceDate];
                
                // time
                NSTimeInterval seconds_in_day        = [[solarCycleData objectForKey:@(SolarCycleDateMid)] timeIntervalSinceDate:[solarCycleData objectForKey:@(SolarCycleDateStart)]];
                NSTimeInterval seconds_in_night      = [[solarCycleData objectForKey:@(SolarCycleDateEnd)] timeIntervalSinceDate:[solarCycleData objectForKey:@(SolarCycleDateMid)]];
                NSTimeInterval seconds_per_day       = seconds_in_day + seconds_in_night;
                // distance
                double map_points_per_second         = MKMapSizeWorld.width / seconds_per_day;
                double meters_per_second             = MKMetersPerMapPointAtLatitude(location.coordinate.latitude) * map_points_per_second;
                double meters_per_day                = seconds_in_day   * meters_per_second;
                double meters_per_night              = seconds_in_night * meters_per_second;
                
                double meters_per_day_hour           = meters_per_day   / HOURS_PER_SOLAR_TRANSIT;
                double meters_per_night_hour         = meters_per_night / HOURS_PER_SOLAR_TRANSIT;
                
                NSTimeInterval timeOffset            = [date timeIntervalSinceDate:[solarCycleData objectForKey:@(SolarCycleDateStart)]];
                
                NSAttributedString *symbol        = attributedPlanetSymbol(planetSymbolForHour([solarCycleData objectForKey:@(SolarCycleDateStart)], currentHour));
                NSString *name                    = planetNameForHour([solarCycleData objectForKey:@(SolarCycleDateStart)], currentHour);
                NSString *abbr                    = planetAbbreviatedNameForPlanet(name);
                UIColor *color                    = PlanetaryHourDataSource.data.colorForPlanetSymbol([symbol string]);
                CLLocation *coordinate            = PlanetaryHourDataSource.data.locatePlanetaryHour(location, date, meters_per_second, meters_per_day, meters_per_day_hour, meters_per_night_hour, timeOffset, currentHour);
                NSMutableDictionary * planetaryHourData = [[NSMutableDictionary alloc] initWithCapacity:data.count];
                [data enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    switch (idx) {
                        case StartDate:
                            [planetaryHourData setObject:startTime forKey:@(StartDate)];
                            break;
                        case EndDate:
                            [planetaryHourData setObject:endTime forKey:@(EndDate)];
                            break;
                            
                        case Symbol:
                            [planetaryHourData setObject:symbol forKey:@(Symbol)];
                            break;
                            
                        case Name:
                            [planetaryHourData setObject:name forKey:@(Name)];
                            break;
                            
                        case Abbreviation:
                            [planetaryHourData setObject:abbr forKey:@(Abbreviation)];
                            break;
                            
                        case Color:
                            [planetaryHourData setObject:color forKey:@(Color)];
                            break;
                            
                        case Hour:
                            [planetaryHourData setObject:[NSNumber numberWithInteger:currentHour] forKey:@(Hour)];
                            break;
                            
                        case Coordinate:
                            [planetaryHourData setObject:coordinate forKey:@(Coordinate)];
                            break;
                            
                        default:
                            break;
                    }
                }];
                
                [planetaryHoursData addObject:planetaryHourData];
                planetaryHourCompletionBlock(planetaryHourData);
                
                dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_HIGH), ^{
                    currentHour = [hours indexGreaterThanIndex:currentHour];
                    if (currentHour != NSNotFound)
                    {
                        calculatePlanetaryHourData(solarCycleData);
                    } else {
                        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_HIGH), ^{
                            currentIndex = [days indexGreaterThanIndex:currentIndex];
                            if (currentIndex != NSNotFound)
                            {
                                solarCycleDates(outgoingTwilightDates);
                            } else {
                                planetaryHourDataSourceCompletionBlock(planetaryHoursData);
                            }
                        });
                    }
                });
            }; calculatePlanetaryHourData(solarCycle);
            
        }; solarCycleDates(solarCycleDataProvider(solarCycleDataProviderDate(date), solarCycleDataProviderLocation(location), dateFromJulianDayNumber));
    } (solarCycleCompletionBlock,
       [NSDate date], _locationManager.location,
       ^int (NSDate * _Nonnull date)
       {
           NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
           NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
           int Y = components.year;
           int M = components.month;
           int D = components.day;
           int julianDayNumber = (1461 * (Y + 4800 + (M - 14)/12))/4 + (367 * (M - 2 - 12 * ((M - 14)/12)))/12 - (3 * ((Y + 4900 + (M - 14)/12)/100))/4 + D - 32075;
           
           return julianDayNumber;
       },
       ^CLLocationCoordinate2D (CLLocation * _Nonnull location)
       {
           return location.coordinate;
       },
       ^NSDate *(double julianDayValue)
       {
           int JulianDayNumber = (int)floor(julianDayValue);
           int J = floor(JulianDayNumber + 0.5);
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
           NSDateComponents *components = [NSDateComponents new];
           components.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
           components.year = y - 4800 + (m + 2) / 12;
           components.month = ((m+2) - ((m+2)/12) * 12) + 1;
           components.day = d + 1;
           double timeValue = ((julianDayValue - floor(julianDayValue)) + 0.5) * 24;
           components.hour = (int)floor(timeValue);
           double minutes = (timeValue - floor(timeValue)) * 60;
           components.minute = (int)floor(minutes);
           components.second = (int)((minutes - floor(minutes)) * 60);
           NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
           NSDate *returnDate = [calendar dateFromComponents:components];
           
           return returnDate;
       },
       ^NSDictionary<NSNumber *,NSDate *> * _Nonnull (int julianDayNumber, CLLocationCoordinate2D coordinate, NSDate *(^dateFromJulianDayNumber)(double))
       {
           double JanuaryFirst2000JDN = 2451545.0;
           double westLongitude = coordinate.longitude * -1.0;
           
           __block double Nearest = 0.0;
           __block double ElipticalLongitudeOfSun = 0.0;
           __block double ElipticalLongitudeRadians = ElipticalLongitudeOfSun * toRadians;
           __block double MeanAnomoly = 0.0;
           __block double MeanAnomolyRadians = MeanAnomoly * toRadians;
           __block double MAprev = -1.0;
           __block double Jtransit = 0.0;
           
           while (MeanAnomoly != MAprev)
           {
               MAprev = MeanAnomoly;
               Nearest = round(((double)julianDayNumber - JanuaryFirst2000JDN - 0.0009) - (westLongitude/360.0));
               double Japprox = JanuaryFirst2000JDN + 0.0009 + (westLongitude/360.0) + Nearest;
               if (Jtransit != 0.0) {
                   Japprox = Jtransit;
               }
               double Ms = (357.5291 + 0.98560028 * (Japprox - JanuaryFirst2000JDN));
               MeanAnomoly = fmod(Ms, 360.0);
               MeanAnomolyRadians = MeanAnomoly * toRadians;
               double EquationOfCenter = (1.9148 * sin(MeanAnomolyRadians)) + (0.0200 * sin(2.0 * (MeanAnomolyRadians))) + (0.0003 * sin(3.0 * (MeanAnomolyRadians)));
               double eLs = (MeanAnomoly + 102.9372 + EquationOfCenter + 180.0);
               ElipticalLongitudeOfSun = fmod(eLs, 360.0);
               ElipticalLongitudeRadians = ElipticalLongitudeOfSun * toRadians;
               if (Jtransit == 0.0) {
                   Jtransit = Japprox + (0.0053 * sin(MeanAnomolyRadians)) - (0.0069 * sin(2.0 * ElipticalLongitudeRadians));
               }
           }
           
           double DeclinationOfSun = asin( sin(ElipticalLongitudeRadians) * sin(23.45 * toRadians) ) * toDegrees;
           double DeclinationOfSunRadians = DeclinationOfSun * toRadians;
           
           double H1 = (cos(ZenithOfficial * toRadians) - sin(coordinate.latitude * toRadians) * sin(DeclinationOfSunRadians));
           double H2 = (cos(coordinate.latitude * toRadians) * cos(DeclinationOfSunRadians));
           double HourAngle = acos( (H1  * toRadians) / (H2  * toRadians) ) * toDegrees;
           double Jss = JanuaryFirst2000JDN + 0.0009 + ((HourAngle + westLongitude)/360.0) + Nearest;
           double Jset = Jss + (0.0053 * sin(MeanAnomolyRadians)) - (0.0069 * sin(2.0 * ElipticalLongitudeRadians));
           double Jrise = Jtransit - (Jset - Jtransit);
           
           return @{@(TwilightDateSunrise) : dateFromJulianDayNumber(Jrise),
                    @(TwilightDateSunset)  : dateFromJulianDayNumber(Jset)};
       });
}


// Enumerates indexes in index set; DO NOT USE - BLOCKS MAIN THREAD

//- (NSDictionary<NSNumber *, NSDate *> *)objectAtIndex:(NSUInteger)index
//{
//    [days enumerateIndexesUsingBlock:^(NSUInteger day, BOOL * _Nonnull stop) {
//        solarCycleCompletionBlock(^NSDictionary<NSNumber *,NSDate *> * _Nonnull(NSDate * _Nullable date, CLLocation * _Nullable location, int (^ _Nonnull solarCycleDataProviderDate)(NSDate * _Nonnull), CLLocationCoordinate2D (^ _Nonnull solarCycleDataProviderLocation)(CLLocation * _Nullable), NSDate *(^dateFromJulianDayNumber)(double), NSDictionary<NSNumber *,NSDate *> * _Nonnull (^ _Nonnull solarCycleDataProvider)(int, CLLocationCoordinate2D, NSDate *(^)(double)))
//                                  {
//                                      NSDictionary<NSNumber *, NSDate *> *twilightDates = solarCycleDataProvider(solarCycleDataProviderDate(date), solarCycleDataProviderLocation(location), dateFromJulianDayNumber);
//
//                                      // Second pair of sunrise-sunset dates
//                                      NSDictionary<NSNumber *, NSDate *> *secondTwilightDates = solarCycleDataProvider(solarCycleDataProviderDate(([[[twilightDates objectForKey:@(TwilightDateSunrise)] earlierDate:date] isEqualToDate:date]) ? [date dateByAddingTimeInterval:-AVERAGE_SECONDS_PER_DAY] : [date dateByAddingTimeInterval:AVERAGE_SECONDS_PER_DAY]), solarCycleDataProviderLocation(location), dateFromJulianDayNumber);
//
//                                      // Combined array of sunrise-set dates
//                                      NSMutableArray<NSDate *> *allDates = [NSMutableArray arrayWithArray:[secondTwilightDates allValues]];
//                                      [allDates addObjectsFromArray:[twilightDates allValues]];
//
//                                      // Dictionary of sorted array of sunrise-set dates combination (solar cycle dates)
//                                      NSDictionary<NSNumber *, NSDate *> * solarCycle = [NSDictionary dictionaryWithObjects:[[allDates sortedArrayWithOptions:NSSortConcurrent
//                                                                                                                                              usingComparator:^NSComparisonResult(id obj1, id obj2) {
//                                                                                                                                                  return (NSComparisonResult)([[(NSDate *)obj1 earlierDate:(NSDate *)obj2] isEqual:(NSDate *)obj1])
//                                                                                                                                                  ? (NSComparisonResult)NSOrderedAscending
//                                                                                                                                                  : (NSComparisonResult)NSOrderedDescending;
//                                                                                                                                              }]
//                                                                                                                             subarrayWithRange:NSMakeRange(0, 3)]
//                                                                                                                    forKeys:(NSArray<id<NSCopying>> *)@[@(SolarCycleDateStart),
//                                                                                                                                                        @(SolarCycleDateMid),
//                                                                                                                                                        @(SolarCycleDateEnd)]];
//
//
//                                      return solarCycle;
//
//                                  } ([[NSDate date] dateByAddingTimeInterval:AVERAGE_SECONDS_PER_DAY * day], self->_locationManager.location,
//                                     ^int (NSDate * _Nonnull date)
//                                     {
//                                         NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
//                                         NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
//                                         int Y = components.year;
//                                         int M = components.month;
//                                         int D = components.day;
//                                         int julianDayNumber = (1461 * (Y + 4800 + (M - 14)/12))/4 + (367 * (M - 2 - 12 * ((M - 14)/12)))/12 - (3 * ((Y + 4900 + (M - 14)/12)/100))/4 + D - 32075;
//
//                                         return julianDayNumber;
//                                     },
//                                     ^CLLocationCoordinate2D (CLLocation * _Nonnull location)
//                                     {
//                                         return location.coordinate;
//                                     },
//                                     ^NSDate *(double julianDayValue)
//                                     {
//                                         // calculation of Gregorian date from Julian Day Number ( http://en.wikipedia.org/wiki/Julian_day )
//                                         int JulianDayNumber = (int)floor(julianDayValue);
//                                         int J = floor(JulianDayNumber + 0.5);
//                                         int j = J + 32044;
//                                         int g = j / 146097;
//                                         int dg = j - (j/146097) * 146097; // mod
//                                         int c = (dg / 36524 + 1) * 3 / 4;
//                                         int dc = dg - c * 36524;
//                                         int b = dc / 1461;
//                                         int db = dc - (dc/1461) * 1461; // mod
//                                         int a = (db / 365 + 1) * 3 / 4;
//                                         int da = db - a * 365;
//                                         int y = g * 400 + c * 100 + b * 4 + a;
//                                         int m = (da * 5 + 308) / 153 - 2;
//                                         int d = da - (m + 4) * 153 / 5 + 122;
//                                         NSDateComponents *components = [NSDateComponents new];
//                                         components.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
//                                         components.year = y - 4800 + (m + 2) / 12;
//                                         components.month = ((m+2) - ((m+2)/12) * 12) + 1;
//                                         components.day = d + 1;
//                                         double timeValue = ((julianDayValue - floor(julianDayValue)) + 0.5) * 24;
//                                         components.hour = (int)floor(timeValue);
//                                         double minutes = (timeValue - floor(timeValue)) * 60;
//                                         components.minute = (int)floor(minutes);
//                                         components.second = (int)((minutes - floor(minutes)) * 60);
//                                         NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
//                                         NSDate *returnDate = [calendar dateFromComponents:components];
//
//                                         return returnDate;
//                                     },
//                                     ^NSDictionary<NSNumber *,NSDate *> * _Nonnull (int julianDayNumber, CLLocationCoordinate2D coordinate, NSDate *(^dateFromJulianDayNumber)(double))
//                                     {
//                                         double JanuaryFirst2000JDN = 2451545.0;
//                                         double westLongitude = coordinate.longitude * -1.0;
//
//                                         __block double Nearest = 0.0;
//                                         __block double ElipticalLongitudeOfSun = 0.0;
//                                         __block double ElipticalLongitudeRadians = ElipticalLongitudeOfSun * toRadians;
//                                         __block double MeanAnomoly = 0.0;
//                                         __block double MeanAnomolyRadians = MeanAnomoly * toRadians;
//                                         __block double MAprev = -1.0;
//                                         __block double Jtransit = 0.0;
//
//                                         while (MeanAnomoly != MAprev)
//                                         {
//                                             MAprev = MeanAnomoly;
//                                             Nearest = round(((double)julianDayNumber - JanuaryFirst2000JDN - 0.0009) - (westLongitude/360.0));
//                                             double Japprox = JanuaryFirst2000JDN + 0.0009 + (westLongitude/360.0) + Nearest;
//                                             if (Jtransit != 0.0) {
//                                                 Japprox = Jtransit;
//                                             }
//                                             double Ms = (357.5291 + 0.98560028 * (Japprox - JanuaryFirst2000JDN));
//                                             MeanAnomoly = fmod(Ms, 360.0);
//                                             MeanAnomolyRadians = MeanAnomoly * toRadians;
//                                             double EquationOfCenter = (1.9148 * sin(MeanAnomolyRadians)) + (0.0200 * sin(2.0 * (MeanAnomolyRadians))) + (0.0003 * sin(3.0 * (MeanAnomolyRadians)));
//                                             double eLs = (MeanAnomoly + 102.9372 + EquationOfCenter + 180.0);
//                                             ElipticalLongitudeOfSun = fmod(eLs, 360.0);
//                                             ElipticalLongitudeRadians = ElipticalLongitudeOfSun * toRadians;
//                                             if (Jtransit == 0.0) {
//                                                 Jtransit = Japprox + (0.0053 * sin(MeanAnomolyRadians)) - (0.0069 * sin(2.0 * ElipticalLongitudeRadians));
//                                             }
//                                         }
//
//                                         double DeclinationOfSun = asin( sin(ElipticalLongitudeRadians) * sin(23.45 * toRadians) ) * toDegrees;
//                                         double DeclinationOfSunRadians = DeclinationOfSun * toRadians;
//
//                                         //    NSDate *solarNoon = dateFromJulianDayNumber(Jtransit);
//
//                                         double H1 = (cos(ZenithOfficial * toRadians) - sin(coordinate.latitude * toRadians) * sin(DeclinationOfSunRadians));
//                                         double H2 = (cos(coordinate.latitude * toRadians) * cos(DeclinationOfSunRadians));
//                                         double HourAngle = acos( (H1  * toRadians) / (H2  * toRadians) ) * toDegrees;
//                                         double Jss = JanuaryFirst2000JDN + 0.0009 + ((HourAngle + westLongitude)/360.0) + Nearest;
//                                         double Jset = Jss + (0.0053 * sin(MeanAnomolyRadians)) - (0.0069 * sin(2.0 * ElipticalLongitudeRadians));
//                                         double Jrise = Jtransit - (Jset - Jtransit);
//
//                                         return @{@(TwilightDateSunrise) : dateFromJulianDayNumber(Jrise),
//                                                  @(TwilightDateSunset)  : dateFromJulianDayNumber(Jset)};
//                                     }));
//    }];
//}

@end


