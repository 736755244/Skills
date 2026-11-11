# Element Plus 控件定位速查（本仓库）

## 通用优先级

优先使用 role → placeholder → label → testid；元素语义不足时，先用 `dialog`、`row`、搜索表单等上下文收窄，最后才建议修改源码补 `data-testid`。断言使用自动等待，不使用 `waitForTimeout`。

## 输入框与按钮

```ts
page.getByPlaceholder('请输入用户名')
page.getByRole('button', { name: '登录' })
```

图标按钮优先用 `aria-label` 或 `title`。

## Element Plus select

本仓库使用 Element Plus 2.11。新版 select 的 placeholder 会覆盖 combobox input，直接点击 `getByRole('combobox')` 可能被 pointer-events 拦截，应点击 `.el-select__wrapper`；多个 select 时收窄到搜索区容器 `.search-form`（全局 `SearchForm` 组件的根类）：

```ts
const searchForm = page.locator('.search-form')
await searchForm.locator('.el-select').filter({ hasText: '直播分组' }).locator('.el-select__wrapper').click()
await page.getByRole('option', { name: '2-1专属', exact: true }).click()
```

**折叠陷阱**：`SearchForm` 默认收起，超出首行的条件是 `display: none` 而非未渲染，`getByLabel` 会命中但自动等待可见一直超时。填这类条件前先点「更多筛选」展开（展开后文案变「收起」，可据此断言切换生效）；只断言首行可见条件时则不需要。

```ts
const more = searchForm.getByRole('button', { name: '更多筛选' })
if (await more.isVisible()) await more.click()
```

## 复选、单选、Tab、菜单

```ts
page.getByRole('checkbox', { name: '记住我' })
page.getByRole('radio', { name: 'xxx' })
page.getByRole('tab', { name: '人工会话' })
page.getByText('会话记录').click()
```

## Dialog

```ts
const dialog = page.getByRole('dialog')
await expect(dialog).toBeVisible()
await dialog.getByRole('button', { name: '确定' }).click()
```

`com-dialog` 可能没有 `.el-dialog__headerbtn`，本仓库关闭图标是 header 内最后一个 `i.is-hover`：

```ts
await dialog.locator('.el-dialog__header i.is-hover').last().click()
```

## 表格

固定列会克隆 DOM，避免直接用全页面 `getByRole('row')` 计数。使用主表体和主表头：

```ts
const rows = page.locator('.el-table__body-wrapper .el-table__row')
const header = page.locator('.el-table__header-wrapper')
const row = rows.filter({ hasText: '目标数据' })
await row.getByRole('button', { name: '编辑' }).click()
```

空态使用主表体 `toHaveCount(0)`，再断言 `getByText('暂无数据')` 可见。

## 列表版式与间距

标准列表页骨架（`.list-page` → `.page-body` → `.search-form` / `.table-toolbar` / `.table-inner` / `.pagination-wrap`）的间距由全局层给，回归时用计算样式核对而不是截图肉眼比：

```ts
const gap = (sel: string, prop: 'marginTop' | 'marginBottom') =>
  page.locator(sel).first().evaluate((el, p) => getComputedStyle(el)[p as CSSPropertiesKey], prop)

await expect(gap('.search-form', 'marginBottom')).resolves.toBe('40px') // 搜索区 ↔ 列表区
await expect(gap('.table-toolbar', 'marginBottom')).resolves.toBe('24px') // 操作按钮 ↔ 表格
await expect(gap('.pagination-wrap', 'marginTop')).resolves.toBe('30px') // 表格 ↔ 分页
```

条件行间距 12px、分页到 wrap 底部 20px 分别来自 `.search-form` 的 `gap` 与 `ContentWrap` 内边距；页面若不带 `.list-page`（双面板工作台、卡片网格），这些数值由页内注释标明的局部复制给出，断言前先确认页面属于哪种。
