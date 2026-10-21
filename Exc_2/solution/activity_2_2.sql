-- Step 1: compare different table sizes

\timing on

CREATE TABLE people_50k AS
SELECT * FROM people_big WHERE id <= 50000;

CREATE TABLE people_100k AS
SELECT * FROM people_big WHERE id <= 100000;

CREATE TABLE people_200k AS
SELECT * FROM people_big WHERE id <= 200000;

-- 50,000 people
SELECT COUNT(*)
FROM people_50k p1
JOIN people_50k p2
  ON p1.country = p2.country;

-- 100,000 people
SELECT COUNT(*)
FROM people_100k p1
JOIN people_100k p2
  ON p1.country = p2.country;

-- 200,000 people
SELECT COUNT(*)
FROM people_200k p1
JOIN people_200k p2
  ON p1.country = p2.country;

-- Step 2: test an index on country

CREATE INDEX people_100k_country_idx ON people_100k(country);

ANALYZE people_100k;

SELECT COUNT(*)
FROM people_100k p1
JOIN people_100k p2
  ON p1.country = p2.country;

EXPLAIN ANALYZE
SELECT COUNT(*)
FROM people_100k p1
JOIN people_100k p2
  ON p1.country = p2.country;

-- Step 3: count matching pairs without a join

SELECT SUM(people_count * people_count) AS matching_pairs
FROM (
    SELECT country, COUNT(*) AS people_count
    FROM people_100k
    WHERE country IS NOT NULL
    GROUP BY country
) AS country_counts;

SELECT SUM(people_count * people_count) AS matching_pairs
FROM (
    SELECT country, COUNT(*) AS people_count
    FROM people_big
    WHERE country IS NOT NULL
    GROUP BY country
) AS country_counts;
