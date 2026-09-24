save_selected_model_diagnostics <- function(fit, stan_data, figure_dir = "figures") {
  dir.create(figure_dir, showWarnings = FALSE, recursive = TRUE)

  grDevices::png(file.path(figure_dir, "traceplots_selected_model.png"), width = 1400, height = 900, res = 130)
  print(
    bayesplot::mcmc_trace(
      fit,
      pars = c("beta0", "beta1", "beta2"),
      facet_args = list(ncol = 1)
    ) + ggplot2::ggtitle("MCMC Trace Plots - Selected Model")
  )
  grDevices::dev.off()

  y_pred <- rstan::extract(fit)$y_pred
  grDevices::png(file.path(figure_dir, "posterior_predictive_check_generated.png"), width = 1300, height = 800, res = 130)
  print(
    bayesplot::ppc_dens_overlay(stan_data$y, y_pred[1:min(100, nrow(y_pred)), ]) +
      ggplot2::ggtitle("Posterior Predictive Check")
  )
  grDevices::dev.off()

  grDevices::png(file.path(figure_dir, "posterior_distributions_generated.png"), width = 1400, height = 600, res = 130)
  print(
    bayesplot::mcmc_areas(
      fit,
      pars = c("beta0", "beta1", "beta2"),
      prob = 0.95,
      prob_outer = 0.99
    ) + ggplot2::ggtitle("Posterior Distributions")
  )
  grDevices::dev.off()
}
