
curl -Ls https://github.com/goharbor/harbor/releases/download/v2.14.2/harbor-online-installer-v2.14.2.tgz | tar xvz 

mv harbor/harbor.yml.tmpl harbor/harbor.yml

cd harbor


# 2. IP 탐지 및 hostname 변경 + https 섹션 주석 처리
HOST_IP=$(python3 -c 'import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(("8.8.8.8", 80)); print(s.getsockname()[0]); s.close()')
echo "HOST_IP: $HOST_IP"

VOLUME_PATH=$(pwd)/volume/harbor
echo "VOLUME_PATH: $VOLUME_PATH"

sed -i.bak "s#hostname: .*#hostname: $HOST_IP#" harbor.yml
sed -i.bak "s#data_volume: .*#data_volume: $VOLUME_PATH#" harbor.yml

# 3. https 섹션 주석 처리 (https: 부터 주석 처리 시작)
sed -i.bak '/^https:/,/private_key:/ s/^/#/' harbor.yml
sed -i.bak '/^http:/,/port:/ s/port: 80/port: 5000/' harbor.yml

# 최종 확인
grep -E "^#?hostname:|^#?https?:|^#?  port: " harbor.yml

# ./install.sh

docker exec kind-control-plane curl -s -o /dev/null --connect-timeout 2 http://${HOST_IP} && echo "SUCCESS" || echo "FAIL"






# 1. 모든 kind 노드 이름을 가져와서 루프 실행
for NODE in $(kind get nodes --name kind); do
  echo "Configuring containerd for node: $NODE"

  # 2. containerd 설정 파일에 harbor.local 미러 및 insecure 설정 추가
  docker exec $NODE bash -c "cat <<EOF >> /etc/containerd/config.toml

[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"harbor.local:5000\"]
  endpoint = [\"http://harbor.local:5000\"]
[plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"harbor.local:5000\".tls]
  insecure_skip_verify = true
EOF"

  # 3. 설정 적용을 위해 containerd 프로세스 재시작
  docker exec $NODE systemctl restart containerd
done




# 1. 현재 Corefile을 파일로 저장
kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' > Corefile.tmp

# 2. 파일 내용 수정 (ready 라인 앞에 hosts 블록 추가)
# 주의: 공백(들여쓰기)을 유지해야 합니다.
sed -i.bak '/ready/i \
    hosts {\
        '${HOST_IP}' harbor.local\
        fallthrough\
    }' Corefile.tmp

# 3. 수정한 파일로 ConfigMap 패치
kubectl create configmap coredns -n kube-system --from-file=Corefile=Corefile.tmp --dry-run=client -o yaml | kubectl apply -f -

# 4. 임시 파일 삭제
rm Corefile.tmp Corefile.tmp.bak


