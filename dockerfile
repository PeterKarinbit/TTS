# Use Python 3.10 slim image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libsndfile1-dev \
    ffmpeg \
    espeak \
    espeak-data \
    libespeak1 \
    libespeak-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy TTS code
COPY . /app

# Install TTS with all dependencies
RUN pip install --no-cache-dir -e .[all]

# Expose port
EXPOSE 5002

# Environment variable for port
ENV PORT=5002

# Create startup script that runs the SERVER, not the CLI
RUN echo '#!/bin/bash\n\
echo "Starting TTS Server on port $PORT..."\n\
echo "Using model: ${TTS_MODEL:-tts_models/en/ljspeech/tacotron2-DDC}"\n\
cd /app\n\
python3 TTS/server/server.py \
  --model_name "${TTS_MODEL:-tts_models/en/ljspeech/tacotron2-DDC}" \
  --port $PORT \
  --host 0.0.0.0' > /app/start.sh && chmod +x /app/start.sh

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:$PORT/ || exit 1

# Run the server
CMD ["/app/start.sh"]
