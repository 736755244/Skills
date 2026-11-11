---
title: "Skill 结果契约与变更范围门禁"
category: reference
module: "skill 集"
tags: [skill, result, confirmation, scope]
---

# Skill 结果契约与变更范围门禁

本文件是技能集共用的结果和变更范围规范。各 Skill 只补充自身特有的字段、证据和流程，不重复定义通用状态。

## 1. 结果信封

每次执行都记录以下字段；字段没有内容时明确写“无”或“不适用”，不能省略导致误解：

- **skill / invocation**：Skill 名称、用户显式调用或其他合法入口及时间。
- **input**：来源、路径/URL、版本或快照信息。
- **scope**：用户选择的页面、条目、文件和明确未处理范围。
- **preconditions**：账号、后端、权限、浏览器、依赖等前置条件及结果。
- **planned_changes**：执行前展示的计划动作和精确路径清单。
- **items**：逐条记录 `subject`、`action`、`outcome`、`confirmation`、`evidence`、`reason`。HTML→Vue 转换以一个路由或一个完整 Tab 逻辑页面组为最小条目；未完成当前条目的源—Vue 对照、交互、格式化与验证前，不得预先记录后续条目为进行中或完成。
- **verification**：命令、真实浏览器动作、原始 HTML—Vue 对照清单与证据、Network、数据库页面、报告及截图等证据。HTML→Vue 转换的对照至少覆盖布局/区域顺序、固定数据/字段/表头、搜索和按钮图标、弹窗、Tab/URL/history 状态、交互结果及对应 snapshot、screenshot 或必要的 computed-style 证据。
- **blockers**：失败、阻塞、未执行和解除条件。
- **next_steps**：仅列建议，不自动调用其他 Skill。
- **conclusion**：按统一顶层状态给出结论。

顶层状态：`completed`、`partial`、`cancelled`、`failed`、`blocked`、`not_run`。

条目状态：`success`、`idempotent`、`skipped`、`cancelled`、`failed`、`blocked`、`not_run`。

`pending` 只描述等待确认的事项，不作为完成状态。存在未确认或未执行条目时，不得使用 `completed`。

## 2. 三类确认门禁

1. **显式调用确认**：独立 Skill 只能由用户当前消息明确调用，不能由其他 Skill 自动串联。
2. **文件范围确认**：移动、重命名、路由接线、页面改动和删除前，展示精确路径、动作和未涉及范围。
3. **外部副作用确认**：数据库写入或真实业务写请求前，逐项展示并取得用户确认。

确认绑定展示过的清单版本。路径、动作或条目发生变化时，原确认失效，必须重新展示并确认。

## 3. 存量代码保护

优化、格式化、自动修复和重构只允许作用于本次新增的页面、子组件、Mock 和对应新增路由。已有文件只能做完成最小接线所需的局部修改，不得夹带格式化、重排或风格统一。

全库、目录级或无法精确限定到本次新增产物的操作，包括 `--fix`、格式化、codemod、批量替换和恢复，必须先展示影响范围、预期改动和备份位置，获得用户本人明确确认后执行。不得自动使用 `git checkout`、`git reset` 或其他覆盖性恢复命令。

## 4. 证据与真实性

结果区分文件证据、工程命令、Chrome DevTools MCP、Network、数据库页面和 Playwright 报告。静态检查、编译或脚本输出不能替代真实页面操作；转换用 Chrome DevTools MCP 与 UI 回归用 Playwright Chrome 不能互相替代。失败、阻塞、未执行和待确认不得汇总为完成。

## 5. 通用结果模板

```text
# {skill} 结果
状态：completed / partial / cancelled / failed / blocked / not_run
调用：...

## 输入与范围
- 输入：...
- 已处理：...
- 未处理：...

## 前置与计划变更
- 前置条件：...
- 计划清单：...
- 确认记录：...

## 条目结果
| 条目 | 动作 | 状态 | 确认 | 证据 | 原因 |
|---|---|---|---|---|---|
| ... | ... | success / ... | ... | ... | ... |

## 验证
- 命令：...
- 浏览器/Network/数据库/Playwright：...
- 失败修复与回归：...

## 阻塞与后续
- 阻塞：...
- 后续：仅等待用户决定，不自动串联
```
