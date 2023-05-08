FROM xrsec/awvs:v15 as base

# 下载 gosu
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION 1.14

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    curl -s -o /usr/local/bin/gosu "https://ghproxy.com/https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	curl -s -o /usr/local/bin/gosu.asc "https://ghproxy.com/https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    chmod +x /usr/local/bin/gosu

# 删除 acunetix 安装目录中无用的文件
RUN rm -rf /home/acunetix/.acunetix/db/* && \
    rm -rf /home/acunetix/.acunetix/logs/*

# 下载破解相关文件
ADD https://www.fahai.org/aDisk/Awvs/awvs15_listen.zip /tmp/

RUN cd /tmp/ && \
    unzip awvs15_listen.zip && \
    chmod 444 /tmp/license_info.json && \
    chmod 444 /tmp/wa_data.dat && \
    chmod 777 /tmp/wvsc && \
    # 将破解相关文件的用户设置为root，防止被篡改
    chown root:root /tmp/license_info.json /tmp/wa_data.dat /tmp/wvsc && \
    # 替换 license
    mkdir -p /home/acunetix/.acunetix/data/license/ && \
    mv /tmp/license_info.json /home/acunetix/.acunetix/data/license/ && \
    mv /tmp/wa_data.dat /home/acunetix/.acunetix/data/license/ && \
    mv /tmp/wvsc /home/acunetix/.acunetix/v_*/scanner/ && \
    # 生成 hosts 文件
    echo '127.0.0.1 updates.acunetix.com' > /etc/.hosts && \
    echo '127.0.0.1 erp.acunetix.com' >> /etc/.hosts && \
    echo '127.0.0.1 telemetry.invicti.com' >> /etc/.hosts




FROM ubuntu:22.04 AS finally

# xrsec/awvs 默认用户和组添加，对应 gid 和 uid
# 参见 https://github.com/docker-library/redis/blob/master/5/32bit/Dockerfile
RUN groupadd -r -g 1000 acunetix && useradd -r -m -g acunetix -u 999 acunetix

# 安装 gosu
COPY --from=base /usr/local/bin/gosu* /usr/local/bin/

COPY --from=base /home/acunetix/.acunetix /home/acunetix/.acunetix
COPY --from=base /etc/.hosts /etc/.hosts
COPY entrypoint.sh /entrypoint.sh

RUN \
    # 检查 gosu 是否安装成功
    gosu --version && \
	gosu nobody true && \
    # 添加 token
    sed -i "/log \"Main user is \$email\"/a if [[ \$acunetix_token =~ ^[a-f0-9]{32}$ ]]; then \"\$psql\" -v ON_ERROR_STOP=1 -qbc \"UPDATE users SET api_key='\$acunetix_token',lang='cn' WHERE user_id='986ad8c0a5b3df4d7028d5f3c06e936c';\" \"\$db\"; fi" /home/acunetix/.acunetix/v_?????????/backend/container-entrypoint.sh && \
    # 修正 wvsc.ini
    sed -i 's|^DataPath=\$data.*$|DataPath=/home/acunetix/.acunetix/data|g' /home/acunetix/.acunetix/v_?????????/backend/container-entrypoint.sh && \
    # 生成启动脚本
    cp /home/acunetix/.acunetix/v_?????????/backend/container-entrypoint.sh /home/acunetix/.acunetix/entrypoint.sh && \
    chown acunetix:acunetix /home/acunetix/.acunetix/entrypoint.sh && \
    # 给入口脚本添加可执行权限
    chmod +x /entrypoint.sh

EXPOSE 3443

ENTRYPOINT ["/entrypoint.sh"]
