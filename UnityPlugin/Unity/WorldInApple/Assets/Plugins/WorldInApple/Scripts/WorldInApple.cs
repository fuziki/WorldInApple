using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;
using System;

namespace WorldInApplePlugin {
    public sealed class Configs
    {
        public const string DllName = "WorldInAppleMacPlugin";
        private Configs() { }
    }

    public class WorldInApple
    {
        private Parameters parameters;
        private DioF0Estimator f0Estimator;
        public WorldInApple(int fs, double frame_period, int x_length)
        {
            parameters = new Parameters(fs, frame_period, x_length);
            f0Estimator = new DioF0Estimator(parameters);
        }
    }

    public class Parameters
    {
        private const string dllName = Configs.DllName;

        [DllImport(dllName)]
        private static extern int GetSamplesForDIO(int fs, int x_length, double frame_period);

        [DllImport(dllName)]
        private static extern int GetFFTSizeForCheapTrick(int fs, IntPtr cheapTrickOption);

        [DllImport(dllName)]
        private static extern IntPtr make_CheapTrickOption(int fs); //tmp

        [DllImport(dllName)]
        private static extern void destroy_CheapTrickOption(IntPtr option); //tmp

        public readonly int fs;
        public readonly double frame_period;
        public readonly int x_length;

        public readonly int f0_length;
        public readonly int fft_size;

        private double[] tmp_f0;
        private double[] f0;
        private double[] time_axis;
        private double[][] spectrogram;
        private double[][] aperiodicity;

        public Parameters(int fs, double frame_period, int x_length)
        {
            this.fs = fs;
            this.frame_period = frame_period;
            this.x_length = x_length;

            this.f0_length = GetSamplesForDIO(fs, x_length, frame_period);

            this.time_axis = new double[f0_length];
            this.f0 = new double[f0_length];
            this.tmp_f0 = new double[f0_length];

            var cheapTrickOption = make_CheapTrickOption(fs);
            this.fft_size = GetFFTSizeForCheapTrick(fs, cheapTrickOption);
            destroy_CheapTrickOption(cheapTrickOption);

            this.spectrogram = new double[f0_length][];
            this.aperiodicity = new double[f0_length][];
            for (int i = 0; i < f0_length; i++)
            {
                spectrogram[i] = new double[fft_size / 2 + 1];
                aperiodicity[i] = new double[fft_size / 2 + 1];
            }
        }
    }

    public class DioF0Estimator
    {
        private const string dllName = Configs.DllName;

        [DllImport(dllName)]
        private static extern IntPtr make_DioOption(double frame_period);

        [DllImport(dllName)]
        private static extern void destroy_DioOption(IntPtr option);

        private IntPtr option;
        private Parameters parameters;

        public DioF0Estimator(Parameters parameters)
        {
            this.parameters = parameters;
            option = make_DioOption(parameters.frame_period);
        }

        ~DioF0Estimator()
        {
            this.parameters = null;
            destroy_DioOption(option);
        }

        public void EstimateF0()
        {

        }
    }
}
