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
lastmod: 2026-03-15
---

There's a shift happening that most of us are describing wrong.

We talk about AI coding agents as tools that help us write code faster. That's accurate but shallow. The deeper change is that the abstraction layer is moving. We're starting to write intent—and agents compile that intent into code the machine executes.

That changes what we should preserve, review, and value.

A compiler offers the right analogy. You write C. The compiler produces assembly. You don't maintain the assembly—you maintain the C. If the compiler improves, you recompile. Coding agents are beginning to occupy that same position relative to a different input: a clear description of what a system should do. What matters is that this description exists upstream of the code, authored by a human who understands the problem, and that the code is its output.

Right now we're in a transitional period, like the early days of high-level languages when programmers didn't fully trust the compiler and kept hand-optimizing the assembly. We still treat the code as the primary artifact. We review it, version-control it carefully, debate its structure. We treat the intent document, if it exists at all, as scaffolding—useful during planning, discarded once building begins.

That has it backwards.

The test: if you lose the code but keep the PRD, can you recover? With a good enough agent, yes. If you lose the PRD but keep the code, can you recover the intent? Not reliably. Comments lie, variable names mislead, and what the code does is not always what it was meant to do. Intent doesn't survive well in code. It never has. We built entire practices—documentation, code review, design logs—trying to preserve it. Those practices exist because code is an imperfect record of intent.

The PRD is the complete record.

This inverts the conventional hierarchy. The code review that matters most is the PRD review, before anyone writes a line. The change worth tracking is the change to the intent document. The thing to version-control with care is the specification, not the implementation.

Technical debt has always been the distance between intent and implementation. We manage it by refactoring: reshaping code without breaking behavior. If you preserve intent cleanly and agents can recompile it, debt works differently. You don't refactor the code. You regenerate it. When a better agent arrives—and they keep arriving—you run the PRD through it and get a better implementation. The debt doesn't accumulate the same way because the implementation is no longer a handcrafted artifact you're committed to maintaining.

Legacy systems are hard not because the code is old but because the intent is lost. The original authors are gone. The requirements documents, if they ever existed, are stale or missing. A legacy system with a well-preserved PRD lineage can be recovered. One without preserved intent is a system you're excavating, not maintaining. Most software rewrites fail because they're translation projects—code into code—when what was needed was to recover the original intent first.

The skills that matter shift. Clarity of thought matters more than typing speed. Specifying precisely—articulating what a system should do, what it shouldn't do, what success looks like—becomes the core engineering skill. The implementation is delegated. A developer who understands systems deeply will write better intent documents, catch agent errors a non-technical author would miss, and recognize when the output has gone wrong. Domain knowledge compounds. Syntax becomes less important.

Hand the same PRD to multiple agents, producing multiple independent implementations. Where they diverge on an underspecified requirement, the PRD is the bug. Where they converge on an approach, you have evidence of a defensible design. The PRD becomes a tool for controlled experimentation at the architecture level.

Charles Simonyi coined Intentional Programming at Microsoft Research in 1995. Donald Knuth gave us Literate Programming—code and explanation interleaved. Both were naming the same problem: the gap between what we mean and what we write. Neither solved it. Simonyi's work came too early. Literate programming demanded more discipline than programmers would give it. What's different now is the agent. No human need manually bridge the gap between intent and executable code. The problem Simonyi and Knuth were working on has a solution neither of them had access to.

Intent-first development isn't a new idea. It's an old one, finally made practical.

Write the intent. Let the agent compile it. The intent is what lasts.
