#!/usr/bin/env python3
import sys

def to_pascal_case(snake_str):
    return ''.join(x.title() for x in snake_str.split('_'))

def main():
    if len(sys.argv) < 2 or not sys.argv[1]:
        # 인자가 없으면 전체 테스트 실행
        print("-only-testing:TodoMateUITests/ScreenshotTests")
        return

    screens = sys.argv[1]
    # Remove 'SCREENS=' prefix if present (justfile artifact)
    if screens.startswith("SCREENS="):
        screens = screens.replace("SCREENS=", "", 1)

    args = []

    for s in screens.split(','):
        s = s.strip()
        if not s: continue

        # screen name (snake_case) -> Method Name (PascalCase)
        # 예: personal_board -> PersonalBoard -> testCapturePersonalBoard
        method_name = f"testCapture{to_pascal_case(s)}"
        args.append(f"-only-testing:TodoMateUITests/ScreenshotTests/{method_name}")

    print(' '.join(args))

if __name__ == "__main__":
    main()
