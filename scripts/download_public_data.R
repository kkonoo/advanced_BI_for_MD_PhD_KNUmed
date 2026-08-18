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

  # ⚠️ 전체를 그대로 두면 수백만 행이라 수업 중에 느리다.
  #    유의하지 않은 변이만 솎아낸다 — 신호는 하나도 잃지 않는다.
  keep <- gwas$P < 0.01 | seq_len(nrow(gwas)) %% 12 == 0
  gwas <- gwas[keep, ]

  write.table(gwas, "rawdata/t2d_gwas_summary.tsv",
              sep = "\t", quote = FALSE, row.names = FALSE)
  cat("[W3] t2d_gwas_summary.tsv —", nrow(gwas), "변이,",
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
