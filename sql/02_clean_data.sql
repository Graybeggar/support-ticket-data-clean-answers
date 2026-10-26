-- Clean the raw export into a typed, deduplicated tickets table.
-- Rules, in order:
--   1. Dates arrive in four formats; normalize all of them to ISO dates.
--   2. Priority, status, and category are normalized to one spelling each.
--      Status synonyms are mapped: closed -> Resolved, pending -> Waiting,
--      new -> Open. Category variants map too: Login Issue -> Login,
--      Bug Report -> Bug, Feature -> Feature Request.
--   3. Blank priorities stay NULL (unknown), never guessed.
--   4. Duplicate ticket_refs: when copies disagree, the row showing a
--      resolved status wins (a ticket cannot un-resolve); otherwise the
--      later row in the file wins.
--   5. Every problem found is logged in data_quality_issues, not deleted.

DROP TABLE IF EXISTS data_quality_issues;
CREATE TABLE data_quality_issues (
    issue_type TEXT,
    ticket_ref TEXT,
    detail     TEXT
);

INSERT INTO data_quality_issues
SELECT 'duplicate_ticket_ref', ticket_ref,
       COUNT(*) || ' rows in the raw export for one ticket'
FROM tickets_raw GROUP BY ticket_ref HAVING COUNT(*) > 1;

INSERT INTO data_quality_issues
SELECT 'blank_priority', ticket_ref, 'priority was empty in the export'
FROM tickets_raw WHERE trim(priority) = '';

INSERT INTO data_quality_issues
SELECT 'non_iso_date', ticket_ref, 'created_at stored as "' || created_at || '"'
FROM tickets_raw WHERE created_at NOT LIKE '____-__-__';

INSERT INTO data_quality_issues
SELECT 'status_synonym', ticket_ref,
       'status "' || status || '" mapped to its canonical value'
FROM tickets_raw
WHERE lower(trim(status)) IN ('closed', 'pending', 'new');

INSERT INTO data_quality_issues
SELECT 'category_variant', ticket_ref,
       'category "' || category || '" is a variant spelling'
FROM tickets_raw
WHERE trim(category) NOT IN ('Billing', 'Login', 'Account', 'Bug', 'Feature Request');

DROP TABLE IF EXISTS tickets_clean;
CREATE TABLE tickets_clean AS
WITH normalized AS (
    SELECT
        rowid AS src_rowid,
        ticket_ref,
        requester_email,
        CASE lower(trim(category))
            WHEN 'billing' THEN 'Billing'
            WHEN 'login' THEN 'Login'
            WHEN 'login issue' THEN 'Login'
            WHEN 'account' THEN 'Account'
            WHEN 'bug' THEN 'Bug'
            WHEN 'bug report' THEN 'Bug'
            WHEN 'feature request' THEN 'Feature Request'
            WHEN 'feature' THEN 'Feature Request'
        END AS category,
        CASE lower(trim(priority))
            WHEN 'urgent' THEN 'Urgent'
            WHEN 'high' THEN 'High'
            WHEN 'normal' THEN 'Normal'
            WHEN 'low' THEN 'Low'
        END AS priority,
        CASE lower(trim(status))
            WHEN 'resolved' THEN 'Resolved'
            WHEN 'closed' THEN 'Resolved'
            WHEN 'in progress' THEN 'In Progress'
            WHEN 'open' THEN 'Open'
            WHEN 'new' THEN 'Open'
            WHEN 'waiting' THEN 'Waiting'
            WHEN 'pending' THEN 'Waiting'
        END AS status,
        CASE
            WHEN created_at LIKE '____-__-__' THEN created_at
            WHEN created_at LIKE '____/__/__' THEN replace(created_at, '/', '-')
            WHEN created_at LIKE '__/__/____' THEN
                substr(created_at, 7, 4) || '-' || substr(created_at, 1, 2) || '-' || substr(created_at, 4, 2)
            ELSE
                substr(created_at, -4)
                || '-' || (CASE substr(created_at, 1, 3)
                    WHEN 'Jan' THEN '01' WHEN 'Feb' THEN '02' WHEN 'Mar' THEN '03'
                    WHEN 'Apr' THEN '04' WHEN 'May' THEN '05' WHEN 'Jun' THEN '06'
                    WHEN 'Jul' THEN '07' WHEN 'Aug' THEN '08' WHEN 'Sep' THEN '09'
                    WHEN 'Oct' THEN '10' WHEN 'Nov' THEN '11' WHEN 'Dec' THEN '12'
                END)
                || '-' || printf('%02d', CAST(trim(replace(substr(created_at, 5, 3), ',', '')) AS INTEGER))
        END AS created_date,
        CASE WHEN trim(resolved_at) = '' THEN NULL
            WHEN resolved_at LIKE '____-__-__' THEN resolved_at
            WHEN resolved_at LIKE '____/__/__' THEN replace(resolved_at, '/', '-')
            WHEN resolved_at LIKE '__/__/____' THEN
                substr(resolved_at, 7, 4) || '-' || substr(resolved_at, 1, 2) || '-' || substr(resolved_at, 4, 2)
            ELSE
                substr(resolved_at, -4)
                || '-' || (CASE substr(resolved_at, 1, 3)
                    WHEN 'Jan' THEN '01' WHEN 'Feb' THEN '02' WHEN 'Mar' THEN '03'
                    WHEN 'Apr' THEN '04' WHEN 'May' THEN '05' WHEN 'Jun' THEN '06'
                    WHEN 'Jul' THEN '07' WHEN 'Aug' THEN '08' WHEN 'Sep' THEN '09'
                    WHEN 'Oct' THEN '10' WHEN 'Nov' THEN '11' WHEN 'Dec' THEN '12'
                END)
                || '-' || printf('%02d', CAST(trim(replace(substr(resolved_at, 5, 3), ',', '')) AS INTEGER))
        END AS resolved_date,
        subject
    FROM tickets_raw
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ticket_ref
            ORDER BY (status = 'Resolved') DESC, src_rowid DESC
        ) AS rn
    FROM normalized
)
SELECT
    ticket_ref,
    requester_email,
    category,
    priority,
    status,
    created_date,
    resolved_date,
    CASE WHEN resolved_date IS NOT NULL
         THEN ROUND((julianday(resolved_date) - julianday(created_date)) * 24, 1)
    END AS resolution_hours,
    CASE priority
        WHEN 'Urgent' THEN 8 WHEN 'High' THEN 24
        WHEN 'Normal' THEN 72 WHEN 'Low' THEN 120
    END AS sla_target_hours,
    subject
FROM ranked
WHERE rn = 1
ORDER BY created_date, ticket_ref;
