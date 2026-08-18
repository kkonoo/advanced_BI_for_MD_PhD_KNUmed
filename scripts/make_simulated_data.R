# ============================================================
# make_simulated_data.R
# 고급 생물정보학 (융합형 의사과학자 양성사업) — 실습용 시뮬레이션 데이터
#
# 개인 유전형·환자 검체에서 나온 데이터는 공유가 불가능하므로
# 교육 목적에 맞게 시뮬레이션한다. 각 데이터셋에는 해당 주차가
# 가르치려는 패턴이 의도적으로 심어져 있다.
#
# 의존성 없음 — base R 만으로 동작한다.
#
# In  : (없음)
# Out : rawdata/prs_scores.tsv          W4
#       rawdata/plasma_proteomics.rds   W10
#       rawdata/plasma_meta.rds         W10
# ============================================================

set.seed(2026)
dir.create("rawdata", showWarnings = FALSE)

# ────────────────────────────────────────────────────────────
# W4 · prs_scores.tsv
#
# 심어둔 것:
#   · PRS 효과는 SD당 OR ≈ 1.73 — 좋은 PRS의 현실적인 크기
#   · 임상모형(나이·성별) 위에 얹었을 때 ΔAUC ≈ 0.02–0.03
#     → "통계적으로 유의하지만 임상적으로는 미미"를 직접 보게 됨
#   · 십분위 위험이 매끄럽게 상승 → 자연스러운 절단점이 없음
#   · 최상위 vs 최하위 십분위 비가 최상위 vs 중간 십분위 비보다
#     훨씬 커짐 → §3.4 "십분위 트릭"이 실제 숫자로 재현됨
# ────────────────────────────────────────────────────────────
n <- 40000

age <- round(rnorm(n, 58, 9))
age[age < 30] <- 30; age[age > 85] <- 85
sex <- rbinom(n, 1, 0.48)                       # 1 = male
prs <- rnorm(n)                                 # 표준화된 PRS

z_age <- (age - mean(age)) / sd(age)

# 절편은 전체 유병률이 ≈ 3.2% 가 되도록 잡았다
lp <- -4.12 + 0.90 * z_age + 0.45 * sex + 0.55 * prs
p  <- 1 / (1 + exp(-lp))
disease <- rbinom(n, 1, p)

prs_scores <- data.frame(
  IID     = sprintf("P-%04d", seq_len(n)),
  PRS     = round(prs, 5),
  disease = disease,
  age     = age,
  sex     = ifelse(sex == 1, "M", "F"),
  stringsAsFactors = FALSE
)

write.table(prs_scores, "rawdata/prs_scores.tsv",
            sep = "\t", quote = FALSE, row.names = FALSE)

# ── 확인: 이 숫자들이 W4 §3.4 그림과 대응한다 ──
dec  <- cut(prs_scores$PRS, breaks = quantile(prs_scores$PRS, 0:10/10),
            include.lowest = TRUE, labels = FALSE)
risk <- tapply(prs_scores$disease, dec, mean)
cat("\n[W4] prs_scores.tsv\n")
cat("  n =", n, " prevalence =", sprintf("%.1f%%", 100 * mean(disease)), "\n")
cat("  십분위별 위험(%):", paste(sprintf("%.1f", 100 * risk), collapse = " "), "\n")
cat("  최상위 vs 최하위 :", sprintf("%.1fx", risk[10] / risk[1]), "\n")
cat("  최상위 vs 중간   :", sprintf("%.1fx", risk[10] / risk[5]), "\n")
cat("  최상위 vs 나머지 :", sprintf("%.1fx",
      risk[10] / mean(prs_scores$disease[dec != 10])), "\n")

# ────────────────────────────────────────────────────────────
# W10 · plasma_proteomics.rds  +  plasma_meta.rds
#
# 심어둔 것:
#   · 결측이 MNAR — 검출한계 아래가 잘린다.
#     → 강도 대비 결측률 산점도에 뚜렷한 음의 추세 (§5.1)
#   · ⚠️ batch 가 군과 부분적으로 교락되어 있다 (B1 은 대조군 쪽,
#     B2 는 환자군 쪽으로 치우침). 실제 은행 검체 코호트가 이렇게 생겼다 —
#     환자와 대조군이 다른 시기에 모였기 때문이다.
#     → design 에서 batch 를 빼면 위양성이 확 늘어난다 (§5.3①)
#   · 진짜 차등 단백질 60개, 그중 일부는 저강도 —
#     결측 처리 방식에 따라 살아남기도 사라지기도 한다
#   · 단백질 수 >> 표본 수 → 과적합이 실제로 발생 (§5.3③)
# ────────────────────────────────────────────────────────────
n_prot <- 1200
n_samp <- 80                                    # 40 case / 40 control

condition <- factor(rep(c("control", "case"), each = n_samp / 2),
                    levels = c("control", "case"))

# ⚠️ 부분 교락: 대조군의 70%가 B1, 환자군의 70%가 B2 에 들어간다.
#    완전 교락(모든 대조군이 B1)은 아니므로 batch 효과를 추정할 수는 있다.
#    다만 design 에서 빼면 batch 차이가 질환 차이로 새어 들어간다.
batch <- character(n_samp)
ctl <- which(condition == "control"); cse <- which(condition == "case")
batch[ctl] <- rep(c("B1", "B2"), c(28, 12))
batch[cse] <- rep(c("B1", "B2"), c(12, 28))

meta <- data.frame(
  sample_id = sprintf("S%03d", seq_len(n_samp)),
  condition = condition,
  age       = round(rnorm(n_samp, 61, 11)),
  sex       = factor(sample(c("F", "M"), n_samp, replace = TRUE)),
  batch     = factor(batch),
  stringsAsFactors = FALSE
)
rownames(meta) <- meta$sample_id

# 단백질별 기저 강도: 실제 혈장처럼 넓은 동적 범위
base_int <- rnorm(n_prot, mean = 20, sd = 3.2)

mat <- matrix(rnorm(n_prot * n_samp, 0, 0.55), nrow = n_prot)
mat <- mat + base_int

# 진짜 차등 단백질 60개 (저강도 단백질을 일부러 섞었다)
de_idx  <- c(sample(which(base_int > 21), 35), sample(which(base_int < 18), 25))
de_size <- runif(length(de_idx), 0.7, 1.9) * sample(c(-1, 1), length(de_idx), TRUE)
is_case <- meta$condition == "case"
mat[de_idx, is_case] <- mat[de_idx, is_case] + de_size

# batch 효과 — 단백질마다 다른 크기
batch_eff <- rnorm(n_prot, 0, 0.75)
mat[, meta$batch == "B2"] <- mat[, meta$batch == "B2"] + batch_eff

# 나이 효과 (약함)
mat <- mat + outer(rnorm(n_prot, 0, 0.12), scale(meta$age)[, 1])

dimnames(mat) <- list(sprintf("PROT%04d", seq_len(n_prot)), meta$sample_id)

# ⚠️ MNAR: 검출한계 부근에서 확률적으로 잘린다
lod   <- 16.5
p_obs <- 1 / (1 + exp(-(mat - lod) * 1.5))      # 강도가 낮을수록 관측될 확률 감소
mat[matrix(runif(length(mat)), nrow = n_prot) > p_obs] <- NA

saveRDS(mat,  "rawdata/plasma_proteomics.rds")
saveRDS(meta, "rawdata/plasma_meta.rds")

miss <- rowMeans(is.na(mat))
cat("\n[W10] plasma_proteomics.rds\n")
cat("  단백질 x 표본     :", nrow(mat), "x", ncol(mat), "\n")
cat("  전체 결측률       :", sprintf("%.1f%%", 100 * mean(is.na(mat))), "\n")
cat("  결측 없는 단백질  :", sum(miss == 0), "\n")
cat("  결측 30%% 초과     :", sum(miss > 0.30), "\n")
cat("  강도 vs 결측률 상관:", sprintf("%.2f",
      cor(rowMeans(mat, na.rm = TRUE), miss, use = "complete")),
    " <- 음수여야 MNAR\n")
cat("  진짜 차등 단백질  :", length(de_idx), "\n")
cat("  batch x condition :\n"); print(table(meta$batch, meta$condition))
cat("\n")
cat("완료. rawdata/ 를 확인하세요.\n")
