#import <WMF/NSDate+WMFRelativeDate.h>
#import <WMF/WMFLocalization.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>
#import <WMF/NSURL+WMFLinkParsing.h>

NSString *const WMFAbbreviatedRelativeDateAgo = @"includingAgo";
NSString *const WMFAbbreviatedRelativeDate = @"excludingAgo";

@implementation WMFLocalizedDateFormatStrings

+ (NSString *)yearsAgoForWikiLanguage:(nullable NSString *)language {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-years-ago", language, nil, @"{{PLURAL:%1$d|0=This year|1=Last year|%1$d years ago}}", @"Relative years ago. 0 = this year, singular = last year. %1$d will be replaced with the number of years ago.");
}

+ (NSString *)daysAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-days-ago", nil, nil, @"{{PLURAL:%1$d|0=Today|1=Yesterday|%1$d days ago}}", @"Relative days ago. 0 = today, singular = yesterday. %1$d will be replaced with the number of days ago.");
}

+ (NSString *)hoursAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-hours-ago", nil, nil, @"{{PLURAL:%1$d|0=Recently|%1$d hour ago|%1$d hours ago}}", @"Relative hours ago. 0 = this hour. %1$d will be replaced with the number of hours ago.");
}

+ (NSString *)hoursAgoAbbreviated {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-hours-ago-abbreviated", nil, nil, @"%1$dh ago", @"Relative hours ago, abbreviated. %1$d will be replaced with the number of hours ago.");
}

+ (NSString *)hoursAbbreviated {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-hours-abbreviated", nil, nil, @"%1$dh", @"Relative hours, abbreviated. %1$d will be replaced with the number of hours.");
}

+ (NSString *)minutesAgo {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-minutes-ago", nil, nil, @"{{PLURAL:%1$d|0=Just now|%1$d minute ago|%1$d minutes ago}}", @"Relative minutes ago. 0 = just now. %1$d will be replaced with the number of minutes ago.");
}

+ (NSString *)minutesAgoAbbreviated {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-minutes-ago-abbreviated", nil, nil, @"%1$dm ago", @"Relative minutes ago, abbreviated. %1$d will be replaced with the number of minutes ago.");
}

+ (NSString *)minutesAbbreviated {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-minutes-abbreviated", nil, nil, @"%1$dm", @"Relative minutes, abbreviated. %1$d will be replaced with the number of minutes.");
}

+ (NSString *)secondsAgoAbbreviated {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-seconds-ago-abbreviated", nil, nil, @"%1$ds ago", @"Relative seconds ago, abbreviated. %1$d will be replaced with the number of seconds ago.");
}

+ (NSString *)secondsAbbreviated {
    return WMFLocalizedStringWithDefaultValue(@"relative-date-seconds-abbreviated", nil, nil, @"%1$ds", @"Relative seconds, abbreviated. %1$d will be replaced with the number of seconds.");
}

@end

@implementation NSDate (WMFRelativeDate)

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToLocalDate:(nonnull NSDate *)date {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
    NSInteger days = [calendar wmf_daysFromDate:self toDate:date]; // Calendar days - less than 24 hours ago that is yesterday returns 1 day ago
    if (days > 2) {
        return [[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self];
    } else if (days > 0) {
        return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings daysAgo], days];
    } else {
        NSDateComponents *components = [calendar wmf_components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:self toDate:date];
        if (components.hour > 12) {
            return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings daysAgo], days]; //Today or Yesterday
        } else if (components.hour > 0) {
            return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings hoursAgo], components.hour];
        } else {
            NSInteger minutes = MAX(0, components.minute);
            return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings minutesAgo], minutes];
        }
    }
}

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToNow {
    return [self wmf_localizedRelativeDateStringFromLocalDateToLocalDate:[NSDate date]];
}

- (NSString *)wmf_localizedRelativeDateFromMidnightUTCDate {
    NSDate *now = [NSDate date];
    NSDate *midnightUTC = [now wmf_midnightUTCDateFromLocalDate];
    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
    NSInteger days = MAX(0, [calendar wmf_daysFromDate:self toDate:midnightUTC]);
    if (days < 2) {
        return [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings daysAgo], days];
    } else {
        return [[NSDateFormatter wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self];
    }
}

- (NSDictionary<NSString *, NSString *>*)wmf_localizedRelativeDateStringFromLocalDateToNowAbbreviated {
    NSDate *now = [NSDate date];
    NSMutableDictionary *result = [NSMutableDictionary new];

    NSDateComponents *components = [[NSCalendar currentCalendar] wmf_components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:self toDate:now];
    if (components.hour > 0) {
        result[WMFAbbreviatedRelativeDateAgo] = [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings hoursAgoAbbreviated], components.hour];
        result[WMFAbbreviatedRelativeDate] = [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings hoursAbbreviated], components.hour];
    } else if (components.minute > 0) {
        result[WMFAbbreviatedRelativeDateAgo] = [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings minutesAgoAbbreviated], components.minute];
        result[WMFAbbreviatedRelativeDate] = [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings minutesAbbreviated], components.minute];
    } else if (components.second > 0) {
        result[WMFAbbreviatedRelativeDateAgo] = [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings secondsAgoAbbreviated], components.second];
        result[WMFAbbreviatedRelativeDate] = [NSString localizedStringWithFormat:[WMFLocalizedDateFormatStrings secondsAbbreviated], components.second];
    }
    return result;
}

@end
