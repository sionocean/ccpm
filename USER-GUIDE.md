# 用户指南

## 命令列表

### 工作区与初始化
- `.claude/scripts/pm/workdir-type.sh`：判断当前路径是主仓库还是 Git worktree。
- `/pm:help` → `help.sh`：输出命令速查表及常用工作流。
- `/pm:init` → `init.sh`：检查并安装 `gh` CLI 与扩展、认证 GitHub、创建目录结构、复制脚本并生成 `CLAUDE.md`。
- `/init include rules from .claude/CLAUDE.md`、`/re-init`：仓库未提供对应脚本，推测由平台注入或更新规则。

### PRD 命令
- **`/pm:prd-new <feature_name>`**：启动新需求的头脑风暴并生成带前置信息的 PRD 文件
- **`/pm:prd-parse <feature_name>`**：把已有 PRD 转换成实现用的 epic，生成包含技术方案与任务预览的 `epic.md`
- **`/pm:prd-edit <feature_name>`**：交互式编辑 PRD 各部分内容，更新 `updated` 时间戳并提示相关 epic 是否需同步调整
- `/pm:prd-new`、`/pm:prd-parse`、`/pm:prd-edit`：未找到脚本。
- `/pm:prd-list` → `prd-list.sh`：按 backlog/in-progress/implemented 分组列出 PRD，并统计数量。
- `/pm:prd-status` → `prd-status.sh`：统计各状态 PRD 数量，打印简单柱状分布及最近修改的 PRD。

### Epic（史诗）
- **`/pm:epic-decompose <feature_name>`**：读取 `epic.md` 后拆分为编号任务文件，必要时并行创建
- **`/pm:epic-sync <feature_name>`**：将 epic 及任务同步到 GitHub，并建立本地工作树与映射文件
- **`/pm:epic-oneshot <feature_name>`**：顺序执行“拆分 + 同步”，一步完成任务分解与 GitHub 发行同步
- **`/pm:epic-close <epic_name>`**：确认所有任务关闭后把 epic 标记为完成，可选归档目录并关闭 GitHub issue
- **`/pm:epic-edit <epic_name>`**：允许修改 epic 描述、架构决策等内容，必要时同步更新对应的 GitHub issue
- **`/pm:epic-refresh <epic_name>`**：统计任务状态计算进度，更新 epic 的 `status`/`progress` 并勾选 GitHub 任务列表
- **`/pm:epic-start <epic_name>`**：在 `epic/<name>` 分支上启动可并行执行的任务，记录执行状态并分派子代理
- **`/pm:epic-merge <epic_name>`**：将完成的 epic 工作树合并回主分支，关闭相关 issue 并归档 epic 数据
- `/pm:epic-decompose`、`/pm:epic-sync`、`/pm:epic-oneshot`、`/pm:epic-close`、`/pm:epic-edit`、`/pm:epic-refresh`、`/pm:epic-start`、`/pm:epic-merge`：未找到脚本。
- `/pm:epic-list` → `epic-list.sh`：按规划/进行中/已完成分类列出 epics，并统计任务数。
- `/pm:epic-show <name>` → `epic-show.sh`：展示指定 epic 的元数据、任务状态及下一步建议。
- `/pm:epic-status <name>` → `epic-status.sh`：汇总任务完成度，绘制进度条并显示 open/blocked/closed 数。

### Issue（任务）
- **`/pm:issue-show <issue_number>`**：显示 GitHub issue 详情、关联任务与最近活动，便于快速了解上下文
- **`/pm:issue-status <issue_number>`**：查询 issue 当前状态、标签与本地同步情况，给出后续操作建议
- **`/pm:issue-start <issue_number>`**：依据分析文件划分并行工作流，在 epic 工作树中启动对应代理
- **`/pm:issue-sync <issue_number>`**：把本地 `updates/` 中的进展整合为 GitHub 评论，同时更新任务与 epic 的前置信息
- **`/pm:issue-close <issue_number>`**：将任务标记为完成并关闭 GitHub issue，勾选 epic 中的任务复选框
- **`/pm:issue-reopen <issue_number>`**：重新打开已关闭任务，恢复本地与 GitHub 状态并重新计算 epic 进度
- **`/pm:issue-edit <issue_number>`**：更新任务标题、描述或标签，先改本地文件再同步至 GitHub
- **`/pm:issue-analyze <issue_number>`**：分析任务可并行的工作流，生成 `*-analysis.md` 并评估并行效率
- `/pm:issue-show`、`/pm:issue-status`、`/pm:issue-start`、`/pm:issue-sync`、`/pm:issue-close`、`/pm:issue-reopen`、`/pm:issue-edit`、`/pm:issue-analyze`：未找到脚本。

### 工作流管理
- `/pm:next` → `next.sh`：扫描所有 epic，列出无未完成依赖的可开工任务。
- `/pm:status` → `status.sh`：统计 PRD、epic、任务总数及任务开闭状态。
- `/pm:standup` → `standup.sh`：生成今日修改记录、进行中的 issue 及下一个可执行任务的简报。
- `/pm:blocked` → `blocked.sh`：查找存在未完成依赖的任务并列出阻塞来源。
- `/pm:in-progress` → `in-progress.sh`：展示 `updates/` 目录下正在进行的 issue 及进度，并列出状态为 in-progress 的 epics。

### 同步与维护
- `/pm:sync`、`/pm:import`、`/pm:clean`：未找到脚本。
- `/pm:validate` → `validate.sh`：检查 `.claude` 目录结构、任务引用、frontmatter 等完整性。
- `/pm:search <query>` → `search.sh`：在 PRD、epic、任务中全文检索关键词并统计结果。

### 上下文管理
- `/context:create`：分析项目结构并生成 `.claude/context/` 下的多份基线文档，作为项目上下文
- `/context:update`：依据最近代码变动更新各类上下文文件，精确记录变更并维护时间戳
- `/context:prime`：在新会话开始时按优先级加载上下文文件并检查完整性，为代理提供项目背景
- `/context:create`、`/context:update`、`/context:prime`：未找到脚本。

### 测试命令
- `/testing:prime`：自动探测测试框架与依赖，生成测试配置并准备测试代理
- `/testing:run [target]`：使用测试代理执行全部或部分测试，输出简明结果并在失败时给出分析
- `/testing:prime`、`/testing:run`：未找到脚本；仓库提供 `test-and-log.sh`，可运行指定 Python 测试并将输出写入 `tests/logs/*.log`。

### 其他工具
- `/prompt`：当复杂提示无法直接输入时，把内容写入专用文件后用该命令触发执行
- `/code-rabbit`：处理 CodeRabbit 代码审查意见，基于上下文判断是否采纳并可并行处理多文件建议
- `/re-init`：将 `.claude/CLAUDE.md` 里的规则重新注入或追加到根目录 `CLAUDE.md` 中
- `/compact`、`/clear`：在 `.claude/commands/` 目录下未找到对应说明文件

## 推荐工作流

### 1. 简单任务：单个功能程序
1. `/pm:init` → 初始化环境，必要时 `/re-init` 更新规则。  
2. `/context:prime` → 加载上下文。  
3. `/pm:prd-new`（若需正式规格）或直接 `/pm:issue-start <id>` 启动任务。  
4. 开发过程中：  
   - `/pm:issue-sync <id>` 定期同步进度。  
   - `/testing:run <target>` 运行相关测试。  
5. 完成后：`/pm:issue-close <id>`，如任务属于某个 epic，再执行 `/pm:epic-refresh <epic>` 更新进度。

### 2. 中型任务：多个功能程序
1. **需求阶段**  
   - `/pm:prd-new <feature>` 编写 PRD。  
   - `/pm:prd-parse <feature>` 生成 epic。  
2. **规划与同步**  
   - `/pm:epic-decompose <feature>` 拆分任务。  
   - `/pm:epic-sync <feature>`（或 `/pm:epic-oneshot`）同步到 GitHub。  
3. **并行执行**  
   - 使用 `/pm:issue-start <id>` 启动各任务；  
   - `/pm:issue-sync <id>`、`/testing:run` 在开发中保持更新。  
4. **追踪与管理**  
   - `/pm:epic-show <feature>`、`/pm:status`、`/pm:standup` 查看整体情况；  
   - `/pm:blocked`、`/pm:next` 辅助调度。  
5. **收尾**  
   - 所有任务关闭后 `/pm:epic-close <feature>`；  
   - `/pm:clean` 归档并整理。

### 3. 大型项目：多阶段、多功能、长期维护
1. **初始搭建**  
   - `/pm:init` → `/context:create` → `/pm:prd-new` 为核心阶段或模块撰写 PRD。  
2. **阶段规划**  
   - 对每个模块执行 `/pm:prd-parse` → `/pm:epic-decompose` → `/pm:epic-sync`，必要时分期迭代。  
3. **并行多团队执行**  
   - 各阶段内使用 `/pm:epic-start` 启动并行工作流；  
   - 日常通过 `/pm:standup`、`/pm:in-progress`、`/pm:blocked` 跟踪团队协作。  
4. **持续测试与同步**  
   - `/testing:prime` 设置测试环境；定期 `/testing:run`。  
   - `/pm:sync` 保持 GitHub 与本地一致，`/pm:import` 接入外部 issue。  
5. **维护与迭代**  
   - 使用 `/context:update`、`/pm:validate` 确保文档与结构健全；  
   - `/code-rabbit` 处理代码审查；  
   - 按阶段执行 `/pm:epic-merge`、`/pm:epic-close`，对新需求重复上述流程，形成长期循环。

### 4. 快速 Bug 修复
1. `/pm:issue-start <bug-id>` 直接基于现有 issue 启动修复流程。  
2. 修复过程中：  
   - `/testing:run <target>` 验证修复效果；  
   - `/pm:issue-sync <bug-id>` 记录修复进展。  
3. 解决后：  
   - `/pm:issue-close <bug-id>` 关闭 issue；  
   - 若影响到 epic，执行 `/pm:epic-refresh <epic>` 更新状态。  

```mermaid
graph LR
A[发现 Bug] --> B[issue-start]
B --> C[修复 & 测试]
C --> D[issue-sync]
D --> E[issue-close]
```

### 5. 文档或小改动
1. `/pm:init`（首次）或 `/context:prime`（已有上下文）  
2. `/pm:issue-start <id>` 处理文档/小改动任务。  
3. `/pm:issue-sync <id>` 提交进展，必要时 `/testing:run` 保障无回归。  
4. `/pm:issue-close <id>` 收尾并 `/pm:clean` 整理历史。

