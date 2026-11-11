# 业务服务与用例函数

业务服务是与 Vue 组件无关、可复用和可测试的前端流程函数。它适合承载多步骤请求、业务规则组合或跨页面共享操作；简单页面逻辑无需额外创建服务。

```ts
export async function submitOrder(
    repository: OrderRepository,
    input: SaveOrderInput,
): Promise<void> {
    validateOrderInput(input)
    await repository.save(input)
}
```

## 边界

- 服务依赖 repository、纯函数和类型，不依赖组件实例或 DOM。
- 服务返回数据或抛出/返回可识别错误；提示消息由页面、composable 或统一交互层决定。
- 有多步骤操作时，按输入校验、请求执行、结果映射的顺序拆分，便于独立测试。

将它放入 feature 的 `application/`，或在较小项目中放入页面同级的 `useXxx.ts`。