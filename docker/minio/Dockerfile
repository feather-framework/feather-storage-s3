FROM minio/minio:RELEASE.2025-09-07T16-13-09Z

# Install mc client (comes pre-installed in recent images)
# If not, you can curl it from: https://dl.min.io/client/mc/release/linux-amd64/mc

WORKDIR /usr/local/bin/

COPY docker/minio/scripts/entrypoint.sh .

RUN chmod +x entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["server", "/data", "--console-address", ":9001"]
