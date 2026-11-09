# Exercise 5 – Stage A

## Step 1

| What | Value |
|---|---|
| Plant sent | 18,760 readings in 94 s |
| Rows in the table (`count(*)`) | 18,760 |
| Detector read | 15,446 |
| Detector `missing` | 3,303 |
| Backlog / delay during the run | max 40 rows / max 0.3 s |

**The detector keeps up**, because 200 readings/s is less than one model can do (3 ms per reading → max ~333/s).
It also found the fault on M-006.

**Are the missing readings in the table? Yes.** The table has all 18,760 readings, but the detector read only 15,446.
So 3,314 readings (~18 %) are in the table but were never seen by the detector.
The model counted 3,303 as missing. That is close, but not exactly the same, because the model only notices a gap
between two readings it actually got. Readings skipped before the first or after the last reading of a machine are not counted.

**Why did the detector never see them?**
A row gets its `id` when it is inserted, but other connections only see it after the commit.
In `PostgresSink` every gateway inserts its batch, waits 0–120 ms, and then commits.
So with 4 gateways, the ids are given out in insert order, but the rows become visible in a different order (commit order).
The detector only remembers the highest id it has read (`last_id`) and asks for `id > last_id`.

The timeline from the README:

1. Gateway 1 inserts rows 100–114, but does not commit yet.
2. Gateway 2 inserts rows 115–129 and commits right away.
3. The detector polls `id > 99`. It only sees 115–129 (100–114 are not committed yet, so they are invisible).
   It remembers `last_id = 129`.
4. Gateway 1 commits, so 100–114 are visible now.
5. The detector polls `id > 129`, so rows 100–114 are never read.

For the model these are gaps in the `seq` of those machines, so `missing` goes up.

## Step 2 – full plant (60 machines × 10 Hz = 600 readings/s)

| read | backlog | delay | missing |
|---|---|---|---|
| 2,160 | 2,880 | 4.9 s | 45 |
| 8,160 | 10,266 | 17.2 s | 45 |
| 12,160 | 15,200 | 25.4 s | 45 |
| 16,160 | 20,155 | 33.6 s | 45 |
| 18,160 (stopped) | 18,755 | 37.9 s | 45 |

Plant: 36,960 readings in 62 s. Detector: 0 anomalies.

- **Backlog and delay grow while the plant is running.** The plant sends 600 readings/s, but one detector can do at most ~333/s.
  In my run the plant wrote ~37,000 readings in 62 s, but the detector only read ~18,000, so roughly 290 readings/s.
  After ~15 s the delay is already over 5 s (R3), and at the end it is 38 s.
  (In the last row the backlog goes down a bit because the plant had already stopped.)
- **Missing stays at 45.** These came right at the start. After that the detector is so far behind that it only reads
  old rows that were committed long ago, so the commit problem from step 1 doesn't hit anymore. Slow hides the bug, but doesn't fix it.
- **0 anomalies**, although M-029 had a fault at t = 40 s. The detector never even reached those readings,
  so the maintenance team would get no alert.

We stop the detector right after the plant because otherwise it would just keep working through its old backlog,
which doesn't tell us anything new.

## Summary
1. **Wrong results (R2):** with several gateways writing at the same time, the detector skips rows (~18 % in step 1).
2. **Too slow (R1, R3):** one detector does roughly 290 readings/s, but 600/s come in, so the delay keeps growing and the fault was missed.
