# Flutter Android 接入 OpenClaw 的正确方式

本文面向“让 AI 或工程代理直接照着做”的场景，目标是把你当前的 Flutter Android App 从“共享 `wss + gateway token` 连接”迁移到“设备配对 + 每设备独立 token”模式。

适用对象：

- Flutter 开发的 Android App
- 需要很多用户/很多设备接入同一个 OpenClaw Gateway
- 不希望所有人共用一个 `gateway token`

不适用对象：

- 你只是一个人本地调试
- 你做的是浏览器 Web 控制台并且前面已经有 SSO / 反向代理

## 1. 先说结论

如果你的 App 面向很多用户，正确做法不是让每个用户都拿同一个 `gateway token` 直连 Gateway。

正确做法是：

1. App 首次连接时使用一个短期 `bootstrapToken`
2. App 在 `connect` 时带上自己的稳定设备身份 `device`
3. Gateway 生成待审批请求
4. 你审批该设备
5. Gateway 返回该设备自己的 `deviceToken`
6. App 持久化保存这个 `deviceToken`
7. 后续重连都使用这个设备自己的 `deviceToken`

一句话：

- `gateway token` 适合“系统级共享入口”或运维工具
- `deviceToken` 才适合“面向大量终端用户/终端设备”的长期连接

## 2. 为什么共享 gateway token 不合理

如果所有 Flutter 客户端都共享同一个 `gateway token`，会出现这些问题：

### 2.1 无法区分设备

虽然你仍然可以上传不同的 `device.id`，但认证入口本身是共享密钥。

这意味着：

- 一旦 token 泄露，很难只封禁某一个用户
- 很难做到逐设备撤销
- 很难做到逐设备轮换

### 2.2 一处泄露，全体失守

如果 APK 被逆向、抓包、日志泄露，攻击者拿到的是“系统通行证”，不是单设备凭证。

### 2.3 权限模型不细

你没法自然地表达：

- 用户 A 只能读写
- 用户 B 能审批
- 用户 C 只有自己的设备管理权

### 2.4 运营和审计都别扭

你以后做这些动作都会很难：

- 只踢掉一台丢失手机
- 只给某台设备降权
- 查某台设备最近是不是还在用

而这些恰恰是 OpenClaw 设备配对模型本来就解决的问题。

## 3. OpenClaw 官方模型里正确的角色分工

根据官方文档，所有 WS 客户端都走 Gateway Protocol，并在 `connect` 时声明：

- `role`
- `scopes`
- `device`
- `auth`

关键点：

- 所有 WS 客户端都必须带 `device` 身份
- Gateway 按“设备 + 角色”签发 token
- 新设备默认需要配对审批

官方依据：

- Gateway Protocol 明确写了所有 WS 客户端在 `connect` 时都要带 `device` 身份，并签名 `connect.challenge` 随机数
- Gateway 也明确写了 token 是按“device + role”签发的

参考：

- https://docs.openclaw.ai/gateway/protocol
- https://docs.openclaw.ai/channels/pairing

## 4. 你这个 Flutter App 应该用什么角色

这里先分清楚一个关键问题：你的 App 到底是 `operator` 还是 `node`。

### 4.1 如果你的 App 是“控制端/聊天端/管理端”

就应该用：

- `role: "operator"`

典型特征：

- 发消息
- 调用聊天/控制/审批/配置类 RPC
- 像一个手机上的控制台

### 4.2 如果你的 App 是“能力宿主”

就应该用：

- `role: "node"`

典型特征：

- 提供摄像头、麦克风、定位、屏幕录制等能力
- 被 Gateway 调用 `invoke`
- 更像受控节点，而不是操作员

### 4.3 很多移动 App 实际上会有双角色需求

例如一个 App 既能：

- 作为用户控制端聊天和操作
- 又能提供相机、定位、屏幕等能力

这时你要非常明确地区分：

- 主连接是不是 `operator`
- 是否还需要单独申请 `node` 角色/token

不要在第一版里混着做。建议先只做一个角色。

对你当前场景，我的判断是：

- 如果你现在是“Flutter 安卓 App 直接连 Gateway 做对话/控制”，第一版优先做 `operator`

这是推断，不是官方硬性规定。

## 5. `gateway token`、`bootstrapToken`、`deviceToken` 三者区别

这是最容易混乱的部分。

### 5.1 `gateway token`

这是 Gateway 的共享入口凭证。

特点：

- 偏系统级
- 适合 CLI、运维、受控内部工具
- 不适合大量终端用户长期共享

### 5.2 `bootstrapToken`

这是“首次配对专用”的短期 token。

特点：

- 短期有效
- 用来完成首次握手/配对
- 不是长期使用的正式 token
- setup code / pairing QR 里带的应该是它，不是共享 `gateway token`

官方明确说明：

- setup code 携带的是短期 `bootstrap token`
- 不是共享 `gateway token/password`

参考：

- https://docs.openclaw.ai/cli#qr
- https://docs.openclaw.ai/channels/pairing

### 5.3 `deviceToken`

这是某一台设备在某个角色下的长期凭证。

特点：

- 由 Gateway 在配对/批准后签发
- 绑定具体设备和角色
- App 需要持久化保存
- 后续重连优先使用它

官方明确说明：

- `hello-ok.auth.deviceToken` 应该由客户端持久化
- 后续重连应复用它以及对应的批准 scope 集合

参考：

- https://docs.openclaw.ai/gateway/protocol

## 6. 推荐架构

建议你把系统拆成 3 部分：

### 6.1 Gateway

负责：

- WebSocket 入口
- 挑战握手
- 设备配对审批
- 设备 token 签发/轮换/撤销

### 6.2 Flutter App

负责：

- 生成稳定设备身份
- 保存本机私钥
- 发起首次 bootstrap 连接
- 接收并保存 `deviceToken`
- 后续用 `deviceToken` 重连

### 6.3 Owner/Admin 审批面板或后台流程

负责：

- 查看 pending requests
- 审批/拒绝
- 必要时 rotate/revoke/remove 某台设备

这个审批面板可以是：

- OpenClaw CLI
- 你自己的管理后台
- 你自己的 AI 管理代理

## 7. Flutter 端应该怎么实现

下面是建议的实现模型。

## 7.1 本地持久化的数据结构

App 本地至少需要保存：

```json
{
  "gatewayUrl": "wss://example.com/ws",
  "deviceId": "stable_device_fingerprint",
  "publicKey": "base64url_public_key",
  "privateKeyRef": "keystore_alias_or_secure_storage_ref",
  "role": "operator",
  "requestedScopes": [
    "operator.read",
    "operator.write"
  ],
  "bootstrapToken": "short_lived_optional",
  "deviceToken": "issued_by_gateway",
  "approvedScopes": [
    "operator.read",
    "operator.write"
  ],
  "lastConnectedAt": 0
}
```

其中：

- `privateKeyRef` 不建议明文保存私钥，最好放 Android Keystore
- `deviceToken` 放加密存储
- `approvedScopes` 是你缓存的“该 token 的已批准 scope”，重连时要跟 token 一起复用

## 7.2 设备身份生成规则

Gateway Protocol 要求设备在 `connect` 时提供：

- `device.id`
- `device.publicKey`
- `device.signature`
- `device.signedAt`
- `device.nonce`

官方还明确要求：

- `device.id` 应该来自稳定 keypair 的指纹
- 所有连接都必须签名服务端发出的 `connect.challenge`

因此你的实现建议是：

1. App 首次启动时生成一对长期设备密钥
2. 用公钥指纹计算稳定 `deviceId`
3. 私钥固定存放在 Android Keystore
4. 以后每次连接都用同一设备密钥对 challenge 做签名

不要这样做：

- 每次启动随机生成新 keypair
- 用 Android ID 直接当 `deviceId`
- 把私钥直接明文放 SharedPreferences

## 7.3 首次连接流程

首次连接时，App 还没有 `deviceToken`，因此流程应该是：

1. App 获取一个 setup code 或短期 `bootstrapToken`
2. 建立 `wss` 连接
3. 等 Gateway 先发 `connect.challenge`
4. App 用本机私钥对 challenge 进行签名
5. App 发送 `connect` 请求
6. `auth` 里带 `bootstrapToken`
7. `device` 里带稳定设备身份
8. Gateway 记录 pending pairing request
9. 管理员审批
10. Gateway 在成功连接响应里返回 `hello-ok.auth.deviceToken`
11. App 持久化保存 `deviceToken`

注意：

- 这里首次连接用的是 `bootstrapToken`
- 不是长期共享 `gateway token`

### 7.3.1 `bootstrapToken` 到底是怎么变成 `deviceToken` 的

这里最容易让 AI 或工程师误解。

要点先说清楚：

- **通常不存在一个额外的“exchange bootstrapToken -> deviceToken”的 HTTP API**
- 这个“换取”动作本身，就发生在**第一次 `connect` 握手**里
- `bootstrapToken` 的作用是：让 Gateway 接受这次“首次配对请求”
- `deviceToken` 的作用是：在配对获批后，作为这台设备后续长期重连的正式凭证

也就是说，正确理解不是：

1. 先拿 `bootstrapToken` 调某个接口
2. 单独换回一个 `deviceToken`
3. 再拿 `deviceToken` 去连 Gateway

而是：

1. 客户端先用 `bootstrapToken` 发起**第一次** challenge-signed `connect`
2. Gateway 识别这是“新设备首次配对”
3. Gateway 记录 pending pairing request
4. 管理员审批这条 request
5. **该次连接成功结果**里返回 `hello-ok.auth.deviceToken`
6. 客户端把这个 `deviceToken` 保存下来
7. 之后所有正常重连都改用这个 `deviceToken`

一句话总结：

- `bootstrapToken` 不是让你去调用一个隐藏接口“换票”
- 它是**首次 `connect` 的临时入场券**
- `deviceToken` 是 Gateway 在配对成功后，于**成功连接响应**里签发给这台设备的长期票据

### 7.3.2 如果你拿到的是 setup code，不是裸 `bootstrapToken`

很多时候服务端给 App 的不是裸 token，而是 setup code。

这时 App 要做的不是把 setup code 当长期口令保存，而是：

1. 解析 setup code
2. 拿到其中的 `url` 和 `bootstrapToken`
3. 用解析出来的 `url` 建立 `wss` 连接
4. 在首次 `connect` 的 `auth.token` 里放这个 `bootstrapToken`
5. 等成功响应里的 `hello-ok.auth.deviceToken`
6. 持久化 `deviceToken`，然后删除 setup code / `bootstrapToken`

也就是说：

- setup code 只是 `url + bootstrapToken + 其他配对元信息` 的打包载体
- 真正长期留在本地的，不应该是 setup code，也不应该是 `bootstrapToken`
- 应该是第一次配对成功后返回的 `deviceToken`

### 7.3.3 客户端应该按什么状态机实现

建议直接按下面这个状态机写，AI 也比较不容易误解：

```text
未配对
  -> 拿到 setup code / bootstrapToken
  -> 建立 WS
  -> 收到 connect.challenge
  -> 发送 connect(auth.token = bootstrapToken, device = stable identity)
  -> 等待审批 / 等待 connect 成功
  -> 收到 hello-ok.auth.deviceToken
  -> 保存 deviceToken + approvedScopes
  -> 删除 bootstrapToken
  -> 进入“已配对”

已配对
  -> 建立 WS
  -> 收到 connect.challenge
  -> 发送 connect(auth.token = deviceToken, device = same stable identity)
  -> 正常工作
```

对应伪代码可以写成：

```ts
if (local.deviceToken != null) {
  authToken = local.deviceToken
  scopes = local.approvedScopes
} else {
  authToken = bootstrapTokenFromSetupCodeOrBackend
  scopes = requestedScopes
}

ws = connect(gatewayUrl)
challenge = await waitConnectChallenge(ws)
signature = signWithDevicePrivateKey(challenge)

result = await sendConnect(ws, {
  role: "operator",
  scopes,
  auth: { token: authToken },
  device: stableDeviceIdentity(signature, challenge),
})

if (result.helloOk?.auth?.deviceToken != null) {
  local.deviceToken = result.helloOk.auth.deviceToken
  local.approvedScopes = result.helloOk.scopes ?? scopes
  local.bootstrapToken = null
}
```

上面这段伪代码最关键的语义是：

- **第一次 `sendConnect(...)` 时传入的是 `bootstrapToken`**
- **同一个配对成功结果里拿到 `hello-ok.auth.deviceToken`**
- **不是连上以后再额外调一个换 token 接口**

### 7.3.4 成功响应里你到底要取什么

实现时请把下面这条规则写死：

- 只要首次配对成功，就从**成功连接结果**里读取 `hello-ok.auth.deviceToken`
- 同时把该结果里的 scope 集合也一并保存为 `approvedScopes`
- 一旦 `deviceToken` 保存成功，就不要再把 `bootstrapToken` 当成长期凭证使用

可以把成功结果概念性理解成：

```json
{
  "helloOk": {
    "role": "operator",
    "scopes": ["operator.read", "operator.write"],
    "auth": {
      "deviceToken": "issued_by_gateway"
    }
  }
}
```

注意这里我故意写成“概念性结果”，因为不同 SDK、不同包装层，外层事件包裹字段可能不同；**真正不能写错的核心字段是 `hello-ok.auth.deviceToken`**。

## 7.4 后续重连流程

一旦 App 已经拿到 `deviceToken`，后续重连应切换为：

1. 建立 `wss` 连接
2. 接收 `connect.challenge`
3. 使用同一设备私钥签名 challenge
4. 发 `connect`
5. `auth` 里带 `deviceToken`
6. `scopes` 使用该 token 对应的缓存批准值

官方明确建议：

- 客户端应持久化 `hello-ok.auth.deviceToken`
- 用保存下来的 token 重连时，也应复用保存下来的已批准 scope 集合

这点非常重要。否则你可能出现：

- 本来已有读写权限
- 重连时没带对 scopes
- 结果会话被意外收窄

## 7.5 连接优先级理解

官方文档给了认证优先级：

- 显式 shared token/password
- 显式 `deviceToken`
- 存储的 per-device token
- bootstrap token

这对你意味着：

- 在 App 已配对后，不要继续优先发送共享 `gateway token`
- 否则你会一直卡在共享入口认证路径，而不是设备认证路径

对你的 App，推荐策略是：

- 正式版：优先只用 `deviceToken`
- 首次配对：才使用 `bootstrapToken`
- 除非你在做运维工具，否则不要把长期 `gateway token` 放进正式用户端

## 8. 推荐的 connect 请求模型

下面是面向 `operator` 型 Flutter App 的建议示例。

```json
{
  "type": "req",
  "id": "req-001",
  "method": "connect",
  "params": {
    "minProtocol": 3,
    "maxProtocol": 3,
    "client": {
      "id": "your-flutter-app",
      "version": "1.0.0",
      "platform": "android",
      "mode": "operator"
    },
    "role": "operator",
    "scopes": [
      "operator.read",
      "operator.write"
    ],
    "caps": [],
    "commands": [],
    "permissions": {},
    "auth": {
      "token": "<bootstrapToken-or-deviceToken>"
    },
    "locale": "zh-CN",
    "userAgent": "your-flutter-app/1.0.0",
    "device": {
      "id": "stable_device_id",
      "publicKey": "base64url_public_key",
      "signature": "signature_of_connect_challenge",
      "signedAt": 1776000000000,
      "nonce": "challenge_nonce"
    }
  }
}
```

说明：

- `auth.token` 在首次配对时放 `bootstrapToken`
- 配对完成后改成 `deviceToken`
- `device` 五元组必须稳定且合法

## 9. 你应该怎么申请 scopes

第一版建议尽量保守。

如果你的 Flutter App 是普通用户控制端，推荐先申请：

- `operator.read`
- `operator.write`

按需再加：

- `operator.pairing`：只有它需要管理自己的设备 token、或者能做配对管理时才加
- `operator.approvals`：只有它需要审批别人时才加
- `operator.talk.secrets`：只有它确实需要读取敏感配置时才加
- `operator.admin`：大多数终端用户都不该有

最稳妥的默认值通常是：

```json
["operator.read", "operator.write"]
```

## 10. 多用户场景下的推荐生命周期

### 10.1 新用户安装 App

1. 用户登录你的业务系统
2. 你的业务后端给它下发一次性 setup code 或短期 `bootstrapToken`
3. App 发起首次配对
4. 管理后台自动或人工审批
5. Gateway 签发该设备自己的 `deviceToken`

### 10.2 老用户再次打开 App

1. App 读取本地 `deviceToken`
2. 发起 challenge-signed connect
3. 使用 `deviceToken` 连入

### 10.3 用户换手机

应该视为新设备，不要复用旧设备 token。

正确流程：

1. 新手机重新生成设备密钥
2. 新 `deviceId`
3. 重新配对
4. 旧设备 token 视情况 revoke/remove

### 10.4 手机丢失

后台应支持：

- `revoke` 该设备对应 role 的 token
- 或 `remove` 整个 paired device entry

参考：

- https://docs.openclaw.ai/cli/devices

## 11. 设备 token 的旋转、撤销、删除

官方提供了设备管理命令：

- `openclaw devices rotate --device <id> --role <role> [--scope ...]`
- `openclaw devices revoke --device <id> --role <role>`
- `openclaw devices remove <deviceId>`

语义区别：

### `rotate`

重新签发一个新 token，旧 token 失效或被替换。

适合：

- 怀疑泄露
- 客户端 token 漂移
- 需要收窄/更新 scope

### `revoke`

撤销某角色下的 device token。

适合：

- 临时封禁
- 禁止这台设备继续以该角色接入

### `remove`

直接删除整台设备的 paired 记录。

适合：

- 设备退役
- 完整解绑

官方还明确说明：

- token rotation 不能超出该设备已批准的角色和 scope 基线

参考：

- https://docs.openclaw.ai/cli/devices
- https://docs.openclaw.ai/gateway/protocol

## 12. 你的服务端应该怎么发 bootstrapToken

这个问题很关键。

正确做法是：

- 让你自己的业务后端在“用户已登录且满足业务条件”后，给 App 下发短期 setup code / bootstrapToken

不推荐：

- 在 App 里硬编码共享 `gateway token`
- 让 App 永久持有系统级入口凭证
- 让用户自己手填长期 `gateway token`

你可以把 bootstrap 发放理解成：

- “一次入网资格”
- 不是“永久通行证”

## 13. 最推荐的工程落地方式

如果我是给 AI 下任务，我会要求它这样实现：

### Phase 1：单角色 `operator` 配对版

目标：

- 只支持 `operator`
- 只申请 `operator.read` + `operator.write`
- 先把稳定配对链路跑通

要做的事：

1. Flutter 生成设备密钥对
2. 基于公钥指纹生成稳定 `deviceId`
3. 保存私钥到 Android Keystore
4. 连接时先接收 `connect.challenge`
5. 使用私钥签名 challenge
6. 首次连接时支持 `bootstrapToken`
7. 保存 `hello-ok.auth.deviceToken`
8. 保存该 token 的 scopes
9. 后续重连统一使用 `deviceToken`
10. 登录后支持显示当前设备 ID、角色、scopes

### Phase 2：设备状态与恢复

要做的事：

1. 处理 `AUTH_TOKEN_MISMATCH` / `AUTH_DEVICE_TOKEN_MISMATCH`
2. 提示用户重新配对
3. 支持后台 rotate 后的重新同步
4. 支持清除本机配对状态

### Phase 3：进阶权限

仅在需要时再加：

- `operator.pairing`
- `operator.approvals`
- `operator.talk.secrets`
- `operator.admin`

## 14. AI 开发任务说明模板

你后面如果要把这份文档直接喂给 AI，可以用下面这段作为任务描述。

```md
请为一个 Flutter Android 客户端实现 OpenClaw Gateway 的设备配对连接模型，不再使用共享 gateway token 作为长期认证方式。

要求：

1. 客户端角色先实现 `operator`
2. 首次连接使用短期 `bootstrapToken`
3. 后续连接使用 Gateway 返回的 `deviceToken`
4. 必须明确按以下语义实现：`bootstrapToken` 直接用于第一次 `connect.auth.token`，配对成功后从 `hello-ok.auth.deviceToken` 读取并保存正式 `deviceToken`，不要假设存在额外的 token exchange API
5. 客户端必须实现完整的 `connect.challenge` 签名流程
6. 设备身份必须稳定：`device.id` 基于长期密钥对的公钥指纹生成
7. 私钥必须存储在 Android Keystore，不允许明文落盘
8. 客户端必须持久化保存：gatewayUrl、deviceId、publicKey、deviceToken、approvedScopes
9. 后续重连必须复用已保存的 `deviceToken` 和对应 scopes
10. 第一版只申请 `operator.read` 与 `operator.write`
11. 需要提供 token 失效、重新配对、清空本地状态的恢复逻辑

请优先保证认证链路正确，再做 UI。
```

## 15. 你现在最应该怎么改

按优先级排序：

1. 停止把共享 `gateway token` 作为正式用户端长期凭证
2. 在 Flutter 里实现稳定设备身份和 challenge 签名
3. 引入首次配对使用的 `bootstrapToken`
4. 把 `hello-ok.auth.deviceToken` 存下来
5. 后续连接一律改用 `deviceToken`
6. 第一版只申请 `operator.read` + `operator.write`

## 16. 一个很重要的现实判断

如果你的 App 是“用户自己的私人手机控制端”，那么“每台手机一个 paired device”是很合理的。

如果你的 App 是“账号体系下的大量普通用户 App”，那么你还要再想一层：

- OpenClaw 设备配对模型管理的是“设备身份”
- 你的业务系统管理的是“用户身份”

这两个身份不冲突，但不要混为一谈。

正确理解是：

- 业务后端先决定“这个用户是否有资格获得 bootstrapToken”
- OpenClaw 再决定“这台具体设备是否被批准进入 Gateway”

## 17. 参考来源

- Pairing: https://docs.openclaw.ai/channels/pairing
- Gateway Protocol: https://docs.openclaw.ai/gateway/protocol
- devices CLI: https://docs.openclaw.ai/cli/devices
- CLI QR / setup code: https://docs.openclaw.ai/cli#qr

## 18. 最短总结

你这个 Flutter Android App，正确模型是：

- 首次：`wss + bootstrapToken + device identity + challenge signature`
- 批准后：保存 `deviceToken`
- 后续：`wss + deviceToken + 同一设备身份 + challenge signature`

不是：

- 所有人长期共用 `wss + gateway token`

