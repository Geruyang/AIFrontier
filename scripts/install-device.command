#!/bin/zsh
set -euo pipefail

project_dir='/Users/geruyang/AIProject/Ai-Teacher'
check_only=false
[[ "${1:-}" == '--check' ]] && check_only=true
run_dir="$project_dir/.build/device-install/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$run_dir"

finish() {
    local exit_code=$?
    if (( exit_code != 0 )); then
        print '\n安装未完成。请查看上面的错误信息。'
        print '检查手机是否已解锁、信任此 Mac，并启用“设置 → 隐私与安全性 → 开发者模式”。'
        print '如果提示系统版本或开发者磁盘映像不支持，请在 Xcode 的 Devices and Simulators 中处理设备支持。'
    fi
    print "\n本次日志：$run_dir"
    if [[ -t 0 && -t 1 && "$check_only" == false ]]; then
        read -r "?按回车关闭窗口…" || true
    fi
}
trap finish EXIT

print 'AI Frontier 真机安装工具'
print '安装开发者全内容开放版本（iOS 18 或更高），保留已有学习数据。'
[[ -f "$project_dir/AIFrontier.xcodeproj/project.pbxproj" ]] || {
    print "找不到项目：$project_dir"; exit 1
}
xcrun --find devicectl >/dev/null
xcodebuild -version
python_bin="$(xcrun --find python3 2>/dev/null || command -v python3)"

xcrun devicectl list devices --json-output "$run_dir/devices.json" --quiet
"$python_bin" - "$run_dir/devices.json" > "$run_dir/available-devices.tsv" <<'PY'
import json
import sys

with open(sys.argv[1], encoding='utf-8') as stream:
    devices = json.load(stream).get('result', {}).get('devices', [])
for device in devices:
    hardware = device.get('hardwareProperties', {})
    connection = device.get('connectionProperties', {})
    if hardware.get('platform') != 'iOS' or hardware.get('reality') != 'physical':
        continue
    if connection.get('tunnelState') == 'unavailable':
        continue
    identifier = device.get('identifier', '')
    udid = hardware.get('udid', '')
    name = device.get('deviceProperties', {}).get('name', 'iPhone / iPad')
    name = name.replace('\t', ' ').replace('\n', ' ')
    if identifier and udid:
        print(identifier, udid, name, sep='\t')
PY

device_ids=()
device_udids=()
device_names=()
while IFS=$'\t' read -r device_id device_udid device_name; do
    [[ -n "$device_id" ]] || continue
    device_ids+=("$device_id")
    device_udids+=("$device_udid")
    device_names+=("$device_name")
done < "$run_dir/available-devices.tsv"

if (( ${#device_ids} == 0 )); then
    print '\n没有可安装的已连接 iPhone / iPad。请用数据线连接并解锁手机，确认信任此 Mac。'
    if [[ "$check_only" == true ]]; then
        print '脚本自检通过；当前未执行构建、安装或启动。'
        exit 0
    fi
    exit 1
fi

print '\n可用设备：'
for (( i = 1; i <= ${#device_ids}; i++ )); do
    print "$i. ${device_names[$i]}"
done
if [[ "$check_only" == true ]]; then
    print '脚本自检通过；未执行构建、安装或启动。'
    exit 0
fi

selection=1
if (( ${#device_ids} > 1 )); then
    read -r "selection?请选择设备编号："
    [[ "$selection" == <-> ]] || { print '设备编号无效。'; exit 1; }
    (( selection >= 1 && selection <= ${#device_ids} )) || { print '设备编号无效。'; exit 1; }
fi
chosen_id="${device_ids[$selection]}"
chosen_udid="${device_udids[$selection]}"
print "\n正在为 ${device_names[$selection]} 构建开发签名版本…"
cd "$project_dir"
xcodebuild -project AIFrontier.xcodeproj -scheme AIFrontier \
    -configuration Debug -destination "platform=iOS,id=$chosen_udid" \
    -derivedDataPath "$run_dir/DerivedData" \
    -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
    -quiet build 2>&1 | tee "$run_dir/build.log"

app_path="$run_dir/DerivedData/Build/Products/Debug-iphoneos/AIFrontier.app"
[[ -d "$app_path" ]] || { print '没有找到构建产物。'; exit 1; }
codesign --verify --deep --strict "$app_path"
print '\n正在安装 AI Frontier…'
xcrun devicectl device install app --device "$chosen_id" "$app_path" \
    --json-output "$run_dir/install.json"
print '\n正在启动 AI Frontier…'
xcrun devicectl device process launch --device "$chosen_id" \
    --terminate-existing --json-output "$run_dir/launch.json" \
    com.geruyang.aifrontier
print '\n安装完成。现在可以在手机上测试 AI Frontier。'
