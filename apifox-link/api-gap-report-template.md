# API 对接差异报告

> **显式调用门禁：** 仅在用户当前消息明确调用 `/apifox-link` 或要求对接 Apifox 接口时使用。本模板补充 [结果契约](../transfer-to-vue3/result-contract.md) 的 API 专属证据，不以聊天摘要替代页面同级 `api-gap-report.md`。

## 1. 输入与范围

- **页面路径 / 模块**：`{pagePath}` / `{module}`
- **后端定义来源 / Apifox 范围**：`{backendDefinitionSource}` / `{apifoxScope}`
- **Mock 来源**：`{mockPath}`（仅作为未对接条目的页面回退，不作为接口契约、搜索输入或匹配依据）
- **操作范围与确认**：`{selected items / confirmation}`
- **可选迁移条目**：`{oldPath → newPath / not applicable}`

## 2. MCP 搜索记录

每个接口需求按已确认的后端模块语义或路径单独记录搜索输入、候选和详情，不能只写“已搜索”；不得使用 Mock 字段作为搜索、筛选或匹配依据。

| 需求编号 | 后端语义输入 | 工具与参数 | 候选路径/结果 | 详情证据 | 时间 |
|---|---|---|---|---|---|
| {id} | {semantic definition} | `search_api` / `smart_search_api`：`{pattern/query}` | `{paths or none}` | `get_api_detail` / `batch_get_apis`：`{summary}` | {time} |

缓存刷新（如使用）：`mcp__apifox__refresh_cache`，参数 `{force}`，结果 `{result}`。

## 3. 接口字段覆盖与人工确认

先以 Apifox 详情中的 HTTP 方法、URL、请求/响应字段覆盖本地 Mock 的字段模型和页面读取方式；本地 Mock 不能反向决定接口候选或字段定义。只有接口语义、URL/方法、请求/响应结构或页面显示需求不能直接落地时，才进入下列差异状态与人工确认。

- `LINKED`：接口字段可直接覆盖本地字段模型并落地，仍需逐项确认写入。
- `FUZZY`：后端语义或候选不唯一，无法确认应使用哪个接口。
- `TYPE_MISMATCH`：接口字段已明确，但页面显示需求无法直接使用其类型或结构，必须逐字段确认适配规则。
- `MISSING`：后端未提供或 Apifox 找不到可核对的定义；只能保留 Mock，不创建接口。

| # | 页面调用点 | 后端语义 | Apifox 方法/URL | 接口字段覆盖结果 | 差异状态 | 人工决定 | 确认人/时间 |
|---:|---|---|---|---|---|---|---|
| 1 | `{localCallSite}` | `{backendSemantic}` | `{method} {url or —}` | `{覆盖字段/未覆盖字段}` | `LINKED/FUZZY/TYPE_MISMATCH/MISSING` | `确认接入/确认保留 Mock/拒绝/待补充` | `{person/time}` |

### FUZZY 详情

| # | 候选接口与详情证据 | 不一致之处 | 人工决定 | 明确确认的实现范围 |
|---:|---|---|---|---|
| {seq} | `{method} {url}; {summary}` | `{diff}` | `{decision}` | `{method/url/fields or none}` |

### TYPE_MISMATCH 详情

| # | 字段路径 | Apifox 定义（唯一字段源） | 页面显示需求 | 无法直接落地的原因 | 人工处理决定 |
|---:|---|---|---|---|---|
| {seq} | `{fieldPath}` | `{type/schema}` | `{type/schema}` | `{diff}` | `按原定义调整/明确适配规则/保留 Mock` |

未确认时不得填写自动 `Number()`、隐式断言、自动别名或猜测性 mapping。

### MISSING 详情

| # | 页面调用点 | 后端定义是否提供 | 搜索输入/结果 | 结论 |
|---:|---|---|---|---|
| {seq} | `{localCallSite}` | `是/否` | `{query/result}` | `继续使用 Mock` |

## 4. 实现、Mock 覆盖与可选迁移

已确认接口的请求/响应字段覆盖页面本地 Mock 的字段模型和读取点；Mock 只保留给未接入、阻塞或明确确认回退的条目。

| # | API 文件 | 页面引用 | 确认的方法/URL | API 层原样透传 / 业务适配位置 | Mock 结果 | 条目状态 |
|---:|---|---|---|---|---|---|
| {seq} | `{apiPath}` | `{import/call}` | `{method} {url}` | `{是/否；调用方或 utils.ts 路径 / 无}` | `保留/按确认处理` | `success/...` |

- **API 层边界**：`{单 params/data 入参、无字段映射/参数拼装/响应加工；业务适配位置或无}`
- **未自动改名或类型转换说明**：`{none or confirmed rule}`
- **可选迁移**：`{confirmed file list / not performed / blocked}`

## 5. 验证与结论

- **工程命令**：`{命令、覆盖路径、退出结果、失败输出摘要}`（已确认接入条目必须记录只读类型检查；lint 不得带 `--fix`）
- **Chrome DevTools 页面与 Network**：`{URL、method、URL、响应、未确认项未误发、展示、交互、console、截图}`
- **失败修复/回退**：`{items}`
- **状态、阻塞与后续**：按 [结果契约](../transfer-to-vue3/result-contract.md) 填写；列出已接入、继续使用 Mock 和需要后端补充的条目。
