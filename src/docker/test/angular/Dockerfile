FROM seedsync/build/angular/env AS seedsync_test_angular

# Install Chrome/Chromium for headless testing
# ARM64: Use Chromium from Debian repos (Chrome not available for ARM64 Linux)
# AMD64: Use Google Chrome
RUN apt-get update && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then \
        apt-get install -y chromium chromium-driver && \
        ln -s /usr/bin/chromium /usr/bin/google-chrome; \
    else \
        apt-get install -y wget gnupg && \
        wget -nv -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
        dpkg -i /tmp/chrome.deb || apt-get -fy install; \
    fi

COPY \
    src/angular/tsconfig.json \
    src/angular/karma.conf.js \
    src/angular/angular.json \
    /app/

RUN ls -l /app/

# ng src needs to be mounted on /app/src
WORKDIR /app/src

# Note: Angular 13+ CLI binary is ng.js
CMD ["node", "/app/node_modules/@angular/cli/bin/ng.js", "test", \
     "--browsers", "ChromeHeadless", \
     "--watch=false"]
