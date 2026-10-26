"""Generate a deliberately messy support ticket export.

The mess is the point of the project: duplicate ticket rows, four date
formats, case and spacing variants in priority/status/category, synonym
statuses ('closed', 'pending'), variant category names ('Login Issue',
'Bug Report'), and blank priorities. Deterministic (seeded) so the
cleaning results in results/query_results.md are reproducible.
"""
import csv, random
from datetime import datetime, timedelta

random.seed(42)

REQUESTERS = [
    "ada.green@example.com", "sam.ortiz@example.com", "priya.nair@example.com",
    "tom.becker@example.com", "jules.kim@example.com", "marta.ruiz@example.com",
    "ben.carter@example.com", "nina.petrova@example.com", "omar.haddad@example.com",
    "lucy.chen@example.com", "derek.wells@example.com", "emma.frost@example.com",
]
CATEGORIES = ["Billing", "Login", "Account", "Bug", "Feature Request"]
CATEGORY_MESS = {
    "Billing": ["Billing", "billing", "BILLING", "Billing "],
    "Login": ["Login", "login", "Login Issue", "LOGIN"],
    "Account": ["Account", "account", "Account "],
    "Bug": ["Bug", "bug", "Bug Report", "BUG"],
    "Feature Request": ["Feature Request", "feature request", "Feature", "FEATURE REQUEST"],
}
PRIORITIES = ["Urgent", "High", "Normal", "Low"]
PRIORITY_MESS = {
    "Urgent": ["Urgent", "urgent", "URGENT", " urgent "],
    "High": ["High", "high", "HIGH", "High "],
    "Normal": ["Normal", "normal", "NORMAL"],
    "Low": ["Low", "low", "LOW", " low"],
}
STATUS_MESS = {
    "Resolved": ["Resolved", "resolved", "Closed", "closed ", "CLOSED"],
    "In Progress": ["In Progress", "in progress", "In progress"],
    "Open": ["Open", "open", "New", "new"],
    "Waiting": ["Waiting", "waiting", "Pending", "pending"],
}
SUBJECTS = {
    "Billing": ["Charged twice for September", "Invoice total looks wrong",
                "Refund not received yet", "Card on file was declined",
                "Discount code did not apply", "Need a copy of my receipt"],
    "Login": ["Password reset link expired", "Locked out after too many tries",
              "Two-factor code never arrives", "Login page loops back to start"],
    "Account": ["Change the email on my account", "Merge two accounts into one",
                "Update billing address", "Close my account request"],
    "Bug": ["Export button downloads an empty file", "App crashes on the reports page",
            "Dates show one day off in the list", "Search returns no results for a known name"],
    "Feature Request": ["Dark mode for the dashboard", "Export tickets to CSV",
                        "Email alerts for overdue tickets", "Saved filters for the queue"],
}
SLA_HOURS = {"Urgent": 8, "High": 24, "Normal": 72, "Low": 120}

def fmt_date(dt, style):
    if style == 0:
        return dt.strftime("%Y-%m-%d")
    if style == 1:
        return dt.strftime("%m/%d/%Y")
    if style == 2:
        return dt.strftime("%b %-d, %Y")
    return dt.strftime("%Y/%m/%d")

rows = []
base = datetime(2026, 9, 1)
for i in range(40):
    ref = f"T-{1001 + i}"
    cat = random.choice(CATEGORIES)
    prio = random.choices(PRIORITIES, weights=[1, 3, 4, 2])[0]
    created = base + timedelta(days=random.randint(0, 44), hours=random.randint(0, 10))
    status = random.choices(["Resolved", "In Progress", "Open", "Waiting"], weights=[6, 2, 1, 1])[0]
    resolved = ""
    if status == "Resolved":
        hrs = max(1.0, random.gauss(SLA_HOURS[prio] * 0.7, SLA_HOURS[prio] * 0.45))
        resolved_dt = created + timedelta(hours=hrs)
        resolved = fmt_date(resolved_dt, random.randint(0, 3))
    prio_raw = random.choice(PRIORITY_MESS[prio])
    if random.random() < 0.10:
        prio_raw = ""  # blank priority, a real export problem
    rows.append({
        "ticket_ref": ref,
        "requester_email": random.choice(REQUESTERS),
        "category": random.choice(CATEGORY_MESS[cat]),
        "priority": prio_raw,
        "status": random.choice(STATUS_MESS[status]),
        "created_at": fmt_date(created, random.randint(0, 3)),
        "resolved_at": resolved,
        "subject": random.choice(SUBJECTS[cat]),
    })

# Duplicates: two exact re-exports and two later status updates of the same ticket.
rows.append(dict(rows[3]))
rows.append(dict(rows[10]))
dup_update = dict(rows[5]); dup_update["status"] = "Closed"; rows.append(dup_update)
dup_update2 = dict(rows[17]); dup_update2["status"] = "resolved"; rows.append(dup_update2)

random.shuffle(rows)
with open("data/tickets_raw.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["ticket_ref", "requester_email", "category",
                                      "priority", "status", "created_at", "resolved_at", "subject"])
    w.writeheader()
    w.writerows(rows)
print(f"wrote {len(rows)} raw rows")
