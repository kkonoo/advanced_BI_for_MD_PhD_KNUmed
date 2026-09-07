# 정리 후보 검토 목록

작성일: 2026-09-07

이 폴더에는 현재 Quarto 사이트에서 참조되지 않거나 자동으로 다시 생성되는 파일만 모았습니다. 원본은 삭제하지 않고 이곳으로 이동했습니다.

## 요약

| 폴더 | 파일 수 | 크기 | 분류 이유 |
|---|---:|---:|---|
| `01_generated-local-state` | 479 | 약 21.1 MB | Quarto가 다시 만드는 기존·검증·AI 보안 점검 후 `.quarto` 캐시와 사이트에 필요 없는 R 명령 기록 |
| `02_unused-styles` | 3 | 약 3.6 KB | `_quarto.yml`에서 참조하지 않는 이전 CSS. 현재 사이트는 `assets/html.css`만 사용 |
| `03_legacy-course-data` | 2 | 약 25.9 KB | 현재 W1–W14와 주차·경로가 다른 이전 커리큘럼의 데이터 안내와 다운로드 스크립트 |
| `04_unused-images` | 22 | 약 2.75 MB | 현재 30개 EN/KO qmd, 설정, CSS, JS 어디에서도 참조하지 않는 이전 강의 그림 |
| `05_duplicate-chapter-images` | 6 | 약 255.7 KB | part3·part4·part5에 동일한 해시로 세 번씩 복제되어 있고 어느 페이지에서도 사용하지 않는 clipboard 그림 |
| `06_unused-favicon-pack` | 27 | 약 692.9 KB | 현재 favicon인 `assets/img/favicon.ico`와 별개이며 사이트에서 참조되지 않는 예전 아이콘 묶음 |
| `07_empty-directories` | 0 | 0 | 내용이 없는 `_extensions`와 실수로 생성된 것으로 보이는 `{_extensions,chapters}` 폴더 |

총 539개 파일, 24,976,713바이트를 이동했습니다. 이 수치에는 이 manifest 파일 자체는 포함하지 않았습니다.

## 유지한 항목

- `_site`, `_freeze`: 추적 중인 빌드·배포 산출물이라 자동 삭제 대상으로 판단하지 않았습니다.
- `.Rproj.user`: RStudio의 복구 가능한 편집 상태가 들어 있을 수 있어 옮기지 않았습니다.
- `rawdata`: 강의 실습에서 사용하므로 유지했습니다.
- `_extensions`의 내용은 없었지만, AI 채팅 구현인 `assets/ai-chat-init.html`과 `cloudflare-worker.js`는 실제 사용 중이므로 유지했습니다.
- `assets/img/logo.jpg`, `assets/img/favicon.ico`, `assets/img/w1`–`w14`: 현재 사이트가 실제로 참조하므로 유지했습니다.

## 삭제 또는 복구

검토 후 필요 없으면 이 `_cleanup_review_2026-09-07` 폴더 전체를 삭제하면 됩니다.

복구하려면 각 하위 폴더 안의 파일을 저장된 상대 경로대로 프로젝트 루트에 다시 옮기십시오. 예를 들어 `02_unused-styles/custom.css`는 원래 프로젝트 루트의 `custom.css`였습니다.
