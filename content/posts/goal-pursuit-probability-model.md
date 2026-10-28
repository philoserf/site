---
title: Goal pursuit probability model
description: Goal persistence modeled as value alignment, skill growth, bounded willpower depletion, and interference, with worked examples of learning Go and adopting Obsidian. The middle phase is the sag from early momentum to a plateau, and the plateau decides whether a goal survives.
date: 2025-12-06
math: true
---

Goal pursuit probability at time $t$:

$$
P(A_{t}) = V \times (1 - e^{-s \times t}) \times \bigl(1 - d(1 - e^{-c \times t})\bigr) \times (1 - \frac{I_{t}}{I_0})
$$

Four forces shape persistence. Value alignment $V$ sets the ceiling. Skill growth $(1 - e^{-s \times t})$ drives early momentum. Depletion $\bigl(1 - d(1 - e^{-c \times t})\bigr)$ erodes willpower at rate $c$, but only down to a floor: $d$, between 0 and 1, is the most it ever takes. Interference $(1 - \frac{I_{t}}{I_0})$ compounds obstacles.

Without skill development ($s \rightarrow 0$), activation stalls regardless of motivation. As interference nears threshold ($I_{t} \rightarrow I_0$), probability crashes. Given time, skill saturates and depletion bottoms out, so $P(A_{t})$ settles toward a plateau:

$$
P_{\infty} = V \times (1 - d) \times (1 - \frac{I_{t}}{I_0})
$$

A goal survives when that plateau stays above the point where you quit. Value raises it; depletion and interference lower it.

The race between $s$ and $c$ sets the shape of the approach, not the destination. When skill grows faster than willpower drains ($s > c$), $P(A_{t})$ climbs to an early peak, then sags as depletion catches up, and levels off at the plateau: fast start, vulnerable middle, stable end. When depletion outpaces skill ($c > s$), there is no early peak—only a slow climb that never feels rewarding, which is its own way to lose a goal.

The formula holds its parameters fixed. Real goals don't: value grows as a practice pays off, depletion falls as habits automate, interference rises and falls with the rest of life. The examples below follow those shifts.

---

**Learning Go from Python**

Early weeks: High value ($V \approx 0.8$), fast skill gains, little depletion yet, minimal interference. $P(A_{t})$ rises through tutorials and first projects.

Months 2-3: Value holds. Skills slow (concurrency, errors) as depletion catches up. Work competes for attention. $P(A_{t})$ peaks, then sags toward its plateau.

Month 6+: Two paths. Persistence: patterns click, interference drops as Go integrates into the workflow, and the plateau sits above the quitting point—$P(A_{t})$ stabilizes, habit forms. Abandonment: $I_{t} \rightarrow I_0$ as priorities shift, the plateau falls below the quitting point, and the sag never ends.

**Obsidian Knowledge System**

Month 1: High value ($V \approx 0.9$), moderate skill growth, low depletion, low interference. $P(A_{t})$ rises through setup and note migration.

Months 2-4: Value tested before benefits materialize. Skill gains slow. Depletion rises from consistency demands. Novelty fades. $P(A_{t})$ sags—critical vulnerability.

Month 6+: Survivors see $V$ climb as note networks compound, and $d$ shrink as automation takes over the routine. Both raise the plateau, so $P(A_{t})$ crosses into habit with accelerating returns—the parameters changed, and the curve followed.

---

The middle phase kills most goals: $P(A_{t})$ falls from its early peak toward a plateau while $I_{t}$ grows, and if the plateau sits below the quitting point, nothing in the formula brings it back. Parameters vary by person—some deplete faster, others manage interference better. Interventions: strengthen $V$ through values alignment, accelerate $s$ through practice, lower $d$ through rest and routine, control $I_{t}$ through environment design.
