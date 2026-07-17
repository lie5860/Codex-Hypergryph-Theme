# Windows 依赖架构

## 结论

Windows 版采用“固定上游引擎 + 下游资源包 + 薄适配器”，而不是继续维护 Codex Dream Skin 的完整分叉，也不重写为纯 Node.js 安装器。

安装入口依然很简单：用户双击根目录的 `安装终末地主题-Windows.cmd`。复杂的 Windows 安装事务由上游处理，本项目只负责把终末地资源交给它。

## 目录边界

| 目录 | 所有者 | 内容 |
| --- | --- | --- |
| `vendor/Codex-Dream-Skin/windows/scripts` | 上游 | Appx 校验、配置事务、进程管理、CDP 注入和恢复 |
| `vendor/Codex-Dream-Skin/windows/tests` | 上游 | 引擎测试，保持上游原始内容 |
| `.runtime-windows/assets` | 本项目 | CSS、renderer、`theme.json` 和原创背景 |
| `.runtime-windows/scripts` | 本项目 | Node.js 探测、运行时组装和四个用户入口 |
| `.runtime-windows/tests` | 本项目 | 上游接口兼容与终末地 renderer 契约测试 |

安装器先在系统临时目录组装完整运行时，再调用上游 `install-dream-skin.ps1 -NoShortcuts`。上游把自包含引擎原子复制到 `%LOCALAPPDATA%\CodexDreamSkin\engine`，本项目随后激活终末地主题并调用该引擎的启动脚本。

## 为什么不使用纯 Node.js

Node.js 很适合上游已经交给它的工作：解析图片、构建 renderer payload、连接 loopback CDP 和持续注入。

Windows 安装侧还要处理 Store Appx 身份、PowerShell/TOML 配置事务、进程所有权、互斥锁和恢复流程。把这些再移植到 Node.js 不会减少系统复杂度，只会产生第二套未经上游验证的实现。因此适配器只负责找到 Node.js 22+ 并放入当前进程的 `PATH`，后续仍调用上游 PowerShell 与 Node.js 引擎。

## 为什么固定快照

- Git submodule 在 GitHub 的普通 ZIP 下载中不会自动携带内容，容易得到缺失运行时的发布包。
- 安装时联网下载会引入网络失败、上游漂移和供应链校验问题。
- 固定 vendored 快照可离线安装、可做代码审查，也能让升级差异保持可见。

当前固定提交记录在 `vendor/Codex-Dream-Skin/UPSTREAM_COMMIT`。`PATCHES.md` 记录唯一的行为补丁：移除隐藏窗口启动参数。上游示例主题资源没有 vendored，本项目只分发自己的资源。

## 升级上游

1. 选择一个明确的上游提交，不跟随浮动分支。
2. 更新 `windows/scripts`、`windows/tests` 和 Windows 文档。
3. 重新应用并审查 `PATCHES.md` 中记录的企业安全补丁。
4. 更新 `UPSTREAM_COMMIT` 与适配器中的期望提交号。
5. 执行 `.runtime-windows/tests/run-tests.ps1` 和 `检查终末地主题环境-Windows.cmd`。
6. 比较 vendored 脚本与上游提交，确认除记录补丁外没有隐式分叉。

如果上游主题 schema 或 renderer 占位符改变，升级应在 `.runtime-windows/assets` 与资源契约测试中完成，不应直接修改上游 injector 来兼容旧资源。
