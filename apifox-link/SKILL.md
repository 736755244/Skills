---
name: apifox-link
description: "依据后端已提供的接口定义，逐条核对页面 Mock，并在人工确认后安全接入 Apifox。"
---

# apifox-link

> **显式调用门禁：** 只有用户当前消息明确输入 `/apifox-link`，或明确要求调用/对接 Apifox 接口时，才允许执行本 Skill 或调用 Apifox MCP。页面出现 API、Mock、字段或后续建议不构成授权。

本 Skill 以已确认的后端定义/Apifox 为唯一目标契约：先用接口的请求、响应字段覆盖页面本地 Mock 的字段模型与页面读取方式，再汇总无法按接口语义或字段直接落地的差异供人工逐条确认。Mock 只用于转换阶段的当前页面行为和未对接回退，绝不反向定义、筛选或匹配接口。结果和通用确认规则见 [结果契约](../transfer-to-vue3/result-contract.md)，逐页面证据模板见 [api-gap-report-template.md](./api-gap-report-template.md)。

## 边界

- 接口契约和字段模型只能来自后端定义或 Apifox；本地 Mock、字段、按钮或组件行为不能反向定义、筛选或匹配接口。
- 对于已确认且可直接使用的接口，以接口请求/响应字段覆盖本地 Mock 的字段模型和页面读取方式；只有接口语义、URL/方法或字段无法直接落地时，才汇总为人工确认项。
- 本 Skill 不创建或修改 Apifox，不设计权限，不自动迁移/重命名页面；API 文件遵循 [通用 API 规范](../transfer-to-vue3/standards.md)：仅放契约类型、接口方法与必要请求封装 import，每个方法只接收一个 `params`（GET）或 `data`（POST/PUT/DELETE）入参并原样透传。
- 不在 API 层做字段改名、请求体拼装、默认值、类型转换、业务校验或响应加工；已确认需要的业务适配写在调用方或页面邻近的 `utils.ts`。
- `MISSING`、`FUZZY`、`TYPE_MISMATCH`、未确认或无法直接适配的条目继续使用 Mock。
- restore 迁移是单独的文件范围确认项；未确认不得移动、重命名或更新引用。
- 真实写请求和其他外部副作用按结果契约另行确认；不自动调用其他 Skill。

## 执行流程

1. 确认页面路径、模块语义、后端定义来源、目标 API 位置和本次范围；缺失时停止询问。
2. 读取已确认页面、`mock.ts`、已有 API 引用和配置，仅登记本地调用点与当前 Mock 回退范围；不得用 Mock 字段反向搜索、筛选或判定接口。
3. 按已确认的后端模块语义或路径搜索 Apifox：已知路径时用 `mcp__apifox__search_api`，只有后端语义时用 `mcp__apifox__smart_search_api`；从候选中用 `mcp__apifox__get_api_detail` 或 `mcp__apifox__batch_get_apis` 获取详情。需要最新定义时先刷新缓存。以详情中的方法、URL、请求/响应字段建立接口字段模型，并记录到页面同级报告。
4. 对已确认接口，先以接口字段覆盖页面本地 Mock 的字段模型和读取点：可直接落地的字段标为 `LINKED`；仅当接口语义、URL/方法、请求/响应结构或页面显示需求无法直接落地时，记录为 `FUZZY`、`TYPE_MISMATCH` 或 `MISSING`，再逐项请求人工决定。不得由本地 Mock 反向判断接口是否匹配。
5. 仅编辑已确认且契约可直接使用的条目，沿用项目请求封装并遵循 [通用 API 规范](../transfer-to-vue3/standards.md) 的单入参与原样透传边界。没有明确适配规则时，不做 `Number` 或其他类型转换；`TYPE_MISMATCH` 的适配必须经人工确认后写在调用方或页面邻近的 `utils.ts`，不能塞入 API 文件。未接入或阻塞条目保留 Mock 回退。
6. 对已确认接入条目，必须运行项目可用的**只读类型检查**（项目提供 `pnpm ts:check` 时优先执行），并只使用不带 `--fix` 的定向 lint；禁止用会对全库执行 `--fix` 的 package script 校验。再以 Chrome DevTools MCP 验证 Network、页面展示、真实交互和 console。类型检查或页面验证失败时，条目不得标为 `success`，必须保留/恢复 Mock 回退或标为 `blocked`，并记录调用点、命令输出和复现证据。

## 结果

每个页面生成或更新同级 `api-gap-report.md`。按 [结果契约](../transfer-to-vue3/result-contract.md) 给出顶层与条目状态，并保留 API 专属的搜索/详情证据、逐项确认、字段差异、Mock 去留、Network 和页面验证。没有后端定义、人工确认、适配规则或真实浏览器证据时，不能使用 `completed`。
