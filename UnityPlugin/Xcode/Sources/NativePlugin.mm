//
//  NativePlugin.mm
//  PROJECT_NAME
//
//  Created by AUTHOR on YYYY/MM/DD.
//

#include <stdio.h>

#import IMPORT_SWIFT_HEADER
#import "NativePlugin.h"

int add_one(int num) {
    return (int)[AddOne addWithNum: num];
}

DioOption* make_DioOption(double frame_period) {
    DioOption *option = (DioOption*)malloc(sizeof(DioOption));
    InitializeDioOption(option);
    option->frame_period = frame_period;
    return option;
}

D4COption* make_D4COption(double threshold) {
    D4COption *option = (D4COption*)malloc(sizeof(D4COption));
    InitializeD4COption(option);
    option->threshold = threshold;
    return option;
}

CheapTrickOption* make_CheapTrickOption(int fs) {
    CheapTrickOption *option = (CheapTrickOption*)malloc(sizeof(CheapTrickOption));
    InitializeCheapTrickOption(fs, option);
    option->f0_floor = 71;
    return option;
}

WorldSynthesizer* make_WorldSynthesizer(int fs, double frame_period, int fft_size, int buffer_size, int number_of_pointers) {
    WorldSynthesizer * synthesizer = (WorldSynthesizer*)malloc(sizeof(WorldSynthesizer));
    InitializeSynthesizer(fs, frame_period, fft_size, buffer_size, number_of_pointers, synthesizer);
    return synthesizer;
}

void destroy_DioOption(DioOption *option) {
    free(option);
}

void destroy_D4COption(D4COption *option) {
    free(option);
}

void destroy_CheapTrickOption(CheapTrickOption *option) {
    free(option);
}

void destroy_WorldSynthesizer(WorldSynthesizer *synthesizer) {
    DestroySynthesizer(synthesizer);
    free(synthesizer);
}
