# 前端用例与状态编排

用例描述用户要完成的动作，如加载列表、筛选、保存、删除、导出或查看详情。它协调数据访问与状态，不负责具体模板渲染。

## 何时使用 composable、store 或用例函数

| 情况 | 建议 |
|---|---|
| 单组件临时状态 | 组件内 `ref` / `reactive` |
| 同页多组件共享流程 | composable |
| 跨页面共享、缓存或统一更新 | Pinia store |
| 多接口、多步骤、可独立测试的动作 | 用例函数 |

## 异步状态

每个用例至少明确：输入、loading、成功数据、空态、错误以及重新执行方式。保存操作需要避免连续点击产生重复请求。

```ts
const saving = ref(false)

async function save(input: SaveOrderInput) {
    if (saving.value) return
    saving.value = true
    try {
        await repository.save(input)
    } finally {
        saving.value = false
    }
}
```

复杂跨页面流程应将步骤和失败处理显式写出，不要把多个请求和条件判断堆在 `index.vue` 的事件函数中。