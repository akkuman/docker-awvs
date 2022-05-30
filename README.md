# docker-awvs

感谢法海的docker-awvs，该项目只是让用户名和apikey的配置更加简单

## 使用

### docker-compose

将 [docker-compose.yml](docker-compose.yml) 保存到你的机器上

然后修改环境变量中的账号密码和apikey

然后使用命令

```shell
sudo docker-compose up -d
```

### docker

或者你不想使用 `docker-compose`，也可以直接使用 `docker`

```shell
sudo docker run -dp 13443:3443 -e AWVS_USERNAME=test@admin.com -e AWVS_PASSWORD=test1@admin.com -e AWVS_APIKEY=4de0e7ba28434d46a0d12e04898cc5a8 akkuman/awvs
```

## 环境变量

```yaml
AWVS_USERNAME: test@admin.com
# AWVS_PASSWORD: 必须包含数字小写字母，特殊符号
AWVS_PASSWORD: test1@admin.com
# AWVS_APIKEY: 必须为32位的md5值
AWVS_APIKEY: 4de0e7ba28434d26a0d12e04898cc5a7
```

其中最后使用的awvs api_key为 `1986ad8c0a5b3df4d7028d5f3c06e936c"$AWVS_APIKEY"`

比如该例子中，最后的 api_key 为 `1986ad8c0a5b3df4d7028d5f3c06e936c4de0e7ba28434d26a0d12e04898cc5a7`


## Reference

- [法海之路](https://www.fahai.org/)
