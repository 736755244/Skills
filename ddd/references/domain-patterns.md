# 复杂前端流程模式

设计模式只用于降低真实复杂度，不应取代清晰的 Vue 代码。

## 策略映射

当同一交互按状态、类型或配置采用多种可扩展规则时，用映射表或策略函数替代长 `if/else`。

```ts
type ExportType = 'csv' | 'xlsx'

const exporters: Record<ExportType, (rows: OrderRow[]) => void> = {
    csv: exportCsv,
    xlsx: exportXlsx,
}

export function exportOrders(type: ExportType, rows: OrderRow[]) {
    exporters[type](rows)
}
```

## 管道式校验

当表单或批量操作有多个独立规则时，将每个规则写成可测试函数，并按顺序执行。规则失败应返回稳定错误信息，UI 决定如何展示。

## 状态机

当页面存在明确且互斥的状态流转，如草稿、提交中、成功、失败、已取消，可使用联合类型或状态机表达允许的转换。不要用多个互相冲突的 boolean 标记状态。

## 选择原则

- 条件少、路径固定：直接实现。
- 可扩展分支：策略函数或映射。
- 多个独立校验：校验管道。
- 明确状态转移：状态机或联合类型。

先写清楚输入、输出和失败路径，再决定是否需要模式。