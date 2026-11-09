# Decision record – Stage B

**Problem:** the polling detector skipped ~18 % of the readings and could not keep up with 600 readings/s (later: 100,000/s).

**Options:** (1) PostgreSQL with several pollers, each for some machines; (2) gateways write to Kafka (key = `machine_id`), detectors read as one consumer group.

| | 1: PostgreSQL + pollers | 2: Kafka |
|---|---|---|
| R1 scale | at risk: all inserts and polling on one database | OK: more partitions and instances |
| R2 complete, ordered | possible with better polling (e.g. by `seq`) | OK per partition, but model state after a rebalance needs care |
| R3 fresh | at risk at scale | possible with enough capacity, p95 must be checked |
| R4 independent | not met: each consumer adds load to Postgres | OK: own consumer group each |

**Decision:** Kafka. Option 1 could fix the bug, but every new consumer still adds load to Postgres (R4), and 100,000/s would be very hard.
PostgreSQL stays the system of record for the machine registry.

**Caveat:** the model learns its baseline from the first 100 readings of a run. After a rebalance, just warming up on new readings
could learn a running fault as "normal". So the detector must save its model state together with its offset,
or replay the machine's readings from the start of the run.

**Numbers:** one detector ≈ 333 readings/s (3 ms each; in Stage A roughly 290/s).
- Lab: 600 / 333 ≈ 2 minimum → 3 instances, 6 partitions.
- Rollout: 100,000 / 333 ≈ 300 minimum → ~400 instances, ~1,000 partitions.

These are estimates: hashing is uneven, so the load (lag) per partition and per detector has to be checked.

**Tipping point:** for one reading per minute, PostgreSQL is fine. ~300 readings/s is the limit of one detector with this model, not of Postgres.
Kafka pays off once you need several detectors in parallel or several consumers of the same data, like our lab plant.
