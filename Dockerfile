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
RUN chmod +x /app/entrypoint.sh /home/acunetix/.acunetix/up.sh && \
    # 将破解相关文件的用户设置为root，防止被篡改
    chmod 444 /home/acunetix/.acunetix/data/license/license_info.json && \
    chmod 444 /home/acunetix/.acunetix/data/license/wa_data.dat && \
    chown root:root /home/acunetix/.acunetix/data/license/license_info.json /home/acunetix/.acunetix/data/license/wa_data.dat


EXPOSE 9001 3443
ENTRYPOINT ["/app/entrypoint.sh"]
CMD [ "/app/supervisord", "-c", "/app/supervisord.conf" ]
