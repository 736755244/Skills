---
name: html-split
description: "将大型 HTML 原型拆分为独立页面，提取完整脚本、样式和页面清单，并进行真实 Chrome 验证。"
---

# html-split

将大型单页 HTML 应用 1:1 拆分为可独立访问的原型页面。本 Skill 只拆分与验证，不生成 Vue，也不自动调用后续 Skill。通用边界、文件范围、浏览器证据和结果格式见 [standards.md](../transfer-to-vue3/standards.md) 与 [结果契约](../transfer-to-vue3/result-contract.md)。

## 输入与产物

- 输入：用户指定的原始 HTML，通常为 `.middleproduct/prototype.html`。
- 输出：`.middleproduct/pages/`、`.middleproduct/styles/common.css`、`.middleproduct/manifests/pages-manifest.json` 与 `.middleproduct/html-split-result.md`。
- 子页面只引用全量公共样式，不写入 `src/`，不新增业务 DOM、样式或逻辑。

## 执行流程

1. **分析输入**：按共有规范分片读取大文件，完整识别页面容器、弹窗、菜单与 Tab 切换、所有 `<script>`、初始化逻辑、样式和资源引用。
2. **拆分页面**：多 Tab 必须拆成独立 HTML 中间单元，用于脚本闭包、DOM 依赖、样式引用和逐 Tab 真实 Chrome 验证；该独立性仅属于 `.middleproduct/pages/`，**不表示最终 Vue 产物应生成多个页面或多个路由**。每个单元保留主体 HTML、关联弹窗、所需完整脚本与数据、初始化调用以及 `../styles/common.css` 引用。
3. **完整性检查**：确认事件处理函数、DOM ID/选择器、全局变量与数据数组在当前页面闭包内完整可用；HTML 标签和脚本语法闭合，样式路径有效。
4. **生成 manifest**：区分可独立访问的物理 `pages` 与逻辑 `tabGroups`。Tab 单元记录 `name`、`filename`、`title`、`groupId`、`tabKey`、`tabLabel` 和 `tabOrder`；每个 Tab 组记录组标识、组标题、默认 Tab 及按源视觉顺序排列的成员。非 Tab 页面不进入 Tab 组，仍作为独立逻辑页面。`tabGroups` 是后续转换选择和最终合并的依据。
5. **真实验证**：用 Chrome DevTools MCP 逐页打开物理单元，按实际控件操作点击、填写、键盘导航、弹窗和跳转；记录 console、snapshot、screenshot 和可见结果。失败只对照原始 HTML 修复脚本、结构、样式或资源路径后复测。该中间验证不能替代最终 Vue 单入口中的逐 Tab 验证。

## 拆分特有质量门禁

在 Chrome 验证前，对每个输出页面完成以下静态预检，并在结果中按“静态结构 / 引用闭包 / 样式引用 / Chrome”分别记录，不能以页面暂时可见掩盖静态缺陷：

- [ ] 内联 `<script>` 已通过语法解析（例如以 `new Function` 验证）；不得存在未触达函数的 `SyntaxError`。
- [ ] `DOCTYPE`、`html`、`head`、`body`、`script` 与 `style` 标签成对闭合。
- [ ] 每个 `onclick`、`onchange`、`onsubmit`、`oninput` 与 `addEventListener` 引用的函数都在页面脚本中定义。
- [ ] 每个 `getElementById`、`querySelector` 所依赖的元素都在当前页面中存在；函数使用的变量和数据数组完整闭合且可用。
- [ ] 每个页面引用全量公共样式；不得为了修复外观增加新的 `<style>` 块或 CSS 类。
- [ ] 有表格语义的页面确认实际渲染数据行；有弹窗语义的页面确认 mask 能打开与关闭。
- [ ] 没有适用控件时记录“不适用”，不得为验证新增控件。

## 结果

按 [结果契约](../transfer-to-vue3/result-contract.md) 输出，额外记录“原始页面 → Tab 页面组 → 物理 HTML 单元”的映射、Tab 顺序与默认项、manifest、脚本/DOM/样式完整性检查和逐页 Chrome 证据。是否调用 `html-to-vue3` 由用户另行明确决定。
