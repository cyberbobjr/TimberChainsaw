"""Builds the chainsaw sounds of Timber! Chainsaw from CC0 recordings.

    python source/build_sounds.py <folder with the BigSoundBank .ogg files>

Sources (BigSoundBank, Joseph Sardin, licence CC0, https://bigsoundbank.com):
    0707 "Chainsaw #2", 0982 "Chainsaw (Starting)", 0983 "Chainsaw, Using"
    downloaded from https://bigsoundbank.com/UPLOAD/ogg/<n>.ogg

Segments were chosen from a loudness and engine-pitch profile (0.1 s steps):
loaded engine in wood = pitch drops to 100-170 Hz at full volume; idle = steady
low level; free revs = ~300 Hz. Loops: the first LOOP_FADE seconds are
cross-faded with the audio that follows the loop end (equal power), so the
end flows into the start without a click. Loudness normalised with ffmpeg
loudnorm, mono 44.1 kHz Ogg Vorbis.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Contents" / "mods" / "batman_TimberChainsaw" / "42.21" / "media" / "sound" / "Chainsaw"
SR = 48000
LOOP_FADE = 0.3
EDGE_FADE = 0.03

# output file: (source, start s, end s, loop, target loudness LUFS, fade out s)
SOUNDS = {
    "ChainsawStart.ogg": ("0982", 5.0, 9.6, False, -20, 0.4),
    "ChainsawStop.ogg": ("0982", 35.6, 37.6, False, -22, 0.2),
    "ChainsawIdle.ogg": ("0983", 104.0, 108.0, True, -24, 0),
    "ChainsawWoodCut.ogg": ("0707", 85.0, 89.0, True, -19, 0),
    "ChainsawRev.ogg": ("0707", 30.0, 34.0, True, -20, 0),
    "ChainsawAttack.ogg": ("0707", 25.4, 26.9, False, -19, 0.3),
    "ChainsawZombieHit.ogg": ("0983", 99.8, 100.6, False, -18, 0.15),
}


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-ac", "1", "-ar", str(SR),
                          "-f", "f32le", "-"], check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).copy()


def ramp(n):
    return np.sin(np.linspace(0, np.pi / 2, n)) ** 2


def cut(audio, start, end, loop, fade_out):
    a, b = int(start * SR), int(end * SR)
    if loop:
        x = int(LOOP_FADE * SR)
        seg = audio[a:b].copy()
        after = audio[b:b + x]
        r = np.sin(np.linspace(0, np.pi / 2, x))
        seg[:x] = after * np.cos(np.linspace(0, np.pi / 2, x)) + seg[:x] * r
        return seg
    seg = audio[a:b].copy()
    edge = int(EDGE_FADE * SR)
    seg[:edge] *= ramp(edge)
    if fade_out > 0:
        n = int(fade_out * SR)
        seg[-n:] *= ramp(n)[::-1]
    else:
        seg[-edge:] *= ramp(edge)[::-1]
    return seg


def encode(samples, target, path, loop):
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "in.f32"
        wav.write_bytes(samples.astype(np.float32).tobytes())
        # Loops: linear gain only (dynamic loudnorm would change the level at the seam).
        norm = f"loudnorm=I={target}:TP=-1.5:LRA=11" + (":linear=true" if loop else "")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "1",
                        "-i", str(wav), "-af", norm, "-ar", "44100", "-c:a", "libvorbis",
                        "-q:a", "5", str(path)], check=True)


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    source_dir = Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    cache = {}
    for name, (source, start, end, loop, target, fade_out) in SOUNDS.items():
        if source not in cache:
            cache[source] = decode(source_dir / f"{source}.ogg")
        encode(cut(cache[source], start, end, loop, fade_out), target, OUT / name, loop)
        print(f"{name}: {source} {start}-{end} s{' loop' if loop else ''}")


if __name__ == "__main__":
    main()
