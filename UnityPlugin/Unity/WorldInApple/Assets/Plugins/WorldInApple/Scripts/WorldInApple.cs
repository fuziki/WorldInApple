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
        private SpectralEnvelopeEstimator spectralEnvelopeEstimator;
        private AperiodicityEstimator aperiodicityEstimator;
        public ParameterModificator parameterModificator;
        private WorldInAppleSynthesizer3 synthesizer;
        public WorldInApple(int fs, double frame_period, int x_length)
        {
            parameters = new Parameters(fs, frame_period, x_length);
            f0Estimator = new DioF0Estimator(parameters);
            spectralEnvelopeEstimator = new SpectralEnvelopeEstimator(parameters);
            aperiodicityEstimator = new AperiodicityEstimator(parameters);
            parameterModificator = new ParameterModificator(parameters);
            synthesizer = new WorldInAppleSynthesizer3( parameters);
        }

        public double[] conv(double[] target)
        {
            for (int i = 0; i < parameters.x_length; i++)
                parameters.xRaw[i] = target[i];

            f0Estimator.EstimateF0();
            spectralEnvelopeEstimator.EstimateSpectral();
            aperiodicityEstimator.EstimatAperiodicity();
            parameterModificator.Modificate();
            synthesizer.Synthesis();

            var ret = new double[parameters.x_length];
            for (int i = 0; i < parameters.x_length; i++)
                ret[i] = parameters.yRaw[i];
            return ret;
        }

        public void Dispose()
        {
            parameters = null;
            f0Estimator = null;
            spectralEnvelopeEstimator = null;
            aperiodicityEstimator = null;
            parameterModificator = null;
            synthesizer = null;
        }
    }

    public class AllocableArray
    {
        double[] array_1 = null;
        double[][] array_2 = null;
        private GCHandle allocedArray;
        public AllocableArray(int size_1, int size_2 = -1)
        {
            if (size_2 == -1)
            {
                array_1 = new double[size_1];
                allocedArray = GCHandle.Alloc(array_1, GCHandleType.Pinned);
            }
            else
            {
                array_2 = new double[size_1][];
                for (int i = 0; i < size_1; i++)
                {
                    array_2[i] = new double[size_2];
                }
                allocedArray = GCHandle.Alloc(array_2, GCHandleType.Pinned);
            }
        }

        public IntPtr ArrayPtr
        { get {
                if (array_2 != null)
                    Debug.Log("aa: " + array_2.Length + ", " + array_2[0].Length);
                return allocedArray.AddrOfPinnedObject(); } }

        ~AllocableArray()
        {
            allocedArray.Free();
        }

        public double[] raw1
        { get { return array_1; } }

        public double[][] raw2
        { get { return array_2; } }
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

        private AllocableArray alloable_x;
        private AllocableArray alloable_y;
        private AllocableArray alloable_tmp_f0;
        private AllocableArray alloable_f0;
        private AllocableArray alloable_time_axis;
        private AllocableArray alloable_spectrogram;
        private AllocableArray alloable_aperiodicity;

        public IntPtr x
        { get { return alloable_x.ArrayPtr; } }
        public double[] xRaw
        { get { return alloable_x.raw1; } }

        public IntPtr y
        { get { return alloable_y.ArrayPtr; } }
        public double[] yRaw
        { get { return alloable_y.raw1; } }

        public IntPtr tmp_f0
        { get { return alloable_tmp_f0.ArrayPtr; } }

        public IntPtr f0
        { get { return alloable_f0.ArrayPtr; } }

        public double[] f0Raw
        { get { return alloable_f0.raw1; } }

        public IntPtr time_axis
        { get { return alloable_time_axis.ArrayPtr; } }

        public IntPtr spectrogram
        { get { return alloable_spectrogram.ArrayPtr; } }

        public IntPtr aperiodicity
        { get { return alloable_aperiodicity.ArrayPtr; } }

        public Parameters(int fs, double frame_period, int x_length)
        {
            this.fs = fs;
            this.frame_period = frame_period;
            this.x_length = x_length;

            this.f0_length = GetSamplesForDIO(fs, x_length, frame_period);


            var cheapTrickOption = make_CheapTrickOption(fs);
            this.fft_size = GetFFTSizeForCheapTrick(fs, cheapTrickOption);
            destroy_CheapTrickOption(cheapTrickOption);

            Debug.Log("f0_length: " + f0_length + ", fft_size:" + fft_size);

            this.alloable_x = new AllocableArray(x_length);
            this.alloable_y = new AllocableArray(x_length);
            this.alloable_tmp_f0 = new AllocableArray(f0_length);
            this.alloable_f0 = new AllocableArray(f0_length);
            this.alloable_time_axis = new AllocableArray(f0_length);
            this.alloable_spectrogram = new AllocableArray(f0_length, fft_size / 2 + 1);
            this.alloable_aperiodicity = new AllocableArray(f0_length, fft_size / 2 + 1);
        }
        ~Parameters()
        {
            alloable_x = null;
            alloable_y = null;
            alloable_tmp_f0 = null;
            alloable_f0 = null;
            alloable_time_axis = null;
            alloable_spectrogram = null;
            alloable_aperiodicity = null;
        }
    }

    public class DioF0Estimator
    {
        private const string dllName = Configs.DllName;

        [DllImport(dllName)]
        private static extern IntPtr make_DioOption(double frame_period);

        [DllImport(dllName)]
        private static extern void destroy_DioOption(IntPtr option);

        [DllImport(dllName)]
        private static extern void Dio(IntPtr x, int x_length, int fs, IntPtr option, IntPtr temporal_positions, IntPtr f0);

        [DllImport(dllName)]
        private static extern void StoneMask(IntPtr x, int x_length, int fs, IntPtr temporal_positions, IntPtr f0, int f0_length, IntPtr refined_f0);

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
            Dio(parameters.x, parameters.x_length, parameters.fs, option, parameters.time_axis, parameters.tmp_f0);
            StoneMask(parameters.x, parameters.x_length, parameters.fs, parameters.time_axis, parameters.tmp_f0, parameters.f0_length, parameters.f0);
        }
    }

    public class SpectralEnvelopeEstimator
    {
        private const string dllName = Configs.DllName;

        [DllImport(dllName)]
        private static extern IntPtr make_CheapTrickOption(int fs);

        [DllImport(dllName)]
        private static extern void destroy_CheapTrickOption(IntPtr option);

        [DllImport(dllName)]
        private static extern void CheapTrick(IntPtr x, int x_length, int fs, IntPtr temporal_positions, IntPtr f0, int f0_length, IntPtr option, IntPtr spectrogram);

        private IntPtr option;
        private Parameters parameters;

        public SpectralEnvelopeEstimator(Parameters parameters)
        {
            this.parameters = parameters;
            option = make_CheapTrickOption(parameters.fs);
        }

        ~SpectralEnvelopeEstimator()
        {
            this.parameters = null;
            destroy_CheapTrickOption(option);
        }

        public void EstimateSpectral()
        {
            Debug.Log("EstimateSpectral");
            CheapTrick(parameters.x, parameters.x_length, parameters.fs, parameters.time_axis, parameters.f0, parameters.f0_length, option, parameters.spectrogram);
            var _ = parameters.spectrogram;
        }
    }

    public class AperiodicityEstimator
    {
        private const string dllName = Configs.DllName;

        [DllImport(dllName)]
        private static extern IntPtr make_D4COption(double threshold);

        [DllImport(dllName)]
        private static extern void destroy_D4COption(IntPtr option);

        [DllImport(dllName)]
        private static extern void D4C(IntPtr x, int x_length, int fs, IntPtr temporal_positions, IntPtr f0, int f0_length, int fft_size, IntPtr option, IntPtr aperiodicity);

        private IntPtr option;
        private Parameters parameters;

        public AperiodicityEstimator(Parameters parameters)
        {
            this.parameters = parameters;
            option = make_D4COption(parameters.fs);
        }

        ~AperiodicityEstimator()
        {
            this.parameters = null;
            destroy_D4COption(option);
        }

        public void EstimatAperiodicity()
        {
            Debug.Log("EstimatAperiodicity");
            D4C(parameters.x, parameters.x_length, parameters.fs, parameters.time_axis, parameters.f0, parameters.f0_length, parameters.fft_size, option, parameters.aperiodicity);
            var _ = parameters.spectrogram;
        }
    }

    public class ParameterModificator
    {
        public double pitch = 1;
        //public double formant = 1;

        private Parameters parameters;
        public ParameterModificator(Parameters parameters)
        {
            this.parameters = parameters;
        }

        public void Modificate()
        {
            for(int i = 0; i < parameters.f0Raw.Length; i++)
                parameters.f0Raw[i] *= pitch;
        }
    }

    public class WorldInAppleSynthesizer3
    {
        private const string dllName = Configs.DllName;

        [DllImport(dllName)]
        private static extern void Synthesis(IntPtr f0, int f0_length, IntPtr spectrogram, IntPtr aperiodicity, int fft_size, double frame_period, int fs, int y_length, IntPtr y);

        private Parameters parameters;
        public WorldInAppleSynthesizer3(Parameters parameters)
        {
            this.parameters = parameters;
        }

        public void Synthesis()
        {
            Debug.Log("Synthesis");
            Synthesis(parameters.f0, parameters.f0_length, parameters.spectrogram, parameters.aperiodicity, parameters.fft_size, parameters.frame_period, parameters.fs, parameters.x_length, parameters.y);
        }
    }
}
