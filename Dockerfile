# ------------
# Build Stage: Get Dependencies
# ------------
FROM alpine:latest AS get-dependencies
LABEL stage=builder

LABEL org.opencontainers.image.description="A ZestCode Build Container"
LABEL org.opencontainers.image.source=https://github.com/ZestCommunity/build-action
LABEL org.opencontainers.image.licenses=MIT

# Install Required Packages and ARM Toolchain
RUN apk add --no-cache bash
RUN mkdir "/arm-none-eabi-toolchain" && wget -O- "https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz" \
    | tar Jxf - -C "/arm-none-eabi-toolchain" --strip-components=1 
RUN <<-"EOF" bash
    set -e

    toolchain="/arm-none-eabi-toolchain"
    mkdir -p "$toolchain"

    rm -rf "$toolchain"/{share,include}
    rm -rf "$toolchain"/lib/gcc/arm-none-eabi/14.2.1/arm
    rm -f "$toolchain"/bin/arm-none-eabi-{gdb,gdb-py,cpp,gcc-14.2.1}
    
    find "$toolchain"/arm-none-eabi/lib/thumb                              -mindepth 1 -maxdepth 1 ! -name 'v7-a+simd' -exec rm -rf {} +
    find "$toolchain"/lib/gcc/arm-none-eabi/14.2.1/thumb                   -mindepth 1 -maxdepth 1 ! -name 'v7-a+simd' -exec rm -rf {} +
    find "$toolchain"/arm-none-eabi/include/c++/14.2.1/arm-none-eabi/thumb -mindepth 1 -maxdepth 1 ! -name 'v7-a+simd' -exec rm -rf {} + 

    apk cache clean # Cleanup image
EOF
# ------------
# Runner Stage
# ------------
FROM alpine:latest AS runner
LABEL stage=runner
LABEL org.opencontainers.image.description="A ZestCode Build Container"
LABEL org.opencontainers.image.source=https://github.com/ZestCommunity/build-action
LABEL org.opencontainers.image.licenses=MIT
# Copy dependencies from get-dependencies stage
COPY --from=get-dependencies /arm-none-eabi-toolchain /arm-none-eabi-toolchain
RUN apk add --no-cache gcompat libc6-compat libstdc++ git gawk python3 pipx unzip bash && pipx install meson ninja && apk cache clean

# Set Environment Variables
ENV PATH="/arm-none-eabi-toolchain/bin:/root/.local/bin:${PATH}"

ENV PYTHONUNBUFFERED=1

COPY build-tools/build.sh /build.sh
RUN chmod +x /build.sh
COPY LICENSE /LICENSE

ENTRYPOINT ["/build.sh"]
