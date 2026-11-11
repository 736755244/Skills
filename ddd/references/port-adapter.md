# API、Mock 与页面转换边界

## 契约集中定义

接口 `type` / `interface` 与请求方法统一定义在 `src/api/...`。后端接口定义是字段、类型、分页与错误语义的唯一契约；页面实现不得根据视觉稿或本地 Mock 臆造真实字段。

API 文件仅包含契约类型、必要请求封装 import、API 方法及证据/TODO 注释：

- 每个方法仅接受一个业务入参：GET 使用 `params`，POST/PUT/DELETE 使用 `data`，并原样透传。
- 不改字段、不拼请求体、不做类型转换、默认值或业务校验。
- 不解包、映射、格式化或补充响应；这些工作由调用方或页面邻近的 `utils.ts` 完成。

## Mock 回退

尚未确认或接入真实 API 时，可以在页面目录保留 `mock.ts`。真实接口接入后，真实字段覆盖同名 Mock 字段；Mock 仅作为显式未接入场景的回退。

真实接口接入必须由用户明确调用 `apifox-link` 并确认范围，API 文件存在不等于请求授权。

## 页面邻近转换

页面需要格式化枚举、日期、金额，或适配表格展示时，使用同级 `utils.ts`：

```ts
import type { OrderListItem } from '@/api/order'

export function formatOrderStatus(status: OrderListItem['status']) {
    return status === 'PAID' ? '已支付' : '待支付'
}
```

局部 UI 状态类型可以留在组件内；不要创建页面本地 `types.ts`。当转换逻辑被多个模块复用时，再提取到已有的共享工具目录。