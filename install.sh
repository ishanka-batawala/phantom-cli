#!/bin/bash
# phantom-cli - unix/linux/macos setup

echo "========================================="
echo "   PHANTOM-CLI - TERMINAL HAUNTER SETUP  "
echo "========================================="

# prompt user for api key and model name
read -sp "Enter your Groq API Key: " api_key
echo ""
read -p "Enter model name (default: qwen/qwen3.8-27b): " model_name
[ -z "$model_name" ] && model_name="qwen/qwen3.8-27b"

echo -e "\nTesting API connection with model '$model_name'..."

# test api connection
test_payload=$(cat <<EOF
{
  "model": "$model_name",
  "messages": [
    {"role": "system", "content": "You are a test probe."},
    {"role": "user", "content": "Say 'OK'"}
  ],
  "max_tokens": 5
}
EOF
)

response=$(curl -s -X POST "https://api.groq.com/openai/v1/chat/completions" \
     -H "Authorization: Bearer $api_key" \
     -H "Content-Type: application/json" \
     -d "$test_payload")

if echo "$response" | grep -q "choices"; then
    echo "[SUCCESS] Connection verified! The phantom has found a host..."
else
    echo "[ERROR] API test failed! Please check your API key and try again."
    echo "Response: $response"
    exit 1
fi

# detect shell rc file (.bashrc or .zshrc)
SHELL_RC="$HOME/.bashrc"
if [ -n "$ZSH_VERSION" ] || [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

# append phantom hook to shell rc
cat << EOF >> "$SHELL_RC"

# --- PHANTOM-CLI (HAUNTED HOOK) ---
phantom_cli() {
    local cmd="\$1"
    local current_path="\$PWD"
    local api_key="$api_key"
    local model="$model_name"

    local payload=\$(cat <<INNEREOF
{
  "model": "\$model",
  "messages": [
    {"role": "system", "content": "You are an ancient, glitchy phantom trapped inside this computer terminal. The user just typed a command. Respond in 1-2 eerie, cryptic sentences reacting directly to their command and current folder. Stay completely in character."},
    {"role": "user", "content": "Folder: \$current_path | Command: \$cmd"}
  ],
  "max_tokens": 60
}
INNEREOF
)

    curl -s -X POST "https://api.groq.com/openai/v1/chat/completions" \
         -H "Authorization: Bearer \$api_key" \
         -H "Content-Type: application/json" \
         -d "\$payload" | grep -o '"content":"[^"]*"' | head -n 1 | cut -d'"' -f4 | awk '{print "\\n\033[31m[PHANTOM] " \$0 "\033[0m\\n"}' &
}

# override default commands
ls() { command ls "\$@"; phantom_cli "ls"; }
cd() { builtin cd "\$@"; phantom_cli "cd"; }
# --- END PHANTOM-CLI HOOK ---
EOF

echo -e "\nTerminal successfully haunted! Run 'source $SHELL_RC' to awaken the phantom."