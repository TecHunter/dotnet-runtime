FROM alpine:3.8

RUN apk add --no-cache \
        ca-certificates \
        \
        # .NET Core dependencies
        krb5-libs \
        libgcc \
        libintl \     
        libstdc++ \
        zlib \
    openssh libunwind \
    nghttp2-libs libidn libuuid lttng-ust openssl openssl-dev


ENV \
    # Configure web servers to bind to port 80 when present
    ASPNETCORE_URLS=http://+:5000 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Set the invariant mode since icu_libs isn't included (see https://github.com/dotnet/announcements/issues/20)
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

# Install .NET Core
RUN dotnet_version=3.1.10 \
    && wget -O dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Runtime/$dotnet_version/dotnet-runtime-$dotnet_version-linux-musl-x64.tar.gz \
    && dotnet_sha512='ee54d74e2a43f4d8ace9b1c76c215806d7580d52523b80cf4373c132e2a3e746b6561756211177bc1bdbc92344ee30e928ac5827d82bf27384972e96c72069f8' \
    && echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -C /usr/share/dotnet -oxzf dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && rm dotnet.tar.gz

# Install ASP.NET Core
RUN aspnetcore_version=3.1.10 \
    && wget -O aspnetcore.tar.gz https://dotnetcli.azureedge.net/dotnet/aspnetcore/Runtime/$aspnetcore_version/aspnetcore-runtime-$aspnetcore_version-linux-musl-x64.tar.gz \
    && aspnetcore_sha512='1a596c6f413c1f37ec6d3f0be74a19a9614d2321b5ab75290d5722ae824206dedf05e8773deac17330c4e9eff97caa56f5e59f5a6fd5d3543d3b8b4f67bbc8b3' \
    && echo "$aspnetcore_sha512  aspnetcore.tar.gz" | sha512sum -c - \
    && tar -ozxf aspnetcore.tar.gz -C /usr/share/dotnet ./shared/Microsoft.AspNetCore.App \
    && rm aspnetcore.tar.gz

# Create non-root user
RUN addgroup --system --gid 1000 appuser && \
    adduser --system --home /home/appuser --uid 1001 appuser --ingroup appuser && \
    chown appuser:appuser /home/appuser

RUN mkdir -p /home/appuser/app
COPY --chown=appuser:appuser . /home/appuser/app

# Copy files
WORKDIR /home/appuser/app

USER 1001

EXPOSE 5000 2222
