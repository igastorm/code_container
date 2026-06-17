# ==========================================
# Version definition
# ==========================================
ARG GTEST_VERSION=1.17.0
ARG GTEST_SHA512=0f57e9ef06925e5b7722df1eb92ef5850e8dce79220ea16a8aaff586a71c0b01460ef1713649ee24ffedb2e6ad5a51e9198c5a5ae1b2789e43feb1f494e7d45c

ARG CODE_SERVER_VERSION=4.124.2
ARG CODE_SERVER_AMD64_SHA512=6fc5a43eea1e42cd22be380f36d26286c6fececd8c343896ec8feee551f6fd5663430de895b391ed831d2ad29dbde1ae78b253bf84b82f88fc6b8358286e8721
ARG CODE_SERVER_ARM64_SHA512=ec18844f49194a052b98dacd8e2d2c91f82fc71ab8ba566ae6fea353fb81bff5f0ded1a43cbc2f7501ea56839e78733c5a678ee5774a176a1d02775ab5db45a8

ARG CODELLDB_VERSION=1.12.2
ARG CODELLDB_X64_SHA512=8076083c0303101edb46f7bf1ebe88d10c41ef9c399a245af8d30a25069cab9c7ab17c63c448a366dcd74a60b9dd9697b34831442e6738a4f2309514bb7096b9
ARG CODELLDB_ARM64_SHA512=d38a7a484c165638a5675a22b8e3fc9bda35f2c8cd2c72c290531f2c17a5ad800713d04f4a772e860e775c290b497fecfa78fd012166de9c3bd46e13f7ae0e06

# ==========================================
# Runtime
# ==========================================
FROM debian:trixie-slim@sha256:4e401d95de7083948053197a9c3913343cd06b706bf15eb6a0c3ccd26f436a0e

ARG GTEST_VERSION
ARG GTEST_SHA512

RUN echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99-no-languages && \
  echo 'Acquire::Languages::Target "en";' >> /etc/apt/apt.conf.d/99-no-languages && \
  apt-get update && apt-get install -y --no-install-recommends \
  tini sudo locales ca-certificates \
  supervisor libnss-extrausers \
  llvm \
  clang clang-tools clang-format clang-tidy clangd \
  libclang-rt-dev \
  lldb \
  lld \
  libc++-dev libc++abi-dev \
  ninja-build cmake curl python3 python3-pip python3-venv git ssh-client && \
  \
  # ==========================================
  # LLVM Native Toolchain
  # ==========================================
  CLANG_VER=$(clang --version | grep -oE 'clang version [0-9]+' | grep -oE '[0-9]+' | head -n1) && \
  mkdir -p /etc/clang && \
  echo "-fuse-ld=lld" > /etc/clang/clang.cfg && \
  echo "-rtlib=compiler-rt" >> /etc/clang/clang.cfg && \
  echo "-stdlib=libc++" > /etc/clang/clang++.cfg && \
  echo "-fuse-ld=lld" >> /etc/clang/clang++.cfg && \
  echo "-rtlib=compiler-rt" >> /etc/clang/clang++.cfg && \
  ln -s clang.cfg /etc/clang/clang-${CLANG_VER}.cfg && \
  ln -s clang++.cfg /etc/clang/clang++-${CLANG_VER}.cfg && \
  # ==========================================
  # GoogleTest (libc++ & Disabled exception)
  # ==========================================
  curl -fsSL https://github.com/google/googletest/archive/refs/tags/v${GTEST_VERSION}.tar.gz -o gtest.tar.gz && \
  echo "${GTEST_SHA512} gtest.tar.gz" | sha512sum -c - && \
  tar -xzf gtest.tar.gz && cd googletest-${GTEST_VERSION} && mkdir build && cd build && \
  cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_CXX_FLAGS="-stdlib=libc++ -fno-exceptions" \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  .. && \
  ninja install && \
  cd ../.. && \
  rm -rf googletest-${GTEST_VERSION} gtest.tar.gz && \
  # ==========================================
  (getent group messagebus || groupadd -r messagebus) && \
  (getent passwd messagebus || useradd -r -g messagebus -s /usr/sbin/nologin messagebus) && \
  apt-get clean && \
  find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' ! -name 'locale.alias' -exec rm -rf {} + && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/* && \
  sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen && update-locale LANG=en_US.UTF-8

RUN sed -i 's/passwd:.*files/& extrausers/' /etc/nsswitch.conf && \
  sed -i 's/group:.*files/& extrausers/' /etc/nsswitch.conf && \
  sed -i 's/shadow:.*files/& extrausers/' /etc/nsswitch.conf && \
  echo "%sudo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sudo_nopasswd && \
  chmod 0440 /etc/sudoers.d/sudo_nopasswd && \
  sed -i '1i auth sufficient pam_extrausers.so nullok' /etc/pam.d/common-auth && \
  sed -i '1i account sufficient pam_extrausers.so' /etc/pam.d/common-account && \
  rm -rf /var/log && ln -s /tmp/log /var/log && \
  rm -rf /run && ln -s /tmp/run /run && \
  rm -rf /var/lib/extrausers && ln -s /tmp/extrausers /var/lib/extrausers && \
  echo '#!/bin/bash\ncd /home/"$USER_NAME"\nexec sudo -u "$USER_NAME" "$@"' > /usr/local/bin/run-as-user && \
  chmod +x /usr/local/bin/run-as-user

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD ["sh", "-c", "curl -fsS http://localhost:3000 -o /dev/null || exit 1"]

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY supervisord-template.conf /usr/local/etc/supervisord-template.conf
COPY settings.json /usr/local/etc/settings.json
RUN chmod +x /usr/local/bin/entrypoint.sh
# ==========================================
# code-server
# ==========================================
ARG CODE_SERVER_VERSION
ARG CODE_SERVER_AMD64_SHA512
ARG CODE_SERVER_ARM64_SHA512

ARG CODELLDB_VERSION
ARG CODELLDB_X64_SHA512
ARG CODELLDB_ARM64_SHA512

RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
  CS_ARCH="amd64"; \
  CS_SHA512="${CODE_SERVER_AMD64_SHA512}"; \
  CODELLDB_ARCH="x64"; \
  CODELLDB_SHA512="${CODELLDB_X64_SHA512}"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  CS_ARCH="arm64"; \
  CS_SHA512="${CODE_SERVER_ARM64_SHA512}"; \
  CODELLDB_ARCH="arm64"; \
  CODELLDB_SHA512="${CODELLDB_ARM64_SHA512}"; \
  else \
  echo "Unsupported architecture: $ARCH" && exit 1; \
  fi && \
  curl -fsSL "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-${CS_ARCH}.tar.gz" -o /tmp/code-server.tar.gz && \
  echo "${CS_SHA512} /tmp/code-server.tar.gz" | sha512sum -c - && \
  tar -xzf /tmp/code-server.tar.gz -C /usr/local && \
  mv /usr/local/code-server-${CODE_SERVER_VERSION}-linux-${CS_ARCH} /usr/local/code-server && \
  curl -fsSL "https://github.com/vadimcn/codelldb/releases/download/v${CODELLDB_VERSION}/codelldb-linux-${CODELLDB_ARCH}.vsix" -o /tmp/codelldb.vsix && \
  echo "${CODELLDB_SHA512} /tmp/codelldb.vsix" | sha512sum -c - && \
  mkdir -p /tmp/vscode-exts && \
  /usr/local/code-server/bin/code-server \
  --extensions-dir /tmp/vscode-exts \
  --install-extension llvm-vs-code-extensions.vscode-clangd \
  --install-extension ms-vscode.cmake-tools \
  --install-extension ms-vscode.hexeditor \
  --install-extension /tmp/codelldb.vsix \
  --install-extension ms-python.python \
  --install-extension ms-python.debugpy \
  --install-extension charliermarsh.ruff && \
  mv /tmp/vscode-exts/* /usr/local/code-server/lib/vscode/extensions/ && \
  rm -rf /tmp/code-server.tar.gz /tmp/codelldb.vsix /tmp/vscode-exts

EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
