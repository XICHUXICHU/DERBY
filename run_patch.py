import sys
with open('macos/Runner/Release.entitlements', 'r') as f:
    c = f.read()

c = c.replace('<key>com.apple.security.app-sandbox</key>', '<key>com.apple.security.app-sandbox</key>\n\t<true/>\n\t<key>com.apple.security.network.client</key>')

with open('macos/Runner/Release.entitlements', 'w') as f:
    f.write(c)

