---
description: "构建、签名、公证并发布 Follin macOS 应用到 GitHub Release。Use when: 发布新版本、release、打包 DMG"
agent: "agent"
tools: [execute, read, search]
argument-hint: "版本号，如 1.2.0"
---

你是 Follin (macOS SwiftUI 应用) 的发布助手。请严格按照以下流程逐步执行发布操作。

**版本号**: {{input}}（不带 v 前缀的纯数字版本，如 `1.2.0`）

## 执行要求

- **逐步执行**：每一步执行完毕后，确认命令返回值为 0 才进入下一步
- **失败即停**：任何步骤失败，立即停止并报告错误原因，不要跳过
- **确认再继续**：在执行最后的 git push 和 gh release 之前，先向用户展示即将发布的内容摘要，确认后再执行

## Step 0: 环境检查

确认以下工具可用，任何一个缺失就停止：

```bash
command -v xcodebuild && command -v codesign && command -v xcrun && command -v hdiutil && command -v gh
```

## Step 1: 查询签名身份

```bash
SIGN_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/')
echo "签名身份: $SIGN_ID"
```

如果 `SIGN_ID` 为空，停止并提示用户检查证书安装。

## Step 2: 准备 ExportOptions.plist

如果 `./dist/ExportOptions.plist` 不存在，创建它：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>SKHQYDKTP3</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
</dict>
</plist>
```

同时确保 `./dist/` 目录存在：`mkdir -p ./dist`

## Step 3: 更新版本号

在 `todaylist.xcodeproj/project.pbxproj` 中将所有 `MARKETING_VERSION` 更新为 {{input}}。

## Step 4: Archive

```bash
xcodebuild archive \
  -scheme todaylist \
  -archivePath ./dist/Follin.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="$SIGN_ID" \
  CODE_SIGN_STYLE=Manual
```

确认 `./dist/Follin.xcarchive` 已生成。

## Step 5: 导出 .app

```bash
xcodebuild -exportArchive \
  -archivePath ./dist/Follin.xcarchive \
  -exportOptionsPlist ./dist/ExportOptions.plist \
  -exportPath ./dist/export
```

确认 `./dist/export/Follin.app` 存在。

## Step 6: 打包 DMG

```bash
rm -rf ./dist/dmg-content
mkdir -p ./dist/dmg-content
cp -R ./dist/export/Follin.app ./dist/dmg-content/
ln -sf /Applications ./dist/dmg-content/Applications
hdiutil create -volname "Follin" \
  -srcfolder ./dist/dmg-content \
  -ov -format UDZO \
  ./dist/Follin.dmg
```

确认 `./dist/Follin.dmg` 已生成。

## Step 7: 签名 DMG

```bash
codesign --sign "$SIGN_ID" ./dist/Follin.dmg
```

验证签名：`codesign --verify --verbose ./dist/Follin.dmg`

## Step 8: Notarize

```bash
xcrun notarytool submit ./dist/Follin.dmg --keychain-profile "follin-notarize" --wait
```

确认输出包含 `status: Accepted`。如果被拒绝，用 `xcrun notarytool log <submission-id> --keychain-profile "follin-notarize"` 查看原因。

## Step 9: Staple

```bash
xcrun stapler staple ./dist/Follin.dmg
```

## Step 10: 生成 Release Notes

从上一个 git tag 到现在的 commit 中提取更新内容：

```bash
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
  git log "$LAST_TAG"..HEAD --pretty=format:"- %s" --no-merges
else
  git log --pretty=format:"- %s" --no-merges -20
fi
```

将输出整理为简洁的中文 release notes，按功能分类。

## Step 11: 确认并发布

**在执行前，向用户展示以下摘要并等待确认：**

- 版本号：v{{input}}
- DMG 文件大小
- Release Notes 内容

确认后执行：

```bash
git add -A && git commit -m "v{{input}}" && git push
gh release create "v{{input}}" ./dist/Follin.dmg --title "Follin v{{input}}" --notes "<整理后的 release notes>"
```
