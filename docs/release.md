# 发布流程

## 前置条件（已完成，无需重复）

- Developer ID Application 证书已安装到 Keychain
- `xcrun notarytool` 凭据已存储（profile: `follin-notarize`）
- `gh` CLI 已登录

## 发布步骤

```bash
# 0. 查询签名身份（确认证书可用）
SIGN_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/')
echo "使用签名: $SIGN_ID"

# 1. Archive
xcodebuild archive \
  -scheme todaylist \
  -archivePath ./dist/Follin.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="$SIGN_ID" \
  CODE_SIGN_STYLE=Manual

# 2. 导出 .app
xcodebuild -exportArchive \
  -archivePath ./dist/Follin.xcarchive \
  -exportOptionsPlist ./dist/ExportOptions.plist \
  -exportPath ./dist/export

# 3. 打包 DMG
rm -rf ./dist/dmg-content
mkdir -p ./dist/dmg-content
cp -R ./dist/export/Follin.app ./dist/dmg-content/
ln -sf /Applications ./dist/dmg-content/Applications
hdiutil create -volname "Follin" \
  -srcfolder ./dist/dmg-content \
  -ov -format UDZO \
  ./dist/Follin.dmg

# 4. 签名 DMG
codesign --sign "$SIGN_ID" ./dist/Follin.dmg

# 5. Notarize（等待 Apple 审核，通常几分钟）
xcrun notarytool submit ./dist/Follin.dmg --keychain-profile "follin-notarize" --wait

# 6. Staple
xcrun stapler staple ./dist/Follin.dmg

# 7. 提交代码并发布 Release（修改版本号）
git add -A && git commit -m "v1.x.x" && git push
gh release create v1.x.x ./dist/Follin.dmg --title "Follin v1.x.x" --notes "更新说明"
```
