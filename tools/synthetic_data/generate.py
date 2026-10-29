#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""
Synthetic 6MWT recordings
=========================

Generates deterministic six-minute walks with known ground truth for testing
distance estimators. Each scenario folder contains an app-style `session.json`
(GPS positions and pedometer counter samples) and a `reference.json` holding
the exact simulated route with cumulative `distance`.

The models are deliberately simple: they reproduce effects seen in real
recordings (correlated GPS drift, outages, underreporting positions, batched or
broken step counters, stride changes), not a faithful sensor simulation.

Usage (from the repository root):

    python3 tools/synthetic_data/generate.py            # writes data/synthetic/
    python3 tools/synthetic_data/generate.py -o out/    # custom directory
"""

from __future__ import annotations

import argparse
import json
import math
import random
import shutil
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Callable

# Public area that already appears in the example data.
ORIGIN_LAT = 48.4220
ORIGIN_LON = 9.9570
METERS_PER_DEG_LAT = 111_320.0
METERS_PER_DEG_LON = METERS_PER_DEG_LAT * math.cos(math.radians(ORIGIN_LAT))

WALK_SECONDS = 360.0
SIM_DT = 0.05
START = datetime(2026, 1, 15, 10, 0, 0, tzinfo=timezone.utc)


# --------------------------------------------------------------------------- #
# Scenario description
# --------------------------------------------------------------------------- #

Profile = Callable[[float], float]


def const(value: float) -> Profile:
    return lambda _t: value


def steps_of(*pieces: tuple[float, float]) -> Profile:
    """Piecewise-constant profile: [(until_second, value), ...]."""

    def f(t: float) -> float:
        for until, value in pieces:
            if t < until:
                return value
        return pieces[-1][1]

    return f


def ramp(t0: float, t1: float, a: float, b: float) -> Profile:
    def f(t: float) -> float:
        if t <= t0:
            return a
        if t >= t1:
            return b
        return a + (b - a) * (t - t0) / (t1 - t0)

    return f


@dataclass
class GpsQuality:
    """Error model for one time span (per axis).

    Phone positions are fused and smooth: the error mostly wanders slowly
    (an error *velocity* integrated into a mean-reverting offset) with little
    independent per-fix noise. The error velocity is what inflates summed
    path length; the offset is what the accuracy radius roughly describes.
    """

    drift_sigma: float  # stationary offset, metres
    drift_velocity: float  # error velocity, m/s
    white_sigma: float  # independent per-fix noise, metres
    accuracy: float  # mean reported accuracy radius, metres
    velocity_tau: float = 8.0  # correlation time of the error velocity, s
    available: bool = True


# Calibrated loosely against the 1 Hz recordings in data/: good conditions add
# a few percent to a raw GPS sum, medium ones roughly 15-25 %.
GOOD = GpsQuality(2.0, 0.15, 0.10, 4.0)
MEDIUM = GpsQuality(5.0, 0.50, 0.40, 10.0)
BAD = GpsQuality(12.0, 0.70, 1.0, 30.0)
VERY_BAD = GpsQuality(30.0, 2.0, 5.0, 60.0)
OUTAGE = GpsQuality(0, 0, 0, 0, available=False)
# Poor accuracy, but the offset changes slowly, so long straight
# displacements remain informative.
INACCURATE_STABLE = GpsQuality(15.0, 0.25, 0.5, 30.0, velocity_tau=30.0)


class GpsError:
    """Integrated, mean-reverting error velocity plus white noise."""

    def __init__(self, rng: random.Random):
        self.rng = rng
        self.e = [0.0, 0.0]
        self.u = [0.0, 0.0]

    def advance(self, q: GpsQuality, dt: float) -> None:
        if not q.available or q.drift_velocity == 0:
            return
        tau_u = q.velocity_tau
        tau_e = max(tau_u, q.drift_sigma**2 / (q.drift_velocity**2 * tau_u))
        steps = max(1, int(math.ceil(dt / 0.1)))
        h = dt / steps
        a_u, a_e = math.exp(-h / tau_u), math.exp(-h / tau_e)
        for _ in range(steps):
            for k in range(2):
                self.u[k] = a_u * self.u[k] + math.sqrt(1 - a_u * a_u) * self.rng.gauss(0, q.drift_velocity)
                self.e[k] = a_e * self.e[k] + self.u[k] * h

    def sample(self, q: GpsQuality) -> tuple[float, float]:
        return (
            self.e[0] + self.rng.gauss(0, q.white_sigma),
            self.e[1] + self.rng.gauss(0, q.white_sigma),
        )


@dataclass
class Scenario:
    name: str
    description: str
    route: list[tuple[float, float]]  # polyline in local metres (east, north)
    stride: Profile = const(0.72)  # metres per step
    cadence: Profile = const(1.85)  # steps per second while walking
    moving: Callable[[float], bool] = lambda _t: True
    gps_quality: Callable[[float], GpsQuality] = lambda _t: GOOD
    gps_interval: float = 1.0
    gps_underreport: float = 1.0  # <1: positions advance too slowly
    gps_catchup_error: float = 25.0  # jump back to truth beyond this lag (m)
    gps_jumps: list[tuple[float, float]] = field(default_factory=list)
    step_mode: str = "interval"  # interval | per_step | every_n | none
    step_interval: float = 1.0
    step_every_n: int = 10
    step_factor: Profile = const(1.0)  # counted / true steps
    step_delay: float = 0.0  # counter reports the state of t - delay
    step_frozen: list[tuple[float, float]] = field(default_factory=list)
    ghost_steps_per_second: float = 0.0  # counted while standing
    seed: int = 1


# --------------------------------------------------------------------------- #
# Routes
# --------------------------------------------------------------------------- #


def straight(length: float = 700, heading_deg: float = 60) -> list[tuple[float, float]]:
    h = math.radians(heading_deg)
    return [(0, 0), (length * math.sin(h), length * math.cos(h))]


def shuttle(length: float, repeats: int = 60) -> list[tuple[float, float]]:
    return [(0, 0) if i % 2 == 0 else (length, 0) for i in range(repeats)]


def zigzag(leg: float = 15, angle_deg: float = 90, legs: int = 60):
    points = [(0.0, 0.0)]
    for i in range(legs):
        h = math.radians(45 + (angle_deg / 2 if i % 2 else -angle_deg / 2))
        x, y = points[-1]
        points.append((x + leg * math.sin(h), y + leg * math.cos(h)))
    return points


def loop(width: float = 80, height: float = 50, laps: int = 4):
    corners = [(0, 0), (width, 0), (width, height), (0, height)]
    return [corners[i % 4] for i in range(laps * 4 + 1)]


def curvy(radius: float = 25, laps: int = 4, segments: int = 72):
    return [
        (
            radius * math.sin(2 * math.pi * i / segments),
            radius - radius * math.cos(2 * math.pi * i / segments),
        )
        for i in range(laps * segments + 1)
    ]


class Route:
    def __init__(self, points: list[tuple[float, float]]):
        self.points = points
        self.cumulative = [0.0]
        for a, b in zip(points, points[1:]):
            self.cumulative.append(self.cumulative[-1] + math.dist(a, b))
        self.length = self.cumulative[-1]
        # Interior vertices with a sharp turn slow the walker down.
        self.turns = []
        for i in range(1, len(points) - 1):
            ax, ay = points[i][0] - points[i - 1][0], points[i][1] - points[i - 1][1]
            bx, by = points[i + 1][0] - points[i][0], points[i + 1][1] - points[i][1]
            na, nb = math.hypot(ax, ay), math.hypot(bx, by)
            if na and nb:
                angle = math.degrees(math.acos(max(-1, min(1, (ax * bx + ay * by) / (na * nb)))))
                if angle > 60:
                    self.turns.append((self.cumulative[i], angle))

    def at(self, s: float) -> tuple[float, float]:
        s = max(0.0, min(self.length, s))
        lo, hi = 0, len(self.cumulative) - 1
        while hi - lo > 1:
            mid = (lo + hi) // 2
            if self.cumulative[mid] <= s:
                lo = mid
            else:
                hi = mid
        seg = self.cumulative[hi] - self.cumulative[lo]
        f = 0 if seg == 0 else (s - self.cumulative[lo]) / seg
        (x0, y0), (x1, y1) = self.points[lo], self.points[hi]
        return x0 + f * (x1 - x0), y0 + f * (y1 - y0)

    def turn_slowdown(self, s: float) -> float:
        factor = 1.0
        for at, angle in self.turns:
            d = abs(s - at)
            if d < 2.0:
                depth = 0.25 + 0.75 * (1 - angle / 180)  # U-turns slow most
                factor = min(factor, depth + (1 - depth) * d / 2.0)
        return factor


# --------------------------------------------------------------------------- #
# Simulation
# --------------------------------------------------------------------------- #


def to_latlon(x: float, y: float) -> tuple[float, float]:
    return ORIGIN_LAT + y / METERS_PER_DEG_LAT, ORIGIN_LON + x / METERS_PER_DEG_LON


def iso(t: float) -> str:
    return (START + timedelta(seconds=t)).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


@dataclass
class Truth:
    t: list[float]
    s: list[float]  # distance along path
    steps: list[float]  # true cumulative steps
    speed: list[float]


def simulate_truth(sc: Scenario, path: Route) -> Truth:
    rng = random.Random(sc.seed)
    t, s, steps = 0.0, 0.0, 0.0
    out = Truth([0.0], [0.0], [0.0], [0.0])
    wobble = 0.0
    while t < WALK_SECONDS - 1e-9:
        # Small natural cadence variation (AR(1), about ±3 %).
        wobble = 0.995 * wobble + 0.1 * rng.gauss(0, 0.03)
        if sc.moving(t):
            cadence = sc.cadence(t) * (1 + wobble) * path.turn_slowdown(s)
            v = cadence * sc.stride(t)
        else:
            cadence, v = 0.0, 0.0
        s = min(path.length, s + v * SIM_DT)
        steps += cadence * SIM_DT
        t += SIM_DT
        out.t.append(t)
        out.s.append(s)
        out.steps.append(steps)
        out.speed.append(v)
    if s >= path.length - 1e-6:
        raise ValueError(f"{sc.name}: route too short ({path.length:.0f} m)")
    return out


def sample_truth(truth: Truth, t: float, values: list[float]) -> float:
    i = min(len(truth.t) - 1, max(0, int(round(t / SIM_DT))))
    return values[i]


def generate_gps(sc: Scenario, path: Route, truth: Truth) -> list[dict]:
    rng = random.Random(sc.seed * 7919 + 1)
    error = GpsError(random.Random(sc.seed * 7919 + 2))
    samples = []
    reported_s = None  # for underreporting positions
    previous_true_s = 0.0
    t = -1.0 + rng.random() * 0.5  # first fix shortly before the start
    error_time = t - 120  # warm the error process up
    while t < WALK_SECONDS:
        q = sc.gps_quality(max(0.0, t))
        error.advance(q, t - error_time)
        error_time = t
        true_s = sample_truth(truth, max(0.0, t), truth.s)
        if q.available:
            if sc.gps_underreport < 1:
                if reported_s is None:
                    reported_s = true_s
                else:
                    # Advance only a fraction of the true movement since the last fix.
                    reported_s += sc.gps_underreport * (true_s - previous_true_s)
                    if true_s - reported_s > sc.gps_catchup_error:
                        reported_s = true_s  # sudden catch-up jump
                previous_true_s = true_s
                x, y = path.at(reported_s)
            else:
                x, y = path.at(true_s)
            dx, dy = error.sample(q)
            x += dx
            y += dy
            for at, size in sc.gps_jumps:
                if 0 <= t - at < 3:
                    x += size
                    y += size * 0.5
            lat, lon = to_latlon(x, y)
            v = sample_truth(truth, max(0.0, t), truth.speed)
            # Doppler speed in real data reads somewhat low.
            reported_speed = max(0.0, 0.9 * v + rng.gauss(0, 0.15))
            accuracy = max(1.0, q.accuracy * math.exp(rng.gauss(0, 0.15)))
            samples.append(
                {
                    "timestamp": t,
                    "type": "position",
                    "sourceId": "gps",
                    "values": {
                        "latitude": lat,
                        "longitude": lon,
                        "accuracy": accuracy,
                        "altitude": 500.0 + rng.gauss(0, 1),
                        "speed": reported_speed,
                        "heading": rng.uniform(0, 360),
                    },
                }
            )
        else:
            reported_s = None
        jitter = rng.gauss(0, 0.03) if sc.gps_interval <= 1.5 else rng.gauss(0, 0.25)
        t += max(0.2, sc.gps_interval + jitter)
    return samples


def generate_steps(sc: Scenario, truth: Truth) -> list[dict]:
    if sc.step_mode == "none":
        return []
    rng = random.Random(sc.seed * 104729 + 3)
    baseline = rng.randint(1_000, 40_000)

    # Counted steps as a function of time, including factor, ghosts and freezes.
    counted = [0.0]
    frozen_loss = 0.0
    for i in range(1, len(truth.t)):
        t = truth.t[i]
        inc = (truth.steps[i] - truth.steps[i - 1]) * sc.step_factor(t)
        if truth.speed[i] == 0:
            inc += sc.ghost_steps_per_second * SIM_DT
        if any(a <= t < b for a, b in sc.step_frozen):
            frozen_loss += inc
            inc = 0.0
        counted.append(counted[-1] + inc)

    def count_at(t: float) -> int:
        t = t - sc.step_delay
        if t <= 0:
            return baseline
        return baseline + int(math.floor(sample_truth(truth, t, counted)))

    samples = [
        {
            "timestamp": -20.0 - rng.random() * 10,
            "type": "steps",
            "sourceId": "pedometer",
            "values": {"cumulative_steps": float(baseline)},
        }
    ]
    times: list[float] = []
    if sc.step_mode == "interval":
        t = rng.random() * sc.step_interval
        while t < WALK_SECONDS:
            times.append(t)
            t += sc.step_interval
    elif sc.step_mode in ("per_step", "every_n"):
        n = 1 if sc.step_mode == "per_step" else sc.step_every_n
        last = baseline
        for i, t in enumerate(truth.t):
            c = count_at(t)
            if c >= last + n:
                last = c - (c - baseline) % n
                times.append(t)
    else:
        raise ValueError(sc.step_mode)

    last_value = None
    for t in times:
        value = count_at(t)
        if sc.step_mode == "every_n":
            value -= (value - baseline) % sc.step_every_n
        if value == last_value and sc.step_mode != "interval":
            continue
        last_value = value
        samples.append(
            {
                "timestamp": t,
                "type": "steps",
                "sourceId": "pedometer",
                "values": {"cumulative_steps": float(value)},
            }
        )
    return samples


def write_scenario(sc: Scenario, out_dir: Path) -> dict:
    path = Route(sc.route)
    truth = simulate_truth(sc, path)
    samples = generate_gps(sc, path, truth) + generate_steps(sc, truth)
    samples.sort(key=lambda s: s["timestamp"])
    for i, s in enumerate(samples, start=1):
        s["id"] = i
        s["timestamp"] = iso(s["timestamp"])
    samples = [{k: s[k] for k in ("id", "timestamp", "sourceId", "type", "values")} for s in samples]

    profile = {
        "id": 1,
        "name": "Synthetic",
        "timestamp": iso(-600),
        "height": 175,
        "age": 60,
    }
    session = {
        "id": f"synthetic-{sc.name}",
        "notes": f"Synthetic: {sc.description}",
        "startedAt": iso(0),
        "duration": int(WALK_SECONDS),
        "distance": 0.0,
        "phase": "finished",
        "profileId": 1,
        "samples": samples,
        "profile": profile,
    }

    reference_samples = []
    for i in range(0, len(truth.t), int(round(1 / SIM_DT))):
        x, y = path.at(truth.s[i])
        lat, lon = to_latlon(x, y)
        reference_samples.append(
            {
                "id": len(reference_samples) + 1,
                "timestamp": iso(truth.t[i]),
                "sourceId": "synthetic_truth",
                "type": "position",
                "values": {
                    "latitude": lat,
                    "longitude": lon,
                    "distance": truth.s[i],
                    "speed": truth.speed[i],
                },
            }
        )
    reference = {
        "id": f"synthetic-{sc.name}-truth",
        "notes": "Synthetic ground truth",
        "startedAt": iso(0),
        "duration": int(WALK_SECONDS),
        "distance": truth.s[-1],
        "phase": "finished",
        "profileId": 1,
        "samples": reference_samples,
        "profile": {**profile, "name": "Synthetic truth"},
    }

    folder = out_dir / sc.name
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "session.json").write_text(json.dumps(session, indent=1))
    (folder / "reference.json").write_text(json.dumps(reference, indent=1))
    true_steps = truth.steps[-1]
    return {
        "name": sc.name,
        "description": sc.description,
        "distance": truth.s[-1],
        "steps": true_steps,
        "stride": truth.s[-1] / true_steps if true_steps else float("nan"),
        "gps": sum(1 for s in samples if s["type"] == "position"),
    }


# --------------------------------------------------------------------------- #
# Scenarios
# --------------------------------------------------------------------------- #


def phases(*pieces: tuple[float, GpsQuality]) -> Callable[[float], GpsQuality]:
    return steps_of(*pieces)  # type: ignore[arg-type]


def scenarios() -> list[Scenario]:
    walking = lambda *stops: (lambda t: not any(a <= t < b for a, b in stops))
    return [
        # --- GPS quality -------------------------------------------------- #
        Scenario("gps_good_straight", "Good GPS, long straight line", straight()),
        Scenario("gps_good_loop", "Good GPS, rectangular block loop", loop()),
        Scenario(
            "gps_medium_loop",
            "Medium GPS (~12 m accuracy) on a block loop",
            loop(),
            gps_quality=const(MEDIUM),  # type: ignore[arg-type]
        ),
        Scenario(
            "gps_intermittent_bad",
            "Good GPS with two bad phases and one outage",
            loop(),
            gps_quality=phases((70, GOOD), (130, BAD), (190, GOOD), (240, OUTAGE), (290, GOOD), (330, BAD), (999, GOOD)),
        ),
        Scenario(
            "gps_mostly_bad",
            "Mostly bad GPS (~30 m), short good phases",
            loop(),
            gps_quality=phases((40, GOOD), (200, BAD), (230, GOOD), (999, BAD)),
        ),
        Scenario(
            "gps_indoor",
            "Indoor corridor, almost no GPS (rare fixes at 60 m accuracy)",
            shuttle(30),
            gps_quality=const(VERY_BAD),  # type: ignore[arg-type]
            gps_interval=12.0,
        ),
        Scenario(
            "gps_inaccurate_long_straight",
            "Inaccurate (~30 m) but stable GPS on a long straight line",
            straight(),
            gps_quality=const(INACCURATE_STABLE),  # type: ignore[arg-type]
        ),
        Scenario(
            "gps_underreporting",
            "Positions advance at 70 % of true speed with catch-up jumps (OnePlus-like)",
            loop(),
            gps_quality=const(GpsQuality(3.0, 0.15, 0.10, 7.0)),  # type: ignore[arg-type]
            gps_underreport=0.7,
        ),
        Scenario(
            "gps_multipath_jumps",
            "Good GPS with occasional 25 m jumps at small reported accuracy",
            loop(),
            gps_jumps=[(50, 25), (140, -20), (230, 30), (300, -25)],
        ),
        Scenario(
            "gps_rate_5s",
            "Good GPS but only one fix every ~5 s (older app versions)",
            loop(),
            gps_interval=4.8,
        ),
        # --- Route geometry ----------------------------------------------- #
        Scenario("route_zigzag", "Zigzag with 15 m legs and 90° turns", zigzag()),
        Scenario("route_curvy", "Repeated circle with 25 m radius", curvy()),
        Scenario("route_shuttle_30m", "Standard 6MWT: back and forth on 30 m", shuttle(30)),
        Scenario(
            "route_shuttle_10m",
            "Very frequent turns: back and forth on 10 m, medium GPS",
            shuttle(10, repeats=200),
            gps_quality=const(MEDIUM),  # type: ignore[arg-type]
        ),
        Scenario(
            "route_pauses",
            "Two 30 s stops with GPS jitter while standing",
            loop(),
            moving=walking((100, 130), (230, 260)),
            gps_quality=const(GpsQuality(3.0, 0.25, 0.2, 6.0)),  # type: ignore[arg-type]
        ),
        # --- Step counter delivery ---------------------------------------- #
        Scenario(
            "steps_per_step",
            "Step counter reports every single step; medium GPS",
            loop(),
            step_mode="per_step",
            gps_quality=const(MEDIUM),  # type: ignore[arg-type]
        ),
        Scenario(
            "steps_every_10",
            "Step counter reports only every 10 steps; medium GPS",
            loop(),
            step_mode="every_n",
            step_every_n=10,
            gps_quality=const(MEDIUM),  # type: ignore[arg-type]
        ),
        Scenario(
            "steps_batched_30s",
            "Step counter batched every 30 s; GPS outage in the middle",
            loop(),
            step_interval=30.0,
            gps_quality=phases((150, GOOD), (240, OUTAGE), (999, GOOD)),
        ),
        Scenario(
            "steps_delayed_10s",
            "Step counter values lag 10 s behind; GPS outage in the middle",
            loop(),
            step_delay=10.0,
            gps_quality=phases((150, GOOD), (240, OUTAGE), (999, GOOD)),
        ),
        # --- Broken step counters ----------------------------------------- #
        Scenario(
            "steps_broken_undercount",
            "Counter registers only 55 % of steps; bad GPS phase",
            loop(),
            step_factor=const(0.55),
            gps_quality=phases((120, GOOD), (240, BAD), (999, GOOD)),
        ),
        Scenario(
            "steps_broken_overcount",
            "Counter reports 140 % of steps; bad GPS phase",
            loop(),
            step_factor=const(1.4),
            gps_quality=phases((120, GOOD), (240, BAD), (999, GOOD)),
        ),
        Scenario(
            "steps_broken_frozen",
            "Counter freezes for 90 s and loses those steps; good GPS",
            loop(),
            step_frozen=[(120, 210)],
        ),
        Scenario(
            "steps_broken_erratic",
            "Counter factor drifts between 50 % and 150 %; GPS outage",
            loop(),
            step_factor=steps_of((60, 1.0), (120, 0.5), (180, 1.5), (240, 0.6), (999, 1.3)),
            gps_quality=phases((150, GOOD), (240, OUTAGE), (999, GOOD)),
        ),
        Scenario(
            "steps_ghost",
            "Counter keeps counting while standing (stops at 100 s and 230 s)",
            loop(),
            moving=walking((100, 140), (230, 270)),
            ghost_steps_per_second=1.5,
        ),
        Scenario("steps_missing", "No step counter at all; good GPS", loop(), step_mode="none"),
        Scenario(
            "steps_missing_bad_gps",
            "No step counter and intermittently bad GPS",
            loop(),
            step_mode="none",
            gps_quality=phases((90, GOOD), (180, BAD), (240, OUTAGE), (999, GOOD)),
        ),
        # --- Stride ------------------------------------------------------- #
        Scenario(
            "stride_short_patient",
            "Short steps (0.45 m) at slow cadence; good GPS",
            loop(width=50, height=30),
            stride=const(0.45),
            cadence=const(1.5),
        ),
        Scenario(
            "stride_short_patient_bad_gps",
            "Short steps (0.45 m) at slow cadence; medium then bad GPS",
            loop(width=50, height=30),
            stride=const(0.45),
            cadence=const(1.5),
            gps_quality=phases((120, MEDIUM), (999, BAD)),
        ),
        Scenario(
            "stride_long",
            "Long steps (0.95 m), fast walker; good GPS then outage",
            loop(width=100, height=60),
            stride=const(0.95),
            cadence=const(2.0),
            gps_quality=phases((200, GOOD), (300, OUTAGE), (999, GOOD)),
        ),
        Scenario(
            "stride_fatigue_gps_lost",
            "Stride drops 0.85 → 0.60 m (fatigue) while GPS degrades and fails",
            loop(),
            stride=ramp(120, 200, 0.85, 0.60),
            gps_quality=phases((150, GOOD), (200, MEDIUM), (999, OUTAGE)),
        ),
        Scenario(
            "stride_change_measured_then_gap",
            "Stride 0.65 m, then 0.85 m (measured by GPS), then GPS outage",
            loop(),
            stride=steps_of((120, 0.65), (999, 0.85)),
            gps_quality=phases((240, GOOD), (999, OUTAGE)),
        ),
        Scenario(
            "stride_variable_intermittent_gps",
            "Stride alternates 0.6/0.8 m every minute; GPS lost on alternate minutes",
            loop(),
            stride=steps_of((60, 0.6), (120, 0.8), (180, 0.6), (240, 0.8), (300, 0.6), (999, 0.8)),
            gps_quality=phases((50, GOOD), (70, OUTAGE), (110, GOOD), (130, OUTAGE), (170, GOOD), (190, OUTAGE), (230, GOOD), (250, OUTAGE), (999, GOOD)),
        ),
    ]


def write_readme(out_dir: Path, summary: list[dict]) -> None:
    lines = [
        "# Synthetic recordings",
        "",
        "Generated by [`tools/synthetic_data/generate.py`](../../tools/synthetic_data/generate.py);",
        "do not edit. See [Synthetic data](../../wiki/Data-and-Tools.md#synthetic-data)",
        "for models and usage.",
        "",
        "| Scenario | Description | Distance | Steps | Mean stride | GPS fixes |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for s in summary:
        lines.append(
            f"| `{s['name']}` | {s['description']} | {s['distance']:.0f} m | "
            f"{s['steps']:.0f} | {s['stride']:.2f} m | {s['gps']} |"
        )
    (out_dir / "README.md").write_text("\n".join(lines) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    root = Path(__file__).resolve().parents[2]
    parser.add_argument("-o", "--output", type=Path, default=root / "data" / "synthetic")
    parser.add_argument("--only", nargs="*", help="Generate only these scenarios")
    args = parser.parse_args()

    selected = [s for s in scenarios() if not args.only or s.name in args.only]
    if not args.only and args.output.exists():
        shutil.rmtree(args.output)
    args.output.mkdir(parents=True, exist_ok=True)
    summary = [write_scenario(sc, args.output) for sc in selected]
    if not args.only:
        write_readme(args.output, summary)
    for s in summary:
        print(f"{s['name']:36} {s['distance']:6.0f} m  {s['steps']:5.0f} steps  {s['gps']:4} fixes")


if __name__ == "__main__":
    main()
