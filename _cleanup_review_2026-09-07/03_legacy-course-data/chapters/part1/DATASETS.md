# Advanced Bioinformatics — Dataset Reference Guide

> **개인 노트북 기준** | 총 용량 약 8 GB | 미리 다운로드 권장

---

## 요약표

| 주차 | 데이터셋 | 크기 | 다운로드 방법 | 비고 |
|------|---------|------|------------|------|
| W1 | 없음 | — | — | 환경세팅만 |
| W2 | T2D GWAS summary stats | ~50 MB | R 스크립트 자동 | ieugwasr |
| W3 | CAD GWAS + 1000G LD panel | ~300 MB | R 스크립트 자동 | bigsnpr |
| W4 | GSE48684 (CRC 450K methylation) | ~400 MB | R 스크립트 자동 | GEOquery |
| W5 | ENCODE heart ATAC-seq peaks | ~50 MB | R 스크립트 자동 | ENCODE portal |
| W6 | HMP2 IBD 16S | ~30 MB | R 스크립트 자동 | phyloseq |
| W7 | Zeller 2014 CRC WMS | ~20 MB | R 스크립트 자동 | curatedMetagenomicData |
| W8 | PBMC 3k | ~30 MB | R 스크립트 자동 | SeuratData |
| W9 | Paul 2015 hematopoiesis | ~50 MB | R 스크립트 자동 | scRNAseq |
| W10 | Breast cancer Visium | **~2 GB** | 수동 다운로드 ⚠ | 10x Genomics |
| W11 | TCGA BRCA (RNA + methylation) | **~1 GB** | R 스크립트 (느림) ⚠ | TCGAbiolinks |
| W12 | STRINGdb human PPI | ~500 MB | 첫 실행 시 자동 | STRINGdb |

---

## 주차별 상세

---

### W2 — GWAS: T2D Summary Statistics

**데이터:** DIAGRAM Consortium T2D GWAS (Mahajan et al. 2022, *Nature Genetics*)  
**논문:** https://doi.org/10.1038/s41588-022-01058-3  
**다운로드 (수동):** https://diagram-consortium.org/downloads.html

**수업용 (작은 버전):**
```r
library(ieugwasr)
tophits("ieu-b-4760", pval = 1e-5)   # T2D top hits
```

**필요 패키지:**
```r
install.packages("ieugwasr")
install.packages("qqman")
BiocManager::install("biomaRt")
```

---

### W3 — PRS: CAD Summary Statistics

**데이터:** CARDIoGRAMplusC4D CAD GWAS  
**논문:** Khera et al. 2018, *Nature Genetics* — https://doi.org/10.1038/s41588-018-0183-z  
**IEU OpenGWAS:** https://gwas.mrcieu.ac.uk/datasets/ieu-a-7/

**1000G LD 참조 패널:**
```r
library(bigsnpr)
download_1000G(dir = "data/raw/w3_prs", population = "EUR")
# ~300 MB, 한 번만 다운로드
```

**PRSice2 (별도 설치 필요):**  
https://www.prsice.info/step_by_step/  
→ Windows/Mac/Linux 바이너리 제공

**필요 패키지:**
```r
install.packages(c("bigsnpr", "bigstatsr"))
install.packages(c("pROC", "DescTools"))
```

---

### W4 — DNA Methylation: GSE48684

**데이터:** CRC vs. normal colon (450K array, n=147)  
**논문:** Hinoue et al. 2012, *Genome Research*  
**GEO:** https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE48684

**자동 다운로드:**
```r
library(GEOquery)
getGEO("GSE48684", GSEMatrix = TRUE)
# ~400 MB, 처음 한 번만
```

**필요 패키지:**
```r
BiocManager::install(c(
  "minfi", "ChAMP", "DMRcate",
  "IlluminaHumanMethylation450kanno.ilmn12.hg19",
  "missMethyl", "methylclock", "GEOquery"
))
```

> ⚠ **Raw IDAT 파일은 수업에서 사용하지 않음** (샘플당 ~8 MB × 147 = 1 GB 이상)  
> GEOMatrix(전처리 완료)만 사용

---

### W5 — ATAC-seq: ENCODE Heart

**데이터:** Human heart left/right ventricle ATAC-seq (GRCh38)  
**ENCODE portal:** https://www.encodeproject.org

| 파일 | ENCODE ID | 설명 |
|------|-----------|------|
| LV peaks | ENCFF073FDM | Left ventricle narrowPeak |
| RV peaks | ENCFF203JGM | Right ventricle narrowPeak |
| LV signal | ENCFF832AWF | bigWig (fold change) |

**직접 다운로드:**
```bash
# ENCODE 파일 직접 다운로드
curl -O -J -L https://www.encodeproject.org/files/ENCFF073FDM/@@download/ENCFF073FDM.bed.gz
```

**필요 패키지:**
```r
BiocManager::install(c(
  "ArchR", "chromVAR", "motifmatchr",
  "BSgenome.Hsapiens.UCSC.hg38",
  "JASPAR2020", "TFBSTools"
))
install.packages("strawr")   # Hi-C .hic 파일
```

> ⚠ **ArchR 설치는 시간이 걸림** — 수업 전날 미리 설치

---

### W6 — 16S: HMP2 IBD

**데이터:** Human Microbiome Project 2 — IBD cohort 16S  
**공식 사이트:** https://ibdmdb.org  
**논문:** Franzosa et al. 2019, *Nature Microbiology*

**수업용 (phyloseq 객체):**
```r
# 옵션 1: curatedMetagenomicData 내장
library(microbiome)
data(atlas1006)   # 대규모 장내 미생물 데이터셋

# 옵션 2: MicrobiomeDB 직접 다운로드
# https://microbiomedb.org/mbio/app/downloads
```

**필요 패키지:**
```r
BiocManager::install(c("dada2", "phyloseq",
                       "microbiome", "DESeq2"))
install.packages(c("vegan", "ggpubr", "rstatix"))
```

---

### W7 — WMS: Zeller 2014 CRC

**데이터:** German CRC cohort — shotgun metagenomics  
**논문:** Zeller et al. 2014, *Molecular Systems Biology*  
**curatedMetagenomicData:**

```r
library(curatedMetagenomicData)

# 자동 다운로드 — R 안에서 처리
crc <- curatedMetagenomicData("ZellerG_2014.relative_abundance",
                               dryrun = FALSE)
```

**필요 패키지:**
```r
BiocManager::install("curatedMetagenomicData")
install.packages(c("MicrobiomeStat", "ggpicrust2"))
if (!requireNamespace("Maaslin2"))
  BiocManager::install("Maaslin2")
```

---

### W8 — scRNA-seq: PBMC 3k

**데이터:** 10x Genomics PBMC 3,000 cells  
**원본:** https://www.10xgenomics.com/datasets/3-k-pbm-cs-from-a-healthy-donor-1-standard-1-1-0

**가장 쉬운 방법 (SeuratData):**
```r
remotes::install_github("satijalab/seurat-data")
library(SeuratData)
InstallData("pbmc3k")
```

**필요 패키지:**
```r
install.packages("Seurat")
BiocManager::install(c("SingleR", "celldex",
                       "scran", "scater", "DoubletFinder"))
```

> ✅ **가장 쉬운 주차** — SeuratData가 자동으로 처리

---

### W9 — Trajectory: Paul 2015 Hematopoiesis

**데이터:** Mouse hematopoietic stem cells → differentiation  
**논문:** Paul et al. 2015, *Cell*

```r
BiocManager::install("scRNAseq")
library(scRNAseq)
sce <- PaulHSCData(ensembl = FALSE)
```

**필요 패키지:**
```r
BiocManager::install("monocle3")   # 별도 설치 절차 있음
# Monocle3 설치:
# install.packages("BiocManager")
# BiocManager::install(c("BiocGenerics", "DelayedArray",
#   "DelayedMatrixStats", "limma", "lme4", "S4Vectors",
#   "SingleCellExperiment", "SummarizedExperiment",
#   "batchelor", "HDF5Array"))
# remotes::install_github("cole-trapnell-lab/monocle3")

install.packages(c("harmony", "SeuratWrappers"))
```

---

### W10 — Spatial: Visium Breast Cancer ⚠ 대용량

**데이터:** Human Breast Cancer Block A Section 1 (10x Genomics)  
**크기:** ~2 GB  
**다운로드:** https://www.10xgenomics.com/datasets/human-breast-cancer-block-a-section-1-1-standard-1-1-0

**다운로드할 파일:**
| 파일 | 크기 |
|------|------|
| `filtered_feature_bc_matrix.h5` | ~100 MB |
| `spatial.tar.gz` (H&E image + positions) | ~1.8 GB |

```bash
# 명령줄에서 다운로드 (터미널)
wget https://cf.10xgenomics.com/samples/spatial-exp/1.1.0/\
V1_Breast_Cancer_Block_A_Section_1/\
V1_Breast_Cancer_Block_A_Section_1_filtered_feature_bc_matrix.h5

wget https://cf.10xgenomics.com/samples/spatial-exp/1.1.0/\
V1_Breast_Cancer_Block_A_Section_1/\
V1_Breast_Cancer_Block_A_Section_1_spatial.tar.gz
```

**필요 패키지:**
```r
install.packages("Seurat")
BiocManager::install(c("NNSVG", "STdeconvolve", "SpatialDE"))
install.packages("ggplot2")
```

> ⚠ **집에서 미리 다운로드** — 수업 당일 다운로드하면 시간 부족  
> H&E 이미지 때문에 파일이 큼

---

### W11 — Multi-omics: TCGA BRCA ⚠ 대용량

**데이터:** TCGA Breast Cancer — RNA-seq + DNA methylation  
**크기:** ~1 GB (100 샘플 기준)  
**공식 포털:** https://portal.gdc.cancer.gov

**TCGAbiolinks 방법 (권장):**
```r
BiocManager::install("TCGAbiolinks")
library(TCGAbiolinks)

# 회원가입 불필요, 공개 데이터
query <- GDCquery(
  project       = "TCGA-BRCA",
  data.category = "Transcriptome Profiling",
  data.type     = "Gene Expression Quantification",
  workflow.type = "STAR - Counts"
)
GDCdownload(query)
```

**대안 (더 빠름):** UCSC Xena  
https://xenabrowser.net/datapages/?cohort=TCGA%20Breast%20Cancer%20(BRCA)

```r
# Xena 방법 — 사전 처리된 매트릭스 직접 다운로드
url <- paste0(
  "https://tcga-xena-hub.s3.us-east-1.amazonaws.com/download/",
  "TCGA.BRCA.sampleMap%2FHiSeqV2_PANCAN.gz"
)
download.file(url, "data/raw/w11_multiomics/brca_rna_xena.gz")
```

**필요 패키지:**
```r
BiocManager::install(c("MOFA2", "mixOmics", "TCGAbiolinks"))
install.packages("OmicsPLS")
```

---

### W12 — Network: STRINGdb

**데이터:** STRING v11.5 human PPI (~500 MB, 첫 실행 시 자동 다운로드)  
**사이트:** https://string-db.org

```r
library(STRINGdb)
# 처음 실행 시 자동 다운로드
string_db <- STRINGdb$new(version = "11.5",
                           species = 9606,
                           score_threshold = 400)
```

**iLINCS (CMAP/L1000 — 웹 기반, 설치 불필요):**  
http://www.ilincs.org  
→ Disease signature 입력 → drug connectivity scores 반환

**필요 패키지:**
```r
BiocManager::install("STRINGdb")
install.packages(c("igraph", "ggraph", "tidygraph"))
install.packages("TwoSampleMR",
  repos = c("https://mrcieu.r-universe.dev", getOption("repos")))
```

---

## 용량 정리 & 다운로드 순서 추천

```
수업 전날 밤 (집에서):
  1. W10 Visium          ~2 GB  ← 제일 먼저
  2. W11 TCGA            ~1 GB
  3. W3  1000G LD panel  ~300 MB

당일 아침 (수업 전):
  4. W4  GSE48684        ~400 MB
  5. W12 STRINGdb        ~500 MB (첫 실행 시)

빠름 (언제든지):
  6. W2  GWAS hits       ~50 MB
  7. W6  HMP2 16S        ~30 MB
  8. W7  CRC WMS         ~20 MB
  9. W8  PBMC3k          ~30 MB
  10. W9 Hematopoiesis   ~50 MB
```

---

## 패키지 한꺼번에 설치

수업 시작 전 한 번에 설치:

```r
# CRAN 패키지
install.packages(c(
  "tidyverse", "here", "renv", "remotes",
  "ggplot2", "patchwork", "ggrepel", "ggpubr",
  "rstatix", "DescTools", "pROC",
  "igraph", "ggraph", "tidygraph",
  "vegan", "pheatmap",
  "ieugwasr", "bigsnpr", "bigstatsr",
  "MicrobiomeStat", "ggpicrust2",
  "harmony", "OmicsPLS", "strawr"
))

# Bioconductor 패키지 (시간 오래 걸림 — 30분 예상)
BiocManager::install(c(
  # Genomics
  "biomaRt", "GenomicRanges", "plyranges",
  # Epigenomics
  "minfi", "ChAMP", "DMRcate", "missMethyl",
  "IlluminaHumanMethylation450kanno.ilmn12.hg19",
  "IlluminaHumanMethylationEPICanno.ilm10b4.hg19",
  "methylclock", "GEOquery",
  # ATAC
  "chromVAR", "motifmatchr",
  "JASPAR2020", "TFBSTools",
  "BSgenome.Hsapiens.UCSC.hg38",
  # Microbiome
  "dada2", "phyloseq", "microbiome",
  "curatedMetagenomicData", "Maaslin2",
  # scRNA-seq
  "SingleR", "celldex", "scran", "scater",
  "scRNAseq",
  # Spatial
  "NNSVG", "STdeconvolve",
  # Multi-omics
  "MOFA2", "mixOmics", "TCGAbiolinks",
  # Utilities
  "STRINGdb", "DESeq2", "limma", "edgeR",
  "fgsea", "clusterProfiler", "org.Hs.eg.db",
  "ComplexHeatmap", "circlize"
))

# GitHub 패키지
remotes::install_github("satijalab/seurat-data")
remotes::install_github("cole-trapnell-lab/monocle3")
remotes::install_github("sqjin/CellChat")

# TwoSampleMR (Mendelian Randomization)
install.packages("TwoSampleMR",
  repos = c("https://mrcieu.r-universe.dev", getOption("repos")))

# Seurat (마지막에)
install.packages("Seurat")
```

---

## 트러블슈팅

**Q: BiocManager::install()이 중간에 멈춥니다**  
A: `options(Ncpus = 4)` 설정 후 재시도. 또는 패키지를 5개씩 나눠서 설치.

**Q: ArchR 설치가 안 됩니다**  
A: `remotes::install_github("GreenleafLab/ArchR", ref="master")` 시도. 또는 W5 수업 때 강사 버전 사용.

**Q: Monocle3 설치 오류**  
A: 의존성 먼저 설치 후 재시도:
```r
BiocManager::install(c("BiocGenerics", "DelayedArray",
  "DelayedMatrixStats", "limma", "S4Vectors",
  "SingleCellExperiment", "SummarizedExperiment"))
remotes::install_github("cole-trapnell-lab/monocle3")
```

**Q: W10 Visium 파일이 너무 큽니다**  
A: `filtered_feature_bc_matrix.h5`만 먼저 다운로드하고 공간 이미지(`spatial.tar.gz`)는 나중에.

**Q: TCGA 다운로드가 너무 느립니다**  
A: UCSC Xena 방법으로 대체 (위 W11 항목 참조).
