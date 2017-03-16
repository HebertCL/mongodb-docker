FROM mongo
RUN mkdir -p /data/db/epicp /data/db/epics /data/arb
#COPY docker-entrypoint.sh /entrypoint.sh
EXPOSE 27017
ENTRYPOINT ["/entrypoint.sh"]
