FROM mlikiowa/napcat-docker:latest

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["bash", "/docker-entrypoint.sh"]
