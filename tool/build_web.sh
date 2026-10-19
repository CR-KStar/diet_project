#!/usr/bin/env bash
# 웹 빌드: app(실제 앱, build/web_app) 또는 demo(체험판, build/web_demo).
# 사용법: tool/build_web.sh app | tool/build_web.sh demo
set -euo pipefail
cd "$(dirname "$0")/.."

case "${1:-}" in
  app)
    flutter build web --release --output build/web_app
    ;;
  demo)
    flutter build web --release --dart-define=USE_FIREBASE=false --output build/web_demo
    # 링크 미리보기(제목 · 설명 · 주소)를 체험판용으로 바꾼다.
    python3 - <<'PY'
p = 'build/web_demo/index.html'
s = open(p, encoding='utf-8').read()
s = s.replace('키워요.">', '키워요. (웹 체험판)">', 1)
s = s.replace('content="밋그린 · 식단 기록 앱"', 'content="밋그린 · 식단 기록 앱 (웹 체험판)"', 1)
s = s.replace('https://meatgreen.web.app/', 'https://diet-project-81ce1.web.app/')
open(p, 'w', encoding='utf-8').write(s)
PY
    ;;
  *)
    echo "사용법: $0 app|demo" >&2
    exit 1
    ;;
esac
