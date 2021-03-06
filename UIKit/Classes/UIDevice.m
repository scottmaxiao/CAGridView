/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UIDevice.h"
#import <IOKit/IOKitLib.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <IOKit/ps/IOPowerSources.h>

NSString *const UIDeviceOrientationDidChangeNotification = @"UIDeviceOrientationDidChangeNotification";

static UIDevice *theDevice;

@implementation UIDevice

+ (void)initialize
{
    if (self == [UIDevice class]) {
        theDevice = [[UIDevice alloc] init];
    }
}

+ (UIDevice *)currentDevice
{
    return theDevice;
}

- (UIUserInterfaceIdiom)userInterfaceIdiom
{
    return UIUserInterfaceIdiomDesktop;
}

- (NSString *)name
{
    return [(__bridge NSString *)SCDynamicStoreCopyComputerName(NULL,NULL) autorelease];
}

- (UIDeviceOrientation)orientation
{
    return UIDeviceOrientationPortrait;
}


- (NSDictionary *)primaryPowerSource
{
    CFTypeRef powerSourceInfo = IOPSCopyPowerSourcesInfo();
    CFArrayRef powerSources = IOPSCopyPowerSourcesList(powerSourceInfo);
    
    if (CFArrayGetCount(powerSources) == 0) return nil;
    
    CFDictionaryRef primarySourceRef = IOPSGetPowerSourceDescription(powerSourceInfo, CFArrayGetValueAtIndex(powerSources, 0));
    NSDictionary *primarySource = [NSDictionary dictionaryWithDictionary:[(__bridge NSDictionary *) primarySourceRef copy]];
    
    CFRelease(primarySourceRef);
    CFRelease(powerSourceInfo);
    CFRelease(powerSources);

    return primarySource;
}

- (UIDeviceBatteryState)batteryState
{
    UIDeviceBatteryState state = UIDeviceBatteryStateUnknown;
    
#ifdef kIOPSPowerSourceStateKey
    NSDictionary *powerSource = [self primaryPowerSource];
    id powerSourceState = [powerSource objectForKey:(__bridge NSString *)CFSTR(kIOPSPowerSourceStateKey)];
    
    if ([powerSourceState isEqualToString:(__bridge NSString *)CFSTR(kIOPSACPowerValue)]) {
        id currentObj = [powerSource objectForKey:(__bridge NSString *)CFSTR(kIOPSCurrentCapacityKey)];
        id capacityObj = [powerSource objectForKey:(__bridge NSString *)CFSTR(kIOPSMaxCapacityKey)];
        
        if ([currentObj isEqualToNumber:capacityObj]) {
            state = UIDeviceBatteryStateFull;
        } else {
            state = UIDeviceBatteryStateCharging;
        }
    } else if ([powerSourceState isEqualToString:(__bridge NSString *)CFSTR(kIOPSBatteryPowerValue)]) {
        state = UIDeviceBatteryStateUnplugged;
    }
#endif
    
    return state;
}

- (float)batteryLevel
{
    float batteryLevel = 1.f;
    
#ifdef kIOPSCurrentCapacityKey
    NSDictionary *powerSource = [self primaryPowerSource];

    if (powerSource != nil) {
        id currentObj = [powerSource objectForKey:(__bridge NSString *)CFSTR(kIOPSCurrentCapacityKey)];
        id capacityObj = [powerSource objectForKey:(__bridge NSString *)CFSTR(kIOPSMaxCapacityKey)];
        
        batteryLevel = [currentObj floatValue] / [capacityObj floatValue];
    }
#endif
    
    return batteryLevel;
}

- (BOOL)isMultitaskingSupported
{
    return YES;
}

- (NSString *)systemName
{
    return [[NSProcessInfo processInfo] operatingSystemName];
}

- (NSString *)systemVersion
{
    return [[NSProcessInfo processInfo] operatingSystemVersionString];
}

- (NSString *)model
{
    return @"Mac";
}

- (BOOL)isGeneratingDeviceOrientationNotifications
{
    return NO;
}

- (void)beginGeneratingDeviceOrientationNotifications
{
}

- (void)endGeneratingDeviceOrientationNotifications
{
}

@end
