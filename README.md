# Project Maverick/Uniswap Rewards Analysis
Live blockchain Dune SQL query for accurately retrieving Total Value Locked for two specific liquidity pools: (MKR/WETH UniV3 0.3%, LUSD/USDC Maverick 0.03%),
additionally retrieving daily generated fee revenues. Furthermore, a Data Science script is curated to standardize
the data and compute the fee elasticity of liquidity (useful in determining efficacy of reward programs) utilizing a logarithmic regression model in Python, statistical significance is achieved.
## Requirements
- Python >= 3.7
- Dune API key
- To install required libraries: `pip install dune-client`
## Key
The Dune API key used to access the queries is stored in a config file located in the same directory as the scripts.
It has the following content:
`API_KEY = "insert_api_key_here"`
## Links
The following is a link to a [Dune dashboard](https://dune.com/hojka_analytics/tvl-analysis) where the query table and TVL graph is displayed live.

