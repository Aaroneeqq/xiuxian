# 凡人放置 · iOS 远程壳

全屏 WKWebView 直接加载游戏服务器前端的 iOS 壳工程（对应 Android 端的 Capacitor 远程壳）。
通过 GitHub Actions（macOS runner）+ XcodeGen + xcodebuild，云端编译出**未签名 IPA**。

## 装这个 IPA 需要满足其一

| 方式 | 前提 | 有效期 |
|---|---|---|
| TrollStore 导入 | iOS 14.0–17.0（部分版本） | 永久 |
| 越狱 + Filza/ipainstaller | 已越狱 | 永久 |
| Sideloadly / AltStore 自签 | 任意设备 + 自己的 Apple ID | 7 天（免费账号） |

## 改服务器地址

只改 `project.yml` 里 `XXJHomeURL` 一处（会生成进 Info.plist），不用动 Swift 代码。

## 流程

push 到 main（或手动 workflow_dispatch）→
`brew install xcodegen` → `xcodegen generate` →
`xcodebuild -sdk iphoneos CODE_SIGNING_ALLOWED=NO build` →
Payload 打包成 `FanrenFangzhi-unsigned.ipa` →
上传 Artifact + 提交回 `dist-ipa/`。

图标缺省时用 Pillow 画一个「凡」字金印兜底；`AppIcon-1024.png.b64` 存在则解码使用。
