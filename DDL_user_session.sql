-- `default`.user_session definition

CREATE TABLE default.user_session
(

    `platform_type` String,

    `user_id` String,

    `session_id` String,

    `version` String,

    `session_number` UInt16,

    `time_start_session` DateTime,

    `time_finish_session` DateTime,

    `length_session` UInt32,

    `amount_get_level` UInt16,

    `amount_get_gold` UInt32,

    `amount_get_bronze_cup` UInt16,

    `amount_get_silver_cup` UInt16,

    `amount_get_gold_cup` UInt16
)
ENGINE = MergeTree
ORDER BY (user_id,
 session_id)
SETTINGS index_granularity = 8192;