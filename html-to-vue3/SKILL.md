---
name: html-to-vue3
description: "消费已拆分的 HTML 原型，将用户选择的页面转换为 Vue3 组件、源数据 Mock 与必要 prototype 路由。"
---

# html-to-vue3

将已拆分的 HTML 原型转换为可独立访问的 Vue3 页面。本 Skill 只处理用户选择的页面、源文件已有的固定数据 Mock、必要 prototype 路由和真实 Chrome 验证；不拆分原始 HTML，不接入 API 或权限，也不自动调用其他 Skill。

转换边界、组件/样式基线、路由、真实浏览器、工程检查、文件范围与存量代码保护见 [standards.md](../transfer-to-vue3/standards.md)；逐页交付和验证规则见 [page-checklist.md](../transfer-to-vue3/page-checklist.md)；状态和确认见 [结果契约](../transfer-to-vue3/result-contract.md)。

## 输入与选择

1. 优先读取 `html-split` 生成的 `.middleproduct/manifests/pages-manifest.json` 与 `.middleproduct/pages/`。若只有原始 HTML，提示用户单独调用 `html-split`，本 Skill 不编排拆分。
2. 展示 manifest：非 Tab 页面以页面为选择单位；多 Tab 页面以 `tabGroups` 中的逻辑页面组为选择单位，组内物理 Tab 单元仅作为内容和验证明细展示。`all` 包含全部独立页面和 Tab 页面组。用户仅指定组内单个 Tab 时，要求其选择完整所属组；不得生成只含一个原始 Tab 的不完整 Vue 页面。
3. **单元串行转换门禁**：即使用户选择 `all`，也必须按逻辑页面组/路由逐个串行完成，禁止批量模板生成、跨页面套用通用 CRUD、并行写入多个转换单元，或在未完成当前单元源—Vue 对照前开始下一个单元。每个单元须按“源完整读取 → 领域 Mock → 页面/专用组件 → 格式化 → lint → 原 HTML 与 Vue Chrome 对照 → 结果矩阵记录”闭环；当前单元存在字段、布局、数据、弹窗或交互差异时必须修复或标记 blocked，不能以 `partial` 继续批量生成下一页。每个单元完成后向用户报告并等待其继续选择下一个路由/逻辑页面组；不得默认自动推进到整个 `all` 余项。
4. 用户明确要求获取原型时，可使用 `transfer-to-vue3/fetch_prototype.sh`。链接可解析 `pwd` 参数；无法解析或未提供时，提示用户以交互、标准输入或密码文件方式提供。下载只取得输入，不推导业务接口。

## 转换流程

**串行门禁**：每个转换单元必须闭环验收后才处理下一个，禁止批量模板生成、跨页面套用通用 CRUD、并行写入多个单元。单元内顺序：

- **非 Tab 页面**：按”源完整读取 → 领域 Mock → 页面/专用组件 → 格式化 → lint → 原 HTML—Vue Chrome 对照 → 结果矩阵记录”闭环。
- **Tab 页面组**：按 `tabGroups` 成员源顺序逐 Tab 提取模板、脚本、样式、弹窗、固定数据和交互；将共享状态、组级数据与 `activeTab` 放入唯一入口 `index.vue`，将复杂 Tab 内容按职责拆至 `components/`。同组仅生成 `src/views/prototype/{group}/index.vue`、组级 `mock.ts`、必要子组件与一条 prototype 路由；**不**生成各 Tab 的独立页面目录、Mock 或路由；Tab 切换**不**改变 path/hash/query、不调用 `router.push` / `router.replace`、不新增 history / TagsView / 应用导航记录。

对每个单元的具体步骤（分片读取 / 组件拆分 / Mock 抽取 / 路由 / 统一 UI / 参考页 / 格式化 / Chrome DevTools 验证）按 [standards.md](../transfer-to-vue3/standards.md) 执行；不在本 SKILL.md 重复。**禁止脑补**：通用 CRUD、自由文本”说明”弹窗、缩减样例数据、位置字段（`field0`）或其他推导替代源行为均不允许；无法还原时记录阻塞。

## 本路径特有约束

- 输出仅位于 `src/views/prototype/{name}/`、必要组件；路由追加到 `src/router/modules/remaining.ts` 末尾；不创建 `src/api`。
- 多 Tab 页面在 `html-split` 阶段可拆为独立物理 HTML 单元，但在本 Skill 中必须按 manifest 的 `tabGroups` 合并为一个 Vue 入口页面：入口以本地 `activeTab = ref(源默认值)`、`<el-tabs v-model="activeTab">` 与 `<el-tab-pane>` 保留页内切换，同组只注册一条路由。Tab 状态不得出现在 path/hash/query，切换不得调用 `router.push`/`router.replace` 或新增任何导航/history/TagsView 记录。不得为同组 Tab 分别创建 `src/views/prototype/{tab}/index.vue`、独立 `mock.ts` 或路由，也不得将 Tab 切换改写为页面跳转；复杂 Tab 内容可拆至入口目录 `components/`。父入口负责 Tab 顺序、默认项和必要共享状态。可参考 `undertake/index.vue`、`order/refund-approval/index.vue` 的入口编排与子组件职责拆分，但 `v-if` 条件挂载、异步加载等仅在不改变源输入的初始化时机和状态保留语义时使用。
- 源页面存在专用 Modal、Drawer、Picker、Confirm、预览或表单时，必须生成对应页面专属组件，保留标题、尺寸、字段、校验、按钮文本、危险态、关闭行为和本地 Mock 状态变更；通用 Dialog 只能作为无损外壳，不得以“说明”textarea 或通用成功提示代替源流程。
- 原输入包含图标的搜索/重置、导入/导出、添加/上传、编辑/删除、工具栏或页面级动作，必须使用项目 `Icon` 等价还原；搜索区使用项目全局 `SearchForm`（折叠、「更多筛选 / 收起」与搜索/重置按钮由组件内置），列表骨架按 checklist S-009 ~ S-011 与 [standards.md](../transfer-to-vue3/standards.md) 的全局版式层落位，页内**不**再自调 `.el-form--inline .el-form-item` 的 bottom margin 或多行 gap。
- 原输入没有的业务动作、API、权限码、`checkPermi` 和真实写请求保持不存在。

## 弹窗尺寸口径

页面里的弹窗一多，尺寸分叉比字段差异更难收拾：口径只在 checklist **B-007（宽度四档）** 与 **B-013（高度只给一次）** 定义一次，本 Skill 在生成时就直接按口径产出，不留到事后统一。

- **宽度**：只用 `600 / 900 / 1200 / 1400` 四档，按源宽度区间归位（<750→600、750–1049→900、1050–1299→1200、≥1300→1400；无 `width` 与 `50%` → 900，`80~95%` → 1400）。写 `:width="900"` 或 `width="900px"` 都行，**不写无单位字符串** `width="600"`——Element Plus 不补 `px`，CSS 丢弃整条，弹窗悄悄退回 `40%`。小屏收窄由 `Dialog.vue` 的 `max-width: calc(100vw - 32px)` 兜住，页面不自写百分比宽度。
- **高度**：`<Dialog :scroll="false">` + 内容根节点 `height: calc(100vh - 300px); overflow: hidden`，内部 `flex: 1; min-height: 0` 把剩余空间交给表格，滚动只出现在表格/局部列表。**不传** `maxHeight`，**不写** `max-height="640"` / `height: 75vh` / `height="500px"`，否则外壳 `ElScrollbar` 与内容两层高度叠加成双层滚动。
- **媒体预览例外**：凭证图、视频、裁剪框保留固定高（360 / 400 / 300 / 220），高度随素材比例走。
- **flex 链要贯通**：`el-form`、`el-tabs`、`el-row/el-col`、grid 都会在中间吃断 flex 链，各自补 `flex: 1; min-height: 0`（`el-tabs` 还要贯通 `.el-tabs__content` 与 `.el-tab-pane`）；`el-table-v2` + `el-auto-resizer` 必须有父高，否则塌成 0。UnoCSS 的 `flex-1` 不带 `min-h-0`，要显式补。
- **验收口径**：内容根节点 `clientHeight` = 视口高 − 300；`.el-dialog__body` 的 `clientHeight == scrollHeight`；860×760 下仍只有一层滚动。这三项量不出来，就是没改对，不能以"看起来正常"收工。

## 结果

输出 `.middleproduct/html-to-vue3-result.md`，遵循 [结果契约](../transfer-to-vue3/result-contract.md)，以**转换单元**为最小记录粒度：每个路由/逻辑页面组单独记录输入、布局分类/参考页、物理 Tab 成员到最终单一组件/路由的映射、完整 Mock/专用组件、格式化/lint、原 HTML—Vue Chrome 对照、逐项交互证据、差异和修复。一个单元未闭环验收时不得记录下一个单元为已开始或已完成。每单元完成后停止，等待用户继续选择下一个单元；后续 API、权限、清理或 Playwright 验证仅作为用户可选项，不自动执行。
