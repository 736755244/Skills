# 数据访问边界

在前端中，Repository 表示页面或用例需要的数据能力，而不是数据库访问层。它的实现可以是已确认的 HTTP API，也可以是在未接入接口时使用的 Mock。

```ts
export interface UserRepository {
    list(query: UserListQuery): Promise<PageResult<UserRow>>
    getById(id: string): Promise<UserDetail>
}
```

## 规则

- 接口只暴露业务所需能力，不泄漏 HTTP 方法、URL 或原始响应结构。
- API 实现处理请求和 DTO 映射；Mock 实现提供等价的返回形状。
- 不应为了单个简单请求强制创建 Repository；当数据源可替换、操作被复用或需要隔离 DTO 时再使用。
- 真实 API 接入仅在用户明确调用接口接入流程后进行。