# 代码地图

> 将代码结构和调用流程整理成可交互、可离线打开的 HTML 导览图。

代码地图用于把一次迭代、一个需求、一次变更或一个项目模块讲清楚。产物为单个交互式 HTML 文件：读者可从工程树、模块关系图、调用时序和说明卡之间自由跳转，也可沿顶部导览按顺序理解主题。

## 能力

- **工程树**：展示与主题相关的模块、类、接口和方法，支持搜索、折叠与状态标记。
- **多图联动**：支持模块全景图、核心时序图和关键流程图；点击任一节点可定位关联内容。
- **说明卡**：为关键节点说明职责、设计规则、变更影响和容易遗漏的边界。
- **导览路径**：将复杂主题拆成连续站点，适合设计沟通、变更说明和项目导读。
- **离线交付**：Mermaid 资源本地打包，HTML 可直接打开和归档。

## 适用场景

| 场景 | 输入 | 输出重点 |
|---|---|---|
| 教学或技术说明 | 一段代码、一项功能或已有文档 | 从结构到调用链的完整讲解 |
| 迭代对比 | 两个 Git 基线或工作区变更 | 改动、动机、影响面与回归重点 |
| 需求蓝图 | 需求描述和现有结构 | 目标态结构、实现顺序与验收条件 |
| 变更讲解 | 当前分支或指定变更范围 | 变更意图、实现方式与关注点 |
| 架构导读 | 项目核心模块和典型请求 | 分层职责与一次请求的生命周期 |

## 快速开始

```bash
# 校验现有地图
node scripts/validate-map.js <地图.html>

# 在具备 Node 22+ 和 Chrome 时进行渲染验收
node scripts/render-map.mjs --html <地图.html>

# 由项目地图数据生成地图
node scripts/build-map.mjs --data <map-data.json> --out <输出目录>
```

生成时建议在目标项目中准备一份 JSON 数据，并输出到 `docs/code-map/<主题>/`。完整数据格式见 [references/data-spec.md](references/data-spec.md)，不同任务的素材和叙事规则见 [references/scenarios.md](references/scenarios.md)。

## 生成流程

```text
识别场景 → 收集项目事实 → 构建地图数据 → 静态校验 → 渲染验收 → 交付
```

- **引擎固定**：`assets/code-map-template.html` 负责渲染与交互；生成内容只写入 `MAP-DATA` 数据区。
- **数据驱动**：按 [references/data-spec.md](references/data-spec.md) 准备项目地图数据，`scripts/build-map.mjs` 会将其写入模板并执行必要校验。
- **事实优先**：变更图以当前项目与实际 Git 基线为准；需求设计图必须明确是目标态，不将建议描述为已经实现。
- **联动可校验**：工程树节点以 `kw` 关联图中的文本锚点，校验器会检查断链。

## 质量验收

静态校验必须为 0 错误：

```bash
node scripts/validate-map.js <地图.html>
```

在可用环境中继续执行渲染验收：

```bash
node scripts/render-map.mjs --html <地图.html>
```

渲染验收会检查图形渲染、页签切换、三栏联动、搜索、导览和运行时错误，并在成功时导出可用的 SVG、PNG 与验证报告。

## 目录结构

```text
coding-map/
├── SKILL.md                      # 技能入口与工作流
├── assets/
│   ├── code-map-template.html    # 渲染引擎与最小地图数据骨架
│   └── vendor/mermaid.min.js     # 本地 Mermaid 运行库
├── references/
│   ├── data-spec.md              # 数据字段、联动与语法规则
│   └── scenarios.md              # 场景化素材与导览规范
├── scripts/
│   ├── extract-diff.sh           # Git 变更采集
│   ├── build-map.mjs             # JSON 生成 HTML
│   ├── render-map.mjs            # 浏览器渲染验收与导出
│   └── validate-map.js           # 静态一致性校验
```

使用产物时：先从顶部导览把握主线，再按需点击工程树、图和说明卡探索细节。