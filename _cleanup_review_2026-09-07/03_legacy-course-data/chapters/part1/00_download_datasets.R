# ============================================================
# Advanced Bioinformatics — Dataset Download Script
# Run this BEFORE each week's class
# Estimated total storage: ~8 GB
# ============================================================

library(here)
library(tidyverse)

# Create project directory structure
dirs <- c(
  "data/raw/w2_gwas",
  "data/raw/w3_prs",
  "data/raw/w4_methylation",
  "data/raw/w5_atac",
  "data/raw/w6_16s",
  "data/raw/w8_scrna",
  "data/raw/w9_trajectory",
  "data/raw/w10_spatial",
  "data/raw/w11_multiomics",
  "data/raw/w12_network",
  "data/processed",
  "results/figures",
  "results/tables"
)

sapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE)
cat("✓ Directory structure created\n")

# ============================================================
# W1 — No data needed (environment setup only)
# ============================================================

# ============================================================
# W2 — GWAS: T2D Summary Statistics
# Size: ~500 MB | Time: 5–10 min
# ============================================================
download_w2 <- function() {
  cat("\n[W2] Downloading T2D GWAS summary statistics...\n")

  # DIAGRAM Consortium — T2D GWAS (Mahajan et al. 2022, Nature Genetics)
  # Full sumstats available at: https://diagram-consortium.org/downloads.html
  # For class: use the smaller practice dataset from IEU OpenGWAS

  if (!requireNamespace("ieugwasr", quietly = TRUE))
    install.packages("ieugwasr")

  library(ieugwasr)

  # T2D GWAS from IEU OpenGWAS (ieu-b-4760)
  # Download top hits only for demo
  t2d_tophits <- tophits("ieu-b-4760", pval = 1e-5)
  write_tsv(t2d_tophits,
            here("data", "raw", "w2_gwas", "t2d_tophits.tsv"))

  # Full chr22 for hands-on (manageable size)
  t2d_chr22 <- associations(
    variants = NULL,
    id       = "ieu-b-4760",
    proxies  = 0
  )
  write_tsv(t2d_chr22,
            here("data", "raw", "w2_gwas", "t2d_chr22.tsv"))

  cat("✓ W2 data downloaded\n")
}

# ============================================================
# W3 — PRS: CAD Summary Statistics + Reference Panel
# Size: ~300 MB | Time: 5–10 min
# ============================================================
download_w3 <- function() {
  cat("\n[W3] Downloading CAD GWAS for PRS...\n")

  library(ieugwasr)

  # CAD GWAS — CARDIoGRAMplusC4D (ieu-a-7)
  cad_hits <- tophits("ieu-a-7", pval = 5e-8)
  write_tsv(cad_hits,
            here("data", "raw", "w3_prs", "cad_gwas_hits.tsv"))

  # LD reference panel — download pre-computed from bigsnpr
  if (!requireNamespace("bigsnpr", quietly = TRUE))
    install.packages("bigsnpr")
  library(bigsnpr)

  # Download 1000G EUR LD reference (bigsnpr format)
  # ~2 GB — download once, reuse for W2 and W3
  download_1000G(
    dir = here("data", "raw", "w3_prs"),
    population = "EUR",
    type = "hm3+"
  )

  cat("✓ W3 data downloaded\n")
}

# ============================================================
# W4 — DNA Methylation: GEO GSE48684 (CRC 450K)
# Size: ~400 MB | Time: 5–15 min
# ============================================================
download_w4 <- function() {
  cat("\n[W4] Downloading methylation data from GEO (GSE48684)...\n")

  if (!requireNamespace("GEOquery", quietly = TRUE))
    BiocManager::install("GEOquery")
  library(GEOquery)

  # Download pre-processed beta values (not raw IDAT — too large)
  gse <- getGEO("GSE48684",
                GSEMatrix  = TRUE,
                AnnotGPL   = FALSE,
                destdir    = here("data", "raw", "w4_methylation"))

  # Save as RDS for fast loading in class
  beta <- exprs(gse[[1]])
  pheno <- pData(gse[[1]])

  saveRDS(beta,  here("data", "raw", "w4_methylation", "beta_matrix.rds"))
  saveRDS(pheno, here("data", "raw", "w4_methylation", "pheno.rds"))

  cat("✓ W4 data downloaded:", nrow(beta), "probes ×", ncol(beta), "samples\n")
}

# ============================================================
# W5 — ATAC-seq: ENCODE Heart (pre-processed peaks)
# Size: ~50 MB | Time: 2–3 min
# ============================================================
download_w5 <- function() {
  cat("\n[W5] Downloading ATAC-seq peak files (ENCODE heart)...\n")

  # ENCODE — Heart left ventricle ATAC-seq peaks (hg38)
  # ENCFF073FDM — narrowPeak file
  urls <- list(
    lv_peaks = "https://www.encodeproject.org/files/ENCFF073FDM/@@download/ENCFF073FDM.bed.gz",
    rv_peaks = "https://www.encodeproject.org/files/ENCFF203JGM/@@download/ENCFF203JGM.bed.gz"
  )

  for (name in names(urls)) {
    dest <- here("data", "raw", "w5_atac", paste0(name, ".bed.gz"))
    if (!file.exists(dest)) {
      download.file(urls[[name]], dest, mode = "wb")
      cat("  ✓ Downloaded:", name, "\n")
    } else {
      cat("  ✓ Already exists:", name, "\n")
    }
  }

  cat("✓ W5 data downloaded\n")
}

# ============================================================
# W6 — 16S rRNA-seq: HMP2 IBD (phyloseq object)
# Size: ~30 MB | Time: 2 min
# ============================================================
download_w6 <- function() {
  cat("\n[W6] Downloading HMP2 IBD microbiome data...\n")

  if (!requireNamespace("microbiomeMarker", quietly = TRUE))
    BiocManager::install("microbiomeMarker")

  # HMP2 IBD 16S dataset — via MicrobiomeDB or direct download
  # Using curatedMetagenomicData 16S subset
  url <- paste0(
    "https://raw.githubusercontent.com/waldronlab/",
    "curatedMetagenomicDataAnalyses/main/inst/",
    "HMP_2019_ibdmdb_16S_phyloseq.rds"
  )

  dest <- here("data", "raw", "w6_16s", "hmp2_ibd_phyloseq.rds")

  if (!file.exists(dest)) {
    tryCatch({
      download.file(url, dest, mode = "wb")
      cat("✓ W6 data downloaded\n")
    }, error = function(e) {
      # Fallback: build from microbiome package built-in data
      if (!requireNamespace("microbiome", quietly = TRUE))
        BiocManager::install("microbiome")
      library(microbiome)
      data(dietswap)
      saveRDS(dietswap, dest)
      cat("✓ W6 fallback dataset (dietswap) saved\n")
    })
  } else {
    cat("✓ W6 already exists\n")
  }
}

# ============================================================
# W7 — WMS: CRC Metagenome (curatedMetagenomicData)
# Size: ~20 MB in R | Time: 3–5 min
# ============================================================
download_w7 <- function() {
  cat("\n[W7] Downloading CRC WMS data (curatedMetagenomicData)...\n")

  if (!requireNamespace("curatedMetagenomicData", quietly = TRUE))
    BiocManager::install("curatedMetagenomicData")
  library(curatedMetagenomicData)

  # Zeller 2014 — CRC vs healthy (German cohort)
  crc_taxa <- curatedMetagenomicData(
    "ZellerG_2014.relative_abundance",
    dryrun = FALSE
  )

  saveRDS(crc_taxa[[1]],
          here("data", "raw", "w7_wms", "zeller_crc_taxa.rds"))

  # Yu 2015 — Chinese CRC cohort (for comparison)
  yu_taxa <- curatedMetagenomicData(
    "YuJ_2015.relative_abundance",
    dryrun = FALSE
  )

  saveRDS(yu_taxa[[1]],
          here("data", "raw", "w7_wms", "yu_crc_taxa.rds"))

  cat("✓ W7 data downloaded\n")
}

# ============================================================
# W8 — scRNA-seq: PBMC 3k (SeuratData)
# Size: ~30 MB | Time: 2 min
# ============================================================
download_w8 <- function() {
  cat("\n[W8] Downloading PBMC 3k dataset...\n")

  if (!requireNamespace("SeuratData", quietly = TRUE)) {
    remotes::install_github("satijalab/seurat-data")
  }
  library(SeuratData)

  InstallData("pbmc3k")
  data("pbmc3k")

  # Pre-process and save so class starts from annotated object
  library(Seurat)

  pbmc3k[["percent.mt"]] <- PercentageFeatureSet(pbmc3k, pattern = "^MT-")
  pbmc3k <- subset(pbmc3k,
                   nFeature_RNA > 200 &
                   nFeature_RNA < 2500 &
                   percent.mt   < 5)
  pbmc3k <- NormalizeData(pbmc3k, verbose = FALSE) |>
    FindVariableFeatures(verbose = FALSE) |>
    ScaleData(verbose = FALSE) |>
    RunPCA(verbose = FALSE) |>
    FindNeighbors(dims = 1:10, verbose = FALSE) |>
    FindClusters(resolution = 0.5, verbose = FALSE) |>
    RunUMAP(dims = 1:10, verbose = FALSE)

  # Annotate clusters (standard PBMC annotation)
  cell_type_map <- c(
    "0" = "CD4 T", "1" = "CD14 Mono", "2" = "CD4 T",
    "3" = "B cell", "4" = "CD8 T", "5" = "FCGR3A Mono",
    "6" = "NK", "7" = "DC", "8" = "Platelet"
  )
  pbmc3k$cell_type <- recode(as.character(pbmc3k$seurat_clusters),
                              !!!cell_type_map)

  saveRDS(pbmc3k,
          here("data", "processed", "pbmc_annotated.rds"))

  cat("✓ W8 data downloaded and pre-processed\n")
}

# ============================================================
# W9 — Trajectory: Hematopoiesis (scRNAseq package)
# Size: ~50 MB | Time: 2 min
# ============================================================
download_w9 <- function() {
  cat("\n[W9] Downloading hematopoiesis dataset...\n")

  if (!requireNamespace("scRNAseq", quietly = TRUE))
    BiocManager::install("scRNAseq")
  library(scRNAseq)

  # Paul et al. 2015 — mouse hematopoiesis
  sce <- PaulHSCData(ensembl = FALSE)

  saveRDS(sce,
          here("data", "raw", "w9_trajectory", "hsc_sce.rds"))

  cat("✓ W9 data downloaded\n")
}

# ============================================================
# W10 — Spatial: Human Breast Cancer Visium (10x Genomics)
# Size: ~2 GB | Time: 15–30 min
# ⚠ Largest download — do this at home on good internet
# ============================================================
download_w10 <- function() {
  cat("\n[W10] Downloading Visium breast cancer data...\n")
  cat("⚠ This is ~2 GB. Run at home or on fast internet.\n")

  out_dir <- here("data", "raw", "w10_spatial")

  # 10x Genomics — Human Breast Cancer Block A Section 1
  base_url <- paste0(
    "https://cf.10xgenomics.com/samples/spatial-exp/",
    "1.1.0/V1_Breast_Cancer_Block_A_Section_1/"
  )

  files <- list(
    filtered_matrix = "V1_Breast_Cancer_Block_A_Section_1_filtered_feature_bc_matrix.h5",
    spatial_dir     = "V1_Breast_Cancer_Block_A_Section_1_spatial.tar.gz"
  )

  for (name in names(files)) {
    fname <- files[[name]]
    dest  <- file.path(out_dir, fname)
    if (!file.exists(dest)) {
      download.file(paste0(base_url, fname), dest, mode = "wb")
      if (grepl(".tar.gz$", fname)) untar(dest, exdir = out_dir)
      cat("  ✓ Downloaded:", name, "\n")
    } else {
      cat("  ✓ Already exists:", name, "\n")
    }
  }

  cat("✓ W10 data downloaded\n")
}

# ============================================================
# W11 — Multi-omics: TCGA BRCA (RNA + methylation)
# Size: ~1 GB | Time: 10–20 min
# ============================================================
download_w11 <- function() {
  cat("\n[W11] Downloading TCGA BRCA multi-omics...\n")

  if (!requireNamespace("TCGAbiolinks", quietly = TRUE))
    BiocManager::install("TCGAbiolinks")
  library(TCGAbiolinks)

  # RNA-seq — STAR counts
  query_rna <- GDCquery(
    project           = "TCGA-BRCA",
    data.category     = "Transcriptome Profiling",
    data.type         = "Gene Expression Quantification",
    workflow.type     = "STAR - Counts",
    sample.type       = c("Primary Tumor", "Solid Tissue Normal"),
    barcode           = NULL   # all samples — subset later
  )

  # Limit to 100 samples for class (50 tumor + 50 normal)
  query_rna$results[[1]] <- query_rna$results[[1]] |>
    group_by(sample_type) |>
    slice_sample(n = 50) |>
    ungroup()

  GDCdownload(query_rna,
              directory = here("data", "raw", "w11_multiomics"),
              method    = "api")

  rna_se <- GDCprepare(query_rna,
                        directory = here("data", "raw", "w11_multiomics"))

  saveRDS(rna_se,
          here("data", "raw", "w11_multiomics", "brca_rna_se.rds"))

  cat("✓ W11 RNA-seq downloaded\n")

  # Methylation — 450K
  query_meth <- GDCquery(
    project       = "TCGA-BRCA",
    data.category = "DNA Methylation",
    platform      = "Illumina Human Methylation 450",
    barcode       = colData(rna_se)$patient   # matched samples
  )

  GDCdownload(query_meth,
              directory = here("data", "raw", "w11_multiomics"),
              method    = "api")

  meth_se <- GDCprepare(query_meth,
                         directory = here("data", "raw", "w11_multiomics"))

  saveRDS(meth_se,
          here("data", "raw", "w11_multiomics", "brca_meth_se.rds"))

  cat("✓ W11 Methylation downloaded\n")
}

# ============================================================
# W12 — Network: STRINGdb (auto-downloads on first use)
# Size: ~500 MB | Time: auto
# ============================================================
download_w12 <- function() {
  cat("\n[W12] Initializing STRINGdb (downloads on first use)...\n")

  if (!requireNamespace("STRINGdb", quietly = TRUE))
    BiocManager::install("STRINGdb")
  library(STRINGdb)

  # This triggers the database download (~500 MB)
  string_db <- STRINGdb$new(
    version         = "11.5",
    species         = 9606,
    score_threshold = 400,
    network_type    = "full",
    input_directory = here("data", "raw", "w12_network")
  )

  # Test with AD genes
  test_genes <- data.frame(gene = c("APOE", "BIN1", "CLU", "APP"))
  string_db$map(test_genes, "gene", removeUnmappedRows = TRUE)

  cat("✓ W12 STRINGdb initialized\n")
}

# ============================================================
# RUN — choose which weeks to download
# ============================================================

cat("
========================================
  Advanced Bioinformatics Data Downloader
========================================
Which weeks do you want to download?
")

# Quick downloads (< 100 MB each) — run all at once
run_quick <- function() {
  download_w2()
  download_w3()
  download_w6()
  download_w7()
  download_w8()
  download_w9()
  download_w12()
}

# Large downloads — run individually, preferably at home
# download_w4()   # ~400 MB
# download_w5()   # ~50 MB
# download_w10()  # ~2 GB ⚠
# download_w11()  # ~1 GB ⚠

# Run the quick ones now:
# run_quick()

# Or run individual weeks:
# download_w2()

cat("
→ Uncomment the function calls above and run.
→ For W10 and W11, download at home (large files).
→ After downloading, run renv::snapshot() to lock your environment.
")
