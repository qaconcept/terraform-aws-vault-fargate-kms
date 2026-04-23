# Use the official Python 3.13 slim image
FROM python:3.13-slim

# Set the working directory
WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir hvac

# Copy your verified agent script into the container
COPY vault_agent.py .

# Run the agent in unbuffered mode so logs appear instantly
CMD ["python", "-u", "vault_agent.py"]