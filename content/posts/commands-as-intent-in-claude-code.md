---
title: Commands as Intent in Claude Code
description: Explains the architectural principle behind Claude Code's command system where commands serve as declarations of intent that delegate work to skills and agents, rather than containing executable logic themselves.
tags:
  - claude-code
date: 2026-01-02
lastmod: 2026-01-22
---

## Commands Are Not Instructions

In Claude Code, a command is not a script, macro, or thin wrapper around a tool call.

A command is a **declaration of intent**. When Claude reads a command file, it interprets the description and decides which capability—skill or agent—should handle the request. The command makes that delegation explicit, stable, and discoverable.

Commands route work. Skills and agents do the work.

## The Command as an Interface

A command file works like an interface definition. What is this command called? What does it do? How do I invoke it? What capability handles it? Where does logic live?

Minimal commands are often around ten lines. They explain who is responsible, not how it works.

## Delegation, Not Invocation

The most important line in a command file is the delegation statement.

A command does not invoke logic or execute steps. It establishes responsibility. This command does not perform analysis. This command delegates to the `bash-audit` skill. That skill owns correctness and evolution.

Delegation is descriptive, not mechanical. Commands avoid explicit invocation syntax or procedural directives. They rely on language Claude can interpret. They make intent clear without encoding execution.

This keeps commands small and stable, while complexity accumulates in the skills and agents. If a command feels procedural, it has crossed the boundary—a key failure mode.

## Skills vs. Agents

**Skills** encapsulate focused expertise or workflows. **Agents** coordinate broader, often multi-step reasoning.

From the command's perspective, it simply names the delegate. Claude handles the rest. This keeps the command layer thin as capabilities grow.

## When Commands Get Larger

Some commands require more surface area. Validation commands, for example. They might specify what is being evaluated, relevant dimensions, and expected output.

Even then: description, not logic. The delegated capability enforces the rules.

## Argument Passing Without Plumbing

Arguments are not parsed or transformed in the command. They are simply available. The command documents meaning and defaults. The delegated skill or agent decides how to interpret them. This keeps commands declarative and hides implementation details.

## Failure Modes

Common mistakes that collapse the intent/execution separation:

- Encoding logic in the command
- Using explicit invocation syntax
- Over-documenting trivial routing
- Treating commands as scripts
- Letting commands grow unchecked

## Why This Scales

Descriptive delegation works because it aligns with Claude's strengths. Natural language is the interface. Responsibility is explicit. Structure is lightweight but consistent. Commands remain readable months later. Audits can reason about intent without running code.

The system behaves more like an API contract than a shell alias.

## The Mental Model

A command tells Claude who should handle this. A skill or agent decides how it is handled.

That's it.

---

[Example command](https://github.com/philoserf/claude-code-setup/blob/main/commands/create-command.md)  
[Example skill](https://github.com/philoserf/claude-code-setup/blob/main/skills/command-authoring/SKILL.md)
