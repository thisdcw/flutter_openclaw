# OpenClaw 聊天命令整理

## 先说结论

OpenClaw 聊天命令分成 4 层：

1. Gateway 后端稳定命令
   - 通过聊天消息发送 /...
   - 由 Gateway 解析
   - 这是你客户端最应该支持的一层

2. Directive 指令型命令
   - 例如 /think、/fast、/model
   - 可以作为独立消息发送
   - 某些情况下也能嵌在普通消息里作为 inline hint

3. Inline shortcut 内联快捷命令
   - 例如 /status、/help
   - 只对授权 sender 生效
   - 可以出现在普通消息中

4. 客户端本地命令
   - 例如 Control UI 里的 /clear
   - 不是文档中的后端稳定 slash command
   - 更像客户端自己拦截执行的本地动作

所以：

- 宿主机 AI 优化客户端时，必须区分“发给 Gateway 的命令”和“客户端本地拦截命令”
- /clear 不能直接当成后端稳定 slash command 来依赖

## 规则总览

### 1. 大多数命令必须是独立消息

官方文档明确说明：

- 大多数命令必须作为 独立消息 发送
- 格式是整条消息以 / 开头

例如：

```text
/new
/status
/model openai/gpt-5.4
/usage full
```

### 2. 有些命令属于 directives

这些命令既可以独立发送，也可以作为消息中的“指令提示”：

- /think
- /fast
- /verbose
- /reasoning
- /elevated
- /exec
- /model
- /queue

规则：

- directive-only message：如果一整条消息只有这些 directives，它们会持久化到 session 设置里
- inline directive：如果它们出现在普通消息中，只对本次消息生效，不持久化

例如：

```text
/think high
```

会修改会话默认 thinking。

而：

```text
请先 /think high 再帮我分析下面这段代码
```

更像本次请求的提示，不应被客户端当成“切换设置成功”来展示。

### 3. 只有少数命令支持 inline shortcut

官方文档明确列出的 inline shortcuts：

- /help
- /commands
- /status
- /whoami
- /id

这些命令：

- 对授权 sender 可以在普通消息中生效
- 会先运行
- 然后剩余文本继续走正常对话流程

例如：

```text
hey /status
```

### 4. 命令支持可选冒号语法

文档明确说明命令和参数之间可以带冒号：

```text
/think: high
/send: on
/help:
```

客户端解析时建议同时兼容：

- /think high
- /think: high
- /think:high

## 推荐给客户端优先支持的稳定命令

下面这些命令都来自官方 slash-commands 文档或相关概念文档，适合作为客户端的一线能力。

### A. 会话类

- /new [model]
  - 开始一个新 session
  - /new <model> 还会切换模型
- /reset
  - /new 的 reset alias
- /compact [instructions]
  - 压缩当前上下文
- /stop
  - 中止当前运行
- /session idle <duration|off>
  - 设置线程/会话空闲过期
- /session max-age <duration|off>
  - 设置线程/会话最大生命周期

客户端建议：

- 这组命令应强制作为独立消息发送
- /new、/reset 建议做显式按钮入口
- /compact 适合在“上下文过长”或“多图对话前”提供快捷入口

### B. 状态与诊断类

- /status
  - 查看当前 session 状态、模型、context、usage
- /usage off|tokens|full|cost
  - 设置或查看 usage 展示
- /context [list|detail|json]
  - 查看上下文构成
- /tools [compact|verbose]
  - 查看当前 agent 实际可用工具
- /tasks
  - 查看当前 session 的后台任务
- /help
  - 简短帮助
- /commands
  - 命令目录
- /whoami
- /id

客户端建议：

- /status、/help、/commands 很适合做快捷菜单
- /status 同时属于 inline shortcut，客户端可以保守支持“独立消息”和“快捷菜单触发”两种方式
- /context 和 /tools 更适合放在高级调试面板，不必默认暴露给普通用户

### C. 模型与推理控制类

- /model [name|#|status]
- /models [provider] [page] [limit=<n>|size=<n>|all]
- /think <off|minimal|low|medium|high|xhigh>
  - alias: /thinking, /t
- /fast [status|on|off]
- /verbose on|off|full
  - alias: /v
- /reasoning [on|off|stream]
  - alias: /reason
- /elevated [on|off|ask|full]
- /exec host=<...> security=<...> ask=<...> node=<id>
- /queue <mode> ...

客户端建议：

- 这组命令最适合做设置面板，而不只是文本输入
- 其中 /model、/think、/fast、/verbose、/reasoning 最值得做成 UI 控件
- 即便 UI 控件最终仍是通过发送 slash command 实现，也要在产品层把它们视为“会话设置”而不是普通聊天文本

### D. 管理与高级功能类

- /skill <name> [input]
- /allowlist [list|add|remove] ...
- /approve <id> <decision>
- /btw <question>
- /subagents ...
- /acp ...
- /focus <target>
- /unfocus
- /agents
- /kill <id|#|all>
- /steer <id|#> <message>
  - alias: /tell
- /config ...
- /mcp ...
- /plugins ...
- /debug ...
- /restart
- /activation mention|always
- /send on|off|inherit
- /bash <command>
  - alias: ! <command>

客户端建议：

- 这组命令不适合默认暴露给普通聊天用户
- 更适合高级面板、管理员模式、开发者模式
- /config、/mcp、/plugins、/debug、/bash 应明确标为高风险操作

## 需要特别说明的 commands

### /model

这是最重要的会话级设置之一。

官方文档确认支持：

```text
/model
/model list
/model 3
/model openai/gpt-5.4
/model status
```

客户端建议：

- 做模型选择器时，不要只靠发裸文本
- 最好缓存 /model 与 /models 返回结果，做 provider/model picker
- 用户切换模型后，UI 要把它当成 session 状态变化

### /think

官方文档确认支持：

- off | minimal | low | medium | high | xhigh | adaptive
- alias: /thinking, /t

客户端建议：

- 做成 dropdown 比让用户手敲更稳
- 不同 provider 实际支持不同，UI 可以在基础层先统一选项，再做 provider-aware 降级

### /fast

官方文档确认支持：

- /fast
- /fast status
- /fast on
- /fast off

客户端建议：

- 这是典型 session toggle，适合 switch
- 文档明确说 provider-specific，不同模型实现不同，不要在客户端写死为“加速模式一定等于低质量”之类的语义

### /verbose 与 /reasoning

这两个都属于高风险可见性控制：

- /verbose on|off|full
- /reasoning on|off|stream

官方文档明确提醒：

- 在群聊里它们可能暴露内部 reasoning 或 tool output

客户端建议：

- 群聊里默认隐藏这两个选项
- 如果要提供，至少加警告文案

## /clear 应该怎么理解

这是你特别提到的命令。

我本地核对后的结论：

- /clear 不是官方 slash-commands 文档里的核心内建命令
- 但在 Control UI 前端运行时代码中，存在一个 本地执行 的 clear command
- 它属于 client-local command，不是后端稳定命令源

也就是说：

- OpenClaw 官方稳定文档主要讲 /new、/reset
- Control UI 额外实现了 /clear
- /clear 更像“客户端清空/重置当前聊天视图并调用相关 session reset 行为”的本地能力

对你自己的客户端，建议这样处理：

- 可以实现 /clear
- 但把它定义成 客户端本地命令，不要假设所有 OpenClaw surface 都支持它
- 在产品文档里把 /clear 和 /new、/reset 明确区分开

推荐策略：

- /new、/reset：视为后端稳定 session command
- /clear：视为客户端 convenience command

## 对宿主机 AI 的客户端优化建议

你可以直接把下面这些要求给宿主机上的 AI：

1. 支持 standalone slash command 检测。
2. 将命令分成 4 类：
   - session
   - status/debug
   - model/options
   - admin/advanced
3. 对 /model、/think、/fast、/verbose、/reasoning 提供 UI 控件，不只支持手输。
4. 仅把 /help、/commands、/status、/whoami、/id 视为 inline shortcut 候选。
5. /new、/reset、/compact、/stop 默认要求独立消息发送。
6. /clear 作为 客户端本地命令 实现，不作为后端稳定命令依赖。
7. 对高风险命令分级展示：
   - 普通用户：session/status/model
   - 高级用户：tools/context/usage
   - 管理员：config/plugins/debug/bash
8. 兼容命令冒号语法：
   - /think high
   - /think: high
9. 客户端帮助面板优先展示高频命令：
   - /new
   - /reset
   - /status
   - /model
   - /think
   - /fast
   - /usage
   - /compact
10. 群聊环境中默认隐藏或弱化 /verbose 和 /reasoning。

## 高频命令建议清单

如果你只想给宿主机 AI 一份最实用的首屏命令集，推荐：

- /new
- /reset
- /status
- /model
- /think
- /fast
- /usage
- /compact
- /stop
- /help

## 最后的判断标准

开发客户端时，命令优先级建议按下面排序：

1. 文档确认的后端稳定命令
2. 文档确认的 directives / inline shortcuts
3. 运行时代码里存在的客户端本地命令
4. 不要把 Control UI 本地行为误当成 Gateway 官方协议
