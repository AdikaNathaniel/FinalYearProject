#ifndef Runner_Bridging_Header_h
#define Runner_Bridging_Header_h

#if defined(__has_include)
  #if __has_include("GeneratedPluginRegistrant.h")
	// Only import GeneratedPluginRegistrant.h for compilers/environments that support it;
	// skip the import when using MSVC/IntelliSense which can produce .tlh/.tli wrappers and cause errors.
	#if !defined(_MSC_VER)
	  #import "GeneratedPluginRegistrant.h"
	#endif
  #else
	// GeneratedPluginRegistrant.h is not available (e.g. before a pod install or code generation).
	// Wrapping with defined(__has_include) + __has_include prevents IntelliSense/compile errors when the header is missing.
  #endif
#endif

// Add imports for any native iOS features you might use
#ifdef __OBJC__
#import <AVFoundation/AVFoundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>
#import <HealthKit/HealthKit.h>
#endif

#endif /* Runner_Bridging_Header_h */