# My KinD Study


### docker ip range

```
vim ~/.orbstack/config/docker.json

{
  "bip": "172.16.0.1/24",
  "default-address-pools": [
    {
      "base": "172.16.0.0/16",
      "size": 24
    }
  ]
}
```


### kube-ps1

```
# 1. kube-ps1 스크립트 로드 (Homebrew 경로)
echo "source $(brew --prefix)/opt/kube-ps1/share/kube-ps1.sh" >> ~/.zshrc

# 2. zsh 프롬프트(PROMPT) 설정에 추가
# %n@%m 등 기존 설정 유지하면서 앞에 붙이는 방식입니다.
echo "PROMPT=' \$(kube_ps1)'\$PROMPT" >> ~/.zshrc

# 3. 설정 반영
source ~/.zshrc
```

### kubectx

```
brew install kubectx
brew install fzf

# ~/.zshrc 파일 끝에 추가
alias kx='kubectx'
alias kn='kubens'
```

### ~/.zshrc

```
cat ~/.zshrc

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(git)
source $ZSH/oh-my-zsh.sh

export JAVA_HOME=$(/usr/libexec/java_home -v 17)

export PATH=/opt/homebrew/bin:$PATH
export PATH="/Users/ejpark/.codeium/windsurf/bin:$PATH"
export PATH="/Users/ejpark/.rd/bin:$PATH"

alias python="python3"
alias k="kubectl"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

source /opt/homebrew/opt/kube-ps1/share/kube-ps1.sh
PROMPT=' $(kube_ps1)'$PROMPT
```

## docker image 분석 도구

### 1. [Wagoodman/dive](https://github.com/wagoodman/dive) (Docker로 실행)

가장 확실한 대안은 `dive`를 **설치하지 않고 Docker로 실행**하는 것입니다. macOS에 패키지를 깔기 싫거나 의존성 문제가 있을 때 가장 깔끔합니다.

```bash
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest <이미지_이름>

```

### 2. [SlimToolkit (구 DockerSlim)](https://github.com/slimtoolkit/slim)

`dive`가 "보기"에 집중한다면, **SlimToolkit**은 "분석하고 줄이기"에 특화된 괴물 같은 도구입니다.

* **기능**: 이미지 내부를 분석해서 사용하지 않는 파일을 찾아내고, 이미지 크기를 최대 30배까지 줄여줍니다.
* **시각화**: `slim xray` 명령어를 쓰면 이미지 레이어의 상세 구조를 리포트로 뽑아줍니다.
* **설치 (macOS)**: `brew install docker-slim`
* **사용법**:
```bash
slim xray --target <이미지_이름>

```


### 3. [Trivy](https://github.com/aquasecurity/trivy) (보안 및 레이어 분석)

원래는 보안 취약점 스캐너지만, 이미지의 **레이어별 구성 요소**를 파악하는 데 아주 훌륭합니다.

* **특징**: 어떤 레이어에서 어떤 패키지가 설치되었고, 어디서 용량이 늘어났는지 보안 관점에서 보여줍니다.
* **사용법**:
```bash
trivy image <이미지_이름>

```

---

### 📊 한눈에 비교하기

| 도구명 | 주요 용도 | 장점 |
| --- | --- | --- |
| **Dive** | 레이어별 파일 탐색 | UI가 직관적이고 레이어 간 차이점 확인이 쉬움 |
| **SlimToolkit** | 이미지 최적화 & 분석 | 이미지 용량을 획기적으로 줄여주는 기능 포함 |
| **Trivy** | 보안 스캔 & 패키지 분석 | 레이어별 설치된 소프트웨어 명세(SBOM) 확인 가능 |
| **Skopeo** | 이미지 전송 & 검사 | Docker 데몬 없이도 리모트/로컬 이미지 메타데이터 조회 |

### headlamp

```
brew install --cask headlamp

open /Applications/Headlamp.app

sudo xattr -rd com.apple.quarantine /Applications/Headlamp.app

open /Applications/Headlamp.app
```

### 1. macOS 데스크톱 앱으로 설치 (가장 추천)

내 맥북에 앱을 깔아서 바로 로컬이나 원격 k8s 클러스터에 연결하는 방식입니다. `kubeconfig` 설정만 되어 있다면 가장 빠릅니다.

```bash
# Homebrew를 이용한 설치
brew install --cask headlamp
brew install kubecolor
```

* 설치 후 **Applications(응용 프로그램)** 폴더에서 `Headlamp`를 실행하면 끝입니다.

### 3. Docker로 실행하기 (설치 없이 찍어먹기)

앱을 깔기도 싫고 클러스터에 배포하기도 부담스러울 때, Docker 컨테이너로 띄워서 브라우저로 보는 방법입니다.

```bash
docker run -p 8080:80 \
  -v ~/.kube/config:/root/.kube/config \
  ghcr.io/headlamp-k8s/headlamp:latest
```

### Portainer

[Getting started with Portainer using Kind](https://yashsrivastav.hashnode.dev/getting-started-with-portainer-using-kind)

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1652346752573/aAA-8szVG.png)
