// ============================================================
//  a2_phrygian_arrays.ck   (session 2 assignment)
//  Aeon — sept 2026
//  Same dark A phrygian idea as a1, but now the notes live in
//  arrays, pitch comes from Std.mtof, and Math.random2 gets to
//  mess with the phrase. Pan2 + Math.sin for movement.
//  No functions / spork yet — that's week 4.
// ============================================================

<<< "a2 // aeon // session 2" >>>;

// ============================================================
//  SOUND NETWORK
// ============================================================
TriOsc lead => Pan2 pan => dac;     // lead goes through a panner
SqrOsc bass => dac;                 // bass straight in, centre
0.0 => lead.gain;
0.0 => bass.gain;

// ============================================================
//  GLOBAL STATE
// ============================================================
138.0 => float BPM;
(60.0 / BPM / 4.0)::second => dur STEP;     // 16th at 138
0.42 => float LEAD_VOL;
0.14 => float BASS_VOL;                     // sqr is loud, keep it down
57   => int   ROOT;                         // A3 as midi

// ============================================================
//  SCALE + PHRASES — everything musical sits up here
// ============================================================
// A phrygian, semitones from root. the 1 is the whole flavour.
[0, 1, 3, 5, 7, 8, 10, 12, 13, 15] @=> int PHR[];

// phrase as scale degrees (index into PHR), not midi — easier to transpose
[7, 6, 5, 4, 3, 2, 1, 0,  0, 2, 3, 5, 4, 3, 1, 0] @=> int phrase[];

// one length per note, in STEPs. MUST match phrase.cap().
[1, 1, 1, 1, 2, 1, 1, 4,  1, 1, 1, 1, 2, 1, 1, 4] @=> int lens[];

// bass: one degree per bar
[0, 5, 3, 1] @=> int bassDeg[];

<<< "scale", PHR.cap(), "/ phrase", phrase.cap(), "/ lens", lens.cap() >>>;
if (phrase.cap() != lens.cap()) <<< "!! phrase and lens don't match, fix that" >>>;

// quick array edit — swap the 5th note for the b6 so bar 2 sits darker
<<< "phrase[4] was", phrase[4] >>>;
5 => phrase[4];
<<< "phrase[4] now", phrase[4] >>>;


// ============================================================
//  PART 1 — phrase straight, no tricks
// ============================================================
<<< "pt1 : phrase, dry" >>>;

LEAD_VOL => lead.gain;
0.0 => pan.pan;

for (0 => int i; i < phrase.cap(); i++) {
    ROOT + PHR[ phrase[i] ] => int midi;        // degree -> semitone -> midi
    Std.mtof(midi) => lead.freq;                // midi -> hz
    <<< "  ", i, "deg", phrase[i], "midi", midi, "len", lens[i] >>>;
    lens[i] * STEP => now;
}

0.0 => lead.gain;
STEP * 2 => now;


// ============================================================
//  PART 2 — bass + lead, lead swims L/R on Math.sin
// ============================================================
<<< "pt2 : + bass, panning" >>>;

LEAD_VOL => lead.gain;
BASS_VOL => bass.gain;

for (0 => int i; i < phrase.cap(); i++) {
    // i / 4 = bar number -> bass degree. integer division does the work.
    ROOT - 12 + PHR[ bassDeg[i / 4] ] => int bmidi;     // one octave under
    Std.mtof(bmidi) => bass.freq;

    ROOT + PHR[ phrase[i] ] => int midi;
    Std.mtof(midi) * 1.004 => lead.freq;                // hair sharp vs bass. beating.

    Math.sin(i * 0.6) => pan.pan;                       // -1..1, slow wobble

    <<< "  bar", i / 4, "bass", bmidi, "lead", midi, "pan", pan.pan() >>>;
    lens[i] * STEP => now;
}

0.0 => lead.gain;
0.0 => bass.gain;
STEP * 2 => now;


// ============================================================
//  PART 3 — the computer solos over the same material
//  random index into the phrase, random octave jump, random dynamics.
//  seeded so it's the same "random" solo every run (delete the srandom
//  line if you want it different every time).
// ============================================================
<<< "pt3 : random solo (seeded)" >>>;

Math.srandom(138);
LEAD_VOL => lead.gain;
BASS_VOL => bass.gain;
0.0 => pan.pan;
24 => int SOLO_LEN;

for (0 => int i; i < SOLO_LEN; i++) {
    // bass keeps cycling the bars underneath so it still feels like the tune
    ROOT - 12 + PHR[ bassDeg[(i / 4) % bassDeg.cap()] ] => int bmidi;
    Std.mtof(bmidi) => bass.freq;

    // ~10% rests. silence is a note too.
    if (Math.random2f(0.0, 1.0) < 0.10) {
        0.0 => lead.gain;
        STEP => now;
        LEAD_VOL => lead.gain;
        continue;
    }

    Math.random2(0, phrase.cap() - 1) => int idx;     // steal a note from the phrase
    ROOT + PHR[ phrase[idx] ] => int midi;
    if (Math.random2(0, 2) == 0) 12 +=> midi;         // 1 in 3: octave up

    Math.random2f(0.22, 0.5) => lead.gain;            // human-ish dynamics
    Math.random2f(-0.8, 0.8) => pan.pan;              // jump around the field

    // length: mostly 16ths, sometimes 8ths, rarely a hold
    1 => int len;
    if (Math.random2f(0.0, 1.0) < 0.20) 2 => len;
    if (Math.random2f(0.0, 1.0) < 0.07) 4 => len;

    Std.mtof(midi) => lead.freq;
    <<< "  solo", i, "idx", idx, "midi", midi, "g", lead.gain(), "len", len >>>;
    len * STEP => now;
}

0.0 => bass.gain;
STEP * 2 => now;


// ============================================================
//  PART 4 — phrase backwards, then out
// ============================================================
<<< "pt4 : reverse, out" >>>;

LEAD_VOL => lead.gain;
0.0 => pan.pan;

for (phrase.cap() - 1 => int i; i >= 0; i--) {
    ROOT + PHR[ phrase[i] ] => int midi;
    Std.mtof(midi) => lead.freq;
    Std.abs(midi - ROOT) => int dist;                  // semitones from root, always +
    <<< "  rev", i, "midi", midi, "dist", dist >>>;
    lens[i] * STEP => now;
}

// let the last note ring and die
0.4 => float g;
while (g > 0.0) {
    g => lead.gain;
    0.01 -=> g;
    20::ms => now;
}
0.0 => lead.gain;

Std.ftoi(BPM) => int bpmInt;                            // float -> int, because why not
<<< "done //", bpmInt, "bpm" >>>;
