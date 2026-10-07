// ============================================================
//  a3_step.ck   (session 3 assignment)
//  Aeon — oct 2026
//  Modulo step sequencer on SndBuf. 138 bpm, 16th grid,
//  8 bars then stops. Needs /audio next to this file.
// ============================================================

<<< "a3 // aeon // session 3" >>>;

// ============================================================
//  SOUND NETWORK
// ============================================================
Gain master => dac;
0.7 => master.gain;

SndBuf  kick  => master;
SndBuf  snare => master;
SndBuf  clap  => master;
SndBuf  hat   => Pan2 hatPan => master;
SndBuf  bell  => master;
SndBuf  click => master;
SndBuf2 fx    => master;            // stereo file

// ============================================================
//  FILES
// ============================================================
me.dir() + "audio/" => string AUDIO;
<<< "audio:", AUDIO >>>;

AUDIO + "kick_01.wav"    => kick.read;
AUDIO + "hihat_01.wav"   => hat.read;
AUDIO + "clap_01.wav"    => clap.read;
AUDIO + "cowbell_01.wav" => bell.read;
AUDIO + "click_01.wav"   => click.read;

// pools — pick one at random each time
[ AUDIO + "snare_01.wav", AUDIO + "snare_02.wav", AUDIO + "snare_03.wav" ] @=> string snares[];
[ AUDIO + "stereo_fx_01.wav", AUDIO + "stereo_fx_02.wav", AUDIO + "stereo_fx_03.wav",
  AUDIO + "stereo_fx_04.wav", AUDIO + "stereo_fx_05.wav" ] @=> string fxs[];
snares[0] => snare.read;
fxs[0]    => fx.read;
<<< snares.cap(), "snares,", fxs.cap(), "fx" >>>;

// park play heads at the end so nothing fires on its own
kick.samples()  => kick.pos;
snare.samples() => snare.pos;
clap.samples()  => clap.pos;
hat.samples()   => hat.pos;
bell.samples()  => bell.pos;
click.samples() => click.pos;
fx.samples()    => fx.pos;

// ============================================================
//  GLOBAL STATE
// ============================================================
138.0 => float BPM;
(60.0 / BPM / 4.0)::second => dur STEP;     // 16th
16 => int STEPS_PER_BAR;
8  => int BARS;

0.9  => kick.gain;
0.6  => snare.gain;
0.5  => clap.gain;
0.25 => hat.gain;
0.3  => bell.gain;
0.4  => click.gain;
0.5  => fx.gain;


// ============================================================
//  SEQUENCER — counter % 16 = step in the bar
// ============================================================
0 => int counter;

while (counter < BARS * STEPS_PER_BAR) {

    counter % STEPS_PER_BAR => int step;    // 0..15
    counter / STEPS_PER_BAR => int bar;     // 0..7

    // kick on 0 4 8 12 — except bar 6, that's the breakdown
    if (step % 4 == 0 && bar != 6) 0 => kick.pos;

    // snare on 4 and 12, random file, slight pitch wobble
    if (step == 4 || step == 12) {
        snares[ Math.random2(0, snares.cap() - 1) ] => snare.read;
        Math.random2f(0.9, 1.1) => snare.rate;
        0 => snare.pos;
    }

    // clap doubles the snare on 12
    if (step == 12) 0 => clap.pos;

    // hat every 16th, random rate, sine pan
    Math.random2f(0.8, 1.6) => hat.rate;
    Math.sin(counter * 0.4) => hatPan.pan;
    0 => hat.pos;

    // cowbell on the offbeat 8ths, second half of the track only
    if (bar >= 4 && step % 4 == 2) 0 => bell.pos;

    // fx once a bar: random file, even bars forward / odd bars reversed
    if (step == 0) {
        fxs[ Math.random2(0, fxs.cap() - 1) ] => fx.read;
        if (bar % 2 == 0) { 0 => fx.pos;             1.0 => fx.rate; }
        else              { fx.samples() => fx.pos; -1.0 => fx.rate; }
    }

    // bar 6 breakdown: click every 16th, pitch climbing
    if (bar == 6) {
        0.6 + step * 0.1 => click.rate;
        0 => click.pos;
    }

    <<< "bar", bar, "step", step >>>;

    counter++;
    STEP => now;
}


// ============================================================
//  OUTRO — reversed snare, master fades
// ============================================================
snare.samples() => snare.pos;
-0.4 => snare.rate;

0.7 => float g;
while (g > 0.0) {
    g => master.gain;
    0.01 -=> g;
    30::ms => now;
}

<<< "done" >>>;
