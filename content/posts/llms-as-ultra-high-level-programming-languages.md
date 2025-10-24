---
tags:
  - language-models
  - programming
  - prompt-engineering
description: Examines the proposition of LLMs as ultra-high-level programming languages, highlighting language evolution, abstraction, and non-deterministic execution. Argues that LLMs push definitional boundaries while inaugurating a new abstraction tier, similar to the historical acceptance of garbage collection in programming.
title: LLMs as Ultra-High-Level Programming Languages
date: 2025-10-23
lastmod: 2025-10-23
publish: true
---

Arguments supporting the proposition gain substantial strength from examining language evolution. High-level languages exist on a spectrum of abstraction and determinism rather than binary categories. SQL exemplifies this: two queries can produce different execution plans and performance characteristics based on optimizer decisions, statistics, and database state, yet SQL remains unquestionably a programming language. LLMs extend this pattern by replacing query optimizers with transformer architectures. Both translate declarative specifications into execution strategies the programmer doesn't control. The abstraction hierarchy from assembly to C to Python to SQL shows progressive movement toward natural language, with LLMs as a logical continuation. Visual programming environments already demonstrated that dragging elements constitutes programming despite hiding syntax entirely. Prompt engineering exhibits compositional structure, reusability, and systematic refinement patterns that characterize programming practice. Modern frameworks treating prompts as first-class objects with versioning, testing, and deployment pipelines mirror how organizations manage traditional code.

Arguments opposing the proposition must confront that many accepted programming languages already violate classical definitions. Interpreted languages introduce runtime variability. JIT compilers make execution-time decisions. Query optimizers choose non-deterministic paths. Concurrent programs produce variable output ordering. Yet these remain programming languages. The real distinguishing factor is intentionality of variability: traditional languages produce variation as implementation details while maintaining logical equivalence, whereas LLM outputs can be semantically different from identical prompts. However, this distinction weakens as we consider that SQL query results can differ based on transaction isolation levels and concurrent modifications, MATLAB numerical computations vary with floating-point implementation, and even C behavior contains undefined regions where compiler choices affect outcomes.

My position is that LLMs represent an emergent category of ultra-high-level programming language that pushes definitional boundaries but ultimately qualifies. The non-determinism that initially seemed disqualifying exists in lesser degrees across the language spectrum. If we accept 4GLs that hide algorithmic details and visual tools that abstract away syntax, excluding LLMs requires drawing an arbitrary line. The meaningful distinction isn't whether LLMs are programming languages but recognizing they inaugurate a new tier in the abstraction hierarchy where probabilistic execution becomes a feature rather than a bug, similar to how garbage collection was once controversial but became standard.
