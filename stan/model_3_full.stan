data {
  int<lower=0> N;
  array[N] int<lower=0> y;
  vector[N] log_farms;
  int<lower=1> P;
  matrix[N, P] X;
}
parameters {
  real beta0;
  vector[P] beta;
}
transformed parameters {
  vector[N] lambda = exp(log_farms + beta0 + X * beta);
}
model {
  beta0 ~ normal(0, 10);
  beta ~ normal(0, 10);
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
