# Gera o oráculo do IC 95% corrigido por cluster com o pacote R survey (design D6 de add-survey-analysis).
# Uso, da raiz do projeto: Rscript scripts/golden/generate_cluster_ci_golden.R
# Saída: Tests/AnthroAnalysisTests/ClusterCIGolden.generated.swift (determinística, semente fixa; duas execuções dão o
# mesmo arquivo).

lib <- file.path(getwd(), ".rlib")
dir.create(lib, showWarnings = FALSE)
paths <- c(lib, .libPaths())
if (!requireNamespace("survey", lib.loc = paths, quietly = TRUE)) {
  install.packages("survey", lib = lib, repos = "https://cloud.r-project.org", quiet = TRUE)
}
suppressPackageStartupMessages(library(survey, lib.loc = paths))

SEED <- 20261015L
N_DESIGNS <- 200L
out_path <- file.path("Tests", "AnthroAnalysisTests", "ClusterCIGolden.generated.swift")

set.seed(SEED)
designs <- character(0)
while (length(designs) < N_DESIGNS) {
  clusters <- sample(2:60, 1)
  sizes <- sample(3:25, clusters, replace = TRUE)
  p <- runif(1, 0.02, 0.6)
  weighted <- length(designs) %% 2L == 1L
  cluster <- rep(seq_len(clusters), sizes)
  y <- rbinom(length(cluster), 1, p)
  w <- if (weighted) round(runif(length(cluster), 0.5, 3), 2) else rep(1, length(cluster))
  estimate <- sum(w * y) / sum(w)
  # Proporções extremas não têm IC por cluster no original (`.unavailable`).
  if (estimate <= 0.00005 || estimate >= 0.99995) next
  data <- data.frame(cluster = cluster, y = y, w = w)
  design <- svydesign(ids = ~cluster, weights = ~w, data = data)
  ci <- confint(svyciprop(~y, design, method = "logit", df = degf(design))) * 100
  # Com poucos graus de liberdade a meia-largura no logit é grande e o `expit` do R estoura (NaN): sem oráculo.
  if (any(!is.finite(ci))) next
  records <- vapply(seq_len(clusters), function(c) {
    rows <- which(cluster == c)
    items <- if (weighted) sprintf("%d@%.2f", y[rows], w[rows]) else sprintf("%d", y[rows])
    paste(items, collapse = ",")
  }, character(1))
  designs <- c(designs, sprintf('        ("%s", %.6f, %.6f),', paste(records, collapse = ";"), ci[1], ci[2]))
}

header <- c(
  "// Gerado por scripts/golden/generate_cluster_ci_golden.R; não editar à mão.",
  sprintf("// %s, survey %s, semente %d, %d desenhos.", R.version.string,
          as.character(packageVersion("survey", lib.loc = paths)), SEED, N_DESIGNS),
  "",
  "/// Oráculo do IC por cluster (design D6): clusters separados por \";\", registros por \",\", cada registro \"1\" (caso)",
  "/// ou \"0\", com \"@fator\" nos desenhos ponderados; limites de `svyciprop(method = \"logit\", df = degf(design))` em",
  "/// percentual.",
  "enum ClusterCIGolden {",
  "    static let designs: [(records: String, low: Double, high: Double)] = ["
)
footer <- c("    ]", "}")
con <- file(out_path, open = "w", encoding = "UTF-8")
writeLines(c(header, designs, footer), con)
close(con)
cat(sprintf("%d desenhos gravados em %s\n", length(designs), out_path))
