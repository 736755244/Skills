# Vue3 前端架构技能

> 面向 Vue3 + TypeScript 项目的业务模块设计、页面组织、状态编排与数据边界规范。

本技能将领域建模中“业务边界、用例、依赖倒置”的思想应用于前端：页面不直接耦合接口细节，复杂交互不散落在组件中。接口契约类型集中定义在 `src/api/...`，页面展示转换在调用方或页面邻近的 `utils.ts` / formatter 中完成。

它服务于当前 Vue3 转换技能集，不包含 Java、Spring、数据库、中间件或服务端部署内容。

## 适用场景

- 规划或重构 Vue3 页面、业务模块与组件边界；
- 设计 Pinia 状态、composable 与异步用例；
- 规范 `src/api/` 下的接口 `type` / `interface`、页面邻近的 formatter 与 Mock 回退；
- 拆分过于庞大的页面逻辑，避免表单、表格、请求和业务规则相互缠绕；
- 设计路由、菜单和前端权限呈现边界；
- 为复杂流程补充单元、组件或浏览器验证。

简单静态页面或一次性展示逻辑无需强行使用完整分层。优先使用项目现有目录与组件模式。

## 依赖方向

```text
Page / Component → Composable / Store / Use Case → Domain Model → API / Mock Adapter
App → Router / Pinia / Plugins / Modules
```

| 区域 | 职责 |
|---|---|
| Page / Component | 页面渲染、交互事件和局部 UI 状态 |
| Composable / Store / Use Case | 异步加载、提交、筛选、跨组件状态和业务流程编排 |
| Domain Model | TypeScript 类型、枚举、业务规则、格式化定义 |
| API / Mock Adapter | 调用集中定义的 API、提供本地回退数据 | 变更接口字段、页面展示转换 |
| App | 路由、状态容器、插件与全局配置组装 |

## 推荐模块结构

```text
src/
├── app/
├── modules/
│   └── <feature>/
│       ├── domain/              # 页面邻近的纯规则与 formatter（按需）
│       ├── application/         # 用例与异步状态（按需）
│       ├── infrastructure/
│       │   ├── api/             # 使用 src/api 中集中定义的类型和方法
│       │   └── mock/            # 未接入接口时的本地回退
│       └── presentation/
│           ├── pages/
│           ├── components/
│           ├── composables/
│           └── stores/
├── shared/
└── main.ts
```

若当前项目采用 `src/views/`、页面目录内 `mock.ts` 或集中路由目录，继续遵循该约定。上述结构用于识别职责边界，不要求机械迁移目录。

## 重要约束

- 后端已提供的接口定义是字段唯一契约；Mock 仅作为未对接时的回退。
- 真实接口接入只在用户单独明确调用 `apifox-link` 后进行。
- 路由、菜单和按钮权限只负责前端呈现，不能替代服务端授权。
- 接口类型统一定义于 `src/api/...`，组件仅导入使用；局部 UI 状态类型可留在组件内。接口层不得改字段、映射响应、补默认值或承担页面业务转换。
- 异步行为应具备 loading、empty、error、success 状态；表单保存应避免重复触发。
- 涉及 UI 验证时，使用当前技能集定义的 Chrome 或 Playwright 验证流程。

## 参考文档

| 主题 | 文档 |
|---|---|
| 架构原则 | [references/architecture.md](references/architecture.md) |
| 模块结构 | [references/project-structure.md](references/project-structure.md) |
| API 与 Mock 适配 | [references/port-adapter.md](references/port-adapter.md) |
| 页面、组件与 composable | [references/domain-design-guide.md](references/domain-design-guide.md) |
| 状态与用例编排 | [references/case-layer.md](references/case-layer.md) |
| 类型、格式化与枚举 | [references/entity.md](references/entity.md) / [references/value-object.md](references/value-object.md) |
| 模式与测试 | [references/domain-patterns.md](references/domain-patterns.md) / [references/infrastructure-patterns.md](references/infrastructure-patterns.md) |