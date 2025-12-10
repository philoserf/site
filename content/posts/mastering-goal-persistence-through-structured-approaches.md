---
date: 2025-12-06
lastmod: 2025-12-06
math: true
tags:
  - goal-setting
  - habits
  - persistence
description: Explore how value alignment, skill growth, depletion, and interference impact goal pursuit over time, with insights from learning programming and using Obsidian.
title: Mastering Goal Persistence Through Structured Approaches
publish: true
---

Goal pursuit probability at time $t$:

$$
P(A_{t}) = V \times (1 - e^{-s \times t}) \times e^{-c \times t} \times (1 - \frac{I_{t}}{I_0})
$$

Four forces shape persistence. Value alignment $V$ sets the ceiling. Skill growth $(1 - e^{-s \times t})$ drives early momentum. Depletion $e^{-c \times t}$ erodes willpower. Interference $(1 - \frac{I_{t}}{I_0})$ compounds obstacles.

Initial progress lifts $P(A_{t})$. Without skill development ($s \rightarrow 0$), activation stalls regardless of motivation. As interference nears threshold ($I_{t} \rightarrow I_0$), probability crashes. Sustainability requires $s > c$ and managed interference.

The model explains inverted-U curves: fast start, vulnerable middle, stable end.

---

**Learning Go from Python**

Early weeks: High value ($V \approx 0.8$), moderate skill gains, low depletion, minimal interference. $P(A_{t})$ rises through tutorials and first projects.

Months 2-3: Value holds. Skills slow (concurrency, errors). Depletion climbs. Work competes for attention. $P(A_{t})$ peaks then declines.

Month 6+: Two paths. Persistence: $s > c$ as patterns click, interference drops as Go integrates workflow, $P(A_{t})$ stabilizes, habit forms. Abandonment: $I_{t} \rightarrow I_0$ as priorities shift, $P(A_{t})$ drops below threshold.

**Obsidian Knowledge System**

Month 1: High value ($V \approx 0.9$), moderate skill growth, low depletion, low interference. $P(A_{t})$ rises through setup and note migration.

Months 2-4: Value tested before benefits materialize. Skill gains slow. Depletion rises from consistency demands. Novelty fades. $P(A_{t})$ drops—critical vulnerability.

Month 6+: Survivors see value climb as note networks compound. Skills refine. Depletion falls through automation. Interference stabilizes. $P(A_{t})$ crosses threshold into habit with accelerating returns.

---

The middle phase kills most goals: $c > s$ while $I_{t}$ grows. Parameters vary by person—some deplete faster, others manage interference better. Interventions: strengthen $V$ through values alignment, accelerate $s$ through practice, reduce $c$ through rest, control $I_{t}$ through environment design.
