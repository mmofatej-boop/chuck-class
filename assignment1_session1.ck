// ============================================================
//  a1_phrygian_sketch.ck   (session 1 assignment)
//  Aeon — sept 2026
//  Three oscs, no arrays, no functions — just time, loops
//  and a bunch of if/else. Dark A phrygian. 138 bpm.
//  Run: open in miniAudicle, start VM, add shred.
// ============================================================

<<< "a1 // aeon // session 1" >>>;

// ============================================================
//  SOUND NETWORK — think of dac as a 3-channel mixer
// ============================================================
SinOsc sub => dac;      // sub — sits underneath everything
SqrOsc lead => dac;     // lead — gritty, the loud one, keep it low
TriOsc pad => dac;      // pad — soft, in between

// everything starts muted. nothing leaks before I want it.
0.0 => sub.gain;
0.0 => lead.gain;
0.0 => pad.gain;

// ============================================================
//  GLOBAL STATE
// ============================================================
138.0 => float BPM;
(60.0 / BPM)::second => dur BEAT;        // one beat
BEAT / 4 => dur STEP;                    // 16th note
220.0 => float ROOT;                     // A3
0.45 => float LEAD_VOL;
0.30 => float PAD_VOL;
now => time T0;                          // remember when we started

// phrygian flavour without arrays: b2 is the whole point
ROOT * 1.0595 => float FLAT2;            // Bb — one semitone up (2^(1/12))
ROOT * 1.3348 => float FOURTH;           // D
ROOT * 1.4983 => float FIFTH;            // E
ROOT * 1.5874 => float FLAT6;            // F

<<< "root", ROOT, "hz  / step", STEP / second, "s" >>>;


// ============================================================
//  PART 1 — hello sine, but make it phrygian
//  hard-coded notes on purpose. this is the "before loops" idea.
// ============================================================
<<< "pt1 : sub intro" >>>;

0.5   => sub.gain;
ROOT  => sub.freq;   BEAT * 2 => now;   // A, hold
FLAT2 => sub.freq;   BEAT     => now;   // Bb — the sour note
ROOT  => sub.freq;   BEAT     => now;   // back home
FLAT6 => sub.freq;   BEAT * 2 => now;   // F — darker
FIFTH => sub.freq;   BEAT * 2 => now;   // E — resolve-ish

0.0 => sub.gain;
STEP => now;                              // tiny breath


// ============================================================
//  PART 2 — lead sweep (for loop). up slow, down fast.
// ============================================================
<<< "pt2 : square sweep" >>>;

0.18 => lead.gain;                        // sqr is loud. 0.18 is plenty.

// climb: 110 -> 880, 1hz per pass
for (110 => int hz; hz < 880; hz++) {
    hz => lead.freq;
    1.5::ms => now;
}

// fall: twice as fast, jumps of 3 — sounds more like a drop
for (880 => int hz; hz > 110; 3 -=> hz) {
    hz => lead.freq;
    1.5::ms => now;
}

0.0 => lead.gain;


// ============================================================
//  PART 3 — pad melody (while loop + if/else)
//  counter decides the note. no arrays yet, so if/else chain it is.
// ============================================================
<<< "pt3 : pad melody" >>>;

PAD_VOL => pad.gain;
0 => int n;
16 => int LEN;

while (n < LEN) {

    // pick the pitch — 4-step phrase repeated, with a twist on the last bar
    if (n % 4 == 0)        ROOT   => pad.freq;    // every bar starts home
    else if (n % 4 == 1)   FLAT2  => pad.freq;    // then the b2
    else if (n % 4 == 2)   FOURTH => pad.freq;
    else                   FIFTH  => pad.freq;

    // last 4 notes: kick it up an octave so the phrase actually goes somewhere
    if (n >= 12) pad.freq() * 2.0 => pad.freq;

    // accent beat 1 of each bar, ghost the rest
    if (n % 4 == 0)        PAD_VOL * 1.5 => pad.gain;
    else                   PAD_VOL * 0.7 => pad.gain;

    <<< "  n", n, "->", pad.freq(), "hz" >>>;

    // rhythm: beat 1 long, everything else a 16th
    if (n % 4 == 0)   STEP * 2 => now;
    else              STEP     => now;

    n++;
}

0.0 => pad.gain;
STEP => now;


// ============================================================
//  PART 4 — sub + lead together, slow detuned climb, then fade
// ============================================================
<<< "pt4 : sub + lead, fade" >>>;

0.4  => sub.gain;
0.12 => lead.gain;

for (55 => int hz; hz < 440; hz++) {
    hz         => sub.freq;
    hz * 2.007 => lead.freq;     // octave up + a hair sharp. beating = alive.
    3::ms => now;
}

// fade both with a float that shrinks. lead stays proportionally quieter.
0.4 => float fade;
while (fade > 0.0) {
    fade        => sub.gain;
    fade * 0.3  => lead.gain;
    0.008 -=> fade;
    25::ms => now;
}

0.0 => sub.gain;
0.0 => lead.gain;
0.0 => pad.gain;

<<< "done //", (now - T0) / second, "s" >>>;
