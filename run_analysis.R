args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: Rscript run_analysis.R /path/to/Dataset8.txt")
}

data_path <- args[[1]]

required_pkgs <- c(
  "rstan", "bayesplot", "loo", "coda",
  "ggplot2", "gridExtra", "dplyr", "corrplot"
)
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop(
    "Missing R packages: ", paste(missing_pkgs, collapse = ", "),
    ". Install them before running the analysis."
  )
}

suppressPackageStartupMessages({
  library(rstan)
  library(bayesplot)
  library(loo)
  library(ggplot2)
})

source("R/data_prep.R")
source("R/model_comparison.R")
source("R/diagnostics.R")

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
set.seed(123)

dir.create("fits", showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

df <- load_wnv_data(data_path)
stan_data <- prepare_stan_data(df)

cat("Loaded", nrow(df), "counties\n")
cat("Mean equine cases:", mean(df$Equine), "\n")
cat("Variance:", var(df$Equine), "\n")
cat("Zero proportion:", mean(df$Equine == 0), "\n\n")

model_files <- c(
  baseline = "stan/model_1_baseline.stan",
  avian = "stan/model_2_avian.stan",
  full = "stan/model_3_full.stan",
  horseshoe = "stan/model_4_horseshoe.stan"
)

compiled <- lapply(model_files, rstan::stan_model)

fit_baseline <- sampling(
  compiled$baseline,
  data = list(N = stan_data$N, y = stan_data$y, log_farms = stan_data$log_farms),
  chains = 4, iter = 4000, warmup = 2000, thin = 2, seed = 123,
  control = list(adapt_delta = 0.95)
)

fit_avian <- sampling(
  compiled$avian,
  data = list(
    N = stan_data$N, y = stan_data$y, log_farms = stan_data$log_farms,
    X_bird = stan_data$X_bird, X_posbirdrate = stan_data$X_posbirdrate
  ),
  chains = 4, iter = 4000, warmup = 2000, thin = 2, seed = 123,
  control = list(adapt_delta = 0.95)
)

fit_full <- sampling(
  compiled$full,
  data = list(
    N = stan_data$N, y = stan_data$y, log_farms = stan_data$log_farms,
    P = stan_data$P, X = stan_data$X
  ),
  chains = 4, iter = 4000, warmup = 2000, thin = 2, seed = 123,
  control = list(adapt_delta = 0.95)
)

fit_horseshoe <- sampling(
  compiled$horseshoe,
  data = list(
    N = stan_data$N, y = stan_data$y, log_farms = stan_data$log_farms,
    P = stan_data$P, X = stan_data$X
  ),
  chains = 4, iter = 4000, warmup = 2000, thin = 2, seed = 123,
  control = list(adapt_delta = 0.99, max_treedepth = 15)
)

fits <- list(
  baseline = fit_baseline,
  avian = fit_avian,
  full = fit_full,
  horseshoe = fit_horseshoe
)

lapply(names(fits), function(name) saveRDS(fits[[name]], file.path("fits", paste0(name, ".rds"))))

comparison <- compare_models(fits)
saveRDS(comparison, "output/model_comparison.rds")
print(comparison$loo_comparison)
print(comparison$dic)

save_selected_model_diagnostics(fit_avian, stan_data)

samples <- rstan::extract(fit_avian)
summary_selected <- summary(fit_avian, pars = c("beta0", "beta1", "beta2"))$summary
write.csv(summary_selected, "output/selected_model_parameter_summary.csv")

lambda_mean <- colMeans(samples$lambda)
lambda_lower <- apply(samples$lambda, 2, quantile, 0.025)
lambda_upper <- apply(samples$lambda, 2, quantile, 0.975)

predictions <- data.frame(
  County = df$County,
  Observed = stan_data$y,
  Predicted_Mean = lambda_mean,
  Predicted_Lower = lambda_lower,
  Predicted_Upper = lambda_upper,
  Bird_Cases = df$Bird,
  Pos_Bird_Rate = df$PosBirdRate
)
write.csv(predictions, "output/county_predictions.csv", row.names = FALSE)

cat("\nAnalysis complete. Generated fits are in fits/, diagnostics in figures/, and tables in output/.\n")
