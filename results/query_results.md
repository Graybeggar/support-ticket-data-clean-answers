# Query results

All figures below come straight from running the SQL in `sql/` against `data/tickets_raw.csv` with SQLite.

## Data quality issues logged during cleaning

| issue_type | count |
|---|---|
| non_iso_date | 31 |
| category_variant | 24 |
| status_synonym | 17 |
| blank_priority | 6 |
| duplicate_ticket_ref | 4 |

## Q1: How much did cleaning change?

| measure | n |
|---|---|
| raw rows | 44 |
| clean tickets | 40 |

## Q2: Tickets by status

| status | tickets |
|---|---|
| Resolved | 27 |
| Waiting | 6 |
| In Progress | 5 |
| Open | 2 |

## Q3: Average resolution time by priority (resolved tickets only)

| priority | resolved | avg_resolution_hours | sla_target_hours |
|---|---|---|---|
| High | 10 | 12.0 | 24 |
| Normal | 9 | 26.7 | 72 |
| Unspecified | 4 | 30.0 |  |
| Low | 4 | 66.0 | 120 |

## Q4: Tickets by category

| category | tickets |
|---|---|
| Login | 12 |
| Bug | 9 |
| Billing | 7 |
| Feature Request | 6 |
| Account | 6 |

## Q5: SLA performance: share of resolved tickets inside their target

| priority | resolved | within_target | pct_within_target |
|---|---|---|---|
| High | 10 | 10 | 100.0 |
| Low | 4 | 3 | 75.0 |
| Normal | 9 | 9 | 100.0 |

## Q6: Open backlog: unresolved tickets and their age at export

| ticket_ref | category | priority | status | age_days |
|---|---|---|---|---|
| T-1031 | Feature Request | High | Open | 43 |
| T-1016 | Bug | Unspecified | In Progress | 41 |
| T-1026 | Billing | High | Waiting | 36 |
| T-1010 | Login | Normal | In Progress | 28 |
| T-1023 | Feature Request | High | Waiting | 28 |
| T-1029 | Login | Normal | Open | 23 |
| T-1022 | Account | High | In Progress | 19 |
| T-1020 | Billing | Unspecified | Waiting | 14 |
| T-1011 | Account | Normal | Waiting | 10 |
| T-1019 | Bug | Normal | In Progress | 9 |
| T-1028 | Billing | High | Waiting | 9 |
| T-1013 | Login | High | Waiting | 6 |
| T-1033 | Bug | Urgent | In Progress | 2 |

## Q7: Repeat requesters (4 or more tickets)

| requester_email | tickets |
|---|---|
| omar.haddad@example.com | 8 |
| jules.kim@example.com | 6 |
| ada.green@example.com | 6 |
| tom.becker@example.com | 5 |
| priya.nair@example.com | 4 |
| ben.carter@example.com | 4 |
