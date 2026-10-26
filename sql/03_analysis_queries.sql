-- Q1: How much did cleaning change?
SELECT 'raw rows' AS measure, COUNT(*) AS n FROM tickets_raw
UNION ALL
SELECT 'clean tickets', COUNT(*) FROM tickets_clean;

-- Q2: Tickets by status
SELECT status, COUNT(*) AS tickets
FROM tickets_clean GROUP BY status ORDER BY tickets DESC;

-- Q3: Average resolution time by priority (resolved tickets only)
SELECT COALESCE(priority, 'Unspecified') AS priority,
       COUNT(*) AS resolved,
       ROUND(AVG(resolution_hours), 1) AS avg_resolution_hours,
       MAX(sla_target_hours) AS sla_target_hours
FROM tickets_clean
WHERE status = 'Resolved'
GROUP BY priority
ORDER BY avg_resolution_hours;

-- Q4: Tickets by category
SELECT category, COUNT(*) AS tickets
FROM tickets_clean GROUP BY category ORDER BY tickets DESC;

-- Q5: SLA performance: share of resolved tickets inside their target
SELECT COALESCE(priority, 'Unspecified') AS priority,
       COUNT(*) AS resolved,
       SUM(CASE WHEN resolution_hours <= sla_target_hours THEN 1 ELSE 0 END) AS within_target,
       ROUND(100.0 * SUM(CASE WHEN resolution_hours <= sla_target_hours THEN 1 ELSE 0 END) / COUNT(*), 0) AS pct_within_target
FROM tickets_clean
WHERE status = 'Resolved' AND sla_target_hours IS NOT NULL
GROUP BY priority;

-- Q6: Open backlog: unresolved tickets and their age at export
SELECT ticket_ref, category, COALESCE(priority, 'Unspecified') AS priority, status,
       CAST(julianday((SELECT MAX(created_date) FROM tickets_clean)) - julianday(created_date) AS INTEGER) AS age_days
FROM tickets_clean
WHERE status != 'Resolved'
ORDER BY age_days DESC;

-- Q7: Repeat requesters (4 or more tickets)
SELECT requester_email, COUNT(*) AS tickets
FROM tickets_clean GROUP BY requester_email
HAVING COUNT(*) >= 4 ORDER BY tickets DESC;
