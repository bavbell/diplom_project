-- `default`.user_payments definition

CREATE TABLE default.user_payments
(

    `platform_type` String,

    `user_id` String,

    `session_id` String,

    `version` String,

    `purchase_number` UInt16,

    `purchase_time` DateTime,

    `item` String,

    `offer_id` String,

    `price` Float64,

    `level` UInt16
)
ENGINE = MergeTree
ORDER BY (user_id,
 purchase_time)
SETTINGS index_granularity = 8192;