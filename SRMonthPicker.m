/*
 Copyright (C) 2012 Simon Rice
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "SRMonthPicker.h"

#define MONTH_ROW_MULTIPLIER 340
#define DEFAULT_MINIMUM_YEAR 1
#define DEFAULT_MAXIMUM_YEAR 99999
#define DATE_COMPONENT_FLAGS NSMonthCalendarUnit | NSYearCalendarUnit

@interface SRMonthPicker()

@property (nonatomic) int monthComponent;
@property (nonatomic) int yearComponent;
@property (nonatomic, readonly) NSArray* monthStrings;

-(int)yearFromRow:(NSUInteger)row;
-(NSUInteger)rowFromYear:(int)year;

@end

@implementation SRMonthPicker

@synthesize date = _date;
@synthesize monthStrings = _monthStrings;

-(id)initWithDate:(NSDate *)date
{
    self = [super init];
    if (self != nil){
        self.dataSource = self;
        self.delegate = self;
        [self setDate:date];
    }
    return self;
}

-(id)init
{
    self = [self initWithDate:[NSDate date]];
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    self.dataSource = self;
    self.delegate = self;
    
    if (!_date)
        [self setDate:[NSDate date]];
}

-(int)monthComponent
{
    return self.yearComponent ^ 1;
}

-(int)yearComponent
{
    return !self.yearFirst;
}

-(NSArray *)monthStrings
{
    return [[NSDateFormatter alloc] init].monthSymbols;
}

-(void)setYearFirst:(BOOL)yearFirst
{
    _yearFirst = yearFirst;
    NSDate* date = self.date;
    [self reloadAllComponents];
    [self setNeedsLayout];
    [self setDate:date];
}

-(void)setMinimumYear:(NSNumber *)minimumYear
{
    NSDate* currentDate = self.date;
    NSDateComponents* components = [[NSCalendar currentCalendar] components:DATE_COMPONENT_FLAGS fromDate:currentDate];
    components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    if (minimumYear && components.year < minimumYear.integerValue)
        components.year = minimumYear.integerValue;
    
    _minimumYear = minimumYear;
    [self reloadAllComponents];
    [self setDate:[[NSCalendar currentCalendar] dateFromComponents:components]];
}

-(void)setMaximumYear:(NSNumber *)maximumYear
{
    NSDate* currentDate = self.date;
    NSDateComponents* components = [[NSCalendar currentCalendar] components:DATE_COMPONENT_FLAGS fromDate:currentDate];
    components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    if (maximumYear && components.year > maximumYear.integerValue)
        components.year = maximumYear.integerValue;
    
    _maximumYear = maximumYear;
    [self reloadAllComponents];
    [self setDate:[[NSCalendar currentCalendar] dateFromComponents:components]];
}

-(int)yearFromRow:(NSUInteger)row
{
    int minYear = DEFAULT_MINIMUM_YEAR;
    
    if (self.minimumYear)
        minYear = self.minimumYear.integerValue;
    
    return row + minYear;
}

-(NSUInteger)rowFromYear:(int)year
{
    int minYear = DEFAULT_MINIMUM_YEAR;
    
    if (self.minimumYear)
        minYear = self.minimumYear.integerValue;
    
    return year - minYear;
}

-(void)setDate:(NSDate *)date
{
    NSDateComponents* components = [[NSCalendar currentCalendar] components:DATE_COMPONENT_FLAGS fromDate:date];
    components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    if (self.minimumYear && components.year < self.minimumYear.integerValue)
        components.year = self.minimumYear.integerValue;
    else if (self.maximumYear && components.year > self.maximumYear.integerValue)
        components.year = self.maximumYear.integerValue;
    
    int monthMidpoint = self.monthStrings.count * (MONTH_ROW_MULTIPLIER / 2);
    [self selectRow:(components.month - 1 + monthMidpoint) inComponent:self.monthComponent animated:NO];
    [self selectRow:[self rowFromYear:components.year] inComponent:self.yearComponent animated:NO];
    
    _date = date;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSDateComponents* components = [[NSDateComponents alloc] init];
    components.month = 1 + ([self selectedRowInComponent:self.monthComponent] % self.monthStrings.count);
    components.year = [self yearFromRow:[self selectedRowInComponent:self.yearComponent]];
    _date = [[NSCalendar currentCalendar] dateFromComponents:components];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == self.monthComponent)
        return MONTH_ROW_MULTIPLIER * self.monthStrings.count;
    
    int maxYear = DEFAULT_MAXIMUM_YEAR;
    if (self.maximumYear)
        maxYear = self.maximumYear.integerValue;
    
    return [self rowFromYear:maxYear] + 1;
}

-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    if (component == self.monthComponent)
        return 150.0f;
    else
        return 76.0f;
}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    CGFloat width = [self pickerView:self widthForComponent:component];
    CGRect frame = CGRectMake(0.0f, 0.0f, width, 45.0f);
    
    if (component == self.monthComponent)
    {
        const CGFloat padding = 9.0f;
        if (component) {
            frame.origin.x += padding;
            frame.size.width -= padding;
        }
        
        frame.size.width -= padding;
    }
    
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    
    if (component == self.monthComponent) {
        label.text = [self.monthStrings objectAtIndex:(row % self.monthStrings.count)];
        formatter.dateFormat = @"MMMM";
        label.textAlignment = component ? UITextAlignmentLeft : UITextAlignmentRight;
    } else {
        label.text = [NSString stringWithFormat:@"%d", [self yearFromRow:row]];
        label.textAlignment = UITextAlignmentCenter;
        formatter.dateFormat = @"y";
    }
    
    if ([[formatter stringFromDate:_date] isEqualToString:label.text])
        label.textColor = [UIColor colorWithRed:0.0f green:0.35f blue:0.91f alpha:1.0f];
    
    label.font = [UIFont boldSystemFontOfSize:24.0f];
    label.backgroundColor = [UIColor clearColor];
    label.shadowOffset = CGSizeMake(0.0f, 0.1f);
    label.shadowColor = [UIColor whiteColor];
    
    return label;
}

@end
