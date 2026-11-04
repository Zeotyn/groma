---
title: Architecture
status: draft
last_reviewed: {{today}}
review_after_days: 90
owner: {{owner}}
sources: [{{sources}}]
---

# Architecture

## System context

```mermaid
flowchart LR
  user([{{primary_user}}]) --> system[{{project_name}}]
  system --> ext[(External system)]
```

{{context: users and external systems the project talks to}}

## Containers

| Container | Technology | Responsibility | Evidence |
|---|---|---|---|
| {{container}} | {{technology}} | {{responsibility}} | {{path}} |

## Building blocks

{{modules: main modules or packages and how they depend on each other}}

## Runtime view

{{runtime: one or two important flows, step by step}}

## Deployment

{{deployment: where and how it runs; "Not yet documented" is fine}}

## Decisions

Architecture decisions are recorded in [adr/](adr/README.md).
