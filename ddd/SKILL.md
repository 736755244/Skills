---
name: frontend-architecture
version: 1.0.0
description: "Vue3 + TypeScript 前端架构技能。用于规划业务模块边界、页面与组件职责、状态编排、接口适配、Mock 回退、路由权限及测试策略。"
triggers:
  - "前端架构"
  - "Vue3 架构"
  - "前端模块划分"
  - "组件边界"
  - "状态管理"
  - "Pinia"
  - "composable"
  - "前端领域建模"
  - "接口适配"
---

# Vue3 前端架构

为 Vue3 + TypeScript 项目设计可维护的业务模块结构。保留领域建模的边界、用例与依赖倒置思想，但不套用服务端 Java、数据库或部署分层。

## 先确认项目约定

实现前必须读取现有目录、路由、组件库、状态管理、接口层和校验命令。当前技能集的既定边界优先：

- 页面转换产物遵循 [../transfer-to-vue3/standards.md](../transfer-to-vue3/standards.md)。
- 接口字段以已确认的后端契约为唯一来源；本地 Mock 只用于未对接时的回退。
- API 对接、权限写入和清理操作仅由对应 Skill 经用户明确调用后执行。
- 页面、组件和状态设计应与已有实现保持一致，不为简单页面引入额外抽象。

## 分层与依赖方向

```text
页面 / 业务组件 → composable / store / 用例 → 前端领域模型 → API 或 Mock 适配器
应用组装 → 路由、Pinia、全局插件与模块
```

| 层 | 主要职责 | 不应承担的职责 |
|---|---|---|
| 页面与业务组件 | 渲染、用户交互、局部 UI 状态、调用页面逻辑 | 直接拼接接口字段、散落复杂业务规则 |
| composable / store / 用例 | 加载、提交、列表筛选、跨组件状态、异步状态编排 | 直接操作 DOM、承载无关展示细节 |
| 前端领域模型 | TypeScript 类型、枚举、格式化与可测试的业务规则 | HTTP、路由和组件框架调用 |
| API / Mock 适配器 | 请求、响应映射、错误归一化、未接入时的 Mock 回退 | UI 判断与页面状态控制 |
| 应用组装 | 路由、Pinia、插件、全局配置 | 具体业务流程 |

依赖只能由外向内。组件不应直接依赖未经映射的 API 响应，也不应绕过既有 API/Mock 边界。

## 推荐的模块结构

以业务功能为边界组织；实际目录以项目已有约定为准：

```text
src/
├── app/                         # 应用组装：路由、Pinia、插件、全局配置
├── modules/
│   └── <feature>/
│       ├── domain/              # 页面邻近的 formatter 与纯规则（按需）
│       ├── application/         # 用例、查询/提交编排、异步状态（按需）
│       ├── infrastructure/
│       │   ├── api/             # 调用已集中定义于 src/api 的类型和方法
│       │   └── mock/            # 未接入接口时的本地数据回退
│       └── presentation/
│           ├── pages/           # 路由级页面
│           ├── components/      # 此业务模块内部复用组件
│           ├── composables/     # 页面逻辑复用
│           └── stores/          # 跨页面或跨组件状态
├── shared/                      # 跨模块通用组件、工具、类型
└── main.ts
```

不必为所有功能创建完整层级。静态展示页或简单 CRUD 可维持页面目录下的 `index.vue`、`mock.ts`、局部组件；当页面逻辑、状态或数据映射开始复用时再抽取。

## 实现流程

1. **确定边界**：按业务能力而非纯技术目录划分模块；先寻找可扩展的现有页面、组件和 composable。
2. **定义前端模型**：接口 `type` / `interface` 统一定义在 `src/api/...`；组件只导入使用。局部 UI 状态类型可保留在组件内，格式化与展示转换放页面邻近的 `utils.ts` 或 formatter。
3. **编排页面用例**：明确列表加载、筛选、分页、保存、删除、导出等输入、输出、loading、empty、error 状态。
4. **划分 UI 职责**：页面负责组合和路由参数；业务组件负责特定交互；通用组件不依赖具体领域术语。
5. **管理状态**：局部状态放组件；同页复用逻辑放 composable；跨页面或跨组件的业务状态才使用 Pinia。
6. **接入数据边界**：接口已明确确认时按契约接入；否则保留类型和调用入口，并由 Mock 提供回退数据。
7. **验证**：执行项目已有类型检查与浏览器验证。涉及可复跑 UI 回归时使用 `ui-verify-playwright`。

## 核心规则

- **契约优先**：不得臆造后端字段；接口定义覆盖本地 Mock 的同名字段。
- **映射集中**：接口层只保留契约类型与请求方法，不改字段、不做类型转换；页面展示转换放调用方或页面邻近的 `utils.ts` / formatter，避免散落在模板中。
- **状态完整**：异步操作必须处理 loading、成功、空态与失败；保存操作防止重复提交。
- **组件内聚**：表格列和 formatter、弹窗表单和校验/保存逻辑保持就近组织，遵循现有页面模式。
- **路由与权限**：前端路由守卫、菜单和按钮可控制体验，不构成安全鉴权；真实权限由服务端执行。
- **适度抽象**：可复用行为再抽 composable 或共享组件；不要为一次性展示逻辑创建 store、抽象仓储或复杂模式。

## 参考索引

| 主题 | 文档 |
|---|---|
| 原则与依赖方向 | [references/architecture.md](references/architecture.md) |
| Vue3 模块结构 | [references/project-structure.md](references/project-structure.md) |
| 类型与命名 | [references/naming.md](references/naming.md) |
| 前端模型与映射 | [references/entity.md](references/entity.md) / [references/value-object.md](references/value-object.md) |
| 用例与状态 | [references/case-layer.md](references/case-layer.md) / [references/domain-service.md](references/domain-service.md) |
| API、Mock 与适配器 | [references/repository.md](references/repository.md) / [references/port-adapter.md](references/port-adapter.md) |
| 页面、组件与 composable | [references/trigger-layer.md](references/trigger-layer.md) / [references/domain-design-guide.md](references/domain-design-guide.md) |
| 复杂流程与状态模式 | [references/domain-patterns.md](references/domain-patterns.md) |
| 测试与验证 | [references/infrastructure-patterns.md](references/infrastructure-patterns.md) |