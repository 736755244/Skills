# AI 编码技能集

提供 Vue3 页面转换、代码地图生成与 DDD 六边形架构设计等独立技能。各技能按自身边界执行，不自动触发其他技能或外部副作用。

## 总原则

- 每个 Skill 独立执行；完成后停止，不自动串联下一步。
- 转换/还原只处理源文件已有的页面表现和交互，不推导 API、权限或真实写操作。
- 真实页面验证与静态检查分开记录；无法取得真实浏览器证据时标记为未验证或阻塞。
- 转换边界、输出目录、实现基线、API/路由最小契约与工程校验见 [standards.md](transfer-to-vue3/standards.md)；逐页 UI/交互、导出、API 接线、详情跳转的详细实现与验收见 [page-checklist.md](transfer-to-vue3/page-checklist.md)；确认门禁、结果状态和存量代码保护见 [result-contract.md](transfer-to-vue3/result-contract.md)。

## Skill 清单

| Skill | 职责 | 入口 |
|---|---|---|
| `transfer-to-vue3` | 获取源码、判断 HTML/dist 类型并分派 | `/transfer-to-vue3` |
| `html-split` | 拆分大型 HTML，生成页面清单并验证原型 | `/html-split` |
| `html-to-vue3` | 将 HTML 页面转换为 Vue、组件和 Mock | `/html-to-vue3` |
| `dist-to-vue3` | 解析 dist 并 1:1 还原 Vue 页面 | `/dist-to-vue3` |
| `ui-verify-playwright` | 使用 Playwright Chrome 做可复跑 UI 回归 | `/ui-verify-playwright` |
| `apifox-link` | 按后端契约核对并逐条确认 API 对接 | `/apifox-link` |
| `clean-build-vue3` | 按确认范围清理转换产物 | `/clean-build-vue3` |
| `coding-map` | 将迭代、需求或架构整理为可交互代码地图 | `/coding-map` |
| `frontend-architecture` | Vue3 + TypeScript 的模块、组件、状态与数据边界设计 | `/frontend-architecture` |

## 职责边界

- `transfer-to-vue3` 只获取、整理、识别和分派，不转换页面。
- `html-split` 只处理原始 HTML 拆分，不生成 Vue。
- `html-to-vue3` 不创建 API 文件；`dist-to-vue3` 仅生成无真实调用的类型/预留 API；真实接口接入仍只能由用户显式调用 `apifox-link` 后进行。
- `apifox-link`、`clean-build-vue3` 必须由用户单独、明确调用；未收到明确调用指令时，任何 Skill 都不得触发 Apifox MCP、API 对接、权限写入或清理操作。
- 详情页采用 `detail/:params` 编码路径参数；编码仅用于序列化与降低可读性，不是敏感数据保护或鉴权机制，详见 [standards.md](transfer-to-vue3/standards.md)。
- 接口契约类型（请求入参、响应体、行/项、字典枚举）只定义在 `src/api/**`，同一文件固定三段顺序：`import` → 类型区（全部 `type` / `interface` 在上）→ 接口方法区（`export const` 在下）；方法签名和 `request.get<...>` 不留匿名对象字面量。组件本地类型（`Props` / `Emits`、弹窗 `open()` 参数、composable 入参与返回、`Pick`/`Omit` 纯 UI 类型）留在组件内，见 checklist E-009。
- `ui-verify-playwright` 使用 Playwright Chrome 做可复跑 E2E；转换类 Skill 的页面证据使用 Chrome DevTools MCP。两者不能互相替代。

## 目录约定

- HTML 页面：`src/views/prototype/{name}/`
- dist 页面：按推导的语义路径 `src/views/{业务模块}/{页面}/`（如 `src/views/order/lead/`）；只有路由统一定义在 `src/router/modules/restore.ts`
- 页面 Mock：对应页面目录下的 `mock.ts`
- 中间产物：`.middleproduct/`，不写入 `src/`、不提交
- API 和权限文件：只有用户单独确认相应 Skill 后才可能修改

## 结果真实性

每个 Skill 按 [结果契约](transfer-to-vue3/result-contract.md) 记录输入、实际范围、产物、命令/浏览器动作、验证证据、失败修复、人工确认、阻塞和后续。确认区分显式调用、文件范围和外部副作用三类；范围变化后必须重新确认。转换的 Chrome DevTools MCP 与 E2E 的 Playwright Chrome 证据不能互相替代，`ts:check` 或 `lint` 也不能替代真实浏览器验证。
