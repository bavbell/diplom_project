-- `default`.user_info definition

CREATE TABLE default.user_info
(

    `platform_type` String,

    `user_id` String,

    `country` String,

    `first_version` String,

    `last_version` String,

    `type_traffic` String,

    `first_time` DateTime,

    `last_time` DateTime,

    `dates` Array(Date),

    `payer` UInt8,

    `total_revenue` Float64,

    `max_level` UInt16,

    `amount_gold` UInt32,

    `amount_bronze_cup` UInt16,

    `amount_silver_cup` UInt16,

    `amount_gold_cup` UInt16
)
ENGINE = MergeTree
ORDER BY user_id
SETTINGS index_granularity = 8192;