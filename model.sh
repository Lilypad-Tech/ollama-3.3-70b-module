#!/bin/bash
set -e

# Start ollama in the background
nohup ollama serve >/dev/null 2>&1 &
OLLAMA_PID=$!

# Wait for ollama to start
until curl -s http://127.0.0.1:11434 > /dev/null; do
  echo "Waiting for ollama to start..."
  sleep 2
done

echo "Ollama service started"

# Function to clean up on exit
cleanup() {
  echo "Shutting down ollama..."
  kill $OLLAMA_PID
  wait $OLLAMA_PID 2>/dev/null || true
  echo "Ollama shutdown complete"
}

# Set trap to ensure cleanup on exit
trap cleanup EXIT

# Get the input JSON
INPUT_JSON=${1:-'{}'}
MODEL_ID=${MODEL_ID:-"llama3.3:70b-instruct-q4_0"}

# Parse the messages from the input JSON
if echo "$INPUT_JSON" | jq -e '.messages' >/dev/null 2>&1; then
  # Extract the messages for API format
  MESSAGES=$(echo "$INPUT_JSON" | jq -c '.messages')
  
  # Prepare the request to Ollama API
  REQUEST=$(jq -n --arg model "$MODEL_ID" --argjson messages "$MESSAGES" '{model: $model, messages: $messages}')
  
  # Call the Ollama API
  echo "Calling Ollama API with model: $MODEL_ID"
  RESPONSE=$(curl -s -X POST http://localhost:11434/api/chat -d "$REQUEST")
  
  # Save the response to the output file
  echo "$RESPONSE" > /outputs/response.json
  echo "Response saved to /outputs/response.json"
  
  # Extract and output just the assistant's message content
  ASSISTANT_MESSAGE=$(echo "$RESPONSE" | jq -r '.message.content')
  echo -e "\nModel response:\n$ASSISTANT_MESSAGE"
else
  echo "Error: Input JSON does not contain 'messages' field"
  echo '{"error": "Input JSON does not contain messages field"}' > /outputs/response.json
  exit 1
fi