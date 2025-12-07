# EVE-SRP Docker Setup Guide

이 문서는 Docker Compose를 사용한 EVE-SRP 설정 가이드입니다.

## 📋 목차

1. [환경 변수 설정 방식](#환경-변수-설정-방식)
2. [로컬 개발 환경 설정](#로컬-개발-환경-설정)
3. [프로덕션 배포](#프로덕션-배포)
4. [Container Manager 배포](#container-manager-배포)

---

## 🔧 환경 변수 설정 방식

EVE-SRP는 두 가지 방식으로 환경 변수를 설정할 수 있습니다:

### **방법 1: compose.yaml 환경변수 (권장 - 프로덕션)**

모든 설정을 `compose.yaml`의 `environment` 섹션에서 관리합니다.

**장점:**
- Docker Hub 배포 시 이미지만 교체하면 됨
- Container Manager GUI에서 쉽게 수정 가능
- 파일 마운트 불필요
- 환경별 설정 분리 용이

### **방법 2: config/.env 파일 (로컬 개발)**

`config/.env` 파일에 설정을 저장합니다.

**장점:**
- 로컬 개발 시 편리
- 기존 방식과 호환

---

## 💻 로컬 개발 환경 설정

### 1. 환경 변수 파일 생성

```bash
# 프로젝트 루트에서
cp .env.example .env

# 또는 config/.env 방식 사용 (선택)
cp config/.env.dist config/.env
```

### 2. .env 파일 수정

```bash
nano .env
```

필수 항목:
- `SSO_CLIENT_ID`: EVE SSO Client ID
- `SSO_CLIENT_SECRET`: EVE SSO Client Secret
- `SSO_REDIRECT_URI`: 리다이렉트 URI

### 3. Docker Compose 시작

```bash
docker compose up -d
```

### 4. 접속

```
http://localhost:9000
```

---

## 🚀 프로덕션 배포

### **시나리오 A: Docker Hub 이미지 사용**

1. **compose.yaml 수정**

   ```yaml
   eve_srp_php:
     # build 주석 처리
     # build:
     #   context: config
     #   dockerfile: dockerfile-php84-fpm

     # 이미지 사용
     image: ${DOCKER_IMAGE:-youruser/eve-srp:latest}
   ```

2. **.env 파일 생성**

   ```bash
   cp .env.example .env
   nano .env
   ```

3. **실제 값 입력**

   ```bash
   # .env
   SSO_CLIENT_ID=your_actual_client_id
   SSO_CLIENT_SECRET=your_actual_secret
   SSO_REDIRECT_URI=https://yourdomain.com/auth
   SESSION_SECURE=1
   ```

4. **Docker Compose 시작**

   ```bash
   docker compose pull
   docker compose up -d
   ```

---

## 🖥 Container Manager (Synology) 배포

Synology Container Manager를 사용하는 경우:

### **방법 1: compose.yaml 업로드 (권장)**

1. **Container Manager 접속**

2. **프로젝트 생성**
   - Project → Create
   - 이름: `eve-srp`
   - 경로: `/docker/eve-srp`

3. **compose.yaml 업로드**
   - `compose.yaml` 파일 선택
   - 환경 변수 확인/수정

4. **환경 변수 설정**

   Environment 탭에서 다음 값들을 GUI로 입력:

   ```
   SSO_CLIENT_ID = your_client_id
   SSO_CLIENT_SECRET = your_secret
   SSO_REDIRECT_URI = https://your-nas-ip:9000/auth
   SESSION_SECURE = 1  (HTTPS 사용 시)
   ESI_SUBMITTER_CORPORATIONS = 98294509
   ESI_REVIEW_CHARACTERS = 2114345170,2115846759
   ```

5. **시작**

### **방법 2: .env 파일 사용**

1. **NAS에 .env 파일 생성**

   ```bash
   # SSH로 NAS 접속
   ssh admin@your-nas-ip

   cd /volume1/docker/eve-srp
   nano .env
   ```

2. **필요한 값 입력 후 저장**

3. **Container Manager에서 프로젝트 생성**

---

## 🔐 보안 권장사항

### 프로덕션 환경

```bash
# .env 파일
SESSION_SECURE=1          # HTTPS 필수
APP_ENV=prod              # 프로덕션 모드
REQUIRE_GROUP=true        # 그룹 필요 시
```

### 파일 권한

```bash
chmod 600 .env
chmod 600 config/.env
```

---

## 📊 환경 변수 우선순위

애플리케이션은 다음 순서로 환경 변수를 로드합니다:

1. **Docker environment** (compose.yaml)
2. **config/.env 파일** (있는 경우)
3. **기본값**

### 예시

```yaml
# compose.yaml
environment:
  EVE_SRP_DB_URL: mysql://user:pass@db/eve_srp  # 1순위
```

```bash
# config/.env (있는 경우)
EVE_SRP_DB_URL=mysql://root:eve_srp@eve_srp_db/eve_srp  # 2순위 (무시됨)
```

**결과:** Docker environment의 값이 사용됨

---

## 🔄 업데이트 방법

### Docker Hub 이미지 업데이트

```bash
# 새 이미지 pull
docker compose pull eve_srp_php

# 컨테이너 재생성
docker compose up -d --force-recreate eve_srp_php

# 또는 모든 서비스 업데이트
docker compose pull
docker compose up -d --force-recreate
```

### 설정 변경

```bash
# .env 파일 수정
nano .env

# 컨테이너 재시작 (환경 변수 재로드)
docker compose restart eve_srp_php

# 또는 재생성
docker compose up -d --force-recreate eve_srp_php
```

---

## 🐛 트러블슈팅

### config/.env vs compose.yaml 충돌

**문제:** 어느 설정이 적용되는지 모르겠음

**해결:**
1. **프로덕션**: `config/.env` 파일 삭제, compose.yaml만 사용
2. **로컬 개발**: compose.yaml의 기본값 사용, 필요 시 .env로 오버라이드

### 환경 변수 확인

```bash
# 컨테이너 내부 환경 변수 확인
docker exec eve_srp_php printenv | grep EVE_SRP

# 또는
docker exec eve_srp_php env
```

### 설정 초기화

```bash
# 모든 컨테이너 및 볼륨 삭제 (주의!)
docker compose down -v

# .env 파일 재생성
cp .env.example .env
nano .env

# 재시작
docker compose up -d
```

---

## 📚 참고 자료

- **compose.yaml**: Docker Compose 설정 (환경 변수 정의 포함)
- **.env.example**: 환경 변수 템플릿
- **config/.env.dist**: 로컬 개발용 환경 변수 템플릿
- **원본 README.md**: 프로젝트 전체 문서

---

## ❓ FAQ

**Q: config/.env와 .env(프로젝트 루트)의 차이는?**

A:
- `config/.env`: PHP 애플리케이션이 직접 읽는 파일 (로컬 개발용)
- `.env`: Docker Compose가 읽는 파일 (변수 치환용)

**Q: 프로덕션에서는 어떤 방식을 써야 하나?**

A: compose.yaml의 environment 섹션 사용 권장. Container Manager에서 관리 용이.

**Q: Docker Hub 배포 시 .env 파일을 이미지에 포함하나?**

A: 아니요. 환경 변수는 이미지 외부에서 주입됩니다. 이미지는 코드만 포함.

**Q: 여러 환경(dev/staging/prod)을 어떻게 관리하나?**

A:
- `compose.dev.yaml`, `compose.prod.yaml` 파일 분리
- 또는 환경별 `.env.dev`, `.env.prod` 파일 사용

---

문제가 발생하면 GitHub Issues에 보고해주세요.
