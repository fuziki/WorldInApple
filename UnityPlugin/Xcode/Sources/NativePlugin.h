//
//  NativePlugin.h
//  PROJECT_NAME
//
//  Created by AUTHOR on YYYY/MM/DD.
//

#ifndef NativePlugin_h
#define NativePlugin_h

#import "world/dio.h"
#import "world/stonemask.h"
#import "world/cheaptrick.h"
#import "world/d4c.h"
#import "world/synthesis.h"
#import "world/harvest.h"
#import "world/synthesisrealtime.h"
#import "world/matlabfunctions.h"

#ifdef __cplusplus
extern "C" {
#endif
    int add_one(int num);
    DioOption* make_DioOption(double frame_period);
    CheapTrickOption* make_CheapTrickOption(int fs);
    D4COption* make_D4COption(double threshold);
    WorldSynthesizer* make_WorldSynthesizer(int fs, double frame_period, int fft_size, int buffer_size, int number_of_pointers);
    void destroy_DioOption(DioOption *option);
    void destroy_CheapTrickOption(CheapTrickOption *option);
    void destroy_D4COption(D4COption *option);
    void destroy_WorldSynthesizer(WorldSynthesizer *synthesizer);
#ifdef __cplusplus
}
#endif

#endif /* NativePlugin_h */
