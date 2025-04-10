FROM ollama/ollama

# Set model info
ENV MODEL_NAME=llama3.3
ENV MODEL_VERSION=70b-instruct-q4_0
ENV MODEL_ID="${MODEL_NAME}:${MODEL_VERSION}"

# Set the working directory
WORKDIR /app

# Update and install necessary packages
RUN apt-get update && apt-get install -y curl jq

# Create directories for ollama models
RUN mkdir -p /root/.ollama/models/blobs

# We'll copy the model files in separately

EXPOSE 11434

# Set the environment variable for the ollama host
ENV OLLAMA_HOST=0.0.0.0

# Create outputs directory and set permissions
RUN mkdir -p /outputs && chmod 777 /outputs

# Set outputs directory as a volume
VOLUME /app/outputs

# Copy the model script
COPY model.sh /app/model.sh
RUN chmod +x /app/model.sh

# Set the entrypoint to the script
ENTRYPOINT ["/app/model.sh"]
