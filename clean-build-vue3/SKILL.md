---
name: clean-build-vue3
description: "在展示精确清单并取得确认后，清理 Vue3 转换/还原产物。Actions: clean-build-vue3, clean-vue3, 清理构建。"
---

# clean-build-vue3

清理 `html-to-vue3` 的 prototype 产物和 `dist-to-vue3` 的 restore 产物。本 Skill 独立执行，不自动开始转换、接口、权限或测试。通用确认、状态和存量文件保护见 [结果契约](../transfer-to-vue3/result-contract.md)。

## 清理范围

| 模块 | 页面范围 | 路由范围 |
|---|---|---|
| `prototype` | `src/views/prototype/`（含页面 Mock）及历史 `src/api/prototype/` | `remaining.ts` 内带转换分组标记的 prototype 分组 |
| `restore` | 从 `src/router/modules/restore.ts` 的 `component` 路径解析出的**具体页面目录**（含组件和 Mock），以及历史 `src/api/restore/`、`src/views/restore/` | `restore.ts` 与 `remaining.ts` 中的 import/展开项 |

restore 绝不删除语义父目录，例如只删除 `src/views/order/lead/`，不得删除 `src/views/order/` 的其他业务页面。`mock.ts` 随页面目录处理，无顶层 `src/mock/` 清理目标。

待删 restore 页面目录必须同时满足：在带转换标记的 `restore.ts` 分组中被引用、位于用户确认的冻结清单、且可由本次转换结果或路由标记证明归属。若目录被非 restore 路由/非本次变更引用，或无法证明属于转换产物，则不删除并标记 `blocked`。

支持两种范围：

- **src-only**：只删用户确认的产物和路由，保留 `.middleproduct/`。
- **all**：在 src-only 基础上删除用户确认的 `.middleproduct/` 内容。

## 执行流程

1. **扫描**：检查 prototype 目录/路由、`restore.ts`、restore 组件路径、遗留目录与 `.middleproduct/`；将路径解析为不可变的计划删除清单。
2. **展示并确认**：展示模块、`src-only`/`all`、每个准确路径、路由编辑和 `.middleproduct` 处置。用户取消、未确认或范围变化时不删除，范围变化后重新生成清单并确认。
3. **执行**：只使用已确认的冻结清单删除目录/文件，并用精确 Edit 移除对应路由接线；不得在执行阶段重新从 `restore.ts` 动态推导范围，不得模糊匹配或删除用户原有文件。
4. **校验与报告**：核对计划与实际路径、路由引用和失败项。删除后只读确认 `restore.ts`、`remaining.ts` 不残留 import/spread/component 引用，也不存在指向已删目录的静态 import；计划路径和实际删除路径必须一一对应。`.middleproduct/` 被删除时，在删除前保留结果或在最终回复中如实说明结果文件无法留存。

## 结果

按 [结果契约](../transfer-to-vue3/result-contract.md) 输出；条目必须记录计划路径、实际路径、确认、删除/跳过/失败原因和 `.middleproduct` 的保留或删除状态。删除不可恢复，未确认、取消、失败和部分完成均不得宣称成功。
