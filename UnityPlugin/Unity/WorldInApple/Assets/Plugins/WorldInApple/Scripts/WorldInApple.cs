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
        public double frame_period = 5;
        public Parameters(int fs, double frame_period, int x_length)
        {
            this.frame_period = frame_period;
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
