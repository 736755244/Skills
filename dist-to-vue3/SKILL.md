---
name: dist-to-vue3
description: "从 Vue3 dist 生产包解析依赖链并 1:1 还原用户选择的 Vue3 页面、API 类型与无真实调用的预留方法及必要 restore 路由；页面按交付规范产出（列表 prop+formatter、弹窗 form rules 与内聚保存、危险确认按钮）。"
---

# dist-to-vue3

从 Vue3 dist（含压缩 chunk）还原标准 Vue3 `<script setup>` 页面。本 Skill 只处理用户选择的页面及其输入中已有的必要依赖链，不接权限，不自动调用其他 Skill。

转换边界、输出目录、API/路由最小契约、样式范围、工程检查、文件范围和存量代码保护见 [standards.md](../transfer-to-vue3/standards.md)；状态和确认见 [结果契约](../transfer-to-vue3/result-contract.md)；**页面交付细则和 80 条验证规则见 [page-checklist.md](../transfer-to-vue3/page-checklist.md)**。

## 输出位置

```text
.middleproduct/                         # 解压与解析中间产物
src/views/{module}/{page}/              # 页面、components/
src/views/{module}/{page}/mock.ts       # 页面级静态 Mock
src/api/{业务模块}/{resource}.ts        # API 类型 + 无真实调用的预留方法
src/router/modules/restore.ts            # restore 路由定义
src/router/modules/remaining.ts          # 引入并在 catch-all 前展开 restore 路由
```

页面与子组件写入推导出的语义目录，类型与数据访问写入 `src/api/`，页面输出不放在 `src/views/restore/`。同时生成页面级 `mock.ts`（保留源数据供静态查看）。

## 还原流程

1. **分析 dist**：从 `index.html`、入口 chunk 和资源清单提取 `createApp`、路由、符号映射、相关 JS/CSS/资源。大 chunk 按共有规范分片读取。
2. **选择范围**：从 routes、页面 chunk、`router.push` 与 `router-link` 提取可核实的路由/chunk 映射，展示清单让用户选择；只还原所选页面及其必要输入依赖。
3. **逐页还原**：结合入口 `export{...}` 映射解析导入别名；从 chunk 和对应 CSS 还原组件、源固定数据、逻辑、样式和独立子组件。`data-v-hash` 用于定位 scoped 样式，框架壳样式不还原。**同时按 [standards.md](../transfer-to-vue3/standards.md) 落地交付形态**。
4. **API 层**：把页面与弹窗的数据访问抽到 `src/api/{业务模块}/{resource}.ts` —— 仅放接口契约类型与**无真实调用**的预留 API 方法。dist 中可核实的 URL/入参写进预留位注释，无证据留 `TODO`；不得由此推导或发起真实请求。API 文件遵循 [standards.md](../transfer-to-vue3/standards.md) 的 API 最小契约，并按 [page-checklist.md](../transfer-to-vue3/page-checklist.md) E-007、E-008 验收。页面与弹窗只引用 API 层，不建页面级共享状态模块；写操作同样只留预留位。
5. **依赖链检查**：检查输入中已有的跳转目标、子组件 chunk 与资源路径；遗漏会导致空白跳转时，只补齐可从输入确认的依赖页面或组件。
6. **必要路由**：在 `restore.ts` 按业务模块定义路由，并由 `remaining.ts` 在 catch-all 前展开；一级列表是所属 `Layout` 下可见 child，由列表进入的二级详情是同一 `Layout` 下 `hidden: true` 的 `detail/:params` child。详情跳转只在输入证据可核实时使用 `encodeRouteParam({ id, backUrl })`；无证据则记录阻塞，不推导路由协议。
7. **真实验证**：启动开发服务，先做 HTTP 200 冒烟，再用 Chrome DevTools MCP 打开每个页面和可达跳转目标，执行实际存在的点击、填写、Tab、弹窗、筛选、分页和跳转；检查 Console/404、snapshot、screenshot、资源与 API 层 Mock/安全空态。逐项按 [page-checklist.md](../transfer-to-vue3/page-checklist.md) 打钩。除非用户已显式进入 `apifox-link` 确认范围，发现真实请求应记录为边界违规或阻塞，不得继续依赖其结果。失败只依据 dist chunk、CSS、资源和路由证据修复后复测。

## dist 特有质量门禁

- import 别名必须结合入口符号映射解析，不能只凭变量名猜测。
- 每个选中页面的跳转依赖、子组件 chunk 和资源必须完整可达；无法确认时记录阻塞，不推导业务页面。
- Vue 模板遵循工程模板约束：不使用 `<template v-if/v-else-if/v-else>` 承载条件分支，不使用自闭合 `div`；`v-for` 与条件分支保持原始逻辑且避免孤立 `v-else-if`；未使用插槽参数时不声明该参数。
- 不还原侧边栏、topbar、登录等框架布局，使用目标项目已有布局。
- 列表骨架同样使用目标项目已有的全局版式层与 `SearchForm`（见 checklist S-009 ~ S-011）：源里的搜索卡 + 列表卡两个容器合并为一个 `ContentWrap`，源里的顶部标题卡不还原为独立区域、其按钮落到 `.table-toolbar`；源没有搜索条件时不硬造 `SearchForm`，区域顺序仍与源一致。
- 交付规范与共有规范冲突时以交付规范为准（如源强调样式、源时间格式），并在结果文档逐条记录偏差。

## 结果

输出 `.middleproduct/dist-to-vue3-result.md`，遵循 [结果契约](../transfer-to-vue3/result-contract.md)，额外记录 chunk → 页面 → 路由映射、选择的依赖链、HTTP 200、路由可达性、逐页 Chrome 证据，以及适用 checklist ID 的偏差与预留接口清单。权限、清理与 Playwright 仅作为用户可选后续动作。
