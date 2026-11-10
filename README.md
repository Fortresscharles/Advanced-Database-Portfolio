# Advanced Database Systems Portfolio — Fortress Community Library

**Course:** MIT 8103 Advanced Database Systems, MIT MIVA Open University

**Student:** FORTRESS CHARLES CHUKWUMA

**Case Study:** Fortress Community Library (simulated public library system)

## Repository structure

```
advanced-database-portfolio/
├── portfolio-1-database-design/      # ER diagram, schema, normalisation
├── portfolio-2-query-optimisation/   # SQL queries, execution plans, indexing
├── portfolio-3-transactions-concurrency/  # Commit/rollback, isolation, locking
├── portfolio-4-nosql/                # MongoDB document model
├── portfolio-5-distributed-cloud/    # Replication & sharding discussion
└── README.md
```

Each folder has its own README with setup steps, explanations, and a list of
evidence to capture (screenshots go in a `screenshots/` subfolder inside
each portfolio folder once you've run things yourself).

## Status / progress log

- [x] Portfolio 1 — schema designed and implemented, verified live
      against MariaDB (structure, indexes, and data all confirmed with
      screenshots)
- [x] Portfolio 2 — queries run, execution plans captured, indexing demonstrated
- [x] Portfolio 3 — transaction demos run and screenshotted
- [x] Portfolio 4 — NoSQL model implemented and queried
- [x] Portfolio 5 — replication set up, evidenced with rs.status() and a demonstrated secondary-preferred read
- [x] Final documentation — summaries written;

## AI Use Declaration

- **AI tool used:** Claude (Anthropic)
- **What it was used for:** Explanatory documentation for the Fortress Community Library case study.
- **How the output was reviewed/verified:** I ran every SQL script against a live MySQL instance, fixed syntax issues, and verified the execution plan outputs matched the explanation.
  I modified the sample data to include my own additional book titles.
  I ran the concurrency demo myself across two terminal sessions and captured the actual blocking behaviour.
