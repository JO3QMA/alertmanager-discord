# syntax=docker/dockerfile:1.6
# Built following https://medium.com/@chemidy/create-the-smallest-and-secured-golang-docker-image-based-on-scratch-4752223b7324

# STEP 1 build executable binary
FROM golang:alpine as builder
# Install SSL ca certificates (cache apk index & packages)
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update --no-progress git ca-certificates
# Create appuser
RUN adduser -D -g '' appuser
COPY . $GOPATH/src/mypackage/myapp/
WORKDIR $GOPATH/src/mypackage/myapp/
#get dependancies (use BuildKit cache)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go get -d -v
#build the binary (use BuildKit cache)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o /go/bin/alertmanager-discord


# STEP 2 build a small image (Distroless)
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# Copy our static executable
COPY --from=builder /go/bin/alertmanager-discord /alertmanager-discord

ENV LISTEN_ADDRESS=0.0.0.0:9094
EXPOSE 9094
ENTRYPOINT ["/alertmanager-discord"]
