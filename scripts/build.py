"""Build the database, run the cleaning, and write results/query_results.md."""
import csv, sqlite3, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB = os.path.join(ROOT, "support_tickets.db")
if os.path.exists(DB):
    os.remove(DB)
con = sqlite3.connect(DB)
cur = con.cursor()

cur.executescript(open(os.path.join(ROOT, "sql/01_create_raw_table.sql")).read())
with open(os.path.join(ROOT, "data/tickets_raw.csv"), newline="") as f:
    rows = list(csv.DictReader(f))
cur.executemany(
    "INSERT INTO tickets_raw VALUES (:ticket_ref,:requester_email,:category,:priority,:status,:created_at,:resolved_at,:subject)",
    rows,
)
con.commit()
cur.executescript(open(os.path.join(ROOT, "sql/02_clean_data.sql")).read())
con.commit()

def md_table(headers, data):
    out = ["| " + " | ".join(headers) + " |",
           "|" + "|".join("---" for _ in headers) + "|"]
    for r in data:
        out.append("| " + " | ".join("" if v is None else str(v) for v in r) + " |")
    return "\n".join(out)

sections = []
sections.append("# Query results\n")
sections.append("All figures below come straight from running the SQL in `sql/` "
                "against `data/tickets_raw.csv` with SQLite.\n")

issues = cur.execute(
    "SELECT issue_type, COUNT(*) FROM data_quality_issues GROUP BY issue_type ORDER BY COUNT(*) DESC"
).fetchall()
sections.append("## Data quality issues logged during cleaning\n")
sections.append(md_table(["issue_type", "count"], issues))
sections.append("")

sql_text = open(os.path.join(ROOT, "sql/03_analysis_queries.sql")).read()
for chunk in sql_text.split(";"):
    lines = [l for l in chunk.splitlines() if l.strip()]
    if not lines:
        continue
    title = next((l.replace("--", "").strip() for l in lines if l.strip().startswith("--")), "Query")
    stmt = "\n".join(l for l in lines if not l.strip().startswith("--"))
    if not stmt.strip():
        continue
    data = cur.execute(stmt).fetchall()
    headers = [d[0] for d in cur.description]
    sections.append(f"## {title}\n")
    sections.append(md_table(headers, data))
    sections.append("")

with open(os.path.join(ROOT, "results/query_results.md"), "w") as f:
    f.write("\n".join(sections))
print("built support_tickets.db and results/query_results.md")
print("raw:", cur.execute("SELECT COUNT(*) FROM tickets_raw").fetchone()[0],
      "clean:", cur.execute("SELECT COUNT(*) FROM tickets_clean").fetchone()[0])
