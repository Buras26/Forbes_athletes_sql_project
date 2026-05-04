-- Create analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;

-- Set search path
SET search_path TO analytics, public;

-- =====================
-- DROP TABLES (safe reset)
-- =====================
DROP TABLE IF EXISTS analytics.agent_managers    CASCADE;
DROP TABLE IF EXISTS analytics.awards            CASCADE;
DROP TABLE IF EXISTS analytics.social_media      CASCADE;
DROP TABLE IF EXISTS analytics.performance_stats CASCADE;
DROP TABLE IF EXISTS analytics.endorsements      CASCADE;
DROP TABLE IF EXISTS analytics.earnings_yearly   CASCADE;
DROP TABLE IF EXISTS analytics.contracts         CASCADE;
DROP TABLE IF EXISTS analytics.teams             CASCADE;
DROP TABLE IF EXISTS analytics.athletes          CASCADE;
DROP TABLE IF EXISTS analytics.sports            CASCADE;

-- =====================
-- CREATE TABLES
-- =====================

CREATE TABLE analytics.sports (
    sport_id                SMALLINT     PRIMARY KEY,
    sport_name              VARCHAR(50)  NOT NULL UNIQUE,
    category                VARCHAR(10)  NOT NULL CHECK (category IN ('team','individual')),
    avg_career_years        INT          NOT NULL CHECK (avg_career_years > 0),
    global_popularity_score FLOAT        NOT NULL CHECK (global_popularity_score BETWEEN 0 AND 10)
);

CREATE TABLE analytics.athletes (
    athlete_id   INT          PRIMARY KEY,
    full_name    VARCHAR(100) NOT NULL,
    birth_date   DATE         NOT NULL,
    nationality  VARCHAR(50)  NOT NULL,
    gender       CHAR(1)      NOT NULL CHECK (gender IN ('M','F')),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    profile_bio  TEXT
);

CREATE TABLE analytics.teams (
    team_id          INT          PRIMARY KEY,
    team_name        VARCHAR(100) NOT NULL,
    sport_id         SMALLINT     NOT NULL REFERENCES analytics.sports(sport_id),
    country          VARCHAR(50)  NOT NULL,
    city             VARCHAR(50)  NOT NULL,
    founded_year     INT          CHECK (founded_year BETWEEN 1800 AND 2025),
    market_value_usd BIGINT,
    is_active        BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE analytics.contracts (
    contract_id         INT           PRIMARY KEY,
    athlete_id          INT           NOT NULL REFERENCES analytics.athletes(athlete_id),
    team_id             INT           REFERENCES analytics.teams(team_id),
    start_date          DATE          NOT NULL,
    end_date            DATE,
    base_salary_usd     NUMERIC(15,2) NOT NULL CHECK (base_salary_usd >= 0),
    signing_bonus       NUMERIC(15,2) DEFAULT 0,
    performance_clauses TEXT,
    contract_type       VARCHAR(30)   NOT NULL DEFAULT 'standard'
                                      CHECK (contract_type IN ('standard','rookie','max','supermax','veteran','endorsement-linked'))
);

CREATE TABLE analytics.earnings_yearly (
    earning_id         INT           PRIMARY KEY,
    athlete_id         INT           NOT NULL REFERENCES analytics.athletes(athlete_id),
    year               INT           NOT NULL CHECK (year BETWEEN 2015 AND 2025),
    on_field_earnings  NUMERIC(15,2) NOT NULL,
    off_field_earnings NUMERIC(15,2) NOT NULL,
    total_earnings     NUMERIC(15,2) NOT NULL,
    forbes_rank        INT           CHECK (forbes_rank BETWEEN 1 AND 200),
    currency           CHAR(3)       NOT NULL DEFAULT 'USD',
    UNIQUE (athlete_id, year)
);

CREATE TABLE analytics.endorsements (
    endorsement_id  INT           PRIMARY KEY,
    athlete_id      INT           NOT NULL REFERENCES analytics.athletes(athlete_id),
    brand_name      VARCHAR(100)  NOT NULL,
    deal_value_usd  NUMERIC(15,2),
    start_date      DATE          NOT NULL,
    end_date        DATE,
    category        VARCHAR(50),
    is_exclusive    BOOLEAN       DEFAULT FALSE,
    contract_status VARCHAR(20)   NOT NULL DEFAULT 'active'
                                  CHECK (contract_status IN ('active','expired','terminated','pending'))
);

CREATE TABLE analytics.performance_stats (
    stat_id           INT        PRIMARY KEY,
    athlete_id        INT        NOT NULL REFERENCES analytics.athletes(athlete_id),
    season_year       INT        NOT NULL,
    sport_id          SMALLINT   NOT NULL REFERENCES analytics.sports(sport_id),
    games_played      INT,
    wins              INT,
    losses            INT,
    score_metric      FLOAT,
    mvp_awards        INT        DEFAULT 0,
    championship_wins INT        DEFAULT 0,
    injury_days       INT        DEFAULT 0,
    notes             TEXT,
    UNIQUE (athlete_id, season_year)
);

CREATE TABLE analytics.social_media (
    social_id                INT           PRIMARY KEY,
    athlete_id               INT           NOT NULL REFERENCES analytics.athletes(athlete_id),
    platform                 VARCHAR(30)   NOT NULL,
    followers_count          BIGINT        NOT NULL CHECK (followers_count >= 0),
    avg_engagement_rate      DECIMAL(5,3),
    posts_per_month          INT,
    verified                 BOOLEAN       NOT NULL DEFAULT TRUE,
    joined_date              DATE,
    estimated_post_value_usd NUMERIC(12,2)
);

CREATE TABLE analytics.awards (
    award_id         INT           PRIMARY KEY,
    athlete_id       INT           NOT NULL REFERENCES analytics.athletes(athlete_id),
    award_name       VARCHAR(100)  NOT NULL,
    awarding_body    VARCHAR(100),
    year_awarded     INT           NOT NULL CHECK (year_awarded BETWEEN 1980 AND 2025),
    award_category   VARCHAR(50),
    prize_money      NUMERIC(12,2),
    is_international BOOLEAN       NOT NULL DEFAULT FALSE
);

CREATE TABLE analytics.agent_managers (
    agent_id            INT           PRIMARY KEY,
    athlete_id          INT           NOT NULL REFERENCES analytics.athletes(athlete_id),
    agent_name          VARCHAR(100)  NOT NULL,
    agency_name         VARCHAR(100),
    commission_rate     DECIMAL(4,2)  CHECK (commission_rate BETWEEN 0 AND 25),
    contract_start      DATE          NOT NULL,
    years_represented   INT,
    total_deals_managed INT           DEFAULT 0,
    email               VARCHAR(100)
);

-- =====================
-- LOAD DATA FROM CSVs
-- =====================
-- Tables must be loaded in FK order

COPY analytics.sports
FROM '/data/sports.csv' CSV HEADER NULL '';

COPY analytics.athletes
FROM '/data/athletes.csv' CSV HEADER NULL '';

COPY analytics.teams
FROM '/data/teams.csv' CSV HEADER NULL '';

COPY analytics.contracts
FROM '/data/contracts.csv' CSV HEADER NULL '';

COPY analytics.earnings_yearly
FROM '/data/earnings_yearly.csv' CSV HEADER NULL '';

COPY analytics.endorsements
FROM '/data/endorsements.csv' CSV HEADER NULL '';

COPY analytics.performance_stats
FROM '/data/performance_stats.csv' CSV HEADER NULL '';

COPY analytics.social_media
FROM '/data/social_media.csv' CSV HEADER NULL '';

COPY analytics.awards
FROM '/data/awards.csv' CSV HEADER NULL '';

COPY analytics.agent_managers
FROM '/data/agent_managers.csv' CSV HEADER NULL '';

-- =====================
-- VERIFY
-- =====================
DO $$
DECLARE
    total_rows INT;
BEGIN
    SELECT SUM(cnt) INTO total_rows FROM (
        SELECT COUNT(*) AS cnt FROM analytics.sports         UNION ALL
        SELECT COUNT(*) FROM analytics.athletes              UNION ALL
        SELECT COUNT(*) FROM analytics.teams                 UNION ALL
        SELECT COUNT(*) FROM analytics.contracts             UNION ALL
        SELECT COUNT(*) FROM analytics.earnings_yearly       UNION ALL
        SELECT COUNT(*) FROM analytics.endorsements          UNION ALL
        SELECT COUNT(*) FROM analytics.performance_stats     UNION ALL
        SELECT COUNT(*) FROM analytics.social_media          UNION ALL
        SELECT COUNT(*) FROM analytics.awards                UNION ALL
        SELECT COUNT(*) FROM analytics.agent_managers
    ) counts;
    RAISE NOTICE '✅ Database initialized. Total rows loaded: %', total_rows;
END $$;
