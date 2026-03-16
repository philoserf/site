---
title: Intent-First Development with AI Coding Agents
aliases:
  - Intent as Code How AI Agents Are Moving the Abstraction Layer
description: Argues that AI coding agents are shifting the primary software artifact from code to intent documents, inverting the conventional development hierarchy where PRDs are treated as scaffolding rather than the durable source of truth worth versioning and preserving.
tags:
  - ai-agents
  - product-requirements
  - programming
  - software-development
  - technical-debt
date: 2026-03-20
lastmod: 2026-03-16
---

There's a shift happening that most of us are describing wrong.

We talk about AI coding agents as tools that help us write code faster. That's accurate but shallow. The deeper change is that the abstraction layer is moving. We're starting to write intent—and agents compile it into code.

That changes what we should preserve, review, and value.

The analogy is the compiler. You write C. The compiler produces assembly. You don't maintain the assembly—you maintain the C. If the compiler improves, you recompile. Coding agents are moving into that position for a different input: a clear description of what a system should do. That description exists upstream of the code, authored by a human who understands the problem. The code is its output.

We're where programmers were when they didn't fully trust the compiler and kept hand-optimizing the assembly. We still treat the code as the primary artifact. We review it, version-control it, debate its structure. We treat the intent document, if it exists at all, as scaffolding—useful during planning, discarded once building begins.

That has it backwards.

The test: if you lose the code but keep the PRD, can you recover? With a good enough agent, yes. If you lose the PRD but keep the code, can you recover the intent? Not reliably. Comments lie, variable names mislead, and what the code does is not always what it was meant to do. Intent doesn't survive well in code. It never has. We built entire practices—documentation, code review, design logs—trying to preserve it. Those practices exist because code is an imperfect record of intent.

The PRD is the complete record.

The code review that matters most is the PRD review, before anyone writes a line. The change worth tracking is the change to the intent document. Version-control the specification, not the implementation.

Technical debt has always been the distance between intent and implementation. We manage it by refactoring: reshaping code without breaking behavior. If you preserve intent cleanly and agents can recompile it, debt works differently. You don't refactor the code. You regenerate it. When a better agent arrives—and they keep arriving—you run the PRD through it and get a better implementation. Debt stops accumulating because the implementation is no longer handcrafted.

Legacy systems are hard not because the code is old but because the intent is lost. The original authors are gone. The requirements documents, if they ever existed, are stale or missing. A legacy system with a well-preserved chain of intent documents can be recovered. One without preserved intent is a system you're excavating, not maintaining. Most software rewrites fail because they're translation projects—code into code—when the real job was recovering intent.

Precise specification—what a system should do, what it shouldn't, what success looks like—becomes the core engineering skill. You delegate the implementation. A developer who understands systems deeply will write better intent documents, catch agent errors a non-technical author would miss, and recognize when the output has gone wrong. Domain knowledge compounds. Syntax fades.

The same PRD, handed to multiple agents, produces multiple independent implementations. Where they diverge on an underspecified requirement, the PRD is the bug. Where they converge, you have evidence of a defensible design. The PRD becomes a tool for controlled experimentation.

Charles Simonyi coined Intentional Programming at Microsoft Research in 1995. Donald Knuth gave us Literate Programming—code and explanation interleaved. Both were naming the same problem: the gap between what we mean and what we write. Neither solved it. Simonyi's work came too early. Literate programming demanded more discipline than programmers would give it. What's different now is that the agent bridges the gap. The problem Simonyi and Knuth were working on finally has a solution.

Intent-first development isn't a new idea. It's an old one, finally made practical.
