# 🏆 Forbes Athletes SQL Analytics Project

A production-quality PostgreSQL dataset based on the **Forbes Top 120 Highest-Paid Athletes**.  
This Dataset created by me.
Built for practicing advanced SQL concepts — JOINs, CTEs, Window Functions, Subqueries, and more.

---

## 📦 What's Inside

| File/Folder | Description |
|---|---|
| `docker-compose.yml` | Spins up PostgreSQL + pgAdmin |
| `scripts/init.sql` | Creates all tables + loads all CSV data automatically |
| `data/*.csv` | 10 CSV files — one per table |
| `queries/` | Sample business queries |
| `.env.example` | Environment variable template |

---

## 🗄️ Database Schema

**10 tables — 1,530+ rows**

```
sports → teams → contracts
       ↘
athletes → earnings_yearly
         → endorsements
         → performance_stats
         → social_media
         → awards
         → agent_managers
```

| Table | Rows | Description |
|---|---|---|
| sports | 10 | NFL, NBA, Soccer, Tennis, Golf, F1, Boxing, MMA, Baseball, Cricket |
| athletes | 120 | Top 100 Forbes athletes + extras |
| teams | 60 | Real clubs with market values |
| contracts | 80 | Player contracts with salary details |
| earnings_yearly | 360 | 3 years per athlete (2022–2024) |
| endorsements | 320 | Brand deals (Nike, Adidas, Rolex...) |
| performance_stats | 340 | Season stats per sport |
| social_media | 80 | Followers, engagement rates |
| awards | 80 | Ballon d'Or, NBA MVP, Grand Slams... |
| agent_managers | 80 | Agents and agencies |

---

## 📊 Sample Queries

### Top 10 earners in 2023
```sql
SELECT
    a.full_name,
    a.nationality,
    ey.total_earnings,
    ey.forbes_rank
FROM analytics.athletes a
JOIN analytics.earnings_yearly ey
    ON ey.athlete_id = a.athlete_id
WHERE ey.year = 2023
ORDER BY ey.total_earnings DESC
LIMIT 10;
```

### Average salary per sport
```sql
SELECT
    s.sport_name,
    ROUND(AVG(c.base_salary_usd), 0) AS avg_salary,
    COUNT(c.contract_id)             AS contracts
FROM analytics.contracts c
JOIN analytics.teams t   ON t.team_id  = c.team_id
JOIN analytics.sports s  ON s.sport_id = t.sport_id
GROUP BY s.sport_name
ORDER BY avg_salary DESC;
```

### Rank athletes within each sport (Window Function)
```sql
SELECT
    a.full_name,
    s.sport_name,
    ey.total_earnings,
    RANK() OVER (
        PARTITION BY s.sport_name
        ORDER BY ey.total_earnings DESC
    ) AS rank_in_sport
FROM analytics.athletes a
JOIN analytics.earnings_yearly ey
    ON ey.athlete_id = a.athlete_id AND ey.year = 2023
JOIN analytics.performance_stats ps
    ON ps.athlete_id = a.athlete_id AND ps.season_year = 2023
JOIN analytics.sports s ON s.sport_id = ps.sport_id
ORDER BY s.sport_name, rank_in_sport;
```

---

## 🛑 Useful Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Stop and delete all data (full reset)
docker-compose down -v

# View logs
docker-compose logs -f postgres

# Connect via psql terminal
docker exec -it forbes_athletes_db psql -U admin -d forbes
```

---

## ⚠️ Important Notes

- Data is **realistic but not 100% real** — salary figures are approximated
- Earnings range from **$10M to $150M/year** (realistic Forbes ranges)
- Years covered: **2022, 2023, 2024**
- Individual sport athletes (tennis, golf, boxing) have **NULL team_id** in contracts

---

## 🧠 SQL Concepts Covered

- `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL OUTER JOIN`, `SELF JOIN`
- `GROUP BY`, `HAVING`, `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`
- `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LAG()`, `LEAD()`, `NTILE()`
- Common Table Expressions (`WITH` clause)
- Correlated subqueries, `EXISTS`, `NOT EXISTS`
- `CASE WHEN` for tiering and classification
- Date functions: `AGE()`, `EXTRACT()`, `DATE_TRUNC()`
- String functions: `CONCAT`, `UPPER`, `COALESCE`, `STRING_AGG`
- Normalization: 1NF, 2NF, 3NF, BCNF checks
- `JSONB` column querying

---

## 📄 License

MIT License — free to use for learning and practice.
