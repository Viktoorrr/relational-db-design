# Bug Tracker - Database Information System
**Authors:** Viktor Caloud, Lubomir Galik


Oracle SQL database project built as part of a university course, covering everything from schema design to advanced SQL features.


## Overview

A bug tracking system built around two user roles: regular users and programmers.

Regular users can report bugs they encounter and submit patches with proposed fixes. Programmers have the same abilities but can also manage modules, claim open tickets, and approve or reject patches submitted by others.

When a user spots a bug, they open a ticket describing the issue. A ticket can reference multiple bugs at once. Any programmer can then claim the ticket, work on a fix, and submit a patch. Patches go through an approval step before they are marked as deployed. Once a patch is deployed, the system automatically credits the author with a reward.

Bugs can optionally be flagged as security vulnerabilities with an associated risk level. Each bug is linked to one or more modules of the software, and every module has a designated programmer responsible for it.

## Repository Structure

```
/
├── README.md
├── docs/
│   └── design.pdf          # Phase 1: use-case diagram and ERD
└── sql/
    └── schema.sql          # Phases 2-4: full Oracle SQL implementation
```

## Environment
Developed and tested on Oracle 21c via a university database server. The script is self-contained and idempotent - it drops and recreates all objects on each run.

## Project Phases

### Phase 1 - System Design (`design.pdf`)

The design document includes:

- **Use-case diagram** mapping interactions between regular users and programmers (reporting bugs, submitting patches, claiming tickets, approving patches)
- **Entity-Relationship diagram** covering all entities, their attributes, and relationships including the `User` -> `Programmer` generalisation/specialisation

Key design decisions:
- `Programmer` is modelled as a specialisation of `User`, sharing the same primary key (joined-table approach)
- `Bug` and `Ticket` as well as `Bug` and `Module` are M:N relationships (a ticket can reference multiple bugs; a bug can appear in multiple modules)
- A patch can fix multiple bugs and must be approved by a programmer before deployment

### Phase 2 - Schema Implementation (`schema.sql`)

- Table definitions with constraints (PK, FK, CHECK, NOT NULL)
- Sequences and `BEFORE INSERT` triggers for automatic primary key generation
- Test data covering users, programmers, modules, tickets, bugs, and patches

### Phase 3 - SELECT Queries (`schema.sql`)

Seven analytical queries demonstrating core SQL features:

| # | Technique | Purpose |
|---|---|---|
| 1 | 2-table JOIN | Find the programmer responsible for a given module |
| 2 | 2-table JOIN | Show ticket status and the name of its creator |
| 3 | 3-table JOIN | Identify which modules are affected by a specific bug |
| 4 | GROUP BY + HAVING | List users proficient in more than one programming language |
| 5 | GROUP BY + COUNT | Count how many bugs each deployed patch resolves |
| 6 | EXISTS | Find all users who have submitted at least one patch |
| 7 | IN + subquery | List all modules that currently have at least one bug reported |

### Phase 4 - Advanced Features (`schema.sql`)

**Triggers**
- `trg_validate_patchdate` - prevents a patch from having a deployment date earlier than its creation date
- `trg_automatic_reward` - automatically credits the patch submitter with a reward when a patch status changes to `Deployed`

**Stored Procedures**
- `proc_programmer_report` - uses an explicit cursor to print all modules and their bug counts for a given programmer
- `proc_assign_patch_to_bug` - safely links a patch to a bug with validation and exception handling

**Query Optimization**
- `EXPLAIN PLAN` run before and after creating `idx_bug_priority` to demonstrate the impact of indexing on a multi-join aggregation query

**Access Control**
- Granular `GRANT` statements giving the second team member full access to core tables and read-only access to reference tables and views

**Materialized View**
- `mv_module_bug_report` - a precomputed module summary including responsible programmer, programming language, total bug count, critical bug count, and vulnerability count; supports manual refresh via `DBMS_MVIEW.REFRESH`

**Reporting Query**
- A `WITH` (CTE) query that ranks every user as `Power Contributor`, `Active User`, `Reporter`, or `Passive Observer` based on their patch and ticket activity

