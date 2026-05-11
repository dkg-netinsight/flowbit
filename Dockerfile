ARG BIN_SOURCE="builder"
FROM golang:alpine AS builder
ARG LDFLAGS=""

RUN apk --update --no-cache add git build-base gcc

COPY . /build
WORKDIR /build

RUN go build -trimpath -ldflags "${LDFLAGS}" -o flowbit cmd/flowbit/main.go

FROM scratch AS prebuilt
ARG PREBUILT_BINARY="flowbit"
COPY ${PREBUILT_BINARY} /build/flowbit

FROM ${BIN_SOURCE} AS binstage

FROM alpine:latest
ARG src_dir
ARG VERSION=""
ARG CREATED=""
ARG DESCRIPTION=""
ARG NAME=""
ARG MAINTAINER=""
ARG URL=""
ARG LICENSE=""
ARG REV=""

LABEL org.opencontainers.image.created="${CREATED}"
LABEL org.opencontainers.image.authors="${MAINTAINER}"
LABEL org.opencontainers.image.url="${URL}"
LABEL org.opencontainers.image.title="${NAME}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.description="${DESCRIPTION}"
LABEL org.opencontainers.image.licenses="${LICENSE}"
LABEL org.opencontainers.image.revision="${REV}"

RUN apk update --no-cache && \
    adduser -S -D -H -h / flow
USER flow
COPY --from=binstage /build/flowbit /

ENTRYPOINT ["./flowbit"]
