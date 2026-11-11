# 页面、组件与 Composable 设计

## 页面职责

路由页面负责布局、路由参数和业务组件组合。页面中可以保留简单的 `ref`、事件处理和页面配置；当请求编排、筛选条件或表单流程复杂时，移入 composable 或用例函数。

## 组件边界

- **页面组件**：路由级容器，负责组合。
- **业务组件**：表达某个业务模块的表格、筛选区、表单、详情区或弹窗。
- **通用组件**：跨领域复用，不应包含订单、用户等具体术语。

组件 API 应明确：使用 props 输入数据和配置，使用 emits 抛出用户意图。不要让子组件通过注入、全局变量或直接调用请求绕过页面的数据边界。

## Composable

Composable 用于复用响应式逻辑，例如列表加载、分页筛选、表单编辑或提交状态。

```ts
export function useOrderList(repository: OrderRepository) {
    const loading = ref(false)
    const rows = ref<OrderRow[]>([])
    const query = reactive<OrderListQuery>({ page: 1, pageSize: 20 })

    async function load() {
        loading.value = true
        try {
            const result = await repository.list(query)
            rows.value = result.items
        } finally {
            loading.value = false
        }
    }

    return { loading, rows, query, load }
}
```

Composable 不应成为无边界的“万能工具箱”：仅抽取具有明确复用价值或使页面明显简化的逻辑。

## 表格和表单

- 表格列定义、枚举标签和 formatter 应与表格就近放置。
- 弹窗表单保留完整的 `form`、`rules`、重置与保存逻辑；保存必须防重复提交。
- loading、空态、错误态和成功反馈是交互流程的一部分，不可只实现成功路径。
- 详情、导出和跳转行为遵循项目已有路由与页面约定。