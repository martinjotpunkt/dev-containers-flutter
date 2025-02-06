ARG FLUTTER_SDK_VERSION=3.27.3

FROM ghcr.io/cirruslabs/flutter:${FLUTTER_SDK_VERSION}

# Default shell to bash
SHELL ["/bin/bash", "-c"]
