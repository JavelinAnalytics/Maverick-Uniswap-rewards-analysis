# Project Liquidity Metrics
This project designs a Dune SQL query for two specific liquidity pools: (MKR/WETH UniV3 0.3%, LUSD/USDC Maverick 0.03%),
accurately querying live TVL data, as well as daily generated fee revenues. The second part of the project takes
the data and computes the fee elasticity of liquidity (useful in determing efficacy of rewards) utilizing a logarithmic model in Python.
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

