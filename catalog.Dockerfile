# Building stage
FROM quay.io/konflux-ci/operator-sdk-builder:latest@sha256:bc390cc52ffdd350f146932e0383e7843b509e51dde0c34d0f68b025ed6ff871 AS builder

# OLM's catalog pod probes exec grpc_health_probe (still true through OCP 4.21)
# GOBIN is under /tmp because the builder runs as a non-root user
ARG GRPC_HEALTH_PROBE_VERSION=v0.4.56
RUN CGO_ENABLED=0 GOFLAGS=-mod=mod GOBIN=/tmp/bin \
        go install github.com/grpc-ecosystem/grpc-health-probe@${GRPC_HEALTH_PROBE_VERSION}

# Final serving stage
FROM registry.access.redhat.com/ubi9/ubi-micro:latest AS serve
COPY --from=builder /bin/opm /bin/opm
COPY --from=builder /tmp/bin/grpc-health-probe /bin/grpc_health_probe
# Rendered from catalog/konflux-template.yaml before the build, so the build never pulls the bundle:
# by the run-opm-command task in Konflux, by `make catalog-render` locally
COPY catalog/hyperfleet-operator/catalog.yaml /configs/hyperfleet-operator/catalog.yaml
RUN ["/bin/opm", "validate", "/configs"]
RUN ["/bin/opm", "serve", "/configs/hyperfleet-operator", "--cache-dir=/tmp/cache", "--cache-only"]
ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs/hyperfleet-operator", "--cache-dir=/tmp/cache"]
ARG APP_VERSION="0.0.0-dev"
LABEL version="${APP_VERSION}"
LABEL operators.operatorframework.io.index.configs.v1=/configs
