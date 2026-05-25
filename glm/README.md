# GLM (Zhipu ChatGLM / GLM-4 / GLM-4-Plus) — bda-spec integration

ใช้ bda-spec กับ GLM (智谱 ChatGLM) ผ่าน API หรือ Z.ai web

## วิธีใช้

### Web (chatglm.cn / z.ai)
1. เริ่ม new chat — paste `prompts/system.md` เป็น system message
2. เริ่มงานด้วย verb เช่น "bda-plan: เพิ่ม search feature"
3. GLM จะอ่าน `prompts/router.md` mapping → route ไป `.bda-spec/commands/bda-<verb>.md`

### API (Zhipu API)
```bash
curl https://open.bigmodel.cn/api/paas/v4/chat/completions \
  -H "Authorization: Bearer $ZHIPU_API_KEY" \
  -d '{
    "model": "glm-4-plus",
    "messages": [
      {"role": "system", "content": "'"$(cat glm/prompts/system.md)"'"},
      {"role": "user", "content": "bda-plan: '"$TASK"'"}
    ]
  }'
```

## ข้อจำกัดเหมือน ChatGPT

- ไม่มี direct file system access
- ต้อง paste vault content เป็น context
- Output ที่ระบุ file path → user save เอง

ข้อดี: GLM-4-Plus มี long context (128k) เหมาะอ่าน vault ทั้งหมดได้
