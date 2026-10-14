# Gera as fixtures douradas de paridade do AnthroCore com os pacotes R da OMS (design D6 de port-anthro-engine).
# Uso, da raiz do projeto: Rscript scripts/golden/generate_golden.R
# Saída: Tests/AnthroCoreTests/Fixtures/golden-standards.csv e golden-reference.csv (determinísticas, semente fixa).

lib <- file.path(getwd(), ".rlib")
dir.create(lib, showWarnings = FALSE)
for (pkg in c("anthro", "anthroplus")) {
  if (!requireNamespace(pkg, lib.loc = lib, quietly = TRUE)) {
    install.packages(pkg, lib = lib, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}
suppressWarnings({
  library(anthro, lib.loc = lib)
  library(anthroplus, lib.loc = lib)
})
versions <- sprintf("anthro %s, anthroplus %s, %s",
                    packageVersion("anthro", lib.loc = lib),
                    packageVersion("anthroplus", lib.loc = lib),
                    R.version.string)

SEED <- 20261014L
N <- 600L
out_dir <- file.path("Tests", "AnthroCoreTests", "Fixtures")

# Medida a partir de z sobre uma linha LMS, com a extensão linear além de +-3 DP (inversa de CalculateZandP).
measure_from_z <- function(z, l, m, s) {
  sd <- function(k) m * (1 + l * s * k)^(1 / l)
  ifelse(z > 3, sd(3) + (z - 3) * (sd(3) - sd(2)),
         ifelse(z < -3, sd(-3) - (-3 - z) * (sd(-2) - sd(-3)),
                m * (1 + l * s * z)^(1 / l)))
}

row_of <- function(table, sex, age) {
  table[table$sex == sex & table$age == age, , drop = FALSE]
}

write_fixture <- function(df, path, header) {
  con <- file(path, open = "w", encoding = "UTF-8")
  writeLines(paste0("# ", header), con)
  utils::write.csv(df, con, row.names = FALSE, na = "NA", quote = FALSE)
  close(con)
}

fmt <- function(x) ifelse(is.na(x), NA, formatC(x, format = "f", digits = 2))

# ---------------------------------------------------------------- Padrões 2006 (0 a 1826 dias), pacote anthro
set.seed(SEED)
wei <- anthro:::growthstandards_weianthro
len <- anthro:::growthstandards_lenanthro
edge_days <- c(0L, 1L, 730L, 731L, 1095L, 1826L)
std_rows <- list()
std_resampled <- 0L
i <- 0L
while (length(std_rows) < N) {
  i <- i + 1L
  sex <- sample(1:2, 1)
  age <- if (i <= length(edge_days) * 2) edge_days[((i - 1L) %% length(edge_days)) + 1L] else sample(0:1826, 1)
  measure <- sample(c("l", "h"), 1)
  oedema <- if (runif(1) < 0.05) "y" else "n"
  lr <- row_of(len, sex, age)
  wr <- row_of(wei, sex, age)
  lenhei <- round(measure_from_z(runif(1, -5, 5), lr$l, lr$m, lr$s), 2)
  weight <- round(measure_from_z(runif(1, -5, 5), wr$l, wr$m, wr$s), 2)
  if (weight < 1 || lenhei < 40 || lenhei > 125) { std_resampled <- std_resampled + 1L; next }
  z <- anthro_zscores(sex = sex, age = age, is_age_in_month = FALSE, weight = weight,
                      lenhei = lenhei, measure = measure, oedema = oedema)
  nas_unexpected <- is.na(z$zlen) || (oedema == "n" && (is.na(z$zwei) || is.na(z$zbmi)))
  if (nas_unexpected) { std_resampled <- std_resampled + 1L; next }
  std_rows[[length(std_rows) + 1L]] <- data.frame(
    id = length(std_rows) + 1L, sex = sex, age_days = age, age_months = NA, weight = fmt(weight),
    lenhei = fmt(lenhei), measure = measure, oedema = oedema,
    z_wfa = fmt(z$zwei), z_lhfa = fmt(z$zlen), z_bfa = fmt(z$zbmi))
}
std <- do.call(rbind, std_rows)
write_fixture(std, file.path(out_dir, "golden-standards.csv"),
              sprintf("%s; semente %d; %d casos; %d sorteios refeitos (medida fora de 40 a 125 cm, peso abaixo de 1 kg ou NA inesperado do R); bordas %s dias",
                      versions, SEED, N, std_resampled, paste(edge_days, collapse = "/")))

# ---------------------------------------------------------------- Referência 2007 (61 a 228 meses), pacote anthroplus
set.seed(SEED + 1L)
hfa <- get("hfa_growth_standards", asNamespace("anthroplus"))
bfa <- get("bfa_growth_standards", asNamespace("anthroplus"))
edge_months <- c(61, 61.5, 120, 120.99, 121.5, 228, 228.99)
ref_rows <- list()
ref_excluded_121 <- 0L
i <- 0L
while (length(ref_rows) < N) {
  i <- i + 1L
  sex <- sample(1:2, 1)
  age <- if (i <= length(edge_months) * 2) edge_months[((i - 1L) %% length(edge_months)) + 1L] else
    if (runif(1) < 0.3) round(runif(1, 61, 228.99), 2) else sample(61:228, 1)
  if (age == 121) { ref_excluded_121 <- ref_excluded_121 + 1L; next }
  oedema <- if (runif(1) < 0.05) "y" else "n"
  hr <- row_of(hfa, sex, floor(age))
  br <- row_of(bfa, sex, floor(age))
  height <- round(measure_from_z(runif(1, -5, 5), hr$l, hr$m, hr$s), 2)
  bmi <- measure_from_z(runif(1, -5, 5), br$l, br$m, br$s)
  weight <- round(bmi * (height / 100)^2, 2)
  z <- anthroplus_zscores(sex = sex, age_in_months = age, height_in_cm = height,
                          weight_in_kg = weight, oedema = oedema)
  ref_rows[[length(ref_rows) + 1L]] <- data.frame(
    id = length(ref_rows) + 1L, sex = sex, age_days = NA, age_months = formatC(age, format = "f", digits = 2),
    weight = fmt(weight), lenhei = fmt(height), measure = "h", oedema = oedema,
    z_wfa = fmt(z$zwfa), z_lhfa = fmt(z$zhfa), z_bfa = fmt(z$zbfa))
}
ref <- do.call(rbind, ref_rows)
write_fixture(ref, file.path(out_dir, "golden-reference.csv"),
              sprintf("%s; semente %d; %d casos; %d sorteios de exatamente 121.0 meses excluídos (R usa limite exclusivo para peso, o original aceita o mês 121); bordas %s meses",
                      versions, SEED + 1L, N, ref_excluded_121, paste(edge_months, collapse = "/")))

cat("fixtures gravadas em", out_dir, "\n")
