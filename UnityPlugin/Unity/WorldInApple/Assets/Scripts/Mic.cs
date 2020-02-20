using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;
using System;

[RequireComponent(typeof(AudioSource))]
public class Mic2 : MonoBehaviour {

    [SerializeField]
    [Range(0.5f, 2f)]
    private float pitch = 1;

    private int x_length = 10240;
    private double frame_period = 5;
    private int fs = 48000;

    List<float[]> micBuffer = new List<float[]>();
    List<float[]> playableBuffer = new List<float[]>();

    private double[] x;

    private WorldInApplePlugin.WorldInApple worldInApple;

    // Use this for initialization
    void Awake()
    {
        x = new double[x_length];
        worldInApple = new WorldInApplePlugin.WorldInApple(fs, frame_period, x_length);
    }

    void Start()
    {
        var audio = GetComponent<AudioSource>();
        audio.clip = Microphone.Start(null, true, 1, fs);
        audio.loop = true;
        while (Microphone.GetPosition(null) <= 0) { }
        audio.Play();
    }

    // Update is called once per frame
    void Update() 
    {
        worldInApple.parameterModificator.pitch = pitch;

        if (micBuffer.Count < 12) return;

        for (int i = 0; i < 10; i++)
        {
            for (int j = 0; j < 1024; j++)
            {
                x[i * 1024 + j] = micBuffer[i][j];
            }
        }
        micBuffer.RemoveRange(0, 10);

        var y = worldInApple.conv(x);

        for (int i = 0; i < 10; i++)
        {
            var buff = new float[1024];
            for (int j = 0; j < 1024; j++)
            {
                buff[j] = (float)y[1024 * i + j];
            }
            playableBuffer.Add(buff);
        }

    }

    void OnAudioFilterRead(float[] data, int channels)
    {

        var queue = new float[1024];
        for (int i = 0; i < queue.Length; i++)
        {
            queue[i] = data[i * 2];
        }
        micBuffer.Add(queue);

        if(playableBuffer.Count == 0)
        {
            for (int i = 0; i < data.Length; i++)
                data[i] = 0;
            return;
        }
        var play = playableBuffer[0];
        playableBuffer.RemoveAt(0);

        for(int i = 0; i < play.Length; i++)
        {
            data[i * 2] = play[i];
            data[i * 2 + 1] = play[i];
        }
    }

    void OnDestroy()
    {
        worldInApple.Dispose();
    }
}


[RequireComponent(typeof(AudioSource))]
public class Mic : MonoBehaviour
{

    [SerializeField]
    [Range(0.5f, 2f)]
    private float pitch = 1;

    //private AudioSource audio;

    //WorldInAppleMacPlugin.bundle
    [DllImport("WorldInAppleMacPlugin")]
    private static extern int add_one(int num);

    //[DllImport("WorldInAppleMacPlugin")]
    //private static extern int add_two(int num);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern IntPtr make_DioOption(double frame_period);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern void destroy_DioOption(IntPtr option);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern void Dio(IntPtr x, int x_length, int fs, IntPtr option, IntPtr temporal_positions, IntPtr f0);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern int GetSamplesForDIO(int fs, int x_length, double frame_period);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern void StoneMask(IntPtr x, int x_length, int fs, IntPtr temporal_positions, IntPtr f0, int f0_length, IntPtr refined_f0);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern IntPtr make_CheapTrickOption(int fs);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern void destroy_CheapTrickOption(IntPtr option);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern void CheapTrick(IntPtr x, int x_length, int fs, IntPtr temporal_positions, IntPtr f0, int f0_length, IntPtr option, IntPtr spectrogram);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern int GetFFTSizeForCheapTrick(int fs, IntPtr option);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern IntPtr make_D4COption(double threshold);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern void destroy_D4COption(IntPtr option);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern void D4C(IntPtr x, int x_length, int fs, IntPtr temporal_positions, IntPtr f0, int f0_length, int fft_size, IntPtr option, IntPtr aperiodicity);

    [DllImport("WorldInAppleMacPlugin")]
    private static extern void Synthesis(IntPtr f0, int f0_length, IntPtr spectrogram, IntPtr aperiodicity, int fft_size, double frame_period, int fs, int y_length, IntPtr y);

    private IntPtr dioOption;
    private double[] x;
    private int x_length = 10240;
    private int f0_length;
    private double[] time_axis;
    private double[] tmp_f0;
    private double[] f0;
    private double frame_period = 5;

    private int fs = 48000;

    private IntPtr cheapTrickOption;

    //private double[,] spectrogram;

    private int fft_size;

    private IntPtr d4cOption;

    //private double[,] aperiodicity;

    private double[] y;

    double[][] spectrogram;
    double[][] aperiodicity;

    List<float[]> micBuffer = new List<float[]>();

    List<float[]> playableBuffer = new List<float[]>();


    // Use this for initialization
    void Awake()
    {


        //int b = add_two(32);
        //Debug.Log("b: " + b);

        x = new double[x_length];

        f0_length = GetSamplesForDIO(fs, x_length, frame_period);

        dioOption = make_DioOption(frame_period);

        time_axis = new double[f0_length];
        f0 = new double[f0_length];
        tmp_f0 = new double[f0_length];


        cheapTrickOption = make_CheapTrickOption(fs);
        fft_size = GetFFTSizeForCheapTrick(fs, cheapTrickOption);

        Debug.Log("f0_length: " + f0_length + ", fft_size: " + fft_size);

        //spectrogram = new double[f0_length, fft_size / 2 + 1];
        spectrogram = new double[f0_length][];
        for (int i = 0; i < spectrogram.Length; i++)
        {
            spectrogram[i] = new double[fft_size / 2 + 1];
        }

        d4cOption = make_D4COption(0.85);

        //aperiodicity = new double[f0_length, fft_size / 2 + 1];
        aperiodicity = new double[f0_length][];
        for (int i = 0; i < aperiodicity.Length; i++)
        {
            aperiodicity[i] = new double[fft_size / 2 + 1];
        }


        y = new double[x_length];

        //Debug.Log("spectrogram: " + spectrogram[f0_length - 10, fft_size / 2]);


        alloc_x = GCHandle.Alloc(x, GCHandleType.Pinned);
        alloc_time_axis = GCHandle.Alloc(time_axis, GCHandleType.Pinned);
        alloc_tmp_f0 = GCHandle.Alloc(tmp_f0, GCHandleType.Pinned);
        alloc_f0 = GCHandle.Alloc(f0, GCHandleType.Pinned);
        alloc_spectrogram = GCHandle.Alloc(spectrogram, GCHandleType.Pinned);
        alloc_aperiodicity = GCHandle.Alloc(aperiodicity, GCHandleType.Pinned);
        alloc_y = GCHandle.Alloc(y, GCHandleType.Pinned);

    }


    void Start()
    {
        var audio = GetComponent<AudioSource>();
        audio.clip = Microphone.Start(null, true, 1, fs);
        audio.loop = true;
        while (Microphone.GetPosition(null) <= 0) { }
        audio.Play();

        int a = add_one(32);
        Debug.Log("a: " + a);
    }

    // Update is called once per frame
    void Update()
    {
        //Debug.Log("micBuffer.Count: " + micBuffer.Count);

        if (micBuffer.Count < 12) return;

        for (int i = 0; i < 10; i++)
        {
            for (int j = 0; j < 1024; j++)
            {
                x[i * 1024 + j] = micBuffer[i][j];
            }
        }
        micBuffer.RemoveRange(0, 10);


        Dio(alloc_x.AddrOfPinnedObject(), x_length,
            fs, dioOption,
            alloc_time_axis.AddrOfPinnedObject(), alloc_tmp_f0.AddrOfPinnedObject());

        StoneMask(alloc_x.AddrOfPinnedObject(), x_length,
            fs, alloc_time_axis.AddrOfPinnedObject(),
            alloc_tmp_f0.AddrOfPinnedObject(), f0_length, alloc_f0.AddrOfPinnedObject());


        CheapTrick(alloc_x.AddrOfPinnedObject(), x_length,
            fs, alloc_time_axis.AddrOfPinnedObject(),
            alloc_f0.AddrOfPinnedObject(), f0_length,
            cheapTrickOption, alloc_spectrogram.AddrOfPinnedObject());

        D4C(alloc_x.AddrOfPinnedObject(), x_length,
            fs, alloc_time_axis.AddrOfPinnedObject(),
            alloc_f0.AddrOfPinnedObject(), f0_length,
            fft_size, d4cOption, alloc_aperiodicity.AddrOfPinnedObject());

        for (int i = 0; i < f0.Length; i++)
            f0[i] *= pitch;


        Synthesis(alloc_f0.AddrOfPinnedObject(), f0_length,
            alloc_spectrogram.AddrOfPinnedObject(), alloc_aperiodicity.AddrOfPinnedObject(),
            fft_size, frame_period, fs,
            y.Length, alloc_y.AddrOfPinnedObject());

        //for (int i = 0; i < y.Length; i++) y[i] = x[i];

        Debug.Log("check spectrogram, l: " + spectrogram.Length);
        for (int i = 0; i < spectrogram.Length; i++)
        {
            Debug.Log("check spectrogram, l: " + i + " = " + spectrogram[i].Length);
        }



        //Debug.Log("l: " + spectrogram.Length + ", l2" + spectrogram[20].Length);

        //string f0_str = "";
        //for (int i = 0; i < 1000; i++)
        //    f0_str += spectrogram[20][i] + ",";

        //Debug.Log("f0: " + f0_str);
        //x_posi = 0;

        for (int i = 0; i < 10; i++)
        {
            var buff = new float[1024];
            for (int j = 0; j < 1024; j++)
            {
                buff[j] = (float)y[1024 * i + j];
            }
            playableBuffer.Add(buff);
        }

    }

    GCHandle alloc_x;
    GCHandle alloc_time_axis;
    GCHandle alloc_tmp_f0;
    GCHandle alloc_f0;
    GCHandle alloc_spectrogram;
    GCHandle alloc_aperiodicity;
    GCHandle alloc_y;

    int x_posi = 0;
    void OnAudioFilterRead(float[] data, int channels)
    {

        var queue = new float[1024];
        for (int i = 0; i < queue.Length; i++)
        {
            queue[i] = data[i * 2];
        }
        micBuffer.Add(queue);

        if (playableBuffer.Count == 0)
        {
            for (int i = 0; i < data.Length; i++)
                data[i] = 0;
            return;
        }
        var play = playableBuffer[0];
        playableBuffer.RemoveAt(0);

        for (int i = 0; i < play.Length; i++)
        {
            data[i * 2] = play[i];
            data[i * 2 + 1] = play[i];
        }


        //if (x_posi == -1) return;
        //for(int i = 0; i < data.Length; i++)
        //{
        //    if (i % 2 == 1) continue;
        //    x[x_posi * 1024 + i / 2] = data[i];
        //}
        //x_posi += 1;
        //if (x_posi < 10)
        //{
        //    return;
        //}
        //x_posi = -1;

        //GCHandle alloc_x = GCHandle.Alloc(x, GCHandleType.Pinned);
        //GCHandle alloc_time_axis = GCHandle.Alloc(time_axis, GCHandleType.Pinned);
        //GCHandle alloc_tmp_f0 = GCHandle.Alloc(tmp_f0, GCHandleType.Pinned);
        //GCHandle alloc_f0 = GCHandle.Alloc(f0, GCHandleType.Pinned);
        //GCHandle alloc_spectrogram = GCHandle.Alloc(spectrogram, GCHandleType.Pinned);
        //GCHandle alloc_aperiodicity = GCHandle.Alloc(aperiodicity, GCHandleType.Pinned);
        //GCHandle alloc_y = GCHandle.Alloc(y, GCHandleType.Pinned);


    }

    void OnDestroy()
    {
        alloc_x.Free();
        alloc_time_axis.Free();
        alloc_tmp_f0.Free();
        alloc_f0.Free();
        alloc_spectrogram.Free();
        alloc_aperiodicity.Free();
        alloc_y.Free();

        if (dioOption != IntPtr.Zero) destroy_DioOption(dioOption);
        if (cheapTrickOption != IntPtr.Zero) destroy_CheapTrickOption(cheapTrickOption);
        if (d4cOption != IntPtr.Zero) destroy_D4COption(d4cOption);
        Debug.Log("on destroy");
    }
}
