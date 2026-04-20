import base64
from pathlib import Path

in_path = Path(r"c:\Users\hp\AppData\Roaming\Code\User\workspaceStorage\5f387acb0b2c2bfc2c5598d88602e224\GitHub.copilot-chat\chat-session-resources\83a3098c-1231-4f9e-9931-d8cfe71fcd3b\call_Ad5cBhQOFJX3XWSt3Sqk65IV__vscode-1776668765199\content.txt")
out_path = Path(r"c:\Users\hp\Flutter_Projects\meeting_room_booking_app\assets\images\login_page.png")

text = in_path.read_text(encoding='utf-8')
# Extract the base64 string from the file content
start = text.find('"')
end = text.rfind('"')
if start == -1 or end == -1 or start == end:
    raise ValueError('Base64 data not found')
encoded = text[start+1:end]
image_data = base64.b64decode(encoded)
out_path.write_bytes(image_data)
print('saved', out_path)
