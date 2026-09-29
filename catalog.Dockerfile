# Use the official operator registry base image with OCP version v4.22
FROM registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.22

# Rendered from catalog/konflux-template.yaml before the build, so the build never pulls the bundle:
# by the run-opm-command task in Konflux, by `make catalog-render` locally
COPY catalog/hyperfleet-operator/catalog.yaml /configs/hyperfleet-operator/catalog.yaml

# Validate the catalog configuration
RUN ["/bin/opm", "validate", "/configs"]

# Generate the catalog cache during build
RUN ["/bin/opm", "serve", "/configs", "--cache-dir=/tmp/cache", "--cache-only"]

ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs", "--cache-dir=/tmp/cache"]


ARG APP_VERSION="0.0.0-dev"
LABEL version="${APP_VERSION}"
LABEL operators.operatorframework.io.index.configs.v1=/configs
