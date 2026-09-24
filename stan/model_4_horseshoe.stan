data {
  int<lower=0> N;
  array[N] int<lower=0> y;
  vector[N] log_farms;
  int<lower=1> P;
  matrix[N, P] X;
}
parameters {
  real beta0;
  vector[P] beta_raw;
  vector<lower=0>[P] lambda_hs;
  real<lower=0> tau;
}
transformed parameters {
  vector[P] beta = tau * lambda_hs .* beta_raw;
  vector[N] log_lambda_poisson = log_farms + beta0 + X * beta;
}
model {
  tau ~ cauchy(0, 1);
  lambda_hs ~ cauchy(0, 1);
  beta_raw ~ normal(0, 1);
  beta0 ~ normal(0, 10);
  y ~ poisson_log(log_lambda_poisson);
}
generated quantities {
  vector[N] log_lik;
  array[N] int y_pred;
  real dev = 0;
  for (i in 1:N) {
    log_lik[i] = poisson_log_lpmf(y[i] | log_lambda_poisson[i]);
    y_pred[i] = poisson_log_rng(log_lambda_poisson[i]);
    dev += -2 * log_lik[i];
  }
}
