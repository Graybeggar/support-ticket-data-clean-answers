# Support Ticket Data, Clean Answers

A support ticket export the way it actually arrives, cleaned and analyzed in SQL.

The raw export has 44 rows for 40 real tickets. Dates show up in four different
formats. The same status is spelled three ways (`Closed`, `closed`, `CLOSED`),
priorities are blank on some rows, categories drift (`Login Issue`, `Bug Report`),
and four tickets were exported twice. Any report built straight on this file
would quietly be wrong.

## What the SQL does

- `sql/01_create_raw_table.sql` loads the export exactly as received, all TEXT.
- `sql/02_clean_data.sql` normalizes every date to ISO format, maps priority,
  status, and category to one spelling each (status synonyms included:
  closed becomes Resolved, pending becomes Waiting), keeps blank priorities as
  NULL instead of guessing, and merges duplicate tickets. When duplicate rows
  disagree, the row showing a resolved status wins. Every problem found is
  written to a `data_quality_issues` table instead of being silently dropped.
- `sql/03_analysis_queries.sql` answers the questions a support lead would ask:
  volume by status and category, average resolution time by priority, SLA
  target performance, the open backlog with ages, and repeat requesters.

## Findings (full tables in results/query_results.md)

- 44 raw rows became 40 clean tickets. The cleaning logged 31 non-ISO dates,
  24 category variants, 17 status synonyms, 6 blank priorities, and
  4 duplicate ticket references.
- Login is the largest category: 12 of 40 tickets.
- High priority tickets resolved in 12.0 hours on average against a 24 hour
  target, and every resolved High and Normal ticket landed inside its target.
- The open backlog holds 13 tickets. The oldest, a High priority feature
  request, had been waiting 43 days at export.
- One requester accounts for 8 of the 40 tickets, a pattern worth a human look
  before it becomes a churn story.

## Run it

```bash
python3 scripts/generate_raw_data.py   # rebuilds data/tickets_raw.csv (seeded, reproducible)
python3 scripts/build.py               # builds the SQLite db and results/query_results.md
```

The database file itself is gitignored; everything needed to reproduce it is here.
