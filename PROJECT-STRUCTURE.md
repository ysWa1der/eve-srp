# EVE-SRP 프로젝트 구조

이 문서는 재구성된 EVE-SRP 프로젝트 구조를 설명합니다.

## 📁 디렉토리 구조

```
eve-srp/
├── docker/                 # Docker 관련 파일 (컨테이너별 분리)
│   ├── nginx/
│   │   └── conf/
│   │       └── default.conf
│   ├── php/
│   │   ├── Dockerfile-php81-fpm
│   │   ├── Dockerfile-php82-fpm
│   │   ├── Dockerfile-php83-fpm
│   │   ├── Dockerfile-php84-fpm
│   │   └── entrypoint.sh
│   ├── node/
│   ├── db/
│   │   └── init/
│   └── postgres/
│       └── init/
│
├── app/                    # PHP 애플리케이션 (기존 구조 유지)
│   ├── bin/                # CLI 스크립트 (doctrine 등)
│   ├── config/             # 애플리케이션 설정
│   │   ├── .env            # 환경 변수 (Git 제외)
│   │   ├── .env.dist       # 환경 변수 템플릿
│   │   ├── config.php      # 메인 설정
│   │   ├── routes.php      # 라우팅 설정
│   │   └── ...
│   ├── src/                # PHP 소스 코드
│   │   ├── Controller/
│   │   ├── Model/
│   │   ├── Service/
│   │   └── ...
│   ├── templates/          # Twig 템플릿
│   ├── web/                # 웹 루트
│   │   ├── static/         # 정적 파일
│   │   ├── dist/           # 빌드된 프론트엔드 (Git 제외)
│   │   └── index.php       # 엔트리 포인트
│   ├── storage/            # 런타임 데이터 (Git 제외)
│   │   ├── doctrine/       # Doctrine 프록시
│   │   ├── compilation_cache/
│   │   └── logs/
│   ├── tests/              # 테스트 코드
│   ├── composer.json       # PHP 의존성
│   ├── composer.lock
│   └── phpunit.xml         # PHPUnit 설정
│
├── frontend/               # 프론트엔드 (Node.js)
│   ├── resources/          # 소스 파일
│   │   ├── index.js        # JavaScript 엔트리
│   │   ├── EveSrp.js
│   │   ├── eve-srp.scss    # SCSS
│   │   ├── js.html         # Webpack 템플릿
│   │   └── css.html
│   ├── package.json        # Node.js 의존성
│   ├── package-lock.json
│   └── webpack.config.js   # Webpack 설정
│
├── .env                    # Docker Compose 환경 변수 (Git 제외)
├── .env.example            # 환경 변수 템플릿
├── compose.yaml            # Docker Compose 설정
├── .gitignore
├── README.md
├── DOCKER-SETUP.md         # Docker 설정 가이드
└── PROJECT-STRUCTURE.md    # 이 파일
```

---

## 🔧 컨테이너별 역할

### **1. eve_srp_php** (PHP-FPM)
- **위치**: `app/`
- **Docker 설정**: `docker/php/`
- **역할**: PHP 애플리케이션 실행
- **볼륨**: `./app:/app`
- **빌드**: `docker/php/Dockerfile-php84-fpm`

### **2. eve_srp_http** (Nginx)
- **위치**: 없음 (이미지만 사용)
- **Docker 설정**: `docker/nginx/conf/default.conf`
- **역할**: HTTP 서버, 정적 파일 제공
- **볼륨**:
  - `./app/web:/app/web:ro` (읽기 전용)
  - `./docker/nginx/conf/default.conf:/etc/nginx/conf.d/default.conf:ro`

### **3. eve_srp_node** (Node.js)
- **위치**: `frontend/`
- **역할**: 프론트엔드 빌드 (npm run build)
- **볼륨**:
  - `./frontend:/app`
  - `./app/web/dist:/app/web/dist` (빌드 결과물)

### **4. eve_srp_db** (MariaDB)
- **위치**: 없음 (이미지만 사용)
- **Docker 설정**: `docker/db/init/` (선택사항)
- **역할**: 데이터베이스
- **볼륨**: `./.db/mariadb:/var/lib/mysql`

### **5. eve_srp_db_postgres** (PostgreSQL)
- **위치**: 없음 (이미지만 사용)
- **Docker 설정**: `docker/postgres/init/` (선택사항)
- **역할**: 대체 데이터베이스
- **볼륨**: `./.db/postgresql:/var/lib/postgresql/data`

---

## 📝 주요 경로 변경사항

| 구분 | 기존 경로 | 새 경로 |
|------|-----------|---------|
| **PHP 소스** | `/src` | `/app/src` |
| **웹 루트** | `/web` | `/app/web` |
| **설정 파일** | `/config` | `/app/config` |
| **Composer** | `/composer.json` | `/app/composer.json` |
| **프론트엔드 소스** | `/resources` | `/frontend/resources` |
| **빌드 설정** | `/webpack.config.js` | `/frontend/webpack.config.js` |
| **NPM 설정** | `/package.json` | `/frontend/package.json` |
| **Docker 설정** | `/config/docker-*` | `/docker/*/` |

---

## 🚀 사용 방법

### 개발 환경 시작

```bash
# 1. 환경 변수 설정
cp .env.example .env
nano .env

# 2. Docker Compose 시작
docker compose up -d

# 3. Composer 의존성 설치 (최초 1회)
docker exec eve_srp_php composer install

# 4. 프론트엔드 빌드
docker exec eve_srp_node npm install
docker exec eve_srp_node npm run build

# 또는 watch 모드로 개발
docker exec eve_srp_node npm run watch
```

### 프론트엔드 개발

```bash
# frontend/ 디렉토리에서 작업
cd frontend/

# 개발 모드 (파일 감시)
npm run watch

# 빌드
npm run build
```

빌드 결과물은 `app/web/dist/`에 생성됩니다.

### PHP 개발

```bash
# app/ 디렉토리에서 작업
cd app/

# Composer 의존성 추가
docker exec eve_srp_php composer require vendor/package

# 테스트 실행
docker exec eve_srp_php ./vendor/bin/phpunit

# Doctrine 명령
docker exec eve_srp_php bin/doctrine orm:schema-tool:update
```

---

## 🔄 마이그레이션 가이드

기존 프로젝트에서 새 구조로 전환하는 경우:

### 1. 백업
```bash
git stash  # 또는 브랜치 생성
```

### 2. 환경 변수 마이그레이션
```bash
# 기존 config/.env 내용을
# app/config/.env와 .env(프로젝트 루트)로 분리
```

### 3. 컨테이너 재생성
```bash
docker compose down
docker compose build
docker compose up -d
```

### 4. 의존성 재설치
```bash
# PHP
docker exec eve_srp_php composer install

# Node.js
docker exec eve_srp_node npm install
docker exec eve_srp_node npm run build
```

---

## 🔐 환경 변수 관리

### `.env` (프로젝트 루트)
Docker Compose에서 사용하는 변수:
- `DB_ROOT_PASSWORD`
- `DB_USER`
- `DB_PASSWORD`
- `SSO_CLIENT_ID`
- `SSO_CLIENT_SECRET`
- 등

### `app/config/.env`
PHP 애플리케이션에서 직접 사용 (로컬 개발용):
- compose.yaml의 environment 섹션을 사용하는 경우 불필요
- 로컬 개발 시 config/.env.dist 복사해서 사용 가능

**권장**: 프로덕션에서는 compose.yaml의 environment 섹션 사용

---

## 📊 볼륨 마운트 흐름

```
┌─────────────┐
│  frontend/  │ → npm build
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ app/web/dist/   │ ← 빌드 결과물
└────────┬────────┘
         │
         ├──→ eve_srp_php (PHP가 템플릿에서 참조)
         │
         └──→ eve_srp_http (Nginx가 정적 파일 제공)
```

---

## 🎯 장점

1. **명확한 분리**: Docker 설정, 백엔드, 프론트엔드가 명확히 분리됨
2. **유지보수**: 각 컨테이너의 설정을 독립적으로 관리 가능
3. **호환성**: PHP 애플리케이션 구조는 기존과 동일 (autoload 경로 유지)
4. **확장성**: 새로운 컨테이너 추가 시 docker/ 아래에 디렉토리만 추가
5. **Docker Hub 배포**: 각 컨테이너별로 이미지 빌드 가능

---

## ⚠️ 주의사항

1. **경로 참조**
   - PHP 코드에서 파일 참조 시 `/app/` 기준 사용
   - Webpack 빌드 결과는 `../app/web/dist`로 출력

2. **볼륨 마운트**
   - 개발 시: 전체 디렉토리 마운트
   - 프로덕션: 필요한 부분만 마운트 (보안)

3. **환경 변수**
   - `.env` 파일은 Git에 커밋하지 않음
   - `.env.example` 템플릿 사용

---

문의사항이나 문제가 있으면 GitHub Issues에 보고해주세요.
