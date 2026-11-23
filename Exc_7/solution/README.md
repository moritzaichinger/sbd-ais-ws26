# Exercise 7 — From the log to the lake

## 1. Decision: B — the lake is the truth

I chose B. Every record in the lake keeps its Kafka partition and offset, so the lake itself shows where the last run stopped: the highest offset + 1 per partition. There is no extra state file that could say something different from the lake.

Each run writes into `STAGING` first. When all files are written, `publish()` moves the run into the lake with one rename. So a run is either completely in the lake or not at all.

**Why not A:** the job writes the data and the state file in two separate steps. If it stops in between, the next run either copies the same records again (duplicates) or skips them (missing). This is the same dual-write problem as in Exercise 6.

**Why not C:** the duplicates are still in the lake, because the view only hides them. Every reader has to remember to use the view.

**Downside of B:** only one run can write at a time. Otherwise two runs would copy the same records.

## 2. Result

```python
def run_once():
    start = lake_position()          # where did the last run stop?
    new = read_new(start)            # read the new records
    run = write_files(new, STAGING)  # write them where no reader looks
    publish(run)                     # move them into the lake in one step
```

- **Example (section 1):** it always starts at offset 0, so the second run copied all 2,000,000 records again. That gave 2,000,000 duplicates, so the check failed.
- **Situations 1–3:** the first run copies everything, the second copies only the 100,000 new records, and the third finds nothing new.
- **Situations 4 and 5 (run stops while / after writing):** the files are only in `STAGING`, so the lake doesn't change (0 duplicates, 0 missing). "Not loaded: 100,000" just means the next run still has work to do. The next run starts at the same position, deletes the leftovers in `STAGING`, writes everything again and publishes it, so the check passes.

The topic starts at 2,300,000 records because of an earlier test run (`check_all` empties the lake, but not the topic).

## 3. Output of `check_all`

```
situation                                 in lake  duplicates  missing  not loaded    run  check
-----------------------------------------------------------------------------------------------
1 first run                             2,300,000           0        0           0  23.2s  PASS
2 new records arrive, run again         2,400,000           0        0           0   5.7s  PASS
3 nothing new, run again                2,400,000           0        0           0   0.1s  PASS
4 run stops WHILE writing: right after  2,400,000           0        0     100,000         PASS
  ... then the next run                 2,500,000           0        0           0   5.2s  PASS
5 run stops AFTER writing: right after  2,500,000           0        0     100,000         PASS
  ... then the next run                 2,600,000           0        0           0   5.2s  PASS
-----------------------------------------------------------------------------------------------
Exactly once after every run: YES
```
