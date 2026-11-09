# Portfolio 5: Distributed and Cloud Database Exercise

## Angle chosen: Replication (read replicas) + brief sharding discussion

## Why replication fits this case study

Fortress Library's catalogue is **read-heavy**: far more people search and
browse the catalogue than borrow/return books at any given instant. A
primary-replica (leader-follower) replication setup lets:

- The **primary** handle all writes (new loans, returns, fine payments —
  data that must be immediately consistent).
- One or more **replicas** handle catalogue search and reporting queries,
  spreading read load across branches and improving availability if the
  primary goes down temporarily (a replica can be promoted).

## Hands-on: MongoDB Atlas replica set (completed)

A free M0 cluster was created on MongoDB Atlas, which provisions a
genuine **3-node replica set** automatically, even on the free tier.

![Atlas cluster overview](screenshots/p5_replica_set_overview.png)

The cluster overview confirms: **Type: Replica Set - 3 nodes**, MongoDB
version 8.0.37, region AWS / Paris (eu-west-3).

Connected via MongoDB Compass's embedded MongoSH shell and ran:

```javascript
rs.status();
```

![rs.status() part 1](screenshots/p5_replica_status_1.png)
![rs.status() part 2](screenshots/p5_replica_status_2.png)
![rs.status() part 3](screenshots/p5_replica_status_3.png)
![rs.status() part 4](screenshots/p5_replica_status_4.png)

### What the output confirms

- `set: 'atlas-dsen8i-shard-0'` — the replica set's name.
- Three members, each a separate node at its own shard endpoint:
  - `shard-00-00` → `stateStr: 'SECONDARY'`
  - `shard-00-01` → `stateStr: 'SECONDARY'`
  - `shard-00-02` → `stateStr: 'PRIMARY'`, with `self: true` confirming
    this is the node the session is actually connected to (Atlas routes
    client connections to the primary by default).
- `health: 1` on every member — all three nodes are up and healthy.
- `optimeDate` timestamps across all three members sit within a second or
  two of each other, which is direct evidence that replication is
  actively keeping the secondaries in sync with the primary's write
  stream in real time, not just configured but idle.

### Consistency trade-off (CAP framing) — demonstrated

By default, MongoDB drivers route reads to the **primary** (strong
consistency) — this is why the earlier `rs.status()` session showed
`self: true` on the primary node rather than a secondary. To demonstrate
the alternative, the session's read preference was explicitly changed and
a read run against it:

```javascript
db.getMongo().setReadPref("secondaryPreferred");
db.books.find({ _id: "book_1" });
```

![Secondary-preferred read](screenshots/p5_secondary_read.png)

The driver accepted the new read preference and returned `book_1`'s full
document correctly — including both reviews pushed during Portfolio 4's
update, confirming the secondary had already caught up with the primary's
latest write by the time this read ran. The read preference was then
reset:

```javascript
db.getMongo().setReadPref("primary");
```

![Read preference reset to primary](screenshots/p5_readpref_reset.png)

**The trade-off in practice:** with this small, low-write-volume dataset,
a `secondaryPreferred` read returned identical data to a primary read, so
no staleness was actually observed here — but the mechanism this
demonstrates is real: under sustained write load or higher replication
lag, a `secondaryPreferred` read can return data that is milliseconds (or
more) behind the primary's latest committed write. Choosing
`secondaryPreferred` trades a small, variable consistency risk for
reduced load on the primary and continued read availability if the
primary becomes temporarily unreachable — a direct, hands-on instance of
the CAP theorem's consistency/availability trade-off, rather than only a
textbook description of it.

## Hands-on option B: MySQL replication (matches the engine used elsewhere)

If staying on the same MySQL engine used in Portfolios 1–3:

1. **AWS RDS for MySQL** lets you create a read replica with one command:
   `aws rds create-db-instance-read-replica --db-instance-identifier
fortress-replica --source-db-instance-identifier fortress-primary`.
   Free-tier eligible for a limited trial period.
2. Alternatively, for a local hands-on demo without cloud costs, run two
   MySQL containers (`docker run ... mysql:8.0`) and configure one as a
   source and one as a replica using `CHANGE REPLICATION SOURCE TO` (MySQL
   8.0.23+) or the older `CHANGE MASTER TO` syntax, then confirm with
   `SHOW REPLICA STATUS;` (or `SHOW SLAVE STATUS;` on older versions).
3. Point your Portfolio 2 reporting queries (the overdue/most-borrowed
   aggregate queries) at the replica's connection string instead of the
   primary, screenshot both connection strings/endpoints and the
   `SHOW REPLICA STATUS` output as evidence that reads are being offloaded
   and replication is active (`Replica_IO_Running` / `Replica_SQL_Running`
   should both read `Yes`).

## Sharding discussion (conceptual — not hands-on, acceptable per brief)

If Fortress grew into a national library network with millions of books
and loans, a single primary would eventually become a write bottleneck.
**Sharding by `branch_id`** would be a natural partition key: each shard
holds all book copies, staff, and loans for a geographic cluster of
branches, since most queries (local catalogue search, local loan
processing) are branch-scoped. The trade-off: a report spanning _all_
branches (like "top 5 most-borrowed books system-wide") becomes a
**scatter-gather query** across shards, which is slower and more complex
than a single-node aggregate — a cost worth explicitly naming since the
rubric rewards showing you understand trade-offs, not just mechanics.

## Availability & consistency summary (CAP framing)

| Setup                                      | Favors                          | Trade-off                                         |
| ------------------------------------------ | ------------------------------- | ------------------------------------------------- |
| Single primary, no replicas                | Strong consistency              | No failover; downtime if primary fails            |
| Primary + sync replicas                    | Consistency + some availability | Writes slower (wait for replica ack)              |
| Primary + async replicas (our Atlas setup) | Availability, read scalability  | Replicas can briefly lag ("eventual consistency") |

## Evidence captured

- `rs.status()` full output (4 screenshots above) showing a real, healthy,
  actively-replicating 3-node set
- Atlas cluster overview confirming the replica set type and node count
- A real `secondaryPreferred` read, demonstrated and reset, against the
  same live catalogue data from Portfolio 4
- The MongoDB connection and catalogue data from Portfolio 4 run against
  this same cluster, so the replicated data underlying this discussion is
  the actual Fortress Community Library catalogue, not a placeholder.
