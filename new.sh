# 1. 실행 중인 모든 에뮬레이터 프로세스 강제 종료
pkill -9 qemu-system-aarch64

# 2. adb 서버 재시작 (연결 초기화)
/Users/chaerin/Library/Android/sdk/platform-tools/adb kill-server
/Users/chaerin/Library/Android/sdk/platform-tools/adb start-server

# 3. 에뮬레이터 데이터 초기화 후 재실행 (stuck된 상태 해결)
flutter emulators --launch Pixel_10_Pro_XL --wipe-data