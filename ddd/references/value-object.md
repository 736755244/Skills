# 枚举、格式化与页面转换

接口枚举类型统一从 `src/api/...` 导入。展示文案、标签类型、日期金额 formatter 等转换放调用方或页面邻近的 `utils.ts`，不写入 API 文件，也不创建页面本地 `types.ts`。

```ts
import type { OrderStatus } from '@/api/order'

const orderStatusLabel: Record<OrderStatus, string> = {
    PENDING: '待支付',
    PAID: '已支付',
    CANCELLED: '已取消',
}

export function formatOrderStatus(status: OrderStatus): string {
    return orderStatusLabel[status]
}
```

## 规则

- 枚举码以接口契约为准；展示文案集中映射，避免在多个模板复制条件判断。
- API 返回的空值、无效值和旧枚举在调用方或 `utils.ts` 中处理，不让展示组件承担协议兼容。
- 局部 UI 状态类型可保留在 `.vue` 文件内；确有跨页面复用的类型遵循项目既有的 `src/api/` 或共享目录约定。