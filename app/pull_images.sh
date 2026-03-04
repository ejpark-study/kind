#!/usr/bin/env bash

# for node in $(kind get nodes); do
#   echo "=== Node: $node ==="
#   docker exec $node crictl images
#   echo ""
# done

#!/bin/bash

# 저장할 디렉토리 생성
mkdir -p images

echo "🔍 Kind 노드에서 이미지 목록 추출 중..."

# 1. 모든 노드에서 이미지 목록 가져오기 (중복 제거)
# crictl output에서 'IMAGE' 컬럼의 태그가 포함된 전체 이름을 가져옵니다.
ALL_IMAGES=$(for node in $(kind get nodes); do
  docker exec "$node" crictl images -o json | jq -r '.images[].repoTags[]'
done | sort -u)

echo "📦 총 $(echo "$ALL_IMAGES" | wc -l) 개의 유니크 이미지를 발견했습니다."

# 2. 각 이미지별로 작업 수행
echo "$ALL_IMAGES" | while read -r IMAGE; do
  # 파일명으로 쓰기 부적절한 문자(: /) 변경
  SAFE_NAME=$(echo "$IMAGE" | sed 's/\//-/g' | sed 's/:/-/g')
  TAR_FILE="images/${SAFE_NAME}.tar"

  if [ -f "$TAR_FILE" ]; then
    echo "⏭️  이미 존재함: $IMAGE"
    continue
  fi

  echo "⬇️  Pulling: $IMAGE"
  docker pull "$IMAGE" > /dev/null

  echo "💾 Saving: $IMAGE -> $TAR_FILE"
  docker save "$IMAGE" > "$TAR_FILE"
done

echo "✅ 모든 작업이 완료되었습니다. 'images/' 폴더를 확인하세요."

# for tar_file in images/*.tar; do
#   echo "🚀 Loading $tar_file into Kind..."
#   kind load image-archive "$tar_file"
# done
