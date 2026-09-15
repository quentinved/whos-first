#!/usr/bin/env python3
"""Compose Fingr's suspense-to-reveal score; original synthesis, no samples.

A minor-key pulse, accelerating clockwork, and a rising noise bed build to a
brief breath of silence. The reveal answers with a bright resolving chord.
"""
from array import array
import math
from pathlib import Path
import random
import sys
import wave

RATE = 44100
TAU = 2 * math.pi
OUTPUT = Path(__file__).resolve().parents[1] / 'Fingr/Resources/Audio'


def frequency(note):
    return 440 * 2 ** ((note - 69) / 12)


class Track:
    def __init__(self, duration):
        self.duration = duration
        self.left = [0.0] * round(duration * RATE)
        self.right = [0.0] * len(self.left)

    def add(self, start, duration, voice, level=1, pan=0):
        offset = round(start * RATE)
        gain_l = math.sqrt((1 - pan) / 2) * level
        gain_r = math.sqrt((1 + pan) / 2) * level
        for sample in range(min(round(duration * RATE), len(self.left) - offset)):
            t = sample / RATE
            value = voice(t)
            self.left[offset + sample] += value * gain_l
            self.right[offset + sample] += value * gain_r

    def pluck(self, start, note, level=0.26, duration=0.42, pan=0):
        f = frequency(note)
        def voice(t):
            envelope = min(1, t / 0.007) * math.exp(-t * 10)
            envelope *= min(1, max(0, duration - t) / 0.04)
            phase = TAU * f * t
            return envelope * (math.sin(phase) + 0.28 * math.sin(2 * phase) + 0.10 * math.sin(3 * phase))
        self.add(start, duration, voice, level, pan)
        self.add(start + 0.15, duration, voice, level * 0.16, -pan)

    def bass(self, start, note, duration=0.38, level=0.26):
        f = frequency(note)
        self.add(start, duration,
                 lambda t: min(1, t / 0.012) * math.exp(-t * 6) * min(1, (duration - t) / 0.04)
                 * (math.sin(TAU * f * t) + 0.2 * math.sin(TAU * f * 2 * t)), level)

    def beat(self, start, strength=1):
        # Soft kick, with an exponential pitch drop rather than a sampled drum.
        self.add(start, 0.2, lambda t: min(1, t / 0.004) * math.exp(-t * 23)
                 * math.sin(TAU * (48 * t + 2.7 * (1 - math.exp(-t * 30)))), 0.23 * strength)

    def hat(self, start, seed, strength=1):
        noise = random.Random(seed)
        self.add(start, 0.055, lambda t: min(1, t / 0.002) * math.exp(-t * 75)
                 * noise.uniform(-1, 1), 0.06 * strength, 0.15 if seed % 2 else -0.15)

    def pulse(self, start, note, progress, pan):
        f = frequency(note)
        duration = 0.23
        def voice(t):
            envelope = min(1, t / 0.004) * math.exp(-t * (19 - progress * 5))
            envelope *= min(1, max(0, duration - t) / 0.025)
            phase = TAU * f * t
            # Upper harmonics open up as the draw gets closer, also audible on a phone.
            tone = math.sin(phase) + (0.12 + progress * 0.24) * math.sin(phase * 2)
            tone += progress * 0.13 * math.sin(phase * 3)
            return envelope * tone
        self.add(start, duration, voice, 0.18 + progress * 0.12, pan)
        self.add(start + 0.12, duration, voice, 0.055, -pan)

    def tension_bed(self, seconds):
        root = frequency(50)
        def drone(t):
            progress = t / seconds
            envelope = min(1, t / 0.25) * (0.3 + progress * 0.7)
            # A fifth with a faint semitone beating above it: expectant, not scary.
            tone = math.sin(TAU * root * t) * 0.50
            tone += math.sin(TAU * root * 2.002 * t) * 0.23
            tone += math.sin(TAU * frequency(57) * t) * 0.16
            tone += math.sin(TAU * frequency(58) * t) * progress * 0.075
            return tone * envelope
        self.add(0, seconds, drone, 0.17)

        noise = random.Random(728)
        filtered = 0.0
        def riser(t):
            nonlocal filtered
            progress = t / seconds
            # Smooth noise with an opening filter and a continuously rising oscillator.
            cutoff = 0.025 + progress * progress * 0.42
            filtered += cutoff * (noise.uniform(-1, 1) - filtered)
            rate = math.log(5) / seconds
            phase = TAU * 190 * math.expm1(rate * t) / rate
            return progress ** 1.8 * (filtered * 0.64 + math.sin(phase) * 0.13)
        self.add(0, seconds, riser, 0.27, -0.12)

    def write(self, name, silence=0):
        # Short edge fades avoid clicks and leave a clean landing for the reveal.
        peak = max(max(map(abs, self.left)), max(map(abs, self.right)), 0.01)
        gain = min(1.8, 0.80 / peak)
        pcm = array('h')
        for i, (left, right) in enumerate(zip(self.left, self.right)):
            t = i / RATE
            fade = min(1, t / 0.008, max(0, self.duration - silence - t - 1 / RATE) / 0.035)
            for value in (left, right):
                pcm.append(round(max(-1, min(1, value * gain * fade)) * 32767))
        if sys.byteorder != 'little':
            pcm.byteswap()
        OUTPUT.mkdir(parents=True, exist_ok=True)
        with wave.open(str(OUTPUT / name), 'wb') as file:
            file.setnchannels(2)
            file.setsampwidth(2)
            file.setframerate(RATE)
            file.writeframes(pcm.tobytes())
        print(f'{name}: {self.duration:.2f}s, 44.1 kHz stereo')


def countdown(seconds):
    track = Track(seconds)
    track.tension_bed(seconds)
    motif = [62, 69, 65, 69, 62, 70, 65, 73]  # D minor, ending on a leading tone.
    start, index = 0.0, 0
    while start < seconds - 0.14:
        progress = start / seconds
        note = motif[index % len(motif)]
        if progress > 0.72:
            note += 12
        track.pulse(start, note, progress, pan=0.30 * math.sin(index * 1.7))
        track.hat(start, index, 0.5 + progress * 0.9)
        # Accelerate continuously from a measured pulse into a tight final roll.
        start += 0.29 - 0.215 * progress ** 0.85
        index += 1
    start = 0.0
    while start < seconds - 0.18:
        progress = start / seconds
        track.beat(start, 0.70 + progress * 0.4)
        track.beat(start + 0.12, 0.33 + progress * 0.24)
        track.bass(start, 50, duration=0.31, level=0.19 + progress * 0.09)
        start += 0.64 - 0.32 * progress
    # The 85 ms breath makes the result feel like a release; duration remains exact.
    track.write(f'fingr-countdown-{seconds}.wav', silence=0.085)


def reveal():
    track = Track(1.20)
    track.beat(0, 1.2)
    track.bass(0, 50, duration=0.85, level=0.31)
    for index, note in enumerate([74, 78, 81, 86]):
        track.pluck(index * 0.035, note, level=0.29, duration=0.9, pan=(index - 1.5) * 0.17)
    track.write('fingr-reveal.wav')


if __name__ == '__main__':
    countdown(3)
    countdown(5)
    reveal()
