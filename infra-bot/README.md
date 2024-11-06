# A quick and dirty solution

Set WebHook:

```sh
curl \
  --request POST \
  --url https://api.telegram.org/bot$TOKEN/setWebhook \
  --header 'content-type: application/json' \
  --data '{"url": "https://d5dusc7jv5ql4rurf3u6.apigw.yandexcloud.net/maintainer-bot"}'
{"ok":true,"result":true,"description":"Webhook is already set"}
```