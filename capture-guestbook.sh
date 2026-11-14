#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

record() {
    local file=$1
    shift
    {
        printf '$'
        printf ' %q' "$@"
        printf '\n'
        "$@"
    } 2>&1 | tee "answers/$file.txt"
}

require_namespace() {
    : "${GUESTBOOK_NAMESPACE:?Export GUESTBOOK_NAMESPACE with your Skills Network registry namespace}"
    [[ $GUESTBOOK_NAMESPACE =~ ^[a-z0-9][a-z0-9_-]*$ ]] || {
        printf 'Use the registry namespace alone.\n' >&2
        exit 1
    }
    image="us.icr.io/$GUESTBOOK_NAMESPACE/guestbook"
}

case "${1:-}" in
    v1)
        require_namespace
        cp index-v1.html public/index.html
        docker build -t "$image:v1" .
        docker push "$image:v1"
        record 02-registry-v1 ibmcloud cr images
        sed -i.bak "s|us.icr.io/.*/guestbook:v[12]|$image:v1|" deployment.yml
        rm -f deployment.yml.bak
        kubectl apply -f deployment.yml
        kubectl rollout status deployment/guestbook --timeout=180s
        ;;
    hpa)
        kubectl autoscale deployment guestbook --cpu-percent=50 --min=1 --max=5
        record 04-hpa-initial kubectl get hpa guestbook
        ;;
    scale)
        record 05-hpa-scaling kubectl get hpa guestbook --watch
        ;;
    v2)
        require_namespace
        cp index-v2.html public/index.html
        docker build -t "$image:v2" .
        record 06-push-v2 docker push "$image:v2"
        sed -i.bak "s|us.icr.io/.*/guestbook:v[12]|$image:v2|" deployment.yml
        rm -f deployment.yml.bak
        record 07-apply-v2 kubectl apply -f deployment.yml
        kubectl rollout status deployment/guestbook --timeout=180s
        ;;
    cpu)
        request=${2:?Supply the CPU request specified by the lab}
        limit=${3:?Supply the CPU limit specified by the lab}
        kubectl set resources -f deployment.yml --local -o yaml \
            --requests="cpu=$request" --limits="cpu=$limit" > deployment.cpu.yml
        kubectl apply -f deployment.cpu.yml
        kubectl rollout status deployment/guestbook --timeout=180s
        revision=$(kubectl get deployment guestbook -o 'jsonpath={.metadata.annotations.deployment\.kubernetes\.io/revision}')
        {
            printf '%s\n' '$ kubectl rollout history deployment/guestbook'
            kubectl rollout history deployment/guestbook
            printf '\n$ kubectl rollout history deployment/guestbook --revision=%s\n' "$revision"
            kubectl rollout history deployment/guestbook --revision="$revision"
        } 2>&1 | tee answers/09-rollout-history.txt
        ;;
    rollback)
        if [[ -n ${2:-} ]]; then
            kubectl rollout undo deployment/guestbook --to-revision="$2"
        else
            kubectl rollout undo deployment/guestbook
        fi
        kubectl rollout status deployment/guestbook --timeout=180s
        record 10-replicasets kubectl get rs
        ;;
    *)
        printf 'Usage: bash %s {v1|hpa|scale|v2|cpu REQUEST LIMIT|rollback [REVISION]}\n' "$0" >&2
        exit 2
        ;;
esac
