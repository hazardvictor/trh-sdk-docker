FROM --platform=$BUILDPLATFORM ubuntu:latest AS builder

# Set non-interactive frontend and working directory
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Copy scripts
COPY scripts /app/scripts

# Install base system packages and Node.js based on architecture
RUN apt-get update && apt-get upgrade -y && \
  apt-get install -y \
  wget \
  gnupg \
  software-properties-common \
  curl \
  unzip && \
  # Install Node.js v20.16.0 with architecture-specific setup
  case "$(uname -m)" in \
  x86_64) ARCH="x64" ;; \
  aarch64) ARCH="arm64" ;; \
  *) echo "Unsupported architecture" && exit 1 ;; \
  esac && \
  curl -fsSL https://nodejs.org/dist/v20.16.0/node-v20.16.0-linux-${ARCH}.tar.gz -o node.tar.gz && \
  tar -xzf node.tar.gz -C /usr/local --strip-components=1 && \
  rm node.tar.gz

# Run setup script
RUN chmod +x /app/scripts/setup.sh && \
  DEBIAN_FRONTEND=noninteractive bash -x /app/scripts/setup.sh 2>&1 | tee /var/log/setup.log

FROM --platform=$TARGETPLATFORM ubuntu:latest

WORKDIR /app
COPY --from=builder /app /app
COPY --from=builder /usr/local /usr/local
COPY --from=builder /root/.bashrc /root/.bashrc

# Clean up
RUN apt-get update && apt-get install -y curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Use bash shell and source profile  
SHELL ["/bin/bash", "-c"]
RUN source ~/.bashrc

CMD ["/bin/bash"]
