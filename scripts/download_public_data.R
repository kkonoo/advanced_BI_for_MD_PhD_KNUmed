# ============================================================
# download_public_data.R
# 공개 데이터를 받아 실습용으로 정리한다.
#
# 시뮬레이션이 아니라 진짜 데이터가 훨씬 나은 것들만 여기에 있다.
#   · GWAS 요약통계 — 진짜 LD 구조, 진짜 TCF7L2 신호를 봐야 의미가 있다
#   · PubMed 논문 수 — 연구 편향은 실제 숫자로 봐야 설득력이 있다
#
# 의존성 없음 — base R 만으로 동작한다. 네트워크가 필요하다.
#
# Out : rawdata/t2d_gwas_summary.tsv   W3
#       rawdata/pubmed_counts.rds      W12
# ============================================================

dir.create("rawdata", showWarnings = FALSE)

# ────────────────────────────────────────────────────────────
# ① GWAS 요약통계  (W3)
#
# ⚠️ 자동 다운로드로 만들지 않았다. 어떤 연구를 쓸지가 수업 내용의
#    일부이기 때문이다 — 표본수와 조상(ancestry)을 직접 보고 고르는 것이
#    W3 §7.1 실습이다.
#
# 받는 법:
#   1. https://www.ebi.ac.uk/gwas/  에서 질환 검색 (예: type 2 diabetes)
#   2. Studies 탭 → "Summary statistics" 아이콘이 있는 연구를 고른다
#      · 표본수가 큰 것
#      · ⚠️ 조상을 확인할 것. 동아시아인 연구가 있으면 그것도 같이 받아
#        두 개를 비교하면 W3 §6 이 훨씬 생생해진다
#   3. FTP 링크를 복사해 아래 url 에 붙인다
#      (harmonised/ 폴더 안 *.h.tsv.gz 가 컬럼이 정리되어 있어 편하다)
# ────────────────────────────────────────────────────────────

url <- ""   # <- 여기에 붙여넣기

# 연구 전체 표본수 — 파일에 변이별 n 컬럼이 없을 때만 쓴다.
#   GWAS Catalog harmonised 파일은 대개 n 이 없다. 비워 두면 N 이 전부 NA 라
#   W3 §7.4 의 λ₁₀₀₀ 도 NA 가 된다.
#   연구 페이지의 "Initial sample size" 에서 환자 + 대조군을 더해 넣는다.
#   예) GCST010118 (Spracklen 2020, 동아시아인 T2D): 77,418 + 356,122 = 433540
n_total <- NA   # <- 예: 433540

# 몇 개 중 하나를 무작위로 남길지. 1 이면 솎지 않는다
# (GCST010118 기준 약 1,100만 변이, TSV 약 700 MB).
thin <- 10

if (nzchar(url)) {
  gz <- file.path(tempdir(), basename(url))
  cat("다운로드 중... 수백 MB 일 수 있습니다.\n")
  download.file(url, gz, mode = "wb")

  cat("읽는 중...\n")
  raw <- read.delim(gzfile(gz), stringsAsFactors = FALSE, check.names = FALSE)
  cat("원본 컬럼:", paste(names(raw), collapse = ", "), "\n")

  # ── 컬럼 이름 표준화 ──────────────────────────────────────
  # 연구마다 컬럼 이름이 제각각이라 책에서 쓰는 이름으로 맞춰준다.
  pick <- function(df, ...) {
    for (nm in c(...)) if (nm %in% names(df)) return(df[[nm]])
    rep(NA, nrow(df))
  }
  gwas <- data.frame(
    SNP  = pick(raw, "hm_rsid", "rsid", "variant_id", "SNP"),
    CHR  = pick(raw, "hm_chrom", "chromosome", "chr", "CHR"),
    BP   = pick(raw, "hm_pos", "base_pair_location", "pos", "BP"),
    A1   = pick(raw, "hm_effect_allele", "effect_allele", "A1"),
    A2   = pick(raw, "hm_other_allele", "other_allele", "A2"),
    FREQ = pick(raw, "hm_effect_allele_frequency", "effect_allele_frequency", "FREQ"),
    BETA = pick(raw, "hm_beta", "beta", "BETA"),
    SE   = pick(raw, "standard_error", "se", "SE"),
    P    = pick(raw, "p_value", "pval", "P"),
    N    = pick(raw, "n", "N"),
    stringsAsFactors = FALSE
  )

  gwas <- gwas[!is.na(gwas$P) & !is.na(gwas$CHR) & !is.na(gwas$BP), ]
  gwas$CHR <- suppressWarnings(as.integer(sub("^chr", "", gwas$CHR)))
  gwas <- gwas[!is.na(gwas$CHR) & gwas$CHR %in% 1:22, ]

  # ── 표본수 ────────────────────────────────────────────────
  if (all(is.na(gwas$N))) {
    if (is.na(n_total)) {
      cat("⚠️ 파일에 n 컬럼이 없습니다. 위 n_total 을 채우지 않으면",
          "W3 §7.4 의 λ₁₀₀₀ 이 NA 가 됩니다.\n")
    } else {
      gwas$N <- n_total
      cat("n 컬럼이 없어 연구 전체 표본수", n_total, "을 N 에 넣었습니다.\n")
    }
  }

  # ⚠️ 전체를 그대로 두면 천만 행이 넘어 수업 중에 느리다. 그래서 솎아내는데,
  #    p 값을 보고 고르면 안 된다. 예전처럼 "P < 0.01 은 전부 + 나머지는 12 개 중
  #    1 개" 를 남기면 작은 p 값만 12 배 부풀려져 χ² 중앙값이 올라간다 —
  #    GCST010118 에서 λ 가 1.30 → 3.37 이 되었다. 무작위로 솎되 유의한 변이
  #    (P < 5e-8) 만 따로 다 남겨도 같은 이유로 1.30 → 1.36 이 된다.
  #    p 값과 상관없이 무작위로 고르면 분포가 그대로라 λ 와 QQ 그림이 변하지 않는다.
  #    유의한 변이도 같은 비율로 줄지만, 좌위마다 LD 로 묶인 변이가 수십~수백 개라
  #    Manhattan 의 봉우리는 그대로 보인다. 선두 변이(lead SNP)까지 보려면 thin <- 1.
  if (thin > 1) {
    set.seed(1)
    gwas <- gwas[sort(sample.int(nrow(gwas), ceiling(nrow(gwas) / thin))), ]
  }

  write.table(gwas, "rawdata/t2d_gwas_summary.tsv",
              sep = "\t", quote = FALSE, row.names = FALSE)
  cat("[W3] t2d_gwas_summary.tsv —", nrow(gwas), "변이",
      if (thin > 1) paste0("(", thin, " 개 중 1 개 무작위)"), "—",
      sum(gwas$P < 5e-8), "개가 유전체 수준 유의\n")
} else {
  cat("[W3] url 이 비어 있어 건너뜁니다. 위 주석의 안내를 따르세요.\n")
}

# ────────────────────────────────────────────────────────────
# ② PubMed 논문 수  (W12)
#
# 네트워크 허브가 정말 "핵심 조절자"인지, 아니면 그냥 논문이 많은
# 유전자인지 확인하는 데 쓴다. 진짜 숫자여야 의미가 있다.
#
# ⚠️ API 키 없이는 초당 3회 제한이라 유전자 300개에 약 2분 걸린다.
#    키가 있으면 아래 api_key 에 넣고 sleep 을 0.11 로 줄여도 된다.
# ────────────────────────────────────────────────────────────

api_key <- ""    # https://www.ncbi.nlm.nih.gov/account/  에서 무료 발급

pubmed_count <- function(gene) {
  q <- sprintf(
    "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=%s[Title/Abstract]&rettype=count&retmode=json%s",
    utils::URLencode(gene), if (nzchar(api_key)) paste0("&api_key=", api_key) else "")
  out <- tryCatch(readLines(q, warn = FALSE), error = function(e) NA_character_)
  if (all(is.na(out))) return(NA_integer_)
  m <- regmatches(paste(out, collapse = ""),
                  regexpr('"count":"[0-9]+"', paste(out, collapse = "")))
  if (!length(m)) return(NA_integer_)
  as.integer(gsub('\\D', "", m))
}

# 여러분의 네트워크에 들어 있는 유전자로 바꾸세요.
# 아래는 W12 실습에서 쓰기 좋은 기본 목록입니다.
genes <- c(
  # 논문이 아주 많은 유전자 — 거의 모든 네트워크에서 허브로 나온다
  "TP53","EGFR","AKT1","TNF","IL6","MYC","VEGFA","STAT3","MTOR","CTNNB1",
  # 중간
  "IL6R","PCSK9","TCF7L2","PPARG","SCN5A","IL23R","RANKL","HMGCR","ESR1","DRD2",
  # 논문이 적은 유전자 — degree 가 낮게 나올 수밖에 없다
  "TMEM175","FAM210B","CCDC91","ZNF385D","RNF130","TTC39B","ANKRD55","SPPL3",
  "CCDC92","MAP3K11","TMEM258","RASIP1"
)

cat("\n[W12] PubMed 조회 중 —", length(genes), "유전자, 약",
    round(length(genes) * 0.35 / 60, 1), "분\n")

counts <- setNames(integer(length(genes)), genes)
for (i in seq_along(genes)) {
  counts[i] <- pubmed_count(genes[i])
  Sys.sleep(if (nzchar(api_key)) 0.11 else 0.35)
  if (i %% 10 == 0) cat("  ", i, "/", length(genes), "\n")
}

saveRDS(counts, "rawdata/pubmed_counts.rds")
cat("[W12] pubmed_counts.rds — 중앙값", median(counts, na.rm = TRUE),
    "편, 최대", max(counts, na.rm = TRUE), "편 (", names(which.max(counts)), ")\n")
cat("\n완료.\n")
