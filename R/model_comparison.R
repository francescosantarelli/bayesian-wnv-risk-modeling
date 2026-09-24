compare_models <- function(fits) {
  log_lik <- lapply(fits, function(fit) loo::extract_log_lik(fit, merge_chains = FALSE))
  r_eff <- lapply(log_lik, function(x) loo::relative_eff(exp(x)))
  loo_objects <- Map(function(ll, re) loo::loo(ll, r_eff = re), log_lik, r_eff)

  waic_objects <- lapply(fits, function(fit) {
    loo::waic(loo::extract_log_lik(fit))
  })

  dic_values <- lapply(fits, function(fit) {
    dev <- mean(rstan::extract(fit)$dev)
    p_d <- stats::var(rstan::extract(fit)$dev) / 2
    c(DIC = dev + p_d, pD = p_d)
  })

  list(
    loo = loo_objects,
    loo_comparison = do.call(loo::loo_compare, loo_objects),
    waic = waic_objects,
    dic = do.call(rbind, dic_values)
  )
}
