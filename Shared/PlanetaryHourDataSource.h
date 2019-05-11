//
//  PlanetaryHourDataSource.h
//  JABPlanetaryHourFrameworkSharedSource
//
//  Created by Xcode Developer on 4/22/19.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <EventKit/EventKit.h>
//#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

//typedef int (^block_type)(int *);
//
//int (^block_var)(int *) = ^int(int *param)
//{
//    return *param;
//};
//
//typedef struct {
//    block_type blk;
//    int param;
//} block_structure;

typedef NS_ENUM(NSUInteger, TwilightDate) {
    TwilightDateSunrise,
    TwilightDateSunset
};

typedef NS_ENUM(NSUInteger, SolarCycleDate) {
    SolarCycleDateStart,
    SolarCycleDateMid,
    SolarCycleDateEnd
};

typedef NS_ENUM(NSUInteger, PlanetaryHourData) {
    StartDate,
    EndDate,
    Symbol,
    Name,
    Abbreviation,
    Color,
    Hour,
    Coordinate
};

#define SECONDS_PER_DAY 86400.00f
#define HOURS_PER_DAY 24
#define HOURS_PER_SOLAR_TRANSIT 12
#define NUMBER_OF_PLANETS 7

typedef NS_ENUM(NSUInteger, Meridian) {
    AM,
    PM
};

typedef NS_ENUM(NSUInteger, Planet) {
    Sun,
    Moon,
    Mars,
    Mercury,
    Jupiter,
    Venus,
    Saturn
};

typedef NS_ENUM(NSUInteger, PlanetaryHour) {
    PlanetaryHourPlanetSymbol,
    PlanetaryHourPlanetName,
    PlanetaryHourPlanetColor,
    PlanetaryHourOrdinal,
    PlanetaryHourStartDate,
    PlanetaryHourEndDate
};

@interface PlanetaryHourDataSource : NSArray <CLLocationManagerDelegate>

+ (nonnull PlanetaryHourDataSource *)data;

@property (strong, nonatomic) CLLocationManager *locationManager;

//@property (strong, nonatomic) __block dispatch_queue_t block_queue;
//@property (strong, nonatomic) __block dispatch_source_t block_queue_event;
//- (void)block_array;
//- (void)get_blocks;

- (void)solarCyclesForDays:(NSIndexSet *)days
         planetaryHourData:(NSIndexSet *)data
            planetaryHours:(NSIndexSet *)hours
             solarCycleCompletionBlock:(void(^ _Nullable)(NSDictionary<NSNumber *, NSDate *> * _Nonnull solarCycle))solarCycleCompletionBlock
          planetaryHourCompletionBlock:(void(^ _Nullable)(NSDictionary<NSNumber *, id> * _Nonnull planetaryHour))planetaryHourCompletionBlock
         planetaryHoursCompletionBlock:(void(^ _Nullable)(NSArray<NSDictionary<NSNumber *, id> *> * _Nonnull planetaryHours))planetaryHoursCompletionBlock
planetaryHourDataSourceCompletionBlock:(void(^ _Nullable)(NSError * __nullable error))planetaryHourDataSourceCompletionBlock;

@property (strong, nonatomic) Planet (^planetForPlanetSymbol)(NSString *planetarySymbol);
@property (strong, nonatomic) NSString *(^planetSymbolForPlanet)(Planet planet);
@property (strong, nonatomic) UIColor *(^colorForPlanetSymbol)(NSString *planetarySymbol);

- (UIImage * _Nonnull (^)(NSString * _Nonnull, UIColor * _Nullable, CGFloat))imageFromText;

- (NSDictionary *)placeholderPlanetaryHourData;

@end

NS_ASSUME_NONNULL_END
