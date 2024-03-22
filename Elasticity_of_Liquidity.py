# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import statsmodels.api as sm
import numpy as np
import pandas as pd
from dune_client.client import DuneClient
from sklearn.preprocessing import StandardScaler
from config_dune import API_KEY

dune = DuneClient(API_KEY)
scaler = StandardScaler()

# Empirical Elasticity Model (1) LogLt = α + β*LogRt-1 + ε
# Dependent variable is cummulative TVL per LP 
#Independent variables are: LP's share of daily fee revenue (lag 1 day)

# Empirical Elasticity Model (2) LogLt = α + β*LogRt-7 + ε
#Dependent variable is cummulative TVL per pool
#Independent variables are: Total daily fee revenue (lag 7 days)

# Script for Maverick LUSD/USDC 0.03% Reward Elasticity of Liquidity Model - by liquidity providers
raw_lusd_usdc_by_users = dune.get_latest_result(3507732)
rows_lusd_usdc_by_users = raw_lusd_usdc_by_users.result.rows
df_lusd_usdc_by_users = pd.DataFrame(rows_lusd_usdc_by_users)

dataframes_lusd_usdc_by_users = {liquidity_provider : dataframe for liquidity_provider, dataframe in df_lusd_usdc_by_users.groupby('liquidity_provider')}
models_summaries_lusd_usdc_by_users = []

for liquidity_provider, dataframe in dataframes_lusd_usdc_by_users.items():
    dataframe['day'] = pd.to_datetime(dataframe['day'])
    dataframe = dataframe.sort_values('day')
    dataframe['TVL_per_user'] = dataframe['TVL_per_user'].replace(0, 0.01)
    dataframe['user_daily_rewards'] = dataframe['user_daily_rewards'].replace(0, 0.01)
    
    dataframe['log_TVL_per_user'] = np.log(dataframe['TVL_per_user'])
    dataframe['log_user_daily_rewards_lag1'] = np.log(dataframe['user_daily_rewards'].shift(1))
    dataframe = dataframe.dropna()
    
    X_scaled = scaler.fit_transform(dataframe['log_user_daily_rewards_lag1'].values.reshape(-1, 1))
    y_scaled = scaler.fit_transform(dataframe['log_TVL_per_user'].values.reshape(-1, 1))
    dataframe['log_user_daily_rewards_lag1_scaled'] = X_scaled.flatten()
    dataframe['log_TVL_per_user_scaled'] = y_scaled.flatten()
    X = sm.add_constant(dataframe['log_user_daily_rewards_lag1_scaled'])
    model = sm.OLS(dataframe['log_TVL_per_user_scaled'], X).fit()
    summary = {
        'Liquidity Provider': liquidity_provider,
        'R-squared': model.rsquared,
        'F-statistic': model.fvalue,
        'Elasticity': model.params['log_user_daily_rewards_lag1_scaled'],
        'P-value': model.pvalues['log_user_daily_rewards_lag1_scaled'],
        '95% Lower': model.conf_int().loc['log_user_daily_rewards_lag1_scaled'][0],
        '95% Upper': model.conf_int().loc['log_user_daily_rewards_lag1_scaled'][1]
    }
    models_summaries_lusd_usdc_by_users.append(summary)
    
    print(f'Model for liquidity provider {liquidity_provider}')
    print(model.summary())
    print("\n\n")

# Script for Uniswap V3 MKR/WETH 0.3% Reward Elasticity of Liquidity Model - by liquidity providers
raw_mkr_weth_by_users = dune.get_latest_result(3508303)
rows_mkr_weth_by_users = raw_mkr_weth_by_users.result.rows
df_mkr_weth_by_users = pd.DataFrame(rows_mkr_weth_by_users)

dataframes_mkr_weth_by_users = {liquidity_provider : dataframe for liquidity_provider, dataframe in df_mkr_weth_by_users.groupby('liquidity_provider')}
models_summaries_mkr_weth_by_users = []

for liquidity_provider, dataframe in dataframes_mkr_weth_by_users.items():
    dataframe['day'] = pd.to_datetime(dataframe['day'])
    dataframe = dataframe.sort_values('day')
    dataframe['TVL_per_user'] = dataframe['TVL_per_user'].replace(0, 0.01)
    dataframe['user_daily_rewards'] = dataframe['user_daily_rewards'].replace(0, 0.01)
    
    dataframe['log_TVL_per_user'] = np.log(dataframe['TVL_per_user'])
    dataframe['log_user_daily_rewards_lag1'] = np.log(dataframe['user_daily_rewards'].shift(1))
    dataframe = dataframe.dropna()
    
    X_scaled = scaler.fit_transform(dataframe['log_user_daily_rewards_lag1'].values.reshape(-1, 1))
    y_scaled = scaler.fit_transform(dataframe['log_TVL_per_user'].values.reshape(-1, 1))
    dataframe['log_user_daily_rewards_lag1_scaled'] = X_scaled.flatten()
    dataframe['log_TVL_per_user_scaled'] = y_scaled.flatten()
    X = sm.add_constant(dataframe['log_user_daily_rewards_lag1_scaled'])
    model = sm.OLS(dataframe['log_TVL_per_user_scaled'], X).fit()
    summary = {
        'Liquidity Provider': liquidity_provider,
        'R-squared': model.rsquared,
        'F-statistic': model.fvalue,
        'Elasticity': model.params['log_user_daily_rewards_lag1_scaled'],
        'P-value': model.pvalues['log_user_daily_rewards_lag1_scaled'],
        '95% Lower': model.conf_int().loc['log_user_daily_rewards_lag1_scaled'][0],
        '95% Upper': model.conf_int().loc['log_user_daily_rewards_lag1_scaled'][1]
    }
    models_summaries_mkr_weth_by_users.append(summary)
    
    print(f'Model for liquidity provider {liquidity_provider}')
    print(model.summary())
    print('\n\n')

# Script for Maverick LUSD/USDC 0.03% Reward Elasticity of Liquidity Model - by total pool
raw_lusd_usdc_by_pool = dune.get_latest_result(3501510)
rows_lusd_usdc_by_pool = raw_lusd_usdc_by_pool.result.rows
df_lusd_usdc_by_pool = pd.DataFrame(rows_lusd_usdc_by_pool)

model_summary_lusd_usdc_by_pool = []

df_lusd_usdc_by_pool['day'] = pd.to_datetime(df_lusd_usdc_by_pool['day'])
df_lusd_usdc_by_pool = df_lusd_usdc_by_pool.sort_values('day')
df_lusd_usdc_by_pool['TVL'] = df_lusd_usdc_by_pool['TVL'].replace(0, 0.01)
df_lusd_usdc_by_pool['daily_fee_revenue'] = df_lusd_usdc_by_pool['daily_fee_revenue'].replace(0, 0.01)

df_lusd_usdc_by_pool['log_TVL'] = np.log(df_lusd_usdc_by_pool['TVL'])
df_lusd_usdc_by_pool['log_daily_fee_revenue_lag7'] = np.log(df_lusd_usdc_by_pool['daily_fee_revenue'].shift(7))
df_lusd_usdc_by_pool = df_lusd_usdc_by_pool.dropna()

X_scaled = scaler.fit_transform(df_lusd_usdc_by_pool['log_daily_fee_revenue_lag7'].values.reshape(-1, 1))
y_scaled = scaler.fit_transform(df_lusd_usdc_by_pool['log_TVL'].values.reshape(-1, 1))
df_lusd_usdc_by_pool['log_daily_fee_revenue_lag7_scaled'] = X_scaled.flatten()
df_lusd_usdc_by_pool['log_TVL_scaled'] = y_scaled.flatten()
X = sm.add_constant(df_lusd_usdc_by_pool['log_daily_fee_revenue_lag7_scaled'])
model = sm.OLS(df_lusd_usdc_by_pool['log_TVL_scaled'], X).fit()
summary = {
    'Liquidity Pool': '0x6c6fc818b25df89a8ada8da5a43669023bad1f4c',
    'R-squared': model.rsquared,
    'F-statistic': model.fvalue,
    'Elasticity': model.params['log_daily_fee_revenue_lag7_scaled'],
    'P-value': model.pvalues['log_daily_fee_revenue_lag7_scaled'],
    '95% Lower': model.conf_int().loc['log_daily_fee_revenue_lag7_scaled'][0],
    '95% Upper': model.conf_int().loc['log_daily_fee_revenue_lag7_scaled'][1]
}
model_summary_lusd_usdc_by_pool.append(summary)

print('Model for liquidity pool 0x6c6fc818b25df89a8ada8da5a43669023bad1f4c')
print(model.summary())
print('\n\n')

# Script for Uniswap V3 MKR/WETH 0.3% Reward Elasticity of Liquidity Model - by total pool
raw_mkr_weth_by_pool = dune.get_latest_result(3508451)
rows_mkr_weth_by_pool = raw_mkr_weth_by_pool.result.rows
df_mkr_weth_by_pool = pd.DataFrame(rows_mkr_weth_by_pool)

model_summary_mkr_weth_by_pool = []

df_mkr_weth_by_pool['day'] = pd.to_datetime(df_mkr_weth_by_pool['day'])
df_mkr_weth_by_pool = df_mkr_weth_by_pool.sort_values('day')
df_mkr_weth_by_pool['TVL'] = df_mkr_weth_by_pool['TVL'].replace(0, 0.01)
df_mkr_weth_by_pool['daily_fee_revenue'] = df_mkr_weth_by_pool['daily_fee_revenue'].replace(0, 0.01)

df_mkr_weth_by_pool['log_TVL'] = np.log(df_mkr_weth_by_pool['TVL'])
df_mkr_weth_by_pool['log_daily_fee_revenue_lag7'] = np.log(df_mkr_weth_by_pool['daily_fee_revenue'].shift(7))
df_mkr_weth_by_pool = df_mkr_weth_by_pool.dropna()

X_scaled = scaler.fit_transform(df_mkr_weth_by_pool['log_daily_fee_revenue_lag7'].values.reshape(-1, 1))
y_scaled = scaler.fit_transform(df_mkr_weth_by_pool['log_TVL'].values.reshape(-1, 1))
df_mkr_weth_by_pool['log_daily_fee_revenue_lag7_scaled'] = X_scaled.flatten()
df_mkr_weth_by_pool['log_TVL_scaled'] = y_scaled.flatten()
X = sm.add_constant(df_mkr_weth_by_pool['log_daily_fee_revenue_lag7_scaled'])
model = sm.OLS(df_mkr_weth_by_pool['log_TVL_scaled'], X).fit()
summary = {
    'Liquidity Pool': '0xe8c6c9227491c0a8156a0106a0204d881bb7e531',
    'R-squared': model.rsquared,
    'F-statistic': model.fvalue,
    'Elasticity': model.params['log_daily_fee_revenue_lag7_scaled'],
    'P-value': model.pvalues['log_daily_fee_revenue_lag7_scaled'],
    '95% Lower': model.conf_int().loc['log_daily_fee_revenue_lag7_scaled'][0],
    '95% Upper': model.conf_int().loc['log_daily_fee_revenue_lag7_scaled'][1]
}
model_summary_mkr_weth_by_pool.append(summary)

print('Model for liquidity pool 0xe8c6c9227491c0a8156a0106a0204d881bb7e531')
print(model.summary())
print('\n\n')

df_model_summary_lusd_usdc_by_users = pd.DataFrame(models_summaries_lusd_usdc_by_users)
df_model_results_lusd_usdc_by_users = df_model_summary_lusd_usdc_by_users[['Liquidity Provider', 'Elasticity', 'P-value']]
print(df_model_summary_lusd_usdc_by_users)
print(df_model_results_lusd_usdc_by_users)

df_model_summary_mkr_weth_by_users = pd.DataFrame(models_summaries_mkr_weth_by_users)
df_model_results_mkr_weth_by_users = df_model_summary_mkr_weth_by_users[['Liquidity Provider', 'Elasticity', 'P-value']]
print(df_model_summary_mkr_weth_by_users)
print(df_model_results_mkr_weth_by_users)

df_model_summary_lusd_usdc_by_pool = pd.DataFrame(model_summary_lusd_usdc_by_pool)
df_model_results_lusd_usdc_by_pool = df_model_summary_lusd_usdc_by_pool[['Liquidity Pool', 'Elasticity', 'P-value']]
print(df_model_summary_lusd_usdc_by_pool)
print(df_model_results_lusd_usdc_by_pool)

df_model_summary_mkr_weth_by_pool = pd.DataFrame(model_summary_mkr_weth_by_pool)
df_model_results_mkr_weth_by_pool = df_model_summary_mkr_weth_by_pool[['Liquidity Pool', 'Elasticity', 'P-value']]
print(df_model_summary_mkr_weth_by_pool)
print(df_model_results_mkr_weth_by_pool)








    

    
