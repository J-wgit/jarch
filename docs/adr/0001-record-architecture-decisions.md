# ADR-0001: Record architecture decisions

Status: accepted · 2026-10-20

## Context

Decisions in this repo have lived in the README, PR descriptions and chat. An agent
or a person resuming the work can see what the code does but not why, so settled
questions get reopened and constraints get broken by accident.

## Decision

Record each significant decision as a numbered ADR in `docs/adr/NNNN-title.md`, with
its context, the decision and its consequences, following the factory conventions
(yard `docs/protocol.md`). Start one with `wv binder adr "<title>"`; the binder lists
every ADR in `AGENTS.md` under "Decisions". A structural change gets its ADR in the
same PR, and building on it waits for Jay's approval.

## Consequences

- The "why" survives the session that made it.
- ADRs are append-only: a reversed decision gets a new ADR that supersedes the old
  one, and the old one's status says so.
