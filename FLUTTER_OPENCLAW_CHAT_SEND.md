# Flutter 接 OpenClaw Gateway 聊天协议说明

本文用于说明：当 Flutter App 通过 OpenClaw Gateway WebSocket 与 Gemini 模型对话时，应该发送什么 JSON。

## 结论

如果你调用的是 Gateway 的 `chat.send` 方法：

- 外层必须有 `message` 字段
- `message` 必须是字符串
- 图片不能直接塞进 `message`
- 图片要走并列的 `attachments`
- OpenClaw 会把 `attachments` 自动转换成 Gemini 的原生图片输入 `inlineData`

这意味着：

- 你不应该直接给 Gateway 发 Gemini 的 `parts` 格式
- 你也不应该直接给 Gateway 发内部会话的 `role/content` 图片块格式
- 对 Gateway 来说，正确入口是 `chat.send` 的 `params.message + params.attachments`

## 为什么会出现“必须有 message 属性”的报错

`chat.send` 这一层的协议要求：

- `sessionKey: string`
- `message: string`
- `idempotencyKey: string`
- `attachments?: array`

所以如果你发送的是下面这种结构：

```json
{
  "sessionKey": "main",
  "content": [
    { "type": "text", "text": "你好" }
  ]
}
```

或者：

```json
{
  "role": "user",
  "content": [
    { "type": "text", "text": "你好" }
  ]
}
```

对 `chat.send` 来说都是错的，因为它不认这层格式。

## 正确的 WebSocket 请求外层格式

Gateway WebSocket 请求外层应类似：

```json
{
  "type": "req",
  "id": "r1",
  "method": "chat.send",
  "params": {
    "sessionKey": "main",
    "message": "你好",
    "deliver": false,
    "idempotencyKey": "run_001"
  }
}
```

说明：

- `type`: 固定为 `req`
- `id`: 本次请求 id
- `method`: 这里是 `chat.send`
- `params`: 真正的请求参数

## 正确的普通文本消息结构

```json
{
  "type": "req",
  "id": "r1",
  "method": "chat.send",
  "params": {
    "sessionKey": "main",
    "message": "帮我总结一下这段内容",
    "deliver": false,
    "idempotencyKey": "run_001"
  }
}
```

## 正确的图片消息结构

单张图片：

```json
{
  "type": "req",
  "id": "r2",
  "method": "chat.send",
  "params": {
    "sessionKey": "main",
    "message": "请描述这张图片",
    "deliver": false,
    "idempotencyKey": "run_002",
    "attachments": [
      {
        "type": "image",
        "mimeType": "image/png",
        "content": "iVBORw0KGgoAAAANSUhEUgAA..."
      }
    ]
  }
}
```

多张图片：

```json
{
  "type": "req",
  "id": "r3",
  "method": "chat.send",
  "params": {
    "sessionKey": "main",
    "message": "请比较这三张图片的差异",
    "deliver": false,
    "idempotencyKey": "run_003",
    "attachments": [
      {
        "type": "image",
        "mimeType": "image/jpeg",
        "content": "/9j/4AAQSkZJRgABAQ..."
      },
      {
        "type": "image",
        "mimeType": "image/png",
        "content": "iVBORw0KGgoAAAANSUhEUgAA..."
      },
      {
        "type": "image",
        "mimeType": "image/webp",
        "content": "UklGRlIAAABXRUJQVlA4..."
      }
    ]
  }
}
```

## attachments 的推荐结构

推荐发送：

```json
{
  "type": "image",
  "mimeType": "image/png",
  "content": "纯base64内容"
}
```

说明：

- `type` 用 `image`
- `mimeType` 例如 `image/png`、`image/jpeg`
- `content` 是纯 base64
- 不要带 `data:image/png;base64,` 前缀

## 兼容但不推荐的 source 写法

OpenClaw 也兼容这种写法：

```json
{
  "type": "image",
  "source": {
    "type": "base64",
    "media_type": "image/png",
    "data": "iVBORw0KGgoAAA..."
  }
}
```

但 Flutter 侧没有必要这么发，推荐统一使用：

- `mimeType`
- `content`

这组简单字段即可。

## message 字段规则

`message` 必须存在，并且必须是字符串。

可以是：

```json
"message": "请描述这张图片"
```

也可以是空字符串：

```json
"message": ""
```

但是：

- 如果 `message` 是空字符串
- 那么 `attachments` 至少要有一个

否则会报：

- `message or attachment required`

## 绝对不要这样发

### 错误 1：把 base64 拼进 message 文本里

```json
{
  "type": "req",
  "id": "bad1",
  "method": "chat.send",
  "params": {
    "sessionKey": "main",
    "message": "请描述这张图片 data:image/png;base64,iVBORw0KGgoAAA...",
    "idempotencyKey": "bad_run_1"
  }
}
```

问题：

- 这会把整串 base64 当文本送进上下文
- 极度浪费 token
- 多图时非常容易触发上下文爆炸

### 错误 2：直接发 Gemini 的 parts

```json
{
  "type": "req",
  "id": "bad2",
  "method": "chat.send",
  "params": {
    "sessionKey": "main",
    "parts": [
      { "text": "请描述这张图" },
      {
        "inlineData": {
          "mimeType": "image/png",
          "data": "iVBORw0KGgoAAA..."
        }
      }
    ],
    "idempotencyKey": "bad_run_2"
  }
}
```

问题：

- 这不是 Gateway 的 `chat.send` 参数结构
- `chat.send` 这一层不认 `parts`

### 错误 3：直接发内部 role/content 结构

```json
{
  "type": "req",
  "id": "bad3",
  "method": "chat.send",
  "params": {
    "sessionKey": "main",
    "content": [
      { "type": "text", "text": "请描述这张图" },
      { "type": "image", "mimeType": "image/png", "data": "..." }
    ],
    "idempotencyKey": "bad_run_3"
  }
}
```

问题：

- 这也不是 `chat.send` 这一层的 schema
- 外层依然缺少 `message`

## OpenClaw 会如何转发给 Gemini

当你用正确的 `message + attachments` 调用 `chat.send` 时，OpenClaw 会：

1. 接收文本 `message`
2. 接收图片 `attachments`
3. 解析为内部的图片输入块
4. 对 Gemini 自动转成：

```json
{
  "role": "user",
  "parts": [
    { "text": "请描述这张图片" },
    {
      "inlineData": {
        "mimeType": "image/png",
        "data": "iVBORw0KGgoAAA..."
      }
    }
  ]
}
```

也就是说：

- 你在 Flutter 侧不需要自己拼 Gemini 的 `inlineData`
- 你只要正确调用 Gateway 的 `chat.send` 即可

## Flutter 端建议

如果你在 Flutter 中拿到的是图片字节：

- 用 `base64Encode(bytes)` 转成纯 base64
- 放到 `attachments[i].content`
- 同时设置 `attachments[i].mimeType`
- 文本放到 `params.message`

建议每次请求都生成新的 `idempotencyKey`，避免重复提交时被网关当成同一请求处理。


1. 使用 WebSocket 连接 OpenClaw Gateway。
2. 发送 Gateway TypeBox 请求，外层格式为 `{ type, id, method, params }`。
3. 聊天发送使用 `method: "chat.send"`。
4. `params` 中必须包含：`sessionKey`、`message`、`idempotencyKey`。
5. 如果有图片，放在 `params.attachments`。
6. 每个图片附件格式为：`{ type: "image", mimeType: "image/png", content: "纯base64" }`。
7. 不要把 `data:image/...;base64,...` 直接拼进 `message`。
8. 不要直接发送 Gemini 的 `parts` 或内部 `role/content` 结构给 `chat.send`。

## 最终一句话

对 Flutter 来说，和 OpenClaw Gateway 对话时：

- 文本走 `message`
- 图片走 `attachments`
- 不要直接发 Gemini 原生格式给 Gateway
