# Flutter 接 OpenClaw 的 Canvas / 图片生成处理说明

本文用于说明：

- 当 assistant 回复里出现 `"action": "canvas"`、`"action": "eval"`、`"javaScript": "..."` 这类内容时，Flutter 应该怎么处理
- OpenClaw 的 canvas 能力和普通聊天消息到底是不是一回事
- 如果你要让 Flutter 真正支持 OpenClaw canvas，需要补哪些宿主能力

## 先说结论

你这次遇到的这段内容：

```json
{
  "action": "canvas",
  "params": {
    "action": "eval",
    "javaScript": "/* ... */"
  }
}
```

在当前会话日志里，是作为 assistant 的普通文本保存的，不是一个已经确认的结构化 Gateway 事件。

所以对 Flutter 客户端来说：

- 不能把这段文本当成真实指令执行
- 不能把里面的 `javaScript` 拿去 `evaluateJavascript`
- 默认应该把它当成普通文本，或者当成“模型幻觉出的伪动作”

## 为什么不能直接执行

因为 OpenClaw 里至少有 3 个不同层级：

1. 聊天消息层
   - 例如 `chat.send`
   - 用户发 `message + attachments`
   - assistant 回文本、图片理解结果等

2. Canvas 宿主层
   - 依赖单独的 canvas host URL
   - 依赖原生桥
   - 依赖结构化用户动作和结构化 UI 更新

3. 模型自己生成的文本
   - 模型可能会“说”出看起来像 JSON、JS、tool call 的内容
   - 但它只是文本，不代表系统真的要求客户端执行

你这次的问题，属于第 3 类伪装成第 2 类。

## 这次问题的根因判断

更像是下面两种情况之一：

1. 入口没走到真正的图片生成工具/宿主通道
   - 模型只能用文本回答
   - 于是它把“本应系统内部执行的动作”描述成了文本

2. 当前 Flutter 客户端只是普通聊天客户端
   - 没有实现 OpenClaw node/canvas 宿主能力
   - 模型没有拿到真实可用的 canvas 执行环境

这意味着：

- 如果你只是普通聊天 App，不需要为了这段文本去执行 JS
- 如果你真要支持 canvas，应该实现受控宿主桥，而不是解析 assistant 文本

## Flutter 的安全默认实现

这是最推荐的第一阶段实现。

规则：

1. 只把 Gateway 的结构化协议当成可信输入
2. 只把 `chat.send` 的正常响应当成聊天结果
3. assistant 文本中即使出现：
   - `action`
   - `canvas`
   - `eval`
   - `javaScript`
   也一律不执行
4. 这些内容只能：
   - 原样显示
   - 记录日志
   - 或提示“模型返回了未受支持的文本动作”

也就是说，Flutter 端至少要有这一条硬规则：

```text
不要从 assistant 文本里提取 JSON 并执行，不要从 assistant 文本里执行 JS。
```

## 什么时候才算真正的 canvas 能力

只有收到 OpenClaw 的受信任结构化信息，才说明 canvas 能力真实存在。

目前本地代码里能确认的可信入口有两类：

### 1. 连接握手里的 `canvasHostUrl`

OpenClaw 在节点连接成功后的 `hello-ok` 结构里，会带出：

- `canvasHostUrl`

这说明 canvas 不是聊天文本，而是连接级能力元数据。

### 2. `node.canvas.capability.refresh`

OpenClaw Gateway 提供了结构化方法：

- `node.canvas.capability.refresh`

返回：

- `canvasCapability`
- `canvasCapabilityExpiresAtMs`
- `canvasHostUrl`

这说明 canvas host 是一个单独的、带 capability 的受控入口。

## 这说明了什么

这说明 OpenClaw 的 canvas 设计是：

- 通过结构化连接元数据暴露 canvas host
- 通过 scoped URL / capability 控制访问
- 通过原生桥转发用户动作

而不是：

- 让模型在聊天文本里随便输出一段 JS
- 然后客户端直接执行

## Flutter 如果不做 canvas，要怎么处理“生成图片”

最低可用策略：

1. 用户照常发送聊天请求
2. 如果模型真的生成了图片，客户端只显示结构化图片结果
3. 如果最后只收到文本描述，没有真正图片结果：
   - 就说明这次没有真正产出可显示图片
   - 不要从文本里的 `canvas/eval` 去补执行

也就是说：

- “图片生成” 和 “canvas 宿主” 不是必须绑定的
- 你的 Flutter 客户端完全可以先不支持 canvas
- 先把“真正返回的图片结果”显示好即可

## Flutter 如果要支持 canvas，需要做什么

这属于高级实现，和普通聊天页面是两套机制。

### 一. 需要一个 WebView 容器

Flutter 端需要一个专门承载 canvas host 的 WebView。

它加载的不是 assistant 文本，而是受信任的：

- `canvasHostUrl`

或者 OpenClaw 的 canvas host 页面。

### 二. 需要实现原生桥名称

OpenClaw 自带页面明确依赖下面两个桥名之一：

- iOS:
  - `window.webkit.messageHandlers.openclawCanvasA2UIAction.postMessage(...)`
- Android:
  - `window.openclawCanvasA2UIAction.postMessage(...)`

页面里还会用辅助方法：

- `window.openclawSendUserAction(...)`

所以 Flutter WebView 侧要做的不是执行 assistant 文本，而是提供这两个桥中的一个。

### 三. 桥上传输的是结构化 `userAction`

页面向宿主发送的不是任意 JS，而是结构化消息，形态接近：

```json
{
  "userAction": {
    "id": "a2ui_xxx",
    "name": "hello",
    "surfaceId": "main",
    "sourceComponentId": "demo.hello",
    "timestamp": "2026-04-12T00:00:00.000Z",
    "context": {
      "t": 1234567890
    }
  }
}
```

Flutter 宿主应该：

1. 收到这条结构化消息
2. 校验字段
3. 转发给你自己的 OpenClaw 节点/网关逻辑
4. 不要执行消息里不存在的任意脚本

### 四. 页面会监听动作状态事件

OpenClaw canvas 页面会监听：

- `openclaw:a2ui-action-status`

所以如果你的 Flutter 宿主需要把“动作已发送成功/失败”回传给页面，可以向 WebView 注入类似事件：

```js
window.dispatchEvent(new CustomEvent("openclaw:a2ui-action-status", {
  detail: {
    id: "a2ui_xxx",
    ok: true,
    error: null
  }
}));
```

如果失败，则：

```js
window.dispatchEvent(new CustomEvent("openclaw:a2ui-action-status", {
  detail: {
    id: "a2ui_xxx",
    ok: false,
    error: "send failed"
  }
}));
```

这一步属于高级增强，不是普通聊天必需项。

## 给宿主机 AI 的实现要求

你可以直接把下面这段给宿主机上的 AI：

1. Flutter 聊天层和 canvas 宿主层必须分离实现。
2. 聊天层只处理 Gateway 的 `chat.send` 协议，不解析 assistant 文本里的伪动作。
3. 如果 assistant 文本中出现 `"action": "canvas"`、`"action": "eval"`、`"javaScript"`，默认只显示文本，不执行。
4. 只有收到结构化 `canvasHostUrl` 或 `node.canvas.capability.refresh` 返回值时，才认为 canvas 能力真实可用。
5. Canvas 使用单独的 WebView 承载，不和普通聊天文本渲染混用。
6. iOS WebView 需要提供 `window.webkit.messageHandlers.openclawCanvasA2UIAction.postMessage(...)`。
7. Android WebView 需要提供 `window.openclawCanvasA2UIAction.postMessage(...)`。
8. 宿主桥只允许转发结构化 `userAction`，不要执行任意 JS。
9. 可选支持向页面回发 `openclaw:a2ui-action-status` 事件，用于显示动作发送成功/失败。
10. 如果暂时不实现 canvas，就完全忽略这条链路，只做普通聊天和结构化图片结果展示。

## 最终建议

对你当前这个 Flutter App，最稳的路线是：

第一步：

- 继续只走 `chat.send`
- 多图输入继续用 `message + attachments`
- 明确禁止执行 assistant 文本里的 `canvas/eval/javaScript`

第二步：

- 如果以后真的要支持 OpenClaw 的原生 canvas
- 再单独做一个 node/canvas WebView 宿主模块
- 通过 `canvasHostUrl + 原生桥 + userAction` 这条正式链路实现

## 一句话总结

你这次看到的 `"action": "canvas"` 更像模型吐出来的说明性文本，不是 Flutter 应该直接执行的动作。

如果要支持 OpenClaw canvas，要做的是“受控 WebView 宿主桥”，不是“解析 assistant 文本里的 JS”。

请为 Flutter 客户端补齐 OpenClaw canvas 宿主支持，目标是“让客户端可以承载真正的 OpenClaw canvas”，而不是解析 assistant 文本里的 JavaScript。

  硬性要求：
  1. 聊天页和 canvas 页分离实现。
  2. 聊天页继续只处理 chat.send 结果。
  3. assistant 文本里即使出现 action=canvas / action=eval / javaScript，也一律不执行。
  4. 只有拿到结构化 canvasHostUrl，或 node.canvas.capability.refresh 返回有效 canvasHostUrl，才认为 canvas 可用。
  5. canvas 必须通过单独 WebView 承载，不允许在普通消息组件里执行脚本。
  6. iOS WebView 需要可用的 window.webkit.messageHandlers.openclawCanvasA2UIAction.postMessage(...)
  7. Android WebView 需要可用的 window.openclawCanvasA2UIAction.postMessage(...)
  8. 除了原生 postMessage 桥，还要确保页面里存在 window.openclawSendUserAction(...)；如果正式 canvas host 页面没有内置这个 helper，就由 Flutter 在 WebView 初始化时注入。
  9. openclawSendUserAction 只能发送结构化 userAction，不允许执行任意 JS。
  10. 可选支持向页面回发 openclaw:a2ui-action-status 事件，显示发送成功/失败。

  请按下面顺序实施：
  1. 梳理当前 Flutter 客户端里聊天页、连接握手、WebView 能力接入点。
  2. 新增 canvas 能力状态判断：无 canvasHostUrl 时禁用 canvas，且保持现有聊天行为。
  3. 新增独立 canvas 页面，使用 WebView 加载 canvasHostUrl。
  4. 在 iOS/Android 侧接入 openclawCanvasA2UIAction 原生桥。
  5. 确保页面中可调用 openclawSendUserAction；必要时由宿主注入 helper。
  6. 把页面发出的结构化 userAction 转发给 OpenClaw 网关/节点。
  7. 至少完成一次按钮动作联通测试，并把成功/失败结果回显到页面日志。

  验收标准：
  1. 普通聊天页不再尝试执行 assistant 文本里的 canvas/eval/javaScript。
  2. 拿不到 canvasHostUrl 时，客户端明确降级，不报脚本执行错误。
  3. 拿到 canvasHostUrl 时，可以进入独立 canvas WebView 页面。
  4. canvas 页面不再显示 bridge missing。
  5. 页面里的测试动作点击后，Flutter 能收到结构化 userAction。
  6. 成功时页面能看到 sent / ok 状态；失败时能看到明确错误。
