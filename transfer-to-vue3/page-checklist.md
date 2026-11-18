---
title: "页面 UI/交互 集中验证清单（转换完成后逐条打钩）"
date: 2026-09-17
category: reference
module: "transfer-to-vue3 / html-to-vue3 / dist-to-vue3"
problem_type: workflow_checklist
tags:
  - vue3-page-checklist
  - element-plus
  - form-rules
  - verification
---

# 页面 UI/交互 集中验证清单

本文件是逐页 UI、交互、导出、API 接线与详情跳转的唯一详细实现和验收来源。转换边界、目录、实现基线与工程校验见 [standards.md](./standards.md)；确认门禁、范围保护和结果记录见 [result-contract.md](./result-contract.md)。

**使用方法**：仅对页面实际具备的结构和行为执行对应规则；按本文件 ID 顺序先跑自动检测（grep），再用 Chrome DevTools MCP 验证。源证据、用户明确授权和安全边界优先，任何偏差都必须记录在结果文档。

**规则 ID 索引**：

| ID 段 | 范围 | ID 段 | 范围 |
|---|---|---|---|
| **B-** 弹窗（Dialog / 尺寸 / 嵌套 / tooltip） | B-001 ~ B-013 | **S-** 搜索区 | S-001 ~ S-014 |
| **T-** 表格列 | T-001 ~ T-011 | **R-** 路由/列表/操作列/一屏/空态/Tab | R-001 ~ R-010 |
| **F-** 表单校验 | F-001 ~ F-008 | **U-** 用户授权例外（2026-09-15） | U-001 ~ U-008 |
| **V-** 数值字段 | V-001 ~ V-007 | **E-** 导出 / 接口化 / 详情页 / API 类型 | E-001 ~ E-009 |
| **P-** 提示与成功文案 | P-001 ~ P-004 | **D-** 字典列/字典刷新链 | D-001 ~ D-003 |
| | | **总** | 87 条 |

**通用检测前提**：所有 grep 在 `<本次目录>`（即 `src/views/<module>/<page>/`）下，排除 `node_modules`。

---

## B — 弹窗（13 条）

### B-001 全局 Dialog 替换 el-dialog

**规则**：仓库使用全局 `Dialog`（自动注册），所有弹窗**必须**用 `<Dialog>` / `</Dialog>`，不用 `<el-dialog>`。
**自动检测**：`grep -rn "<el-dialog\|el-dialog>" <本次目录>/` 应为 0。
**Chrome 验证**：打开任一弹窗 → `dialog.closest('.com-dialog')` 非空。

### B-002 弹窗内聚（对外只 `open(row?)` + `refresh`）

**规则**：弹窗自己完成保存链路；对外只暴露 `open(row?)` 命令式入口（`defineExpose`）+ `refresh` 事件。**无** `save` / `submit` / `del` / payload 事件。
**自动检测**：`grep -rn "defineEmits.*'save'\|defineEmits.*'submit'\|defineEmits.*'del'" <本次目录>/` 应为 0；`grep -rn "message\.success('保存成功')" <本次目录>/` 在 index.vue 应为 0（应在弹窗组件内）。
**Chrome 验证**：保存后弹窗关闭 + 父组件列表自动重查（不必手动再点搜索）。

### B-003 保存/新增 success 文案分支

**规则**：编辑态 → `message.success('保存成功')`；新增态 → `message.success('新增成功')`；不共用一条。
**自动检测**：`grep -rn "message\.success('已保存\|message\.success('已新增\|message\.success('保存')" <本次目录>/` 检查是否有正确分支。
**Chrome 验证**：打开编辑弹窗保存 → toast 为「保存成功」；打开新增弹窗保存 → toast 为「新增成功」。

### B-004 删除二次确认

**规则**：删除类操作（含「移除」「取消收藏」「删除分类」）一律 `ElMessageBox.confirm`；源无二次确认的按授权偏差补齐。
**自动检测**：`grep -rn "ElMessageBox.confirm" <本次目录>/` 在每个含删除动作的文件中应至少出现 1 次。
**Chrome 验证**：点击每个删除类入口 → 先出确认框 → 取消后无请求、无 toast。

### B-005 确认框取消不触发后续动作

**规则**：取消确认框后不得发起请求或显示 toast；确认后的后续动作只能发生在 `await ElMessageBox.confirm(...)` 成功之后。通常不需要为取消单独写 `try/catch`；如调用上下文必须捕获，则只可终止当前流程，不能触发后续请求或 toast。
**反例**：取消后仍执行删除请求或成功/失败 toast。
**正例**：`await ElMessageBox.confirm(...)` 后再执行删除请求。
**自动检测**：人工核对确认后的请求和 toast 仅位于 `await ElMessageBox.confirm(...)` 之后。
**Chrome 验证**：打开删除 → 点取消 → 接口调用次数不变、无 toast。

### B-006 确认按钮 el-button--danger

**规则**：`ElMessageBox.confirm` 确认按钮 `class="el-button--danger"`（危险动作必带）。
**自动检测**：`grep -rn "confirmButtonClass.*el-button--danger" <本次目录>/`。
**Chrome 验证**：打开确认框 → 读确认按钮 `className` 含 `el-button--danger`。

### B-007 弹窗宽度四档（600 / 900 / 1200 / 1400）

**规则**：`<Dialog width="...">` 只用 `600` / `900` / `1200` / `1400` 四档。写法二选一：数字绑定 `:width="900"` 或带单位字符串 `width="900px"`；**禁止**无单位字符串 `width="600"`——Element Plus 原样拼成 `width: 600`，CSS 判定非法整条丢弃，弹窗静默退回默认 `40%`，且在 1400 屏上肉眼像"没设宽度"。

**归位映射**（源宽度不落在边界上时按区间归档）：

| 源宽度 | 归档 | 典型值 |
|---|---|---|
| < 750 | 600 | 380 / 420 / 460 / 520 / 560 / 720 |
| 750 – 1049 | 900 | 800 / 860 / 1000 |
| 1050 – 1299 | 1200 | 1100 / 1200 |
| ≥ 1300 | 1400 | 1300 / 1440 / 1600 |
| 未写 `width`（默认 `40%`）/ `50%` | 900 | — |
| `80%` / `90%` / `95%` | 1400 | 百分比一律归最大档 |
| `min(900px, 75vw)` 一类 | 取 `min` 的第一个参数 | 900 |
| 三元 `isX ? 900 : 1200` | 取较大值 | 1200 |

- **保底 900**：原宽 660–749 且内容含 `el-table` / `el-tabs` / `el-col` 的不降到 600——降到 600 会挤压表格列与左右分栏，宁可多给一档。
- 纯确认框（原 380–460，只有一行文案 + 两个按钮）同样归 600，不单独设档；不为"看起来更小"再开新档。
- 小屏兜底由 `Dialog.vue` 的 `max-width: calc(100vw - 32px)` 统一给，页面**不**再自写 `width: 95%` / `max-width: 90vw` / 媒体查询改宽。

**自动检测**：`grep -rhoE '<Dialog[^>]*width="[^"]*"' <本次目录>/ | grep -oE 'width="[^"]*"'` 输出的取值应只落在四档；`grep -rnE '(^|[^:a-zA-Z])width="[0-9]+"' <本次目录>/` 应为 0（无单位字符串）。
**Chrome 验证**：逐个弹窗读 `.el-dialog` 的 `getBoundingClientRect().width` 等于档位值；视口不足 `档位 + 32` 时收窄到 `100vw - 32`；`document.body` 横向溢出为 0。

### B-008 嵌套弹窗拆独立组件 + append-to-body

**规则**：弹窗套弹窗两边各是独立 SFC 文件、各自 `append-to-body`、各自一套表单/校验/保存逻辑。
**自动检测**：`grep -rn "append-to-body" <本次目录>/` 数量 ≥ 嵌套层数 × 2。
**Chrome 验证**：打开子弹窗 → `.com-dialog` 数 = 2，两个标题分别为父/子，各自可单独关闭。

### B-009 tooltip 触发元素用 el-button（不用 span/disabled）

**规则**：行操作按钮统一 `<el-button link type="danger">`，禁用态 tooltip 用 `:disabled` 控制，**不**给按钮加 `disabled`（会 `pointer-events: none` 导致 tooltip 无法触发）、**不**用 `<span>`。
**自动检测**：`grep -rn "class=\"del-disabled\"\|class=\"disabled\"" <本次目录>/` 应为 0。
**Chrome 验证**：操作列按钮 `className` 含 `el-button` 与 `el-tooltip__trigger`；`dataCount > 0` 行 hover 出提示、`= 0` 行 hover 无提示。

### B-010 弹窗底部单按钮 footer 不渲染

**规则**：底部仅 1 个按钮（无论「关闭」或「取消」）→ 删整段 `<template #footer>`；≥ 2 个按钮保留。
**自动检测**：人工核对每个 `<Dialog>` 的 footer 按钮数。
**Chrome 验证**：单按钮 footer 弹窗的 `.el-dialog__footer` 应为 `null`。

### B-011 关闭图标用 .is-hover（不用 .el-dialog__headerbtn）

**规则**：全局 `Dialog` 走自定义头部，`.el-dialog__headerbtn` class 恒为 `null`，关闭图标用 header 内 `.is-hover` 判断（通常 2 个：全屏 + 关闭）。
**自动检测**：人工核对。
**Chrome 验证**：header 内 `.is-hover` 图标数 = 2。

### B-012 弹窗不传字典 props（字典自取）

**规则**：弹窗需要的字典（分类 / 标签）由弹窗 `await loadXxx()` 取；**页面 / 父弹窗都不传字典 props**。
**自动检测**：`grep -rn "defineProps.*[Cc]ategor\|defineProps.*[Dd]ict" <本次目录>/` 应为 0（字典不应通过 props 传）。
**Chrome 验证**：打开弹窗 → 字典下拉直接有选项（不闪"暂无分类"）。

### B-013 弹窗高度：只给一次，单层滚动

**规则**：带列表、表格或分栏的业务弹窗统一写 `<Dialog :scroll="false">`，由内容根节点给**唯一**一次高度 `height: calc(100vh - 300px); overflow: hidden`，内部用 flex 链把剩余空间交给表格 / 局部列表，滚动只发生在表格或那块列表里。

```html
<Dialog v-model="visible" :scroll="false" :width="900" title="…">
  <div class="xxx-dialog"><!-- 唯一高度在这里 -->
    <div class="xxx-head">…</div><!-- flex-shrink: 0 -->
    <div class="xxx-body">
      <div class="xxx-left">…<el-table height="100%" /></div>
      <div class="xxx-right">…</div>
    </div>
  </div>
</Dialog>
```

```scss
.xxx-dialog { display: flex; flex-direction: column; height: calc(100vh - 300px); overflow: hidden; }
.xxx-dialog > .xxx-head { flex-shrink: 0; }
.xxx-body  { display: flex; gap: 12px; flex: 1; min-height: 0; }
.xxx-left  { display: flex; flex-direction: column; flex: 1; min-width: 0; min-height: 0; }
```

**禁止**：
- **双层滚动**：开了 `scroll`（默认 `true`）又给内容设 `max-height` / `height`。外壳 `ElScrollbar` 已有 `max-height: calc(100vh - 300px)`，两套高度叠加 → 弹窗外滚一层、内容再滚一层。
- **自定义高度**：页内写 `max-height="640"` / `height="500px"` / `height: 75vh` / `max-height: 90vh`。高度只由上面那一个 `calc` 决定，`Dialog` 的 `maxHeight` prop 不再由页面传。
- **中间层断链**：漏 `min-height: 0`、漏 `flex-direction: column`、给子级写死 `minmax(380px, 3fr)` 这类保底值。`flex: 1` 的表格会把容器撑高，`overflow: hidden` 直接裁掉下半部分（实测 `minmax(380px, …)` 在内容高只剩 206px 时必裁）。UnoCSS 的 `flex-1` 不带 `min-h-0`，等价于这条。
- **`el-table-v2` 不给父高**：`el-auto-resizer` 靠父容器测量，父级缺 `height` / `flex: 1; min-height: 0` 时表格塌成 0 高。虚拟表格另需给 `:row-height`。

| 内容结构 | 需要贯通的那条链 |
|---|---|
| 左右直接分栏 | `根 → .body(flex, min-height:0) → 左/右(flex-direction:column, min-height:0)` |
| `el-form` 包裹 | `根 → el-form(flex:1, min-height:0, flex-direction:column) → form-item 区` |
| `el-tabs` 包裹 | `根 → el-tabs(flex:1, min-height:0, flex-direction:column) → .el-tabs__content(flex:1, min-height:0) → .el-tab-pane(height:100%)` |
| `el-row` / `el-col` | `el-row` 与 `el-col` 各补 `flex: 1; min-height: 0`（`el-col` 默认 `height: auto`） |
| grid | 容器 `display: grid; grid-template-rows: auto 1fr; min-height: 0`，行高用 `1fr` 不用固定 px |

**例外（可保留固定高）**：媒体预览类——凭证图 360 / 400、视频预览 400、裁剪框 300 / 220。高度随素材比例走，不参与一屏口径。

**自动检测**：`:scroll="false"` 的文件与含 `height: calc(100vh` 的文件应一一对应；`grep -rn 'max-height: [0-9]\{3\}px\|:max-height=\|height="[0-9]\{3\}"\|: [0-9]\{2,3\}vh' <本次目录>/` 命中项应只剩媒体预览例外。
**Chrome 验证**：打开弹窗后逐层量——内容根节点 `clientHeight` = 视口高 − 300；`.el-dialog__body` 的 `clientHeight == scrollHeight`（零溢出）；不出现 `.el-scrollbar`（或它的 `clientHeight == scrollHeight`）；表格 `clientHeight` = 剩余高度且内部滚动；视口缩到 860×760 仍只有一层滚动。

---

## T — 表格列（11 条）

### T-001 列表列无手写 `|| '-'`

**规则**：模板里**不**写 `{{ row.xxx || '-' }}` / `{{ row.xxx ?? '-' }}` 这类伪兜底；空值由 `TableColumn` 包装组件兜底。
**例外**：业务回退（`row.title || row.courseAlias || '-'`）、多字段拼接、`0` 业务确认。
**自动检测**：`grep -rn "|| '-'" <本次目录>/` 仅允许业务回退与组合字段。
**Chrome 验证**：打开空数据列表 → cell 显示 `-`。

### T-002 纯透传插槽删除

**规则**：插槽仅原样透传字段（含 `<span>`/`<strong>` 包裹）→ 补 `prop`，删插槽；插槽只为兜横线 → 删除。
**判定**：插槽体内除兜底表达式没有其它内容（无单位/拼接/标签/条件分支）→ 伪兜底。
**自动检测**：`grep -rn "scope\.row\.[a-zA-Z_]\+ *}}" <本次目录>/` 应为 0（除保留业务场景）。

### T-003 prop 与插槽字段一致

**规则**：删除插槽前必须核对 `prop` 与插槽字段一致。
**教训**：真实案例 `prop="successTime"` + 插槽显示 `row.appName` —— 若只删插槽会把 `successTime` 显示出来；必须先改 `prop="appName"` 再删插槽。

### T-004 标准时间列 prop + formatter

**规则**：时间列用 `prop` + `:formatter` 三档之一：`dateFormatter`（秒级 `YYYY-MM-DD HH:mm:ss`）/ `dateFormatterMinute`（分钟级）/ `dateFormatter2`（日期）。
**不迁移**：相对时间、时长、日期区间、可点击时间、附带状态文案的时间列。
**自动检测**：`grep -rn "dayjs.*format\|formatTime(" <本次目录>/` 应为 0（除保留场景）。
**Chrome 验证**：打开时间列 → 显示值与选定 formatter 一致。

### T-005 时间列宽度统一（180 / 150）

**规则**：秒/分钟级 `width="180"`、日期级 `width="150"`；保持原 `width` / `min-width` 形态，只改数值。
**禁止**：`min-width` 与 `width` 互改。
**自动检测**：`grep -rn "label.*时间\|label.*日期" <本次目录>/` 后人工核对。

### T-006 时间列字段回退用 formatter 包装

**规则**：源里 `a || b` 两字段同语义取一 → 用 `prop + formatter` 包装保留（不删成裸 `prop`，也不写兜横线插槽）。
**自动检测**：人工核对。
**Chrome 验证**：保留字段回退行为。

### T-007 表格金额 `/100` / `.toFixed(2)` 禁止

**规则**：金额列统一 `formatFenToYuanNoZero`；**禁止** `x / 100` / `(x / 100.0).toFixed(2)` / `Math.round(x/100)`。
**不迁移**：表单回填赋值、Detail 抽屉、el-select 下拉选项价格、时间戳换算。
**自动检测**：`grep -rn "/ 100\b\|/100\.0\|Math.round(x / 100)" <本次目录>/` 应为 0（除表单回填等不迁移场景）。

### T-008 金额列 align="right"

**规则**：所有金额列（支付/退款/余额/实付/累计消费/提现等）`align="right"`；非数值列（金额所属主体、渠道）不加。
**自动检测**：`grep -rn "label.*金额\|label.*余额" <本次目录>/` 后人工核对。

### T-009 本次范围内不新增本地 formatAmount

**规则**：本次创建或已获确认修改的页面中，列表金额转换**不**新增或保留本地 `formatAmount` 函数，改用全局 `formatFenToYuanNoZero`。不在本次范围的存量页面只记录建议，不自动修改。
**自动检测**：`grep -rn "const formatAmount\s*=\|function formatAmount" <本次目录>/` 应为 0。

### T-010 业务回退字段保留

**规则**：业务回退（`row.title || row.courseAlias || '-'`）、空值业务文案（`row.startTime || '开播时间待定'`）、多字段组合（`row.inputCode` + `row.inputPhone`）→ 保留。
**例外**：`0` 表示"未消费/未发生"语义需业务确认，保留原判断。

### T-011 有插槽的列不写 prop

**规则**：`<el-table-column>` 只要写了 `#default` 插槽，就**不**再写 `prop`——两者同写时插槽内容虽然优先，但 `prop` 会让组件同时按字段值参与渲染，实测可能让元素渲染不出来（2026-11-06 第 37 轮全仓清掉 **254 处**：改造前 `src/views` 下 116 个文件共 257 处同写，改造后只剩 3 处登记例外；本轮补漏 2 处：`edit/review/DetailDrawer.vue` 的 `xetoPhone`、`order/offline/index.vue` 的 `productTagName`）。纯展示列（只 `{{ row.x }}` 或兜横线）反过来：删插槽、留 `prop`（见 T-002/T-003），两条规则按「有没有真实插槽内容」分流，不冲突。
**例外（保留 prop）**：列带 `sortable` / `sortable="custom"`，或表格 `:default-sort="{ prop: ... }"` 指到该列——EP 的排序状态、`sort-change` 回调参数、default-sort 匹配都读 `column.property`，摘掉 prop 会连排序一起坏掉。这类"插槽改写显示 + 保留排序"的列就是本规则的登记例外（现存 3 处：`product-manage/link/components/DepositLinksTab.vue`、`product-manage/livestream-link/components/DepositLinksTab.vue` 的 `depositAmount`，`user/taskpush/components/TaskPushLivePickerDialog.vue` 的 `startTime`）。
**自动检测**：按引号感知扫一遍模板，输出「同写 prop 与 #default」的列清单，逐条核对是否都在上面的例外里：
`node -e 'const{execSync}=require("child_process");const fs=require("fs");const files=execSync("git ls-files src/views",{encoding:"utf8"}).split("\n").filter(f=>f.endsWith(".vue"));const end=(s,i)=>{let q=null;for(;i<s.length;i++){const c=s[i];if(q){if(c===q)q=null;continue}if(c==="\""||c==="'"){q=c;continue}if(c===">"&&s[i-1]!=="=")return i}return -1};let bad=[];for(const f of files){const src=fs.readFileSync(f,"utf8");let i=0;while((i=src.indexOf("<el-table-column",i))>=0){const ae=end(src,i+16);const a=src.slice(i+16,ae);const sc=src[ae-1]==="/";let b="";if(!sc){const c=src.indexOf("</el-table-column>",ae);b=src.slice(ae+1,c<0?ae+1:c)}if(/(^|\s)prop=/.test(a)&&/#default/.test(b))bad.push(f+":"+(src.slice(0,i).split("\n").length)+" sortable="+/sortable/.test(a));i=ae}}console.log(bad.length,bad.join("\n"))'`
**Chrome 验证**：改造过的插槽列逐行有内容（标签列每行都要有插槽根容器，如 `.tag-list`；带兜底文案的列每行非空），e2e 侧对应 `e2e/specs/ai-rag-qa.spec.ts`「插槽列不写 prop 也必须渲染出内容」。

---

## F — 表单校验（8 条）

### F-001 必填走 rules 内联红字（不用 toast）

**规则**：必填校验用 `el-form` + `:rules` + `formRef.validate()`，错误以**内联红字**展示；不用 `message.warning` 拦截。
**自动检测**：`grep -rn "message\.warning.*不能为空\|message\.warning.*必填" <本次目录>/` 应为 0。
**Chrome 验证**：空提交 → `.el-form-item__error` 有文案，**无** toast。

### F-002 await validate 直接中断

**规则**：`await formRef.value.validate()` 校验失败时自动抛出异常中断后续执行，无需 `.catch(() => false)` + `if (!valid) return`。

**正例**：`await formRef.value.validate()`。

### F-003 必填规则 trim 后判空

**规则**：必填规则 validator 先 `trim()` 再判空，避免纯空格通过。
**正例**：`if (!v || !v.trim()) cb(new Error('昵称不能为空'))`。
**自动检测**：`grep -rn "\.trim()" <本次目录>/` 检查必填规则内是否都先 trim。

### F-004 maxlength / show-word-limit 不按 isEdit 分支

**规则**：`:maxlength="isEdit ? undefined : N"` 配 `:show-word-limit="!isEdit"` 拍平成 `:maxlength="N" show-word-limit`；源只在新增弹窗写了 `maxlength` 的，编辑弹窗一并补。
**仓库约定上限**：昵称 12 / 话术内容 200 / 敏感词 50 / 计划名称 30 / 分类名称 20 / 文件名称 80。
**自动检测**：`grep -rn "isEdit ? undefined :" <本次目录>/` 应为 0。

### F-005 必填提示语不区分新增/编辑

**规则**：必填提示语只有一套文案（不写 `isEdit ? '请填写完整' : '请输入敏感词'`）；`rules` 保持普通常量对象，**不**包成 `computed`。
**自动检测**：`grep -rn "computed.*=>.*rules\|computed(() =>.*{.*required" <本次目录>/` 应为 0。

### F-006 前端不做判重（list.some）

**规则**：唯一性（重名）校验交后端；前端**不**写 `list.some(x => x.name === name)`、**不**弹"名称已存在"toast；只保留必填与 `:maxlength`。弹窗里说明"不可重名"的 `.form-tip` 可保留（描述后端约束）。
**自动检测**：`grep -rn "\.some(.*=>.*\.name\|已存在" <本次目录>/` 应为 0。
**Chrome 验证**：保存同名 → 由后端返回错误，前端无"已存在"toast。

### F-007 打开弹窗 clearValidate

**规则**：打开弹窗时清掉上次的报错：`nextTick(() => formRef.value?.clearValidate())`。
**自动检测**：`grep -rn "clearValidate" <本次目录>/` 每个弹窗 `open()` 内至少 1 次。

### F-008 form-tip 配 :deep(.el-form-item__error)

**规则**：`.form-item` 内带 `.form-tip` 时必须补：

```scss
:deep(.el-form-item__error) { position: static; padding-top: 2px; }
```

否则绝对定位的 error 会遮住 tip。
**例外**：必填字典下拉（U-001）删 `.form-tip` 后这条样式也一并删除。
**自动检测**：`grep -rn "form-tip" <本次目录>/` 后核对配套 `:deep` 样式是否存在。

---

## V — 数值字段（7 条）

### V-001 排序号保留 el-input 不换 el-input-number

**规则**：排序号等数值字段**保持 `el-input`**；不换 `el-input-number`（它静默改值、`label-position="top"` 下偏窄、"可为空"靠 `undefined` 表达易出岔）。
**自动检测**：`grep -rn "el-input-number" <本次目录>/` 应为 0。

### V-002 排序号 type="number" 不写 maxlength

**规则**：`type="number"` 输入**不**配 `maxlength`（HTML 规范 `maxlength` 不适用于 `type="number"`）。
**自动检测**：`grep -rn "type=\"number\".*maxlength\|maxlength.*type=\"number\"" <本次目录>/` 应为 0。

### V-003 排序号不加宽度类

**规则**：`el-input` 默认 `width: 100%` 撑满 `label-position="top"`，**不**写 `style="width: ..."`、**不**换组件。
**自动检测**：`grep -rn "style=\"width.*\"" <本次目录>/` 在表单 `<el-input>` 处应为 0。

### V-004 新增态给默认 99 / 编辑态照后端无则空

**规则**：新增态照源默认值（如 `99`）；编辑态照后端值，**后端没返回该字段就留空**（**不**兜默认值）。
**错误写法**：`row ? String(row.sort) : '99'`（会把"编辑态缺字段"也填成 99）。
**正确写法三层分支**：`row ? (row.sort !== undefined && row.sort !== null ? String(row.sort) : '') : '99'`。
**自动检测**：人工核对 `open(row)` 内 sort 默认值回填逻辑。
**Chrome 验证**：编辑一条无 sort 的记录 → 表单 sort 为空（不是 99）。

### V-005 边界提成 SORT_MIN / SORT_MAX 常量

**规则**：模板 `:min` / `:max` 与 validator 共用同一对 `SORT_MIN=1` / `SORT_MAX=999999`（6 位 9，不用 `Infinity` / `Number.MAX_SAFE_INTEGER`）。
**自动检测**：`grep -rn "SORT_MIN\|SORT_MAX" <本次目录>/` 模板与 validator 都引用。

### V-006 排序列直接 prop（不写插槽）

**规则**：列表排序列 `<el-table-column label="排序号" prop="sort" />`，**不**写 `#default` 插槽、**不**写 `{{ row.sort || 0 }}` / `{{ row.sort ?? '-' }}`。
**自动检测**：`grep -rn "row\.sort\s*?\|row\.sort\s*||" <本次目录>/` 应为 0。

### V-007 提交原样传（不写 parseSort）

**规则**：`rules` 已保证"要么空、要么是区间内正整数"，提交**原样传** `form.sort`，**不**写 `parseSort()` / `normalizeSort()` 这类转换或兜底函数。
**自动检测**：`grep -rn "parseSort\|normalizeSort\|form\.sort.*[+\-*/]" <本次目录>/` 应为 0。

---

## P — 提示与成功文案（4 条）

### P-001 前端提示用 message.warning（不用 error）

**规则**：页面 `<script setup>` 里自己判断的提示（前置校验、状态不允许、操作失败兜底）一律 `message.warning`；**不**用 `message.error`（`error` 语义是"未预期的系统/接口异常"，由 axios 拦截器全局统一弹）。
**例外**：全局工具方法（`src/utils/`、`src/hooks/web/`、自定义 `useXxx`）可用 `message.error`。
**判定**：仅独立业务页面 `src/views/<module>/...` 的 `<script setup>` 函数体直接调 `message.error` 才违反。
**自动检测**：`grep -rn "message\.error(" src/views/<本次目录>/` 应为 0。
**Chrome 验证**：触发各前置校验 → toast 为 warning 样式（黄色），不是 error 样式（红色）。

### P-002 成功提示「动作+成功」（不用「已 X」）

**规则**：操作成功 toast 一律 `动作 + 成功`（`保存成功` / `新增成功` / `删除成功` / `移除成功` / `分配计划创建成功`）；**不**写「已 X」语序（`已保存` / `已新增` / `已删除`）。
**例外**：描述状态的进度提示（如「已开始下载当前版本视频（…）」）按源保留。
**自动检测**：`grep -rn "message\.success('已" <本次目录>/` 应为 0。
**判定**：同一动词在不同页面用同一句话，不要 `已取消收藏` / `取消收藏成功` 各处不一致。

### P-003 删除成功文案统一「删除成功」

**规则**：删除类操作 toast 文案统一 `删除成功`，不用 `已删除`。
**自动检测**：`grep -rn "message\.success.*删除" <本次目录>/` 检查文案。
**Chrome 验证**：触发删除 → toast 为「删除成功」。

### P-004 全局工具方法可用 message.error

**规则**：`src/utils/`、`src/hooks/web/`、自定义 `useXxx` 等系统层工具方法可用 `message.error`（属于"系统层统一提示"，与 axios 拦截器同语义）。调用方调用全局工具时不需要再手工 `try/catch` 改 toast 类型。
**示例**：`src/utils/domUtils.ts` 的 `copyToClipboard` 失败分支直接 `ElMessage.error('复制失败，请手动复制')` 是允许的。

---

## D — 字典列/字典刷新链（3 条）

### D-001 字典名称列直接 prop（不写 resolveXxxId）

**规则**：分类 / 状态名等字典名称列直接用后端随列表返回的字段；**不**写 `{{ xxxName(resolveXxxId(row)) }}` 这种"拿 id 回查前端字典"的模板。
**理由**：后端已冗余返回名称，前端再匹配会多一次字典依赖、字典未加载时闪"未分类"。
**自动检测**：`grep -rn "resolveCategoryId\|resolveXxxId\|categoryName(\|statusName(" <本次目录>/` 应为 0。
**Chrome 验证**：打开列表 → 字典列直接显示名称（不是"未分类"或空）。

### D-002 弹窗字典自取（不传 props）

**规则**：弹窗需要的字典由弹窗 `await loadXxx()` 取；**页面 / 父弹窗都不通过 props 传字典**。
**自动检测**：`grep -rn "defineProps.*[Cc]ategor\|defineProps.*[Dd]ict\|:categories=" <本次目录>/` 应为 0。
**Chrome 验证**：打开弹窗 → 字典下拉直接有选项（不闪"暂无分类，请先去新增"再跳成真实选项）。

### D-003 字典刷新链逐层抛

**规则**：子弹窗保存成功 → `emit('refresh')` → 父弹窗**先刷新自己持有的字典**再 `emit('refresh')` → 页面重查下拉 + 列表。链条上每一层持有字典就都要刷新自己那一份。
**反例**：只抛给页面 → 父弹窗列表停在旧数据。
**自动检测**：`grep -rn "loadCategories\|loadXxxDict" <本次目录>/` 在父弹窗的 `onFormRefresh` 内应先 await 再 emit。
**Chrome 验证**：子弹窗新增分类 → 父弹窗表格出现新行、页面搜索下拉出现新选项、页面列表已重查（轨迹 `createCat → catList ×2 → page`）。

---

## S — 搜索区（14 条）

### S-001 重置走 resetFields

**规则**：搜索条件统一走表单重置 `searchFormRef.value?.resetFields()`；`pageNo` / `pageSize` 等非表单字段单独处理（`pageNo = 1`）。
**自动检测**：`grep -rn "queryParams\.keyword = ''\|queryParams\.categoryId = ''" <本次目录>/` 应为 0（除 pageNo/pageSize 等非表单字段）。
**Chrome 验证**：填好条件点「重置」→ 输入回到空、下拉回到 placeholder；`pageNo` 回到 1。

### S-002 搜索项 prop 必须有

**规则**：每个搜索项的 `el-form-item` 必须有 `prop`，否则该字段不被注册、`resetFields()` 静默跳过。
**自动检测**：`grep -B1 "SearchTypeInput\|SearchTypeSelect" <本次目录>/` 核对每个上层 `<el-form-item>` 都有 `prop`。
**Chrome 验证**：填好条件点「重置」→ 该字段被清空（不是静默保留）。

### S-003 搜索项不显式传 :width

**规则**：`SearchTypeInput` / `SearchTypeSelect` 自带 `width: 220`，**不**显式传 `:width="240"` 之类。
**自动检测**：`grep -rn "SearchTypeInput\|SearchTypeSelect" <本次目录>/` 检查是否带 `:width=`。

### S-004 搜索项不显式传 placeholder

**规则**：搜索组件自带默认占位（`请输入` / `请选择`），**不**显式传 `placeholder`。源里的检索词提示（如「话术/分类模糊检索」）**不**搬成 placeholder。
**自动检测**：`grep -rn "SearchTypeInput\|SearchTypeSelect" <本次目录>/` 检查是否带 `:placeholder=`。

### S-005 下拉首项不加「全部分类」

**规则**：下拉首项 `{ label: '全部分类', value: '' }` 一律删掉；未选择即不过滤（`queryParams.xxxId` 保持 `''`），清空走 `clearable` 的 × 或「重置」按钮。源里若有"全部分类"，改由 placeholder 表达。
**自动检测**：`grep -rn "全部分类\|全部" <本次目录>/` 在搜索区下拉 options 应为 0。
**Chrome 验证**：展开下拉 → option 数 = 真实数据条数，不含「全部分类」/「全部」；`xxxOptions` 里没有 `value: ''` 的首项。

### S-006 不挂 @keyup.enter / @input-change 自动提交

**规则**：搜索区控件**不**挂 `@keyup.enter`、`@change`、`@input-change` 一类触发的提交；查询只由明确的「搜索 / 重置」按钮触发（`SearchForm` 的 `@search` / `@reset`）。`SearchTypeInput` / `SearchTypeSelect` 的 `@input-change`、`el-select` 的 `@change`、`el-input` 的 `@keyup.enter` 都算自动提交，一律删。**唯一例外**：该搜索区根本没有「搜索」按钮（只有输入框 + 重置，或只有一个裸 `el-input`）时不能删——删了就没有任何触发查询的入口；这种页面先补搜索按钮或按偏离记录，不要直接删。
**自动检测**：`grep -rn "@keyup\.enter\|@input-change\|@change=\"handleQuery\"\|@change.*loadList\|@input.*loadList" <本次目录>/` 应为 0（弹窗内的选择器不在此列）；命中时先确认同页有 `<SearchForm @search=` 或等价的搜索按钮，再删。
**Chrome 验证**：在搜索输入框回车 / 输入文字 / 切换下拉 → 都不发起查询、无 toast；点「搜索」才发请求，点「重置」清空条件并回到第 1 页。

### S-007 SearchTypeSelect 默认不显式开启 filterable

**规则**：`SearchTypeSelect` 默认**不**显式开启 `filterable`；仅在后端 keyword 契约确认且用户授权后才显式传。
**自动检测**：`grep -rn "SearchTypeSelect.*filterable\|:filterable=\"true\"" <本次目录>/` 应为 0（除已确认场景）。

### S-008 搜索/重置按钮必须有 + pageNo = 1

**规则**：必须有「搜索」「重置」按钮，点击才发起查询；用 `SearchForm` 时按钮由组件渲染，页面接 `@search` / `@reset`，`@search` 处理先 `pageNo = 1` 再查，`@reset` 处理走 `resetFields()`（或逐字段清空）+ `pageNo = 1` 再查——组件只发事件，字段清理仍归页面。
**自动检测**：`grep -rn "@search\|@reset" <本次目录>/index.vue` 存在；`pageNo = 1` 必须先于 `loadList()`。
**Chrome 验证**：输入条件点「搜索」→ 命中条数变化且回到第 1 页；点「重置」→ 条件清空、`total` 恢复。

### S-009 搜索区用全局 SearchForm，不自排折叠与间距

**规则**：搜索区一律用全局组件 `<SearchForm>`（`setupGlobCom` 注册，无需 import），只放插槽条件和 `@search` / `@reset`；折叠、「更多筛选 / 收起」切换、搜索/重置按钮都由组件内置，页面**不**自写折叠逻辑、**不**在 scoped 里调 `.el-form--inline .el-form-item` 的 margin。`props.collapsible="false"` 仅用于条件本就不规整的页面；`props.collapse-rows` 决定超出几行才收缩，默认 1，含整行控件（`width: 100%` 的数据范围行等）的页面传 2。折叠测量默认**只在初始化与用户动作时算**（挂载、挂载后一帧、KeepAlive 激活、点「更多筛选」），不观察容器宽度变化；`live-measure` 这个开关**页面一律不外部设置**，全仓统一走默认 `false`——条件项随运行时状态增减（直接子级 `el-form-item` 带 `v-if` / `v-show`）的页面也照样默认关闭，实测出现折叠错排才按开关文档开启。
**自动检测**：`grep -rn "<SearchForm" <本次目录>/index.vue` 至少 1 处；`grep -rn "el-form--inline" <本次目录>/` 应为 0；`grep -rn 'inline="true"' <本次目录>/` 应为 0；搜索区若有 `style="width: 100%"` 的整行 `el-form-item`，`grep -rn 'collapse-rows' <本次目录>/index.vue` 应命中。
**Chrome 验证**：首屏只见一行条件（传 `collapse-rows="2"` 的页面为两行）；条件放不下时「搜索/重置/更多筛选」整体换到下一行；点「更多筛选」展开全部、文案变「收起」；条件本就装得下时不出现该按钮；折叠切换时页面无 1~2px 跳动。

### S-010 列表骨架按标准块产出

**规则**：页面根节点 `class="xxx-page list-page"`，容器唯一（`<ContentWrap class="page-body">`），搜索区与列表区**同处这一个 wrap**，内部顺序固定 `SearchForm → .table-toolbar → .table-inner(el-table height="100%") → .pagination-wrap`。间距（12 / 40 / 24 / 30 / 20）由全局 `.list-page` 层给，页内不重复声明，详见 [standards.md](./standards.md) 的「列表页统一版式」。
**自动检测**：`grep -rn "list-page\|page-body\|table-toolbar\|table-inner\|pagination-wrap" <本次目录>/index.vue` 五类齐全；`grep -c "<ContentWrap" <本次目录>/index.vue` 应为 1；页内 `grep -rn "margin-bottom: 2[0-9]px\|margin-top: 30px" <本次目录>/index.vue` 应无与全局层重复的声明。
**Chrome 验证**：`getComputedStyle` 逐段核对——条件行间距 12px、搜索区下沿 40px、操作行到表格 24px、表格到分页 30px、分页到 wrap 底部 20px；`document.body.scrollHeight <= window.innerHeight`。

### S-011 无页面顶部描述区，操作按钮归操作行

**规则**：不产出「标题 + 副标题 + 右侧按钮」的顶部描述块（`head-wrap`、`xx-head`、`page-title` + `page-subtitle` 这类），也不产出顶部文档提示条（`doc-alert` 及指向使用文档的说明 alert）；源里的页面名称由菜单/路由标题承担，按钮一律移到列表上方 `.table-toolbar`。操作行内部顺序固定：**新增 / 创建 / 绑定类主动作 → 其他动作（同步、导入、导出）→ 批量 / 更多 → 只读信息元素**（「上次同步时间」标签、`已选中 N`、`上次更新时间`）；信息元素不插在按钮前面，也不用 `space-between` / `margin-left: auto` 推到行尾。同步类按钮不占首位——它挤掉新增类动作的主按钮位就是错排，改法是把新增/绑定按钮挪到首位，而不是给同步按钮让位。操作行里只有首位按钮用 `type="primary"`（实心），其余不设 `type`、不加 `plain`，彩色（danger/success/warning）不落在操作行；首位是「返回 / 取消」时主按钮顺延到下一个动作按钮。多 Tab 列表页的操作行放在**每个 Tab 自己的列表卡片里**（子组件 `.table-toolbar` 内开 `<slot name="toolbar">`，页壳传按钮），不放在 `<el-tabs>` 上方。仅独立详情页为保留「返回 + 动态实体名」允许留头部，且必须在结果文档记为偏离。
**自动检测**：`grep -rn "head-wrap\|page-title\|page-subtitle\|doc-alert" <本次目录>/` 应为 0（详情页返回头除外）；Tab 容器页 `grep -n "table-toolbar" <本次目录>/components/*Tab.vue` 应命中，且页壳 `index.vue` 里 `<el-tabs>` 之前无按钮；操作行内 `type="primary"` 每行至多 1 个，无 `plain`、无 `type="danger|success|warning"`；把 `.table-toolbar` 的子节点顺序打出来核对——`el-tag` / `el-tooltip` / 计数 `span` 必须排在全部 `el-button` 之后，首位按钮是新增/创建/绑定类而非同步类；页内 `grep -n "justify-content: space-between\|margin-left: auto" <本次目录>/index.vue` 在 `.table-toolbar` 作用域内应为 0。
**扫描器口径（第 38 轮全仓实测）**：`src/views` 下 `.table-toolbar` 共 **96** 处，首位不是实心 primary 的只剩 **1** 处登记的「返回」例外（`ai/knowledge/segment/index.vue`，主按钮顺延到下一个「新增」）；`primary` 多于 1 个 = 0，彩色按钮 = 0，`plain` / `link` = 0，只读信息排在按钮前 = 0；另有 82 处首位按钮自身带 `v-if`，入口无权限时可见首位顺延到下一个线条按钮，属预期而非错排。两条踩过的坑：① 抽属性串要按标签名实际长度取（`<el-button` 是 10 个字符，取 12 会把 `type="primary"` 截成 `y="primary"`，一次误报 26 处）；② 匹配 `plain` / `link` / `danger` 这类裸词前必须先把引号内的值整段剥掉，否则权限串 `user:scrm-sale-link:personal:create` 里的 `link` 会被 `\blink\b` 命中。
**页壳传按钮与样式作用域（第 38 轮）**：`<slot name="toolbar">` 那类操作行，首位按钮由**页壳**负责——审子组件时看到空 `<slot>` 不能判合规，要去看调用方（全仓唯一实例是 `material-library/index.vue`，传进来的首位是 primary 的「新建一级分组」）。另一条容易判错：页壳 `<style scoped>` 里写 `.table-toolbar { justify-content: flex-end }` **不会**打到子组件模板里的操作行，scope 属性挂在 `.table-toolbar` 自己身上（`compileStyle` 实测产物 `.order-delivery-page .table-toolbar[data-v-PARENT]`），子模板的 div 带的是子组件 id，只有子组件**根节点**才同时带父 id。要取证就把那段 SCSS 先用仓库自带 sass 展平，再交给 `@vue/compiler-sfc` 的 `compileStyle({ scoped: true })` 看产物选择器，别靠推断。
**Chrome 验证**：列表区上方第一行就是操作按钮，其上没有整块标题卡与提示条；操作行内最后一个元素是批量/更多按钮或只读信息（同步时间标签、已选计数），信息不出现在按钮左侧；只有首位按钮是实心填充色、其余为白底灰边线条；切换 Tab 后操作行随列表一起切换、按钮作用于当前 Tab。e2e 侧对应 `e2e/specs/list-page-layout.spec.ts`「操作行首位按钮是实心主按钮：订单录入、交付订单两个页签、学员明细」，helper `expectToolbarFirstButtonPrimary` 按**可见**首位判定（入口权限 `v-if` 顺延时不误报），整页核到 0 条时显式 `test.skip` 点名原因，防止「扫了个空」被当成通过。

### S-012 顶部提示 / 汇总块并入同一个 wrap，配色沿用源页面

**规则**：源页面顶部若是**业务提示语文案块**或**汇总/统计块**，还原后它是「一张白卡里的第一个块」，**不单独开 `ContentWrap`**（蓝湖规范页：带汇总数据或提示语块的列表页 = 汇总｜提示 + 普通列表页 + 统计）。写法：提示块 `<div class="tip-box page-tip">`、统计块 `<div class="stats-bar page-summary">`（或 `el-row.stat-card-wrapper.page-summary`），其后才是 `SearchForm` / `.table-toolbar` / `<el-tabs>` / `.table-inner`。`.page-tip` 与 `.page-summary` 在全局层**只给间距**（`flex-shrink: 0` + `margin-bottom: 24px`），块的底色、边框、字号、图标一律沿用源页面原样，**不得借合并容器顺手改配色**（例：源是蓝底 `#ecf5ff` + `#b3d8ff` 边框就保持蓝底，不换成规范页的灰底 `#f7f8fa`）。合并后原来用于撑开两个 wrap 的根 `gap` 与页内复制的白卡声明（`background: #fff` / `border-radius` / `padding`）要一并删掉。带「返回 + 动态实体名」的独立详情页头部不在本条范围（见 S-011 的偏离口径）。
**自动检测**：`grep -c "<ContentWrap" <本次目录>/index.vue` 应为 1；`grep -n "page-tip\|page-summary" <本次目录>/index.vue` 命中且位于 `page-body` 内第一位；页内 `grep -n "gap: 16px\|background: #fff\|border-radius: 8px" <本次目录>/index.vue` 不应残留撑 wrap 用的声明；提示块配色声明与源页面逐条一致（`git diff` 里不出现 `background` / `border` / `color` 的改动）。
**Chrome 验证**：`document.querySelectorAll('.v-content-wrap').length === 1`；提示块与表格在同一张白卡内，`getComputedStyle` 取提示块 `margin-bottom` = 24px；提示块背景色与源页面一致（取 `backgroundColor` 与源 CSS 对照，不是灰底就算改错方向）。

### S-013 左右双面板间距 18px，删 gap 前先判主轴

**规则**：「左树 / 左分组 / 左筛选栏 + 右列表」的双面板页，两块之间 **18px**，数值由 `--app-panel-gap` 统一给。flex 排法：在**真正承担横向排列的那个元素**上挂全局类 `panel-row`（给 `display:flex` + `flex-direction:row` + `gap:var(--app-panel-gap)` + `overflow:hidden` + `min-height:0`），页内不再写 `flex-direction: row` 与 `gap`；这个元素可以是页面根节点（与 `.list-page` 同挂，`.panel-row` 在 index.scss 里排在 `.list-page` 之后，同特异性下后者被覆盖成横向），也可以是根下的内层容器（如 `system/user` 的 `.account-layout`，它自己那条 `flex: 1` 留在页内）。grid 排法不套 `panel-row`，只把 `gap` 写成 `var(--app-panel-gap)`。**删页内 `gap` 之前先判主轴方向**：根是 `column` 时那句 `gap` 是「搜索 wrap ↔ 列表 wrap」的纵向间距，合并单 wrap 后该删；根是横向（写了 `row`，或 `display:flex` 没写 direction 的默认 row）时那句 `gap` 是面板间距，删了两块贴死——换成 `panel-row`，不是删掉。块内元素间距（统计条 `.stat-bar`、行内控件组 `.scope-item` 一类）与面板间距无关，按源页面原值保留，不跟着改 18px。右面板**内部**顺序与单列表页完全一致：`SearchForm` → `.table-toolbar` → `.table-inner` → `.pagination-wrap`（2026-11-06 第 32 轮）；原型右栏那个 `panel-header` 不还原——纯说明性的副标题一律删，标题若只是复述左栏选中项也整块删（quick-reply 的 `reply-header` 第 34 轮、`ai/rag/document` 的 `document-header` 第 36 轮都已整块删除；后者的标题读的是当前分类名，因为左栏分类列表已有选中态与「全部文档」项，仍算复述），连带删净只剩它一个消费者的样式与 `@media` 块；操作按钮从页头右侧搬进 `.table-toolbar`、`checkPermi([...])` 跟着按钮一起搬。
**自动检测**：`grep -rn "grid-template-columns\|flex-direction: row" <本次目录>/` 找出全部横向容器，逐个确认 gap 来源是 `panel-row` 或 `var(--app-panel-gap)`；页内 `grep -rn "gap: 16px\|gap: 20px" <本次目录>/index.vue` 不应再有面板级 gap；用「HEAD 有 gap、现在没有」的逐块对齐脚本回扫本轮所有改动文件，按选择器末段对齐（换嵌套层级的不算丢），确认剩下的删除项全部是纵向 wrap gap、`.table-toolbar` 的 8px、以及随顶部描述区一起删掉的 `.head-wrap` / `.page-actions` 内部 gap。
**Chrome 验证**：双面板页取 `getComputedStyle(左面板.parentElement).gap` = 18px；左面板 `getBoundingClientRect().right` 与右面板 `.left` 之差 = 18；`flex-direction` 为 `row`（挂了 `.list-page` 的根节点也要是 row，不能被纵向流覆盖回去）；右面板第一块就是 `.search-form`（不再有 `panel-header` 页头），且右面板内不出现滚动条。

### S-014 前端假查询只留一份条件变量

**规则**：列表在前端过滤/分页（假查询）的页面，检索条件**只定义一份变量**（`keyword` / `selectedType` 这种），同时**取消 computed 的实时列表计算**——过滤结果改成一个 `ref`（如 `filteredReplies`）+ 一个手动函数（`applyReplyFilter()`），只在「搜索」「重置」「数据加载完成」这三类提交点调用（2026-11-06 第 37 轮，`ai/quick-reply`）。判据两条：① 输入/选择过程中不发请求、列表行数不变（`feedback-no-live-filtering-commit-on-search` 仍然成立，"不实时"靠的是"只在点搜索时才重算"，不是靠第二份变量）；② 页面上不再出现 `keyword` + `appliedKeyword` 这种成对字段。
**为什么以前要第二份**：`computed` 会在任何依赖变化时重算，为了不让未提交的输入生效才存一个"已提交值"。改成点击后手动算，这个理由就没了。
**保留例外**：真·服务端分页的页面（条件直接进查询串）**可以**保留 `appliedXxx`——翻页、保存后刷新、外部触发的重载都要复用已提交值，而不是当前输入框里的值。这类字段是承重结构，不属于本条范围（现存 4 处：`ai/rag/permission` 的 `appliedKeyword`、`MaterialMultiPickerDialog` 的 `appliedName`、`delivery-live/tasks/detail/ScriptEditTab` 的 `appliedKeyword`、`UsersTab` 的 `appliedParams`）。要按本条把它们并成一份，必须先把所有非搜索触发的重载路径改成"重载前清空条件"（quick-reply 的 `selectCategory → resetQuery` 就是这个形状），否则输入框里没提交的字会跟着切部门/翻页悄悄生效——`ai/rag/permission` 是否照此合并，2026-11-06 已作为待确认项交回。
**自动检测**：`grep -rn "applied[A-Za-z]*\s*=\s*ref\|appliedParams" src/views` 逐个确认是服务端分页还是假查询；假查询页面里对同一语义出现两个 ref 即为违规。
**Chrome / e2e 验证**：改动后单跑 `pnpm exec playwright test ai-quick-reply`，「类型/关键词条件：改动不实时生效、点搜索才本地过滤且不打接口」两条用例断言"改了条件请求数不变 + 点搜索也不发列表请求"。

---

## R — 路由/列表/操作列/一屏/空态/Tab（10 条）

### R-001 操作列必须 OverflowButtonGroup 包裹

**规则**：行操作按钮用 `OverflowButtonGroup` 包裹；默认 `threshold: 2`，前 2 个平铺、其余收进「更多」下拉。
**自动检测**：`grep -rn "OverflowButtonGroup" <本次目录>/`。
**Chrome 验证**：`.overflow-button-group` 数量 = 行数。

### R-002 OverflowButtonGroup 必须传 :scope="{ row }"

**规则**：必须用 `:scope="{ row: scope.row }"` + `#default="{ row }"` 把行数据传进去，否则 `v-if` 条件按钮拿不到 `row`。
**自动检测**：`grep -B2 -A3 "OverflowButtonGroup" <本次目录>/` 检查是否有 `:scope="{ row: ... }"`。

### R-003 一屏适配走全局层，不写 115px

**规则**：一屏撑满由根节点 `.list-page` 的全局样式承担（`height: var(--app-page-height)` + `overflow: hidden`，`.page-body` 与 `.table-inner` 为 `flex: 1; min-height: 0`），表格用 `height="100%"` 内滚。**不**在页内写 `height: calc(100vh - 115px)` 之类的自算高度——那是全局层落地前的旧写法，与 `--app-page-height` 会打架。两个特例：
- 双面板页（`list-page panel-row`）：页内那条 `display:grid` + `min-height:calc(100vh-120px)` 要整块删掉，改左面板 `flex: 0 0 280px`、右面板 `flex:1; min-width:0`、两块 `min-height:0; overflow:hidden`，卡头/工具条 `flex-shrink:0`，左栏列表 `overflow-y:auto`，右栏表格进 `.table-inner` + `height="100%"`。
- iframe 页：`IFrame` 自带那条 `h-[calc(100vh-…)]` 数值上等于 `--app-page-height`，塞进 ContentWrap 会被套两遍（多出 40px 内边距 + 2px 边框）。固定写 `list-page` + `ContentWrap class="page-body"` + `<IFrame class="!h-full" />`，`:bodyStyle` / `!mb-0` 是死属性不写。

**自动检测**：`grep -rn "calc(100vh" <本次目录>/` 应为 0（`.list-page` 与 `IFrame.vue` 里的全局定义除外）；`grep -rn "list-page" <本次目录>/index.vue` 命中；iframe 页 `grep -n "!h-full" <本次目录>/index.vue` 命中。
**Chrome 验证**：`document.body.scrollHeight <= window.innerHeight`；表格内部滚动；分页与操作行不随滚动消失。

### R-004 空态用 el-table empty 不自造

**规则**：列表空数据用 `<el-table>` 自带 empty 插槽 / `empty-text`，**不**自造 `.empty-state` 区块（`v-if="list.length === 0"`）。
**自动检测**：`grep -rn "empty-state" <本次目录>/` 应为 0。
**Chrome 验证**：`.document.querySelector('.el-table__empty-text')` 有文案且 `.empty-state` 为 `null`。

### R-005 文案=「暂无数据」时不写 #empty

**规则**：`el-table` 在 zh-CN 下默认空文案是 `暂无数据`，写 `<template #empty>暂无数据</template>` 等于复制组件默认值。
**判定**：`#empty` 数量 = 文案非 `暂无数据` 的表格数。
**自动检测**：人工核对每个 `<template #empty>` 的文案。
**Chrome 验证**：文案为 `暂无数据` 的表格没有 `#empty`。

### R-006 Tab 计数只显激活项（withCount 函数）

**规则**：Tab 标签 `withCount(label, isActive, total)` → 仅当前激活 Tab 显示 `名称 (N)`；未激活 Tab 显示纯名称。
**反例**：模板写 `名称 ({{ total }})` → 两个 Tab 同时带数字。
**自动检测**：`grep -rn "名称 ({{ total\|name.*({{ total" <本次目录>/` 应为 0。
**Chrome 验证**：点第一个 Tab → 第 1 个标签文本带 `(N)`、第 2 个是纯名称；切到第二个 Tab 后正好相反。

### R-007 不跨 Tab 计数回填

**规则**：未挂载 Tab 计数为 `null`（不显示数字），切过去时自取并 `emit('update:total', n)`；**不**写"为另一个 Tab 补数字"的请求（`syncFavoriteTotal` 之类）。
**自动检测**：`grep -rn "syncFavoriteTotal\|sync.*Total" <本次目录>/` 应为 0。
**Chrome 验证**：首屏 → 计数接口在未挂载 Tab 调用 0 次。

### R-008 页壳不默认取数

**规则**：页面壳 (`index.vue`) **不**做默认取数（无 `onMounted` 取列表、无列表 API import）；只持有 Tab 状态与标题计数。
**自动检测**：`grep -rn "import.*from.*api" src/views/<本次目录>/index.vue` 应为 0。
**Chrome 验证**：首屏加载 → 列表类接口只被当前 Tab 调 1 次。

### R-009 操作列宽度按最长按钮计算

**适用**：仅在页面存在显式操作列宽度时适用。

| 按钮数量 | 计算公式 |
|---|---|
| 1 个 | `(14×字符数 + 6) + 24`，最小 `100px` |
| 2 个 | `(14×字符数₁ + 6) + (14×字符数₂ + 6) + 36` |
| 3+ 个 | `(14×字符数₁ + 6) + (14×字符数₂ + 6) + 100` |

**规则**：使用最长的两个按钮参与计算，结果向上取整到 10（如 182 → 190）。
**自动检测**：定位 `label="操作"` 或同义列后人工核对宽度计算。
**Chrome 验证**：窄屏下操作按钮不意外换行或截断。

### R-010 学员 ID 展示统一走 displayUserId

**规则**：任何展示学员 `userId`（企微 userid，不是学号 `studentId`）的位置——表格列、详情抽屉、弹窗回显、导出——都调 `src/utils/displayUserId.ts` 的 `displayUserId(id)`，口径是**取后 6 位、不足 6 位左侧补 0**（`123` → `000123`），空值给 `-`。页面里不再各写一套 `.slice(-6)`、`padStart`、`String(x).substring(...)`（2026-11-06 第 37 轮统一到这一个实现，现存 11 个文件 12 处调用）。
**为什么只留一个**：历史上三处各写各的（有的补 0、有的不补、有的截前 6 位），同一个人在不同页面显示成两个 ID，排查问题时对不上。规则本身不是重点，**只有一个实现**才是。
**自动检测**：`grep -rn "slice(-6)\|padStart(6" src/views` 应只剩 `src/utils/displayUserId.ts` 命中的调用形式；出现裸写 `String(...).slice(-6)` 即违规。
**Chrome 验证**：同一学员在列表列与详情抽屉里的 ID 文案完全一致。

---

## U — 用户授权例外（2026-09-15，8 条）

### U-001 必填字典下拉不做 disabled / placeholder / form-tip

**规则**：必填字典下拉（如「分类」）就是普通必填字段——**不** `:disabled`、**不**加"暂无分类"占位 option、**不**改 placeholder、**不留 `.form-tip`**、**不**因"没有字典数据"而把提交按钮 `:disabled`。
**理由**：空态由 `rules` 内联红字拦截，不再有"按钮点不动"死状态。
**自动检测**：`grep -rn ":disabled=\"categories.length === 0\"\|form-tip.*如需新增\|暂无分类" <本次目录>/` 应为 0。
**Chrome 验证**：空字典点提交 → 字段下方红字报错，提交按钮仍可点。

### U-002 同一字段的新增/编辑/导入弹窗一次全改

**规则**：源里「新增 / 编辑」弹窗和「导入」弹窗往往共用同一字段（如同一个分类下拉），改的时候都要改（`XxxFormDialog` 与 `XxxImportDialog` 一起），**不**只改用户点名的那个。
**自动检测**：人工核对同一字段的所有出现位置。

### U-003 新增按钮用 ep:plus 图标（不用 +）

**规则**：源里"新增"按钮的文字 `+` 一律换成 `<Icon icon="ep:plus" class="mr-5px" />`。
**自动检测**：`grep -rn "+\s*新增\|新增.*+\s*" <本次目录>/` 应为 0。
**Chrome 验证**：读 `.table-toolbar button` 的 `innerHTML`，含 `+ ` 文案的按钮应为 0，新增按钮内存在 `svg`。

### U-004 页面级操作按钮补 ep:* 图标

**规则**：操作行 `.table-toolbar` 的操作按钮，无论源里有没有图标，都按语义补 `ep:*`：新增 `ep:plus` / 导入 `ep:upload` / 导出 `ep:download` / 搜索 `ep:search` / 重置 `ep:refresh` / 管理分类 `ep:folder-opened` / 返回 `ep:arrow-left` / 设置 `ep:setting`。搜索/重置按钮的图标已由 `SearchForm` 内置给出，页内不再重复摆放。
**自动检测**：`grep -rn "管理分类\|查询\|导出\|返回" <本次目录>/` 后核对是否有对应 `ep:*` 图标。

### U-005 表格行内 link 按钮 + 弹窗底部按钮不加图标

**规则**：表格行内 `link` 按钮（编辑 / 删除 / 在线预览）与弹窗、抽屉底部的「取消 / 确定 / 保存 / 删除」按钮**不**加图标——加图标会挤 / 喧宾夺主。
**自动检测**：`grep -rn "Icon icon" <本次目录>/` 在表格行内 link 按钮和底部按钮处应为 0。

### U-006 不写角色判断（isAdmin / role / 仅管理员可操作）

**规则**：**不**在页面引入 `isAdmin` / `role` 变量，**不**写「仅管理员可操作」占位文案；按钮可见性由系统菜单/按钮权限配置决定。
**自动检测**：`grep -rn "isAdmin\|isAdmin()\|role ===\|仅管理员可操作" <本次目录>/` 应为 0。
**Chrome 验证**：模板里没有 `v-if="isAdmin"` 类分支。

### U-007 不写 CAN_VIEW_ALL / CAN_CONFIRM 开关

**规则**：源里"开发调试用"的权限/数据开关常量（`CAN_VIEW_ALL`、`CAN_CONFIRM`）一律删除——不保留、不改成 props；数据权限口径写进 VO 注释，由后端过滤。
**自动检测**：`grep -rn "CAN_VIEW_ALL\|CAN_CONFIRM" <本次目录>/` 应为 0。
**例外**：源里依赖该开关切换的空态文案只保留"有数据权限"那一条。

### U-008 删除「权限说明」开发弹窗（连入口 + 状态 + 样式）

**规则**：源里"权限说明 / 实现说明"类弹窗（`openPlanPermissionModal`、`permissionVisible` 等）**整体删除**——入口按钮、`<Dialog>` 整块、`ref` 状态、专属 scoped 样式（`.perm-body` / `.perm-table`）一并删除。
**自动检测**：`grep -rn "权限说明\|permissionVisible\|openXxxPermissionModal" <本次目录>/` 应为 0。
**例外**：删除的是"说明性文案弹窗"，不是权限逻辑本身。

---

## E — 导出 / 接口化 / 详情页 / API 类型（9 条）

### E-001 列表跳详情使用编码的 detail/:params

**适用**：仅当输入证据包含详情页及其跳转时适用；否则标记为 `not_applicable`，不得仅因本规范补造详情页。

**规则**：列表（或任意来源页）跳详情时，将 `id`、当前完整地址 `backUrl: route.fullPath`（含查询参数）及必要上下文一起传入 `encodeRouteParam`，并写入 `detail/:params` 路径。**不**使用旧的查询参数返回协议。
**正例**：`router.push(`/xxx/detail/${encodeRouteParam({ id: row.id, backUrl: route.fullPath })}`)`。
**自动检测**：`grep -rn "encodeRouteParam\|route.fullPath" <本次目录>/` 后核对详情跳转的编码对象同时包含 `id` 和 `backUrl`；路由定义为 `detail/:params`。
**Chrome 验证**：列表带筛选/分页进入详情 → URL 只有一个编码路径参数，详情正确解析 `id`。

### E-002 详情页单次解码后返回 backUrl

**适用**：仅当输入证据包含详情页及其跳转时适用；否则标记为 `not_applicable`，不得仅因本规范补造详情页。

**规则**：详情页只创建一个 `routeParams` 解码源（`decodeRouteParam(route.params.params as string)`），从中读取 `backUrl`；返回时先 `closeCurrent()`，再跳转解码后的 `backUrl`，缺失或非法参数才走默认路径。**不**读取旧的查询参数返回值，**不**用 `router.back()`，**不**在多个位置重复解码。
**自动检测**：`grep -rn "decodeRouteParam\|router.back()" <本次目录>/`；人工核对解码只有一个来源、没有旧查询参数返回读取，且返回前调用 `closeCurrent()`。
**Chrome 验证**：从筛选/翻页后的列表进入详情再返回 → 恢复原完整地址且详情标签关闭；直接访问、缺少 `backUrl` 与非法编码均回退到默认路径。

### E-003 导出走后端接口（不用 Blob/createObjectURL/a.download）

**规则**：导出 Excel 走 `request.download` 返回文件流，前端 `download.excel(data, ...)`；**禁止** `new Blob` / `URL.createObjectURL` / `a.download` / 手写 XML 或 CSV 拼装；公共 utils 里也不留 `exportRowsToXls` 这类本地导出函数。
**自动检测**：`grep -rn "new Blob\|createObjectURL\|a.download\|exportRowsToXls" <本次目录>/` 应为 0。

### E-004 message.exportConfirm + 平铺 await

**规则**：导出二次确认用 `message.exportConfirm()`（系统统一文案「是否确认导出数据项？」），不自己写 `ElMessageBox.confirm` 文案；确认后、开始真实下载前统一 `ElMessage.warning('正在导出，请稍候...')`。确认框**平铺在 `try` 之外**，`try/finally` 只用来复位 `exportLoading`；按钮 `:loading="exportLoading"`；入参直接取 `queryParams`，**不**另设 `applied` 副本；文件名用 `formatDate(new Date(), 'YYYY-MM-DD')`，**不**用 `toISOString()`（UTC 会差一天）。
**自动检测**：`grep -rn "message\.exportConfirm\|download\.excel" <本次目录>/`。

### E-005 列表筛选与分页走接口（不本地 filter+slice）

**规则**：筛选条件与分页参数必须一起传给后端；**禁止**页面里出现基于全量数据的 `computed` 过滤 + `slice` 分页、`total = computed(() => rows.length)`、`rows.slice((pageNo-1)*pageSize, ...)`。
**自动检测**：`grep -rn "\.slice((\|filter((" <本次目录>/` 在分页/筛选处应为 0。
**例外**：源无分页的整表页面（E-006 过渡形态）允许前端 `slice` 切分。

### E-006 源无分页也要补 Pagination（过渡：前端 slice）

**规则**：源没有分页控件时，若页面属于列表交付形态，也按统一形态加 `<Pagination>`（已授权的过渡形态：前端 `slice` 切分全量数组算 `total` 给分页器用，不依赖后端；保留「整表返回」接口形态不变）。非列表、静态概览或源中明确不可分页的表格标记为 `not_applicable`；待后端按分页提供时再补 `pageNo` / `pageSize` 入参与 `pageNo = 1` 重置，并在结果文档标注。
**自动检测**：`grep -rn "Pagination" <本次目录>/` 数量应与列表数一致。
**Chrome 验证**：空数据时 `Pagination` 的 `total = 0` 自动隐藏。

### E-007 API 文件原样透传

**适用**：仅适用于 `dist-to-vue3` 生成的 API 预留位，或已确认 `apifox-link` 范围内的 API 文件；`html-to-vue3` 不创建 API 文件，应标记为 `not_applicable`。

**规则**：按 [standards.md](./standards.md) 的 API 最小契约检查：API 文件只包含接口契约类型、API 方法、必要请求封装 import 与接口证据/TODO 注释。每个方法仅接受一个 `params`（GET）或 `data`（POST/PUT/DELETE）入参，并原样透传；不得出现字段改名、参数拼装、类型转换、默认值、业务校验、响应 `map`/解包/格式化等业务处理。业务适配放在调用方或页面邻近的 `utils.ts`。
**自动检测**：人工检查 `src/api/<本次模块>/`；使用 `grep -rn "\.map(\|parseInt\|String(\|Number(" src/api/<本次模块>/` 筛查高风险处理，再核对是否属于业务转换。

### E-008 未显式 apifox-link 时不发真实请求

**规则**：`html-to-vue3` 不创建 API 文件；`dist-to-vue3` 仅生成类型和无真实调用的预留方法。未收到用户显式 `apifox-link` 授权时，转换与浏览器验证不得发起真实读写请求，写操作尤其不得执行；需要对接的条目必须标记为后续 `apifox-link`，浏览器验证也不得把真实接口成功响应作为转换完成证据。
**自动检测**：人工核对本次范围的 API 方法均为 Mock/安全空实现/预留位，并检查结果文档没有将未对接条目标为真实接口成功。

### E-009 契约类型集中在 API 文件上部

**适用**：`dist-to-vue3` 生成的 API 文件，以及 `apifox-link` 已接入的 API 文件；`html-to-vue3` 不创建 API 文件，标记为 `not_applicable`。

**规则**：接口契约的 `type` / `interface`（请求入参、响应体、行/项、字典枚举）只定义在 `src/api/{业务模块}/*.ts`（或同模块 `types.ts`），不写进 `src/views/**`、页面 `utils.ts` 或 `src/types/**`。同一 API 文件内固定三段顺序：`import` → 类型区（全部 `type` / `interface`，连同文档注释和分段注释一起在上）→ 接口方法区（`export const` 方法与运行时常量）；类型不得穿插在方法之间或写在方法之后。方法签名不留匿名对象类型：`(params: { pageNo: number; … })`、`request.get<{ list: X[]; total: number }>` 都要提取成类型区的命名 `interface`，分页响应复用全局 `PageResult<T>`，同文件已有同形状类型直接引用不重复声明。**豁免**：组件本地类型留在组件内——`interface Props` / `interface Emits` / 弹窗 `open()` 参数形状 / composable 入参与返回 / `Pick`、`Omit` 派生的纯 UI 类型；判定口径是「描述后端契约还是描述前端控件形态」。
**自动检测**：`grep -nE "^\s*(export )?(interface|type) |^\s*export const" src/api/<本次模块>/` 核对首个 `export const` 之后不再出现类型声明；`grep -rnE "\((params|data)[A-Za-z0-9_]*\s*:\s*\{|request\.(get|post|put|delete|upload|download)<\{" src/api/<本次模块>/` 应为 0；`grep -rnE "^\s*(export )?(interface|type) [A-Za-z]" <本次目录>/` 的命中应全部属于豁免类别，出现 `*ReqVO` / `*RespVO` 一类契约命名即为契约外流。

---

## 附：转换完成后的执行顺序建议

1. **B / T / F / V / P / D / S 类**全部跑 `grep` 自动检测（每条 30 秒内）。
2. **R / U / E 类**部分需人工核对（自动检测覆盖的是"绝对不能写"，人工核对的是"应该写但 grep 抓不到"）。
3. **Chrome 验证**：启动 dev server → Chrome DevTools MCP 逐项打钩（50+ 项）。
4. **结果文档**：按本清单 ID 引用偏差，每条偏差可定位到具体 checklist 条目。
5. **工程校验**（`pnpm ts:check`、`npx eslint --ext .ts,.vue` 不带 `--fix`）由 [standards.md](./standards.md) 执行。

---

## 与其它规范的引用

- 转换边界、输出目录、Vue 实现基线、API/路由最小契约和工程校验：[standards.md](./standards.md)
- 确认门禁、变更范围保护和结果记录：[result-contract.md](./result-contract.md)