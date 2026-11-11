---
name: ui-verify-playwright
description: 将本仓库 Vue3 + Element Plus 页面固化为安全、可复跑的 Playwright UI 验证：CLI 探索、page object/spec、回归报告与有限自愈。
---

# UI 自测：CLI → Test → Skill

本 Skill 将真实联调页面固化为可复跑的 Playwright Chrome 回归。执行前先读取目标项目的 `docs/ui-verification/README.md`、`e2e/README.md` 等项目说明（存在时），并读取 [控件定位速查](references/locator-guide.md)。通用状态、确认和结果字段见 [结果契约](../transfer-to-vue3/result-contract.md)。

## 验证资格门槛

- 先查看 `git status --short --untracked-files=all`，仅做本次 E2E 所需的增量修改；不 reset、clean、checkout 或覆盖未提交变更。
- 后端接口、鉴权/SSO、权限、测试数据与账号必须完成联调并可用；任何一项缺失、账号不可用或页面仍使用 Mock 时停止并记录 `blocked`，不得跳过登录或伪造通过。
- 不读取、输出、提交 `.env.e2e`、`e2e/.auth/user.json`、cookie、token 或 trace 中的敏感信息。
- 只验证本 Skill 范围，不自动调用转换、接口、权限或清理 Skill。

## 环境与产物

- 使用 `pnpm dev:e2e`，默认地址为 `http://127.0.0.1:9000`，可由 `E2E_PORT` 覆盖。
- 使用本机 Google Chrome（Playwright `channel: 'chrome'`），不安装 Playwright Chromium。
- `auth.setup.ts` 仅登录一次，业务用例复用 `storageState`；固定 `workers: 1` 避免 SSO 互踢。
- 正式产物：`e2e/pages/<Name>Page.ts`、`e2e/specs/<name>.spec.ts` 和失败时的 report/trace/video/screenshot 路径。
- 本地缺少认证前置时明确记录 `blocked` 或项目已定义的 `skip`；CI 缺少必需认证配置必须失败，不能静默跳过。
- locator 遵循 [控件定位速查](references/locator-guide.md)：优先 `role → placeholder/label → testid`，再用 dialog、row、搜索表单等语义上下文收窄；不用样式、索引、随机文本或全局 `nth` 作为脆弱替代。定位失败先修 page object/spec，只有产品确实缺少语义定位时才建议最小 `data-testid`。

## 工作流

1. **预检与探路**：记录联调、账号、权限和数据前提，执行 `pnpm e2e:check`、`pnpm dev:e2e`、`pnpm e2e:explore`。录制代码只存入 `e2e/archive/` 作为脱敏探路材料，必须整理成 page object + spec，不把密码、cookie 或 storage state 写入用例。
2. **固化真实用户行为**：真实 Chrome 覆盖页面实际能力中的导航、权限边界、菜单/Tab/按钮、搜索、下拉、表单与校验、弹窗、表格/空态/异常态、分页、返回和刷新。每个关键动作断言可见结果、console 和页面状态；用自动等待与 `expect.poll`，禁止 `waitForTimeout`、接口直调、静态 DOM 断言或脚本注入替代操作。
3. **回归**：按需要执行 `pnpm ts:check:e2e`、定向 `pnpm test:e2e -- --grep "<用例名>"`、单 spec、全量、`CI=1 pnpm test:e2e` 和 `pnpm test:e2e:report`。通过 `pnpm` 传参数时使用 `--`。
4. **有限自愈**：分析 report、trace、video、screenshot、console、URL 和项目快照，区分 locator、权限、数据、后端与环境问题。仅修复有证据的问题，每轮后重新执行受影响真实操作；最多两轮。不得以增加等待、放宽断言、跳过用例或伪造数据掩盖失败。

## 结果

输出 `.middleproduct/ui-verify-playwright-result.md`，遵循 [结果契约](../transfer-to-vue3/result-contract.md)，额外记录环境、认证前提、测试文件、执行命令、report/trace/video/screenshot 路径、自愈轮次和浏览器 console 摘要。转换用 Chrome DevTools MCP 证据不能替代本 Skill 的 Playwright Chrome 回归证据。
