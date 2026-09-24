load_wnv_data <- function(path) {
  if (!file.exists(path)) stop("Dataset not found: ", path)

  df <- read.table(
    path,
    header = FALSE,
    sep = "",
    stringsAsFactors = FALSE,
    fill = TRUE
  )

  colnames(df) <- c(
    "CountyName", "State", "Bird", "Equine", "Farms",
    "Area", "Population", "HumanDensity", "PosBirdRate", "PosEquineRate"
  )

  df$CountyName <- gsub(",", "", df$CountyName)
  df$County <- paste(df$CountyName, df$State)

  numeric_cols <- c(
    "Bird", "Equine", "Farms", "Area", "Population",
    "HumanDensity", "PosBirdRate", "PosEquineRate"
  )
  for (col in numeric_cols) df[[col]] <- as.numeric(df[[col]])

  na.omit(df)
}

prepare_stan_data <- function(df) {
  x_bird <- as.numeric(scale(df$Bird))
  x_posbirdrate <- as.numeric(scale(df$PosBirdRate))
  x_humandensity <- as.numeric(scale(df$HumanDensity))
  x_population <- as.numeric(scale(log(df$Population)))
  x_area <- as.numeric(scale(log(df$Area)))

  x_matrix <- cbind(
    x_bird,
    x_posbirdrate,
    x_humandensity,
    x_population,
    x_area
  )

  list(
    N = nrow(df),
    y = as.integer(df$Equine),
    log_farms = log(df$Farms),
    X_bird = x_bird,
    X_posbirdrate = x_posbirdrate,
    X_humandensity = x_humandensity,
    X_population = x_population,
    X_area = x_area,
    P = ncol(x_matrix),
    X = x_matrix
  )
}
