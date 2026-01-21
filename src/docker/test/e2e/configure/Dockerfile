FROM alpine:3.19

RUN apk add --no-cache curl bash python3

WORKDIR /
ADD src/docker/wait-for-it.sh /
ADD src/docker/test/e2e/configure/setup_seedsync.sh /

# Force rebuild 2026-01-21-v5
RUN echo "Cache bust: 2026-01-21-v5"

CMD ["/setup_seedsync.sh"]