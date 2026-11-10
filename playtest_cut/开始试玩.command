#!/bin/zsh
# 双击运行《HR.exe》砍减版试玩
cd "$(dirname "$0")/game"
GODOT=""
for p in "/Users/apple/Downloads/Godot.app" "/Applications/Godot.app" "$HOME/Applications/Godot.app"; do
  [ -x "$p/Contents/MacOS/Godot" ] && GODOT="$p/Contents/MacOS/Godot" && break
done
if [ -z "$GODOT" ]; then
  echo "找不到 Godot 4.7，请把 Godot.app 放进“应用程序”文件夹后再双击。"
  read -k1
  exit 1
fi
# 第一次运行先导入资源（字体、图片）
[ -d .godot/imported ] || "$GODOT" --headless --path . --import >/dev/null 2>&1
exec "$GODOT" --path .
