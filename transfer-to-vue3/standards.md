---
title: "Vue3 转换共用规范（边界、实现基线与验证）"
date: 2026-09-17
category: reference
module: "transfer-to-vue3 / html-to-vue3 / dist-to-vue3"
tags:
  - vue3-conversion
  - prototype
  - dist-restore
  - page-delivery
---

# Vue3 转换共用规范

本文件定义跨转换路径的边界、产物结构、实现基线、API/路由最小契约和工程验证。

- 逐页 UI、交互、导出、API 接线与详情跳转的详细实现和验收，以 [page-checklist.md](./page-checklist.md) 为唯一来源。
- 确认门禁、文件范围保护和结果记录，以 [result-contract.md](./result-contract.md) 为唯一来源。
- 源证据、安全边界和用户明确授权优先于交付参考；除 checklist 明确规定或用户明确授权的统一交付偏差外，不得扩展业务、数据、权限或流程。

---

## 一、不可违反的转换边界

1. **忠实还原**：字段、表头、固定数据、DOM/区域顺序、样式、初始化与交互均以输入为准；禁止脑补、合理补全或顺手修复。
2. **完整提取**：脚本、数据、样式、初始化和必要子组件不得遗漏。
3. **阶段隔离**：转换只还原页面；不得推测真实 API、接口契约、权限或业务流程。统一 UI 仅能做等价组件和已授权的表现层适配。
4. **可验证交付**：产物必须遵守固定目录，并使用 Chrome DevTools MCP 对照原始输入与目标 Vue 页面。

---

## 二、输出位置与变更范围

> **强制**：转换产物必须写入项目 `src/`；`.middleproduct/` 仅存放结果文件和解压/解析中间产物，绝不写入代码。

| 产物 | 位置 |
|---|---|
| 页面组件 | `src/views/prototype/{name}/index.vue` 或 `src/views/{业务模块}/{页面}/index.vue` |
| 页面子组件 | 页面同级的 `components/*.vue` |
| Mock 数据 | 页面目录下 `{name}/mock.ts` |
| API 类型与预留位 | `src/api/{业务模块}/{resource}.ts`（`dist-to-vue3` 阶段生成；契约类型集中在文件上部，接口方法在下部） |
| prototype 路由 | `src/router/modules/remaining.ts` 末尾追加 |
| restore 路由 | 定义在 `src/router/modules/restore.ts`，由 `remaining.ts` 在 catch-all 前展开 |

- prototype / restore 一级列表必须可见；详情可 `hidden: true`，但必须可达。
- 文件范围确认、存量保护、删除和全库/目录级/批量操作限制，遵循 [result-contract.md](./result-contract.md)。

---

## 三、Vue 实现与样式基线

- 使用 `<script setup>`、Composition API 与 Element Plus 语义组件；HTML 控件按等价 Element Plus 组件转换。
- DOM 事件和直接 DOM 操作改为响应式状态、Vue 事件和声明式渲染。
- 弹窗使用项目全局 `Dialog`，以 `ref` + `open()` + `defineExpose` 暴露命令式入口；尺寸口径固定下来：宽度只取 `600 / 900 / 1200 / 1400` 四档，高度由内容根节点给唯一一次 `calc(100vh - 300px)` 配 `:scroll="false"`，禁止双层滚动与页内自定义高度；细节见 checklist B-007、B-013。
- 全局 `Dialog` 的 class 落在 `.el-dialog` **同一个元素**上。在 `Dialog.vue` 里给自身加样式必须写 `&.#{$elNamespace}-dialog`；写成 `.com-dialog .el-dialog` 是后代选择器，命中 0，规则静默失效。`Dialog.vue` 里既有的 `.el-dialog { margin: 0 !important; … }` 块就是这种死代码，所以弹窗现在靠 `top` prop 的 `8vh` 定位、**垂直不居中**；同文件那条 `.com-dialog .el-overlay-dialog { display: flex; align-items: center }` 也是反向命中（overlay 是 `.com-dialog` 的祖先），一并算死代码。要改垂直居中，得先确认全部弹窗的位置变化可接受，再动这两块。
- 未使用的全局组件连同首页挂载一起删除：`App.vue` 里的标签与 `import` 一并去掉；`src/types/auto-components.d.ts` 由 `unplugin-vue-components` 生成，不手改（删了也会重新长出来）。
- Tab 切换不得读取、写入或删除 URL 的 path/hash/query，不得调用 `router.push` / `router.replace`。
- 页面样式写在当前 SFC 的 `<style lang="scss" scoped>`；保留源页面使用的类名、DOM 层级和区域顺序；禁止创建或修改全局 CSS。
- **同一控件在两个页面要「一样」时，抽共享组件，不复制样式**：把形态与样式搬进同模块 `components/` 下的一个小组件（只接受数据 + 一个 `change` 事件），两个页面都挂它；被搬空的那页要顺手删掉自己那份样式块和注释掉的旧实现（如整块 `<!-- <el-button v-for …> -->`）。复制过去的那份 CSS 会在两处各自漂移。转换/还原不留注释掉的旧实现。
- 转换阶段 API 请求只能替换为 Mock 数据读取或安全空函数。逐页实现与验收见 [page-checklist.md](./page-checklist.md)。

### 列表页统一版式（2026-11-04 起，目标仓库已内置全局层）

目标仓库 `src/styles/index.scss` 的 `.list-page` 层与全局组件 `SearchForm` 已承担列表版式。**页面只挂类名，不得在页内重复声明这些间距，也不得改全局层**（全局 `.list-page .x` 特异性 0,2,0，会被页内 `.root .x[data-v]` 0,3,0 压掉，所以页内重复声明只会造成分叉）。

```html
<div class="xxx-page list-page">
  <ContentWrap class="page-body">
    <SearchForm @search="handleQuery" @reset="resetQuery">
      <el-form-item prop="kw"><SearchTypeInput v-model="queryParams.kw" label="关键字" /></el-form-item>
    </SearchForm>
    <div class="table-toolbar"><!-- 操作按钮，批量/更多放最后 --></div>
    <div class="table-inner"><el-table height="100%">…</el-table></div>
    <div class="pagination-wrap"><Pagination … /></div>
  </ContentWrap>
</div>
```

| 间距 | 数值 | 由谁给 |
| --- | --- | --- |
| 条件行 ↔ 条件行 | 12px | `SearchForm` 的 `gap: 12px 15px` |
| 搜索区 ↔ 列表区 | 40px | `SearchForm` 的 `margin-bottom` |
| 操作按钮 ↔ 表格 | 24px | `.list-page .table-toolbar` |
| 表格 ↔ 分页 | 30px | `.list-page .pagination-wrap` |
| 分页 ↔ wrap 底部 | 20px | `ContentWrap` 内边距 |
| 提示 / 汇总块 ↔ 下一块 | 24px | `.list-page .page-tip` / `.page-summary` |
| 页面 ↔ 右侧区域 | 14px | `--app-content-padding` |

- 操作行里**只有首位按钮用 `type="primary"`（实心）**，其余按钮不设 `type`、不加 `plain`，走 Element Plus 默认线条（白底灰边）；`danger` / `success` / `warning` 一类彩色按钮不落在操作行，批量删除也是默认线条。首位若是「返回 / 取消」这类退出型按钮，主按钮顺延到下一个动作按钮，不把退出染成实心。操作行**只有一个按钮时它就是首位**——「只有一个导出」「只有导入 + 导出」这类形状不是例外，首位那个要实心（第 38 轮据此修掉 3 处：`order/delivery` 两个页签的「导出订单」、`student/course-detail` 的「导入」）。入口权限用 `v-if` 挂在首位按钮上时（全仓 96 处操作行里有 82 处），无权限账号看到的首位会顺延到下一个线条按钮，这是预期形状，不要为此把第二个按钮也染成实心。
- 操作行内部顺序固定：**新增 / 创建 / 绑定类主动作 → 其他动作（同步、导入、导出）→ 批量 / 更多 → 信息元素**。「上次同步时间」一类标签、`已选中 N`、`上次更新时间` 这些**只读信息排在所有按钮之后**，不插在按钮前面，也不用 `space-between` / `margin-left: auto` 把它推到行尾——跟着按钮走，`gap: 8px` 就够。同步类按钮不占首位：它挤掉新增类动作的主按钮位是常见错排，正确做法是把新增/绑定类按钮挪到首位（首位即实心 primary）。
- 搜索条件与列表**同处一个 `ContentWrap`**，不再拆成上下两块 wrap；页面**不自带顶部描述区**（标题 + 副标题 + 头部按钮那一块），按钮一律落到 `.table-toolbar`。
- 顶部**业务提示语块**与**汇总/统计块**同样是「一张白卡里的第一个块」，不单独开 wrap（蓝湖规范页「带汇总数据或提示语块的列表页：汇总｜提示 + 普通列表页 + 统计」）：提示块写 `<div class="tip-box page-tip">`、统计块写 `<div class="stats-bar page-summary">`，紧跟其后才是 `.table-toolbar` / `<el-tabs>` / `.table-inner`。`.page-tip` 与 `.page-summary` 在全局层**只给间距**（`flex-shrink:0` + `margin-bottom:24px`），**配色、字号、边框一律沿用源页面原样**——合并容器不是重做视觉，别把源里的蓝底提示改成规范页的灰底。合并后原来撑两个 wrap 的 `gap` 与页内复制的白卡声明（背景 / radius / padding）要一并删掉。
- `SearchForm` 默认折叠：只保留能塞进首行的条件，操作条（搜索/重置/更多筛选）作为整体放不下就换到第二行；条件没超出一行时不显示「更多筛选」。页面不自己写折叠逻辑。
- **折叠测量的时机由 `live-measure` 控制，默认关闭且页面不外部设置**（2026-11-06 第 33 轮加开关、第 35 轮定口径）：默认只在「挂载 + 挂载后一帧（图标撑宽按钮）+ KeepAlive 激活 + 点『更多筛选/收起』」这四个初始化/用户动作时量一次，不挂 `ResizeObserver`/`MutationObserver`，因此拖动窗口或收起侧边栏后折叠不重算——这是默认口径的代价，不要为它单独加观察器，也不要在页面里自写重算。全仓 123 个 `SearchForm` 实例统一走默认值，**没有任何页面传这个 prop**：条件项数量会随运行时状态增减的页面（判定依据是 SearchForm 直接子级 `el-form-item` 上有没有 `v-if`/`v-show`，不是「看起来会跳」；prop 固定的子组件实例每次都是重新挂载，算静态）目前也照样默认关闭，实测出现折叠错排再按 prop 文档开启，不预先给开关。组件本体只保留一条 `measure()` 路径，加的是开关不是变体。
- 折叠允许的行数由 `collapse-rows` 控制，**默认 1**（全仓既有页面行为不变）。页面若有一个占满整行的控件（如 `style="width: 100%"` 的数据范围 / 角色切换行），传 `:collapse-rows="2"`，让条件先占满两行再收缩——否则那一整行吃掉唯一配额，其余条件会被全部藏进「更多筛选」。承接学员管理的「服务中学员 / 历史学员」就是这两例。
- 多 Tab 列表页的操作行**放在每个 Tab 自己的列表卡片里**，不放在 `<el-tabs>` 上方：子组件渲染 `<div class="table-toolbar"><slot name="toolbar"></slot> …子组件自己的按钮…</div>`，页壳用 `<template #toolbar>` 传按钮，弹窗与权限判断留在页壳，作用于当前激活的 Tab。
- 页面顶部不放文档提示条一类的通知区（源里的 `doc-alert`、指向使用文档的说明条一律不还原，对应的开关组件与环境变量也不要留）；业务态提示（表单校验说明、风险告警、空态引导）不受此条约束。
- **左右双面板（左树 / 左分组 / 左筛选栏 + 右列表）两块之间 18px**，由 `--app-panel-gap` 统一给：flex 排法在承担横向排列的那个元素上挂全局类 `panel-row`（`display:flex` + `flex-direction:row` + `gap:var(--app-panel-gap)` + `overflow:hidden` + `min-height:0`），页内不再写 `flex-direction: row` 与 `gap`；grid 排法不套这个类，只把 `gap` 写成 `var(--app-panel-gap)`。`panel-row` 既可以挂在页面根节点（与 `.list-page` 同挂，靠它在文件里排在 `.list-page` 之后覆盖纵向流），也可以挂在根节点下的内层容器上（如 `system/user` 的 `.account-layout`），内层容器自己那条 `flex: 1` 保留在页内。
- **双面板页也要一屏**（2026-11-06 第 29 轮补）：根节点 `list-page panel-row` 同挂之后，页内那条 `display:grid; grid-template-columns:280px minmax(0,1fr); min-height:calc(100vh-120px)` 要整块删掉——`min-height` 只保底不封顶，且自算的 120px 与 `--app-page-height` 的 138px 打架，一定出滚动。换成：左面板 `flex: 0 0 280px`、右面板 `flex: 1; min-width: 0`，两块各带 `min-height: 0; overflow: hidden`；卡片头与工具条 `flex-shrink: 0`；左栏那份分类列表 `min-height: 0; overflow-y: auto`（自己在卡里滚）；右栏表格包 `.table-inner` 且 `el-table` 给 `height="100%"`，分页包 `.pagination-wrap`。`.panel-row` 恒为横向，窄屏不再堆叠成单列，与既有双面板页一致。
- **双面板页的右列也是标准列表区**（2026-11-06 第 32 轮补、第 34 轮定页头口径）：右面板内部顺序与单列表页完全一致——`SearchForm` → `.table-toolbar` → `.table-inner` → `.pagination-wrap`，不允许再写页内工具条（`.xxx-toolbar` 里塞 `el-select`/`el-input` + 一个手写重置按钮，配 `padding:16px 20px; border-bottom`）。原型右栏那个页头（`panel-header`）不还原：纯说明性的副标题一律删，整块搬空后标题若只是重复左栏选中项也一起删——quick-reply 的 `reply-header`（第 34 轮）和 `ai/rag/document` 的 `document-header`（第 36 轮）都是整块删除，后者当时读的是 `queryParams.categoryName || '全部文档'`，看着像回显也照样删，因为左栏分类列表本身有选中态和「全部文档」那一项，右栏不需要复述；连带删掉只剩它一个消费者的样式（`.reply-header` / `.document-header` 高度规则 + 仅含它的 `@media` 块）与 computed（`selectedCategory`）。操作按钮从页头右侧挪进 `.table-toolbar`，权限判断（`checkPermi([...])`）跟着按钮一起搬，不能丢。搬完要删净页内那套工具条样式（容器规则 + 各控件的宽度规则 + `@media` 里的对应条目）；`SearchType*` 的宽度是组件行内样式，页内 `width` 类本来就失效，一律回到默认 220。右列的条件若只在前端过滤（接口不吃这些参数），也算「搜索条件」，同样走提交值口径，但**不靠第二份变量**：条件只定义一份（`keyword` / `selectedType`），`filtered*` 不是 computed 而是一个 `ref` + 一个 `applyXxxFilter()` 手动函数，只在「搜索」「重置」「数据加载完成」三类提交点调用（2026-11-06 第 37 轮改成这个形状，样板 `ai/quick-reply`）。`appliedXxx` 只留给真·服务端分页的页面——那里翻页、保存后刷新、外部触发的重载都要复用已提交值而不是输入框当前值，字段是承重的（现存 4 个文件：`ai/rag/permission` 的 `appliedKeyword`、`MaterialMultiPickerDialog` 的 `appliedName`、`delivery-live/tasks/detail/ScriptEditTab` 的 `appliedKeyword`、同目录 `UsersTab` 的 `appliedParams`）；要给这类页面合并成一份，前提是先把所有非搜索触发的重载路径改成「重载前清空条件」，否则未提交的值会跟着切部门/翻页悄悄生效。见 page-checklist S-014。
- **内嵌 iframe 的页面（报表、外部系统）高度只能给一次**：`IFrame.vue` 自带 `h-[calc(100vh-var(--top-tool-height)-var(--tags-view-height)-var(--app-content-padding)*2-2px)]`，这个 calc 数值上等于 `--app-page-height`；把它放进 `ContentWrap`（20px 内边距 + 1px 边框）就是被套了两遍，页面必然比一屏高 42px。写法固定为 `<div class="list-page"><ContentWrap class="page-body"><IFrame :src="src" class="!h-full" /></ContentWrap></div>`——`!h-full` 用 important 压掉组件自带高度，高度由 `.page-body` 给。`ContentWrap` 只声明 `title` / `message` 两个 prop，`:bodyStyle="{ padding: '0px' }"` 与 `!mb-0` 都是 el-card 时代的死属性，不要再写。
- **删页内 `gap` 之前先判主轴方向**：根节点是 `flex-direction: column` 时那句 `gap` 是「搜索 wrap ↔ 列表 wrap」的纵向间距，合并成单 wrap 后确实该删；根节点是横向（`row` 或没写 direction 的默认 row）时那句 `gap` 是**左右面板间距**，删了两块就贴死，必须换成 `panel-row` / `var(--app-panel-gap)` 而不是直接删。同一批删除动作还要回扫块内元素间距（如统计条 `.stat-bar`、行内控件组 `.scope-item`），它们与面板间距无关，按原值保留。
- 页面确实不属于该骨架（双面板工作台、卡片网格、嵌套列表、整页滚动）时，保留原排版并在页内注释写明原因，同时按标准数值就地给出所需间距；结果文档记为偏离，不强行套 `.list-page`。**但不套骨架 ≠ 不撑满一屏**：内容不足一屏时最后一张卡也要贴到视口底，写法是根节点 `min-height: var(--app-page-height)`（不用 `height`，内容超出时仍能整页滚动）+ 最后一块 `flex: 1`；块内是 grid 时补 `align-content: start`，否则 `align-content` 默认的 stretch 会把卡片行拉高变形。双面板页即使不套 `.list-page`，面板间距仍走 `panel-row` / `--app-panel-gap`。


---

## 四、API 与权限最小契约

- 转换/还原不得推测接口 URL、方法、入参、响应类型、菜单权限、按钮权限或权限码；不得调用真实 API，尤其不得执行真实写操作。
- `html-to-vue3` 不创建 API 文件，仅使用 Mock 或安全空函数。
- `dist-to-vue3` 仅可依据输入中可核实的证据生成接口契约类型和无真实调用的预留方法；无 URL、字段、入参或响应证据时必须写 `TODO`，不得猜测。
- 真实接口接入仅能在用户显式调用 `apifox-link`、完成契约核对并确认范围后进行；API 文件存在不构成请求授权。
- API 文件仅包含契约 `type` / `interface`、必要请求封装 import、API 方法及证据/TODO 注释。每个方法仅接受一个业务入参：GET 使用 `params`，POST/PUT/DELETE 使用 `data`，并原样透传。
- **API 文件内部只有三段，顺序固定**：① `import`；② 类型区——本文件全部 `type` / `interface` 集中在此，连同各自的文档注释和 `// ===== xxx =====` 分段注释一起上移，**不得穿插在方法之间或写在方法之后**；③ 接口方法区——`export const` 方法与其证据/TODO 注释、运行时常量（字典 code 一类）。新增契约类型只往类型区追加，不就近插在调用它的方法上面。
- **方法签名里不写匿名对象类型**：`(params: { pageNo: number; keyword?: string })` 这类内联字面量必须提取为类型区的命名 `interface`；`request.get<{ list: X[]; total: number }>` 这类内联响应同样如此，分页响应直接复用全局 `PageResult<T>`，同文件已有同形状类型直接引用不重复声明。内联写法的坏处是类型不在类型区、调用方无法复用、契约改动散落在方法体上。
- API 层不得改字段、拼请求体、做类型转换/默认值/业务校验，也不得解包、映射、格式化或补充响应；这些业务适配由调用方或页面邻近 `utils.ts` 完成。
- 接口契约类型（请求入参、响应体、行/项、字典枚举）只定义在 `src/api/{业务模块}/*.ts`（或同模块 `types.ts`），`src/views/**`、页面级 `utils.ts`、`src/types/**` 都不接受契约类型；组件仅导入使用。**豁免**：组件本地类型可以留在组件内——`interface Props` / `interface Emits` / 弹窗 `open()` 参数形状 / composable 的入参与返回类型 / `Pick`、`Omit` 派生的纯 UI 类型。判定口径是「这个类型描述的是后端契约还是前端控件的形态」，不是「这个类型在哪个目录」。
- 请求封装已处理响应/错误时，调用方直接 `await`，不重复解包或自造响应协议；同一原始接口数据只请求一次。
- 不因 API、Mock、字段或按钮存在推断权限。详细验收见 checklist E-007、E-008。
- 用户显式授权接按钮权限时，权限只挂**页面级的写操作 / 执行类入口**（新增、编辑、删除、导入、导出、开播等）。两类一律不挂：**弹窗 / 抽屉内部的按钮**（入口按钮已通过校验，内部再校验是重复）、**query 类 key**（`*:query`、`*:category-query`、`*:stat:query` 等查询/统计语义，含表格操作列的「详情 / 进度 / 历史」跳转与「管理分类」一类入口）——能看到页面即已具备查询权限，挂上去只会让搜索区、详情跳转、Tab / 区域整体凭空消失；尤其不得把 query 判断写进 `getList()`，那会让无该权限的人列表永远空白。菜单里某个 key 的唯一落点属于这两类时，按「无落点（规则排除）」写进结果文档，不硬塞。
- 例外：若某块的 query 权限是**成套设计**（如聊天工作台的 tab 可见性 + API 层按权限跳过对应端点），不拆——拆了会让门控 tab 对所有人可见并发出 403 请求；这类按偏离记录，等用户拍板。

---

## 五、路由架构与详情参数协议

- **prototype**：在 `remaining.ts` 末尾追加 `Layout` 顶级分组；多 Tab 页面组只注册一个指向入口 `index.vue` 的 child。
- **restore**：在 `restore.ts` 按业务模块定义路由；由 `remaining.ts` 在 catch-all 前展开 `...restoreRouter`。
- 仅当输入证据确认存在详情页及其跳转时，详情才作为所属模块 `Layout` 下的 `hidden: true` `detail/:params` child 创建；不凭规范补造详情页。
- 来源页将 `id`、`backUrl: route.fullPath` 和必要上下文合并为一个对象，经 `encodeRouteParam` 写入 `detail/:params`；不得使用旧查询参数返回协议。
- 编解码工具应提供失败兜底。详情页从 `route.params.params` 建立唯一 `routeParams` 解码源，其余字段均从该对象读取；不在多个位置重复解码。
- 返回时先关闭当前 TagsView，再跳转解码的 `backUrl`；缺失或非法参数时跳转明确的默认列表路径，禁止 `router.back()`。
- 编码仅用于路径参数序列化和降低可读性，**不是**加密、脱敏、防篡改、鉴权或授权措施；敏感数据不得放入路由，访问控制必须由后端负责。详细实现和验收见 checklist E-001、E-002。

---

## 六、参考页与验证

- **仅表现层参考，不替代源证据**：标准列表 `product-manage/library`、`live-manage`、`system/post`、`wecom/corp`、`order/lead`；树形 + 列表 `system/user`；多 Tab `transfer-student/undertake`、`order/refund-approval`；双面板 + 右列就是标准列表区（根节点 `list-page panel-row`，第 29/32 轮改造完）`ai/rag/document`、`ai/quick-reply`；双面板工作台（不套标准骨架，见上条偏离口径）`student/tag`、`system/role`。
- 使用 Chrome DevTools MCP 检查可导航性、404/Console Error、标题、表格、弹窗、Tab、文案和必要样式对照；逐页验收按 [page-checklist.md](./page-checklist.md)。
- 类型检查使用 `pnpm ts:check`；只对本次目录运行不带 `--fix` 的 `npx eslint --ext .ts,.vue`。
- **禁止**使用 `pnpm lint:eslint <路径>` 校验产物：该脚本会退化为全库 `--fix`。

---

## 七、文件操作约束

- 单次写入最大 500 行或 50KB；读取超过 500 行或 100KB 的文件时必须分片。
