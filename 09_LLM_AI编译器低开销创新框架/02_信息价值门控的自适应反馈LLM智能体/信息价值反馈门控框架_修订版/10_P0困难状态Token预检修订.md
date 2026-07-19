# P0 困难状态 Token 预检修订

四类状态预检 `p0-hard-preflight-v2-20260720-001` 共 16 次生成，其中 Test 的 RealFeedback、Test 的 MatchedPlacebo、IR 的 MatchedPlacebo 均在 completion_tokens 精确达到 2048 时以 `finish_reason=length` 结束，正文为空。正式运行尚未开始。

因此在正式运行前固定最后一次工程修订：

- max_tokens 从 2048 统一提高到 4096；
- 模型、temperature、top_p、Prompt、Schema、20 个状态、真实反馈、安慰剂映射、效用和进入 P1 门槛均不变；
- 重新执行四种反馈类型各一个状态的预检；
- 若任一条件成功生成率低于 75%，停止困难状态 P0，不再提高 Token 上限；
- 4096 配置通过预检后即冻结，正式运行中不重试或选择性替换截断样本。

该调整针对 API 可执行性，不使用正式结果选择条件或任务。
