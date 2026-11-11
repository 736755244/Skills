# 前端命名规范

以项目已有规则为准；无既有约定时使用以下一致命名。

| 对象 | 规则 | 示例 |
|---|---|---|
| 路由页面 | `index.vue` 或语义化页面名 | `views/order/list/index.vue` |
| 业务组件 | PascalCase | `OrderFilter.vue` |
| 通用组件 | PascalCase | `PageTable.vue` |
| composable | `useXxx.ts` | `useOrderList.ts` |
| Pinia store | `useXxxStore` | `useOrderStore` |
| API DTO | `XxxDTO` | `OrderListItemDTO` |
| 页面展示模型 | `XxxRow` / `XxxViewModel` | `OrderRow` |
| 查询参数 | `XxxQuery` | `OrderListQuery` |
| 保存输入 | `SaveXxxInput` | `SaveOrderInput` |
| formatter | `formatXxx` | `formatOrderStatus` |
| mapper | `toXxx` | `toOrderRow` |

- 枚举码使用接口契约原值；展示文案使用集中映射。
- boolean 以 `is`、`has`、`can` 开头。
- 异步动作使用动词：`load`、`query`、`save`、`remove`、`export`。
- 不使用 `data1`、`handle`、`utils` 等无法表达职责的名称。