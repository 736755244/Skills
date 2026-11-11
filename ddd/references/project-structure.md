# Vue3 前端模块结构

## 以业务功能组织

优先将页面、组件、格式化逻辑和 Mock 按业务功能靠近放置。接口 `type` / `interface` 与请求方法统一定义在 `src/api/...`，页面和组件只导入使用；不要在页面目录额外创建 `types.ts`。

```text
src/
├── views/
│   └── order/
│       └── list/
│           ├── index.vue            # 路由页面
│           ├── mock.ts              # 未接入 API 时的本地回退
│           ├── utils.ts             # 页面邻近的 formatter / 展示转换（按需）
│           ├── useOrderList.ts      # 页面逻辑（可选）
│           └── components/
│               └── OrderDialog.vue
├── api/
│   └── order/
│       └── index.ts                 # 集中定义接口 type / interface 与方法
├── components/                       # 跨业务可复用 UI 组件
├── composables/                      # 跨页面可复用逻辑
├── stores/                           # 跨页面共享状态
├── router/
│   └── modules/
├── shared/                           # 通用工具、常量与组件
└── main.ts
```

对于业务复杂或长期维护的模块，可升级为 feature 结构；但接口类型仍保留在 `src/api/`：

```text
modules/<feature>/
├── application/      # 查询、保存、提交等用例编排
├── presentation/     # 页面、业务组件、composable、store
├── utils.ts          # 页面展示转换与纯规则（按需）
└── mock.ts           # 未接入 API 时的回退
```

## 文件职责

- `index.vue`：组装页面布局、路由参数、页面级事件；不堆积复杂转换和请求细节。
- `components/`：业务组件只接收明确 props、emit 明确事件；通用组件不携带领域名称。
- `useXxx.ts`：封装可复用的加载、筛选、保存和状态逻辑；返回状态和操作，不直接操作页面 DOM。
- `src/api/...`：只包含契约 `type` / `interface`、必要请求封装 import、API 方法和证据/TODO 注释；接口层不改字段、不解包、不映射、不格式化、不补默认值。
- `utils.ts`：调用方或页面邻近的字段展示转换、formatter、枚举文案等纯逻辑。
- `mock.ts`：仅服务未接入接口的页面回退；接口确认接入后由真实字段覆盖。
- `router/modules/`：集中维护路由，不让页面自行注册路由。

## 依赖约束

- 业务页面可以使用同模块组件、composable、`utils.ts` 与 `src/api/...` 定义的契约。
- 共享组件不应反向依赖具体业务页面。
- 不因方便将所有组件、formatter、store 放入全局目录，导致业务边界消失。
- 复用既有目录约定优先于本参考中的目录命名。