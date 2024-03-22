WITH RawData AS (
  SELECT
    t.to AS liquidity_pool,
    DATE_TRUNC('minute', t.evt_block_time) AS time,
    t.contract_address AS token,
    CASE
      WHEN t.contract_address = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2 THEN CAST(t.value AS DOUBLE)
      ELSE 0
    END AS MKR_solidity_amount,
    CASE
      WHEN t.contract_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 THEN CAST(t.value AS DOUBLE)
      ELSE 0
    END AS WETH_solidity_amount,
    CASE
      WHEN t.contract_address = 0x5f98805a4e8be255a32880fdec7f6728c6568ba0 THEN CAST(t.value AS DOUBLE)
      ELSE 0
    END AS LUSD_solidity_amount,
    CASE
      WHEN t.contract_address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 THEN CAST(t.value AS DOUBLE)
      ELSE 0
    END AS USDC_solidity_amount
  FROM
    erc20_ethereum.evt_Transfer AS t
  WHERE
    t.evt_block_time > CAST('2020-12-19' AS TIMESTAMP)
    AND (t.to IN (0x6c6FC818b25dF89A8adA8da5A43669023bAD1F4c, 0xe8c6c9227491c0a8156a0106a0204d881bb7e531))
  
  UNION ALL
  
  SELECT
    t."from" AS liquidity_pool,
    DATE_TRUNC('minute', t.evt_block_time) AS time,
    t.contract_address AS token,
    CASE
      WHEN t.contract_address = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2 THEN (-1) * CAST(t.value AS DOUBLE)
      ELSE 0
    END AS MKR_solidity_amount,
    CASE
      WHEN t.contract_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 THEN (-1) * CAST(t.value AS DOUBLE)
      ELSE 0
    END AS WETH_solidity_amount,
    CASE
      WHEN t.contract_address = 0x5f98805a4e8be255a32880fdec7f6728c6568ba0 THEN (-1) * CAST(t.value AS DOUBLE)
      ELSE 0
    END AS LUSD_solidity_amount,
    CASE
      WHEN t.contract_address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 THEN (-1) * CAST(t.value AS DOUBLE)
      ELSE 0
    END AS USDC_solidity_amount
  FROM 
    erc20_ethereum.evt_Transfer AS t
  WHERE
    t.evt_block_time > CAST('2020-12-19' AS TIMESTAMP)
    AND (t."from" IN (0x6c6FC818b25dF89A8adA8da5A43669023bAD1F4c, 0xe8c6c9227491c0a8156a0106a0204d881bb7e531))
),
PriceData AS (
  SELECT
    DATE_TRUNC('minute', minute) AS time,
    contract_address AS token,
    avg(decimals) AS decimals,
    avg(price) AS price
  FROM
   prices.usd
  WHERE
    minute > CAST('2020-12-19' AS TIMESTAMP)
    AND (contract_address in (0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2,
                              0x5f98805A4E8be255a32880FDeC7F6728C6568bA0, 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48))
  GROUP BY
    1, 2
),
RawDataFinal AS (
  SELECT
    r.time,
    r.liquidity_pool,
    r.token,
    CASE 
       WHEN r.token = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2 THEN (MKR_solidity_amount / power(10, p.decimals)) * p.price 
       ELSE 0
       END AS MKR_amount_USD,
    CASE
      WHEN r.token = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 THEN (WETH_solidity_amount / power(10, p.decimals)) * p.price 
      ELSE 0
      END AS WETH_amount_USD,
    CASE
      WHEN r.token = 0x5f98805a4e8be255a32880fdec7f6728c6568ba0 THEN (LUSD_solidity_amount / power(10, p.decimals)) * p.price
      ELSE 0
      END AS LUSD_amount_USD,
    CASE
      WHEN r.token = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 THEN (USDC_solidity_amount / power(10, p.decimals)) * p.price
      ELSE 0
      END AS USDC_amount_USD,
    CASE
      WHEN r.token = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2 THEN MKR_solidity_amount / power(10, p.decimals)
      ELSE 0
      END AS MKR_token_amount,
    CASE
      WHEN r.token = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 THEN WETH_solidity_amount / power(10, p.decimals)
      ELSE 0
      END AS WETH_token_amount,
    CASE
      WHEN r.token = 0x5f98805a4e8be255a32880fdec7f6728c6568ba0 THEN LUSD_solidity_amount / power(10, p.decimals)
      ELSE 0
      END AS LUSD_token_amount,
    CASE
      WHEN r.token = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 THEN USDC_solidity_amount / power(10, p.decimals)
      ELSE 0
      END AS USDC_token_amount,
    p.price as price
  FROM
    RawData r
    JOIN PriceData p ON r.time = p.time
    AND r.token = p.token
),
FeeDescriptionData AS (
  SELECT
    time,
    liquidity_pool,
    SUM(MKR_amount_USD) AS minute_MKR_amount_USD,
    SUM(WETH_amount_USD) AS minute_WETH_amount_USD,
    SUM(LUSD_amount_USD) AS minute_LUSD_amount_USD,
    SUM(USDC_amount_USD) AS minute_USDC_amount_USD,
    SUM(MKR_token_amount) AS minute_MKR_token_amount,
    SUM(WETH_token_amount) AS minute_WETH_token_amount,
    SUM(LUSD_token_amount) AS minute_LUSD_token_amount,
    SUM(USDC_token_amount) AS minute_USDC_token_amount,
    SUM(MKR_amount_USD) + SUM(WETH_amount_USD) AS minute_net_amount_USD_uni,
    SUM(LUSD_amount_USD) + SUM(USDC_amount_USD) AS minute_net_amount_USD_mav
  FROM
    RawDataFinal
  GROUP BY
    1, 2
),
FeeDescriptionDataFinal AS (
  SELECT
    *,
    CASE
      WHEN (minute_MKR_amount_USD > 0 AND minute_WETH_amount_USD < 0) OR (minute_MKR_amount_USD < 0 AND minute_WETH_amount_USD > 0) THEN
        CASE
          WHEN ABS(minute_net_amount_USD_uni / GREATEST(minute_MKR_amount_USD, minute_WETH_amount_USD)) < 0.031 THEN
            CASE
              WHEN GREATEST(minute_MKR_amount_USD, minute_WETH_amount_USD) = minute_MKR_amount_USD THEN
                minute_MKR_token_amount * 0.003
              ELSE 0
            END
          ELSE 0
        END 
      ELSE 0
    END AS minute_MKR_unclaimed_token_fees,
    CASE
      WHEN (minute_MKR_amount_USD > 0 AND minute_WETH_amount_USD < 0) OR (minute_MKR_amount_USD < 0 AND minute_WETH_amount_USD > 0) THEN
        CASE
          WHEN ABS(minute_net_amount_USD_uni / GREATEST(minute_MKR_amount_USD, minute_WETH_amount_USD)) < 0.031 THEN
            CASE
              WHEN GREATEST(minute_MKR_amount_USD, minute_WETH_amount_USD) = minute_WETH_amount_USD THEN
                minute_WETH_token_amount * 0.003
              ELSE 0
            END
          ELSE 0
        END 
      ELSE 0
    END AS minute_WETH_unclaimed_token_fees,
    CASE
      WHEN (minute_LUSD_amount_USD > 0 AND minute_USDC_amount_USD < 0) OR (minute_LUSD_amount_USD < 0 AND minute_USDC_amount_USD > 0) THEN
        CASE
          WHEN ABS(minute_net_amount_USD_mav / GREATEST(minute_LUSD_amount_USD, minute_USDC_amount_USD)) < 0.031 THEN
            CASE
              WHEN GREATEST(minute_LUSD_amount_USD, minute_USDC_amount_USD) = minute_LUSD_amount_USD THEN
                minute_LUSD_token_amount * 0.0003
              ELSE 0
            END
          ELSE 0
        END 
      ELSE 0
    END AS minute_LUSD_unclaimed_token_fees,
    CASE
      WHEN (minute_LUSD_amount_USD > 0 AND minute_USDC_amount_USD < 0) OR (minute_LUSD_amount_USD < 0 AND minute_USDC_amount_USD > 0) THEN
        CASE
          WHEN ABS(minute_net_amount_USD_mav / GREATEST(minute_LUSD_amount_USD, minute_USDC_amount_USD)) < 0.031 THEN
            CASE
              WHEN GREATEST(minute_LUSD_amount_USD, minute_USDC_amount_USD) = minute_USDC_amount_USD THEN
                minute_USDC_token_amount * 0.0003
              ELSE 0
            END
          ELSE 0
        END 
      ELSE 0
    END AS minute_USDC_unclaimed_token_fees
  FROM
    FeeDescriptionData
),
AggregatedDataRaw AS (
  SELECT
    r.time,
    r.liquidity_pool,
    r.token,
    SUM(r.MKR_token_amount) AS minute_MKR_token_amount,
    SUM(r.WETH_token_amount) AS minute_WETH_token_amount,
    SUM(r.LUSD_token_amount) AS minute_LUSD_token_amount,
    SUM(r.USDC_token_amount) AS minute_USDC_token_amount,
    AVG(r.price) AS price,
    AVG(f.minute_MKR_unclaimed_token_fees) AS minute_MKR_unclaimed_token_fees,
    AVG(f.minute_WETH_unclaimed_token_fees) AS minute_WETH_unclaimed_token_fees,
    AVG(f.minute_LUSD_unclaimed_token_fees) AS minute_LUSD_unclaimed_token_fees,
    AVG(f.minute_USDC_unclaimed_token_fees) AS minute_USDC_unclaimed_token_fees
  FROM
    RawDataFinal r
    JOIN FeeDescriptionDataFinal f ON r.time = f.time
    AND r.liquidity_pool = f.liquidity_pool
  GROUP BY
    1, 2, 3
),
AggregatedDataDaily AS (
  SELECT
    DATE_TRUNC('day', time) AS day,
    liquidity_pool,
    token,
    SUM(minute_MKR_token_amount) AS daily_MKR_token_amount,
    SUM(minute_WETH_token_amount) AS daily_WETH_token_amount,
    SUM(minute_LUSD_token_amount) AS daily_LUSD_token_amount,
    SUM(minute_USDC_token_amount) AS daily_USDC_token_amount,
    AVG(price) AS price,
    SUM(minute_MKR_unclaimed_token_fees) AS daily_MKR_unclaimed_token_fees,
    SUM(minute_WETH_unclaimed_token_fees) AS daily_WETH_unclaimed_token_fees,
    SUM(minute_LUSD_unclaimed_token_fees) AS daily_LUSD_unclaimed_token_fees,
    SUM(minute_USDC_unclaimed_token_fees) AS daily_USDC_unclaimed_token_fees
  FROM
    AggregatedDataRaw
  GROUP BY
    1, 2, 3
),
CumulativeData AS (
  SELECT
    day,
    liquidity_pool,
    token,
    SUM(daily_MKR_token_amount) OVER (PARTITION BY liquidity_pool, token ORDER BY day) AS cumulative_MKR_amount,
    SUM(daily_WETH_token_amount) OVER (PARTITION BY liquidity_pool, token ORDER BY day) AS cumulative_WETH_amount,
    SUM(daily_LUSD_token_amount) OVER (PARTITION BY liquidity_pool, token ORDER BY day) AS cumulative_LUSD_amount,
    SUM(daily_USDC_token_amount) OVER (PARTITION BY liquidity_pool, token ORDER BY day) AS cumulative_USDC_amount,
    price,
    CASE
      WHEN token = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2 THEN daily_MKR_unclaimed_token_fees
      ELSE 0
    END AS daily_MKR_unclaimed_token_fees,
    CASE
      WHEN token = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 THEN daily_WETH_unclaimed_token_fees
      ELSE 0
    END AS daily_WETH_unclaimed_token_fees,
    CASE
      WHEN token = 0x5f98805a4e8be255a32880fdec7f6728c6568ba0 THEN daily_LUSD_unclaimed_token_fees
      ELSE 0
    END AS daily_LUSD_unclaimed_token_fees,
    CASE
      WHEN token = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 THEN daily_USDC_unclaimed_token_fees
      ELSE 0
    END AS daily_USDC_unclaimed_token_fees
  FROM
    AggregatedDataDaily
),
TVLData AS (
  SELECT
    day,
    liquidity_pool,
    SUM(cumulative_MKR_amount * price) + SUM(cumulative_WETH_amount * price) AS UniswapTVL,
    SUM(cumulative_LUSD_amount * price) + SUM(cumulative_USDC_amount * price) AS MaverickTVL,
    SUM(daily_MKR_unclaimed_token_fees * price) + SUM(daily_WETH_unclaimed_token_fees * price) AS daily_fee_revenue_uni,
    SUM(daily_LUSD_unclaimed_token_fees * price) + SUM(daily_USDC_unclaimed_token_fees * price) AS daily_fee_revenue_mav
  FROM
    CumulativeData
  GROUP BY
  1, 2
),
TVLDataFinal AS (
  SELECT
    day,
    liquidity_pool,
    UniswapTVL + MaverickTVL AS TVL
  FROM
    TVLData
),
LaggedTVL as (
  SELECT
    day,
    liquidity_pool,
    TVL,
    LAG(TVL, 1) OVER (PARTITION BY liquidity_pool ORDER BY day) AS LaggedTVL
  FROM
    TVLDataFinal
),
MissingDays AS (
  SELECT
    day,
    COUNT(liquidity_pool) AS poolcount
  FROM
    LaggedTVL
  GROUP BY
    day
  HAVING
    COUNT(liquidity_pool) < 2
),
DuplicatedRows AS (
  SELECT
    current.day,
    CASE 
      WHEN current.liquidity_pool = 0x6c6FC818b25dF89A8adA8da5A43669023bAD1F4c 
        THEN 0xe8c6c9227491c0a8156a0106a0204d881bb7e531 
      ELSE 0x6c6FC818b25dF89A8adA8da5A43669023bAD1F4c
    END AS liquidity_pool,
    lagged.TVL AS TVL,
    lagged.LaggedTVL AS LaggedTVL
  FROM
    MissingDays m
    JOIN LaggedTVL current ON m.day = current.day
    LEFT JOIN LaggedTVL lagged ON lagged.day = m.day - INTERVAL '1' day
      AND lagged.liquidity_pool = CASE
                                    WHEN current.liquidity_pool = 0x6c6FC818b25dF89A8adA8da5A43669023bAD1F4c
                                      THEN 0xe8c6c9227491c0a8156a0106a0204d881bb7e531
                                    ELSE 0x6c6FC818b25dF89A8adA8da5A43669023bAD1F4c
                                  END 
),
FinalOutput AS (
  SELECT *
  FROM LaggedTVL
  
  UNION ALL
  
  SELECT *
  FROM DuplicatedRows
)
SELECT 
  day,
  liquidity_pool,
  TVL
FROM 
  FinalOutput
ORDER BY 
  day desc, 
  liquidity_pool;