# Bug Tracking Information System

> **Authors:** Viktor Čaloud, Ľubomír Gálik  
> **Year:** 2025/2026

A relational database modelling a bug tracking workflow, from initial bug reports and vulnerability classification through patch submission, programmer review, and deployment. Implemented in Oracle SQL and PL/SQL.

---

## Repository Structure

```
/
├── README.md
├── docs/
│   └── design.pdf          # ERD and Use-Case diagrams with description
└── sql/
    └── schema.sql           # Full schema, sample data, SELECT queries, triggers,
                             # procedures, indexes, EXPLAIN PLAN, materialized view
```

---

## Database Schema

The schema consists of **10 tables**:

| Table | Description |
|---|---|
| `User` | Base entity - all system users |
| `Programmer` | Specialisation of User; shares PK via FK |
| `Programming_Language` | Languages users know and modules use |
| `User_Programming_Language` | M:N - user language skills |
| `Module` | Code modules, each owned by a programmer |
| `Bug` | Reported defects with priority and vulnerability flag |
| `Patch` | Code fixes submitted by users, approved by programmers |
| `Ticket` | Bug reports created by users, claimed by programmers |
| `Module_Bug` | M:N - which bugs belong to which modules |
| `Ticket_Bug` | M:N - which bugs a ticket references |

### Notable Design Decisions

**Generalisation/Specialisation** - `Programmer` is a separate table whose PK is also a FK referencing `User`, ensuring every programmer is a valid user while keeping shared attributes in one place.

**Bank account validation** - `User.bank_account` uses a CHECK constraint with `REGEXP_LIKE` to enforce the Czech/Slovak bank account format.

**Auto-increment PKs** - Sequences combined with BEFORE INSERT triggers handle automatic ID generation.

---

## SQL Script Highlights

**SELECT queries** - 7 queries covering 2- and 3-table joins, GROUP BY with aggregation, EXISTS, and IN with a subquery.

**Triggers**
- `trg_validate_patchdate` - prevents deployed date from being earlier than created date
- `trg_automatic_reward` - awards +100 to a user's reward balance when their patch is deployed

**Stored Procedures**
- `proc_programmer_report` - uses an explicit cursor to list all modules and bug counts for a given programmer
- `proc_assign_patch_to_bug` - uses `%ROWTYPE` and exception handling to safely link a patch to a bug

**Index & EXPLAIN PLAN** - `idx_bug_priority` on `Bug(priority)`, demonstrated with before/after EXPLAIN PLAN on a 3-table join with GROUP BY.

**Materialized View** - `mv_module_bug_report` aggregates per-module bug statistics including critical and vulnerable bug counts.

**WITH + CASE query** - ranks every user as *Power Contributor*, *Active User*, *Reporter*, or *Passive Observer* based on their activity.