FROM alpine/curl AS downloader

WORKDIR /app
RUN curl -s -o supervisord.tar.gz https://ghproxy.com/https://github.com/ochinchina/supervisord/releases/download/v0.7.3/supervisord_0.7.3_Linux_64-bit.tar.gz && \
    tar -zxvf supervisord.tar.gz -C . && \
    mv /app/supervisord_0.7.3_Linux_64-bit/supervisord_static /app/supervisord



FROM secfa/docker-awvs:awvs13-20200904 AS finally

COPY --from=downloader /app/supervisord /app/supervisord
COPY supervisord.conf /app/
COPY up.sh /home/acunetix/.acunetix/
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh /home/acunetix/.acunetix/up.sh

EXPOSE 9001 3443
ENTRYPOINT ["/app/entrypoint.sh"]
CMD [ "/app/supervisord", "-c", "/app/supervisord.conf" ]
