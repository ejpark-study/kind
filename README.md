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
alias kx='kubectx'
alias kn='kubens'

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

### Harbor
Kind 클러스터와 Harbor를 연동하는 패턴은 로컬 개발 환경에서 **가장 프로페셔널한 설정**입니다. 이미지 백업/복구 없이 `docker push` 한 번으로 모든 노드가 이미지를 공유할 수 있기 때문입니다.

가장 일반적인 **"자체 서명 인증서(Self-signed)를 사용하는 Harbor + Kind"** 연동 가이드를 정리해 드립니다.

---

### 1. Harbor 준비 (Quick Check)

Harbor가 설치되어 있고, 외부에서 접속 가능한 상태라고 가정합니다.

* **Harbor 주소:** `harbor.local` (또는 IP 주소)
* **프로젝트 이름:** `my-project`

---

### 2. Kind 클러스터 설정 (`kind-config.yaml`)

Kind 노드 내부의 `containerd`가 Harbor를 신뢰하고 바라보도록 설정해야 합니다. 특히 **HTTPS 인증서 오류**를 방지하는 설정이 핵심입니다.

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
containerdConfigPatches:
- |-
  # 1. Harbor를 미러 레지스트리로 등록
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."harbor.local"]
    endpoint = ["https://harbor.local"]

  # 2. 자체 서명 인증서(Insecure) 허용 설정
  [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.local".tls]
    insecure_skip_verify = true

```

*설정 후 클러스터 생성:* `kind create cluster --config kind-config.yaml`

---

### 3. Kubernetes 인증 설정 (`imagePullSecret`)

Harbor 프로젝트가 비공개(Private)인 경우, 쿠버네티스가 이미지를 가져올 권한이 필요합니다.

```bash
# harbor-creds라는 이름의 시크릿 생성
kubectl create secret docker-registry harbor-creds \
  --docker-server=harbor.local \
  --docker-username='admin' \
  --docker-password='HarborPassword123' \
  --email='admin@example.com'

```

---

### 4. 이미지 워크플로우 (실습)

**① 호스트에서 이미지 푸시**

```bash
# 로컬 이미지를 Harbor용으로 태깅
docker tag starrocks/fe-ubuntu:3.5-latest harbor.local/my-project/starrocks-fe:3.5

# Harbor로 푸시
docker push harbor.local/my-project/starrocks-fe:3.5

```

**② YAML에서 사용 (`deployment.yaml`)**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: starrocks-fe
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: fe
        image: harbor.local/my-project/starrocks-fe:3.5 # Harbor 주소 포함
      imagePullSecrets:
      - name: harbor-creds # 위에서 만든 시크릿 지정

```

---

### 5. (중요) 도메인 인식 문제 해결 (DNS/Hosts)

Kind 노드(컨테이너)는 호스트의 `/etc/hosts`를 자동으로 참조하지 못할 수 있습니다. `harbor.local`이라는 도메인을 노드들이 알게 하려면 두 가지 방법이 있습니다.

**방법 A: IP 주소 사용**
위 설정에서 `harbor.local` 대신 Harbor 서버의 **실제 LAN IP**를 사용합니다. (가장 추천)

**방법 B: Kind 설정에 Extra Hosts 추가**

```yaml
nodes:
- role: control-plane
  extraPortMappings: []
  # 노드 안에 /etc/hosts 설정을 강제로 주입
  extraMounts: []
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "my-label=true"
# ... (중략) ...
# 아래 설정을 추가하여 모든 노드가 harbor.local IP를 알게 함
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."harbor.local"]
    endpoint = ["https://harbor.local"]

```

*(사실 방법 A처럼 IP를 쓰는 게 정신 건강에 가장 이롭습니다.)*

---

### 💡 요약

1. **Kind 생성 시:** `containerdConfigPatches`로 Harbor IP/도메인을 등록한다.
2. **K8s 내에서:** `imagePullSecret`을 만들어 권한을 준다.
3. **사용 시:** 이미지 주소 앞에 `HarborIP/Project/`를 붙인다.

**혹시 Harbor 설치부터 막히시는 상황인가요? 아니면 위 설정 중 `insecure_skip_verify` 적용 단계에서 도움이 더 필요하신가요?**

### nginx test

```
kubectl label namespace default istio-injection=enabled

cat << EOS | kubectl apply -n default -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.24.0
        ports:
        - containerPort: 80
EOS

# 서비스 테스트
kubectl expose deployment nginx --port=80 --type=LoadBalancer




# Cilium 포드 중 하나를 선택해 서비스 리스트 확인
kubectl -n kube-system exec -it ds/cilium -- cilium-dbg service list

alias cilium-dbg='kubectl -n kube-system exec -it ds/cilium -- cilium-dbg'

# 이제 로컬에서 바로 실행 가능
cilium-dbg service list


k get CiliumLoadBalancerIPPool ipam


docker run -d --rm --name mypc --network kind  nicolaka/netshoot sleep infinity

docker exec -it mypc bash
 
curl http://172.16.1.65


```

### 그림과 실습으로 배우는 쿠버네티스 입문

https://github.com/gilbutITbook/080437

```bash
git clone https://github.com/gilbutITbook/080437.git
```

```
cat <<EOF | kubectl apply --namespace default -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  containers:
  - name: hello-server
    image: blux2/hello-server:1.0
    ports:
    - containerPort: 8080
EOF

kubectl get pod myapp -o jsonpath='{.spec.containers[0].name}'

kubectl debug --stdin --tty myapp --image=curlimages/curl:8.4.0 --target=hello-server -n default -- sh


k -n default run busybox --image=busybox:1.36.1 --rm --stdin --tty --restart=Never --command -- nsl
ookup google.com


k -n default run curlpod --image=curlimages/curl:8.4.0 --command -- /bin/sh -c "tail -f /dev/null"

k -n default exec -it curlpod -- /bin/sh


k -n default run netshoot --image=nicolaka/netshoot --command -- /bin/sh -c "tail -f /dev/null"


k -n default exec -it netshoot -- /bin/sh


k port-forward myapp 5555:8080 -n default


k api-resources

brew install stern
brew install kube-ps1

```



1. pod 내에서 애플리케이션 접속 확인하기
	```
	k get po

	kubectl get pod hello-server-6cc6b44795-6vd57 -o jsonpath='{.spec.containers[*].name}'

	kubectl describe pod hello-server-6cc6b44795-6vd57

	kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

	k debug --stdin --tty hello-server-6cc6b44795-6vd57 --image=curlimages/curl:8.4.0 --profile=general -- sh 
	```

2. 클러스터 내 별도의 pod 로부터 접속 확인하기

	```
	kubectl get pods -o custom-columns=NAME:.metadata.name,IP:.status.podIP

	k run curl --image=curlimages/curl:8.4.0 --rm --stdin --tty --restart=Never --command -- curl 10.10.1.26:8080 
	```

3. 클러스터 내 별도의 Pod로부터 Service를 통해 접속 확인하기

	```
	kubectl get svc -o custom-columns=NAME:.metadata.name,IP:.spec.clusterIP
	
	k run curl --image=curlimages/curl:8.4.0 --rm --stdin --tty --restart=Never --command -- curl 10.11.4.116:8080 
	```


![](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdna%2FdH14X9%2FdJMcahJXgqp%2FAAAAAAAAAAAAAAAAAAAAAItzMWlrnszyZkxsYVpg-9YlKmFJ6ZbiDQsONjhmqR7v%2Fimg.png%3Fcredential%3DyqXZFxpELC7KVnFOS48ylbz2pIh7yKj8%26expires%3D1774969199%26allow_ip%3D%26allow_referer%3D%26signature%3D2SKkpGoVfbsQceLQyPIdp3oGmuQ%253D)

![](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdna%2Fcwfm0P%2FdJMcajuaFGi%2FAAAAAAAAAAAAAAAAAAAAAGQafShayRl_qkr0Oxq8BdkRblvkh_yP-8_18okZxIzu%2Fimg.png%3Fcredential%3DyqXZFxpELC7KVnFOS48ylbz2pIh7yKj8%26expires%3D1774969199%26allow_ip%3D%26allow_referer%3D%26signature%3D%252BClgAElh00kAKLx1ld39tsMBRDo%253D)


### 그림으로 이해하는 도커와 쿠버네티스 

https://github.com/gilbutITbook/080434


```
git clone https://github.com/gilbutITbook/080434.git

cd 08043/hello

docker build -f Dockerfile . -t hello

mkdir tmp
docker save hello:latest | tar -xC tmp

# image layers
docker create --name temp_container hello:latest

docker export temp_container | tar -xC tmp

dive hello:latest

docker history --no-trunc hello:latest

# skopeo

skopeo inspect docker://docker.io/library/hello:latest

skopeo inspect docker-daemon:hello:latest

```

