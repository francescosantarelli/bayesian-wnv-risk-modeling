data {
  int<lower=0> N;
  array[N] int<lower=0> y;
  vector[N] log_farms;
}
parameters {
  real beta0;
}
transformed parameters {
  vector[N] lambda = exp(log_farms + beta0);
}
model {
  beta0 ~ normal(0, 10);
  y ~ poisson(lambda);
}
generated quantities {
  vector[N] log_lik;
  array[N] int y_pred;
  real dev = 0;
  for (i in 1:N) {
    log_lik[i] = poisson_lpmf(y[i] | lambda[i]);
    y_pred[i] = poisson_rng(lambda[i]);
    dev += -2 * log_lik[i];
  }
}
