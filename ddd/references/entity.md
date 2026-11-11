# 页面模型与纯规则

接口类型统一定义在 `src/api/...`，页面与组件仅导入使用。前端业务规则不要求额外创建本地类型文件：简单规则可留在组件或页面邻近的 `utils.ts`；具备跨模块复用价值时再放入项目已有的共享工具目录。

## 页面邻近规则

将不依赖 Vue、路由和 HTTP 的展示判断集中为纯函数：状态是否可操作、枚举文案、金额/日期格式化、输入规范化等。它们可独立测试，也避免模板中堆积多层条件表达式。

```ts
import type { OrderDetail } from '@/api/order'

export function canCancel(order: OrderDetail): boolean {
    return order.status === 'PENDING'
}
```

不要为普通接口字段额外复制 `interface`、创建 `types.ts`，或构造不必要的 class。只有项目既有架构要求且确有跨模块复用价值时，才抽取共享类型或规则。