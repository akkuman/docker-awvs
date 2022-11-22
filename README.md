# docker-awvs

该项目让用户名和 token 的配置更加简单

## 使用

### docker-compose

将 [docker-compose.yml](docker-compose.yml) 保存到你的机器上

然后修改环境变量中的账号密码和token

然后使用命令

```shell
sudo docker-compose up -d
```

### docker

或者你不想使用 `docker-compose`，也可以直接使用 `docker`

```shell
sudo docker run -dp 13443:3443 -e acunetix_user=test@admin.com -e acunetix_password=test1@admin.com -e acunetix_token=4de0e7ba28434d46a0d12e04898cc5a8 akkuman/awvs
```

## 环境变量

```yaml
acunetix_user: test@admin.com
# AWVS_PASSWORD: 必须包含数字小写字母，特殊符号
acunetix_password: test1@admin.com
# AWVS_APIKEY: 必须为32位的md5值
acunetix_token: 4de0e7ba28434d26a0d12e04898cc5a7
acunetix_database: pg 数据库地址，格式 `postgresql://<user>:<password>@<host>:<port>/<db>`
```

其中最后的 api_key为 `1986ad8c0a5b3df4d7028d5f3c06e936c"$acunetix_token"`

比如该例子中，最后的 api_key 为 `1986ad8c0a5b3df4d7028d5f3c06e936c4de0e7ba28434d26a0d12e04898cc5a7`

调用方法例如 `curl -k -X GET https://127.0.0.1:3443//api/v1/users -H 'Accept: application/json' -H 'X-Auth: 1986ad8c0a5b3df4d7028d5f3c06e936c4de0e7ba28434d26a0d12e04898cc5a7'`


## Reference

- [法海之路](https://www.fahai.org/)
- [XRSec-AWVS](https://github.com/XRSec/AWVS-Update)
