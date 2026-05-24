# Курсовая работа на профессии "DevOps-инженер с нуля" - Стрельников Александр

## Содержание

- [Инфраструктура](#инфраструктура)
- [Сайт](#сайт)
- [Мониторинг](#мониторинг)
- [Логи](#логи)
- [Сеть](#сеть)
- [Резервное копирование](#резервное-копирование)

---

## Инфраструктура

Инфраструктура развёрнута в Yandex Cloud с помощью Terraform и Ansible.

### Состав инфраструктуры

| ВМ | Зона | Подсеть | Публичный IP |
|---|---|---|---|
| bastion | ru-central1-b | public (192.168.10.0/24) | да |
| web1 | ru-central1-b | private-b (192.168.20.0/24) | нет |
| web2 | ru-central1-d | private-d (192.168.30.0/24) | нет |
| prometheus | ru-central1-b | private-b (192.168.20.0/24) | нет |
| grafana | ru-central1-b | public (192.168.10.0/24) | да |
| elasticsearch | ru-central1-b | private-b (192.168.20.0/24) | нет |
| kibana | ru-central1-b | public (192.168.10.0/24) | да |

### Структура репозитория

```
.
├── terraform/
│   ├── providers.tf           # Провайдер Yandex Cloud и версия Terraform
│   ├── variables.tf           # Переменные: токен, cloud_id, folder_id, SSH ключ
│   ├── network.tf             # VPC, подсети (public, private-b, private-d), NAT-шлюз
│   ├── security_groups.tf     # Security Groups для каждого сервиса
│   ├── compute.tf             # Все виртуальные машины (7 штук)
│   ├── alb.tf                 # Application Load Balancer: target group, backend, router
│   ├── snapshots.tf           # Расписание ежедневных снапшотов всех дисков
│   ├── outputs.tf             # Вывод публичных и приватных IP после apply
│   └── terraform.tfvars  # Файл с переменными
└── ansible/
    ├── ansible.cfg            # Настройки Ansible: inventory, SSH ключ, параметры подключения
    ├── inventory.ini          # Хосты и группы: bastion, web, prometheus, grafana, elasticsearch, kibana
    ├── site.yml               # Главный плейбук — запускает все остальные по порядку
    └── playbooks/
        ├── nginx.yml              # Установка nginx, деплой index.html с именем и IP машины
        ├── node_exporter.yml      # Установка Node Exporter на все хосты (метрики системы)
        ├── nginx_log_exporter.yml # Установка Nginx Log Exporter на веб-серверы (метрики логов)
        ├── prometheus.yml         # Установка Prometheus, конфиг со всеми targets
        ├── grafana.yml            # Установка Grafana, автоматический datasource Prometheus
        ├── elk.yml                # Установка Elasticsearch с исправлением прав и отключением SSL
        ├── kibana.yml             # Установка Kibana, подключение к Elasticsearch
        └── filebeat.yml           # Установка Filebeat, отправка логов nginx в Elasticsearch
```

### Описание Terraform файлов

**providers.tf** — определяет провайдер `yandex-cloud/yandex` версии `~> 0.100` и минимальную версию Terraform `>=1.8.4`. Содержит настройки подключения к облаку через токен.

**variables.tf** — объявляет переменные: `token` (IAM токен, sensitive), `cloud_id`, `folder_id`, путь к SSH ключу и ID образа Ubuntu 22.04.

**network.tf** — создаёт VPC `main-network`, три подсети (публичная и две приватные в разных зонах), NAT-шлюз и таблицу маршрутизации для выхода приватных ВМ в интернет.

**security_groups.tf** — создаёт 7 Security Groups: `sg-bastion` (SSH из интернета), `sg-internal-ssh` (SSH от Bastion + весь внутренний трафик VPC), `sg-web` (HTTP от ALB), `sg-prometheus`, `sg-grafana` (порт 3000), `sg-elasticsearch`, `sg-kibana` (порт 5601), `sg-alb` (HTTP + healthcheck порты).

**compute.tf** — создаёт 7 виртуальных машин: bastion (публичная подсеть), web1/web2 (приватные подсети в разных зонах), prometheus/elasticsearch (приватная подсеть), grafana/kibana (публичная подсеть). Все ВМ преемптивные для экономии ресурсов. Каждой ВМ назначена своя SG и `sg-internal-ssh`.

**alb.tf** — создаёт Application Load Balancer: Target Group (web1 + web2), Backend Group с healthcheck на `/`, HTTP Router с маршрутом на backend, и сам ALB с listener на порту 80 в публичной подсети.

**snapshots.tf** — настраивает расписание снапшотов для всех 7 дисков: запуск ежедневно в 03:00 UTC, время хранения 168 часов (7 дней).

**outputs.tf** — выводит публичные IP (bastion, grafana, kibana, ALB) и приватные IP (web1, web2, prometheus, grafana, elasticsearch, kibana) после `terraform apply`. Приватные IP используются в Ansible inventory.

### Описание Ansible плейбуков

**ansible.cfg** — глобальные настройки: путь к inventory, SSH ключ `~/.ssh/id_ed25519`, отключение проверки host key, включение pipelining для ускорения.

**inventory.ini** — список хостов по группам. Bastion подключается напрямую, все остальные через ProxyJump с ForwardAgent для проброса SSH ключа в приватную сеть.

**site.yml** — мастер-плейбук, импортирует все плейбуки в правильном порядке: nginx → node_exporter → nginx_log_exporter → prometheus → grafana → elk → kibana → filebeat.

**nginx.yml** — устанавливает nginx на группу `web`, создаёт `index.html` с именем хоста и IP адресом машины, настраивает конфиг с access/error логами.

**node_exporter.yml** — устанавливает Node Exporter v1.8.1 на все хосты (`hosts: all`). Скачивает tar.gz с GitHub, копирует бинарник, создаёт systemd-сервис от пользователя `nobody`.

**nginx_log_exporter.yml** — устанавливает prometheus-nginxlog-exporter v1.9.2 на веб-серверы через `.deb` пакет. Настраивает права на лог-файлы nginx (0644), создаёт конфиг для парсинга `access.log` и публикации метрик на порту 4040.

**prometheus.yml** — устанавливает Prometheus v2.52.0. Создаёт пользователя `prometheus`, настраивает конфиг с тремя job: `prometheus` (localhost), `node_exporter` (все 6 ВМ), `nginx_logs` (web1 и web2).

**grafana.yml** — устанавливает Grafana через зеркало Яндекса (`mirror.yandex.ru/mirrors/grafana`). Настраивает `grafana.ini` и автоматически создаёт datasource Prometheus через provisioning.

**elk.yml** — устанавливает Elasticsearch через репозиторий `elasticrepo.serveradmin.ru`. Настраивает `elasticsearch.yml` с отключёнными xpack security и SSL, исправляет права на директории `/usr/share/elasticsearch`, `/var/lib/elasticsearch`, `/var/log/elasticsearch`.

**kibana.yml** — устанавливает Kibana через тот же репозиторий `elasticrepo.serveradmin.ru`. Настраивает подключение к Elasticsearch по приватному IP.

**filebeat.yml** — устанавливает Filebeat через `elasticrepo.serveradmin.ru` на веб-серверы. Настраивает два input типа `filestream` для access.log и error.log, отправку в Elasticsearch в индекс `nginx-logs-YYYY.MM.DD`.

### Развёртка инфраструктуры

1. Для начала необходимо заполнить файлы terraform.tfvars variables.tf переменными

```bash
cloud_id            = "<id yandex cloud>"
folder_id           = "<id папки в yandex cloud>"
ssh_public_key_path = "<путь до публичного ssh ключа>"

# image_id для Ubuntu 22.04 LTS в Yandex Cloud
ubuntu_image_id = "fd87j6d92jlrbjqbl32q"
```

2. Выполнить команду ```export YC_TOKEN=$(yc iam create-token)``` для экспорта токена yandex в переменную окружения.


3. Выполнить следующие команды в дирректории с tf файлами для создания инфраструктуры

```bash
# Terraform — создание инфраструктуры
terraform init
terrafrom plan
terraform apply
```

4. Полученные ip адреса с помощью output необходимо внести в inventory.ini

5. Для конфигурации инфраструктуры в директории ansible необходимо выполнить следующие команды:

```bash
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
ansible all -m ping        # Проверить доступность
ansible-playbook site.yml
```

---

## Сайт

Два веб-сервера nginx в разных зонах доступности за Application Load Balancer.

- **web1** — зона `ru-central1-b`, приватная подсеть
- **web2** — зона `ru-central1-d`, приватная подсеть
- **ALB** — публичный IP, порт 80

Проверка работы балансировщика:

```bash
curl -v http://158.160.166.213
```
Проверка через браузер:

![web1](https://github.com/Stvrrow/fops-sysadm-diplom/blob/main/img/img1.png)

![web2](https://github.com/Stvrrow/fops-sysadm-diplom/blob/main/img/img2.png)

---

## Мониторинг

### Prometheus

Развёрнут на отдельной ВМ в приватной подсети. Собирает метрики с:
- Node Exporter (порт 9100) — все 6 ВМ
- Nginx Log Exporter (порт 4040) — web1, web2

Все targets в статусе UP:

![prometheus](https://github.com/Stvrrow/fops-sysadm-diplom/blob/main/img/img3.png)

### Grafana

Развёрнута на отдельной ВМ с публичным IP.

- **URL**: `http://89.169.161.22:3000`
- **Логин/пароль**: admin/admin

Настроен дашборд **Node Exporter Full** (ID: 1860) с метриками CPU, RAM, диск, сеть, HTTP.

![grafana](https://github.com/Stvrrow/fops-sysadm-diplom/blob/main/img/img4.png)

---

## Логи

### Elasticsearch

Развёрнут на отдельной ВМ в приватной подсети (`192.168.20.15:9200`).

Проверка:
```bash
curl http://192.168.20.15:9200
```

![elastic](https://github.com/Stvrrow/fops-sysadm-diplom/blob/main/img/img5.png)

### Filebeat

Установлен на web1 и web2. Отправляет логи nginx в Elasticsearch:
- `/var/log/nginx/access.log` → индекс `nginx-logs-YYYY.MM.DD`
- `/var/log/nginx/error.log` → индекс `nginx-logs-YYYY.MM.DD`

### Kibana

Развёрнута на отдельной ВМ с публичным IP.

- **URL**: `http://89.169.170.187:5601`

Настроен Data View `nginx-logs-*` для просмотра логов nginx.

![kibana](https://github.com/Stvrrow/fops-sysadm-diplom/blob/main/img/img6.png)

---

## Сеть

### VPC и подсети

| Подсеть | CIDR | Назначение |
|---|---|---|
| public | 192.168.10.0/24 | Bastion, Grafana, Kibana, ALB |
| private-b | 192.168.20.0/24 | web1, Prometheus, Elasticsearch |
| private-d | 192.168.30.0/24 | web2 |

Приватные подсети выходят в интернет через NAT-шлюз.

### Security Groups

| SG | Входящий трафик |
|---|---|
| sg-bastion | SSH (22) из интернета |
| sg-internal-ssh | SSH от sg-bastion + весь трафик из 192.168.0.0/16 |
| sg-web | HTTP (80) от sg-alb |
| sg-prometheus | только исходящий |
| sg-grafana | HTTP (3000) из интернета |
| sg-elasticsearch | только исходящий |
| sg-kibana | HTTP (5601) из интернета |
| sg-alb | HTTP (80) из интернета + healthcheck (198.18.235.0/24, 198.18.248.0/24) |

![groups](https://github.com/Stvrrow/fops-sysadm-diplom/blob/main/img/img7.png)

### Bastion Host

Единственная точка SSH-доступа снаружи. Подключение к приватным ВМ через ProxyJump:

```bash
ssh -A ubuntu@158.160.11.45        # Bastion
ssh ubuntu@192.168.20.21           # Prometheus (с Bastion)
```

---

## Резервное копирование

Настроено расписание снапшотов для всех 7 дисков:
- **Частота**: ежедневно в 03:00 UTC
- **Хранение**: 7 дней

```bash
yc compute snapshot-schedule list
yc compute snapshot list
```

![snapshots](https://github.com/Stvrrow/fops-sysadm-diplom/blob/main/img/img8.png)
