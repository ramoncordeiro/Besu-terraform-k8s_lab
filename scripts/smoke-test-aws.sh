#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Smoke Test: Besu AWS Cloud Network
# =============================================================================
# Versão do smoke-test.sh adaptada para rodar no GitHub Actions (ubuntu-latest)
# contra o cluster k3s remoto na EC2 t2.micro.
#
# PRINCIPAIS MUDANÇAS em relação ao local:
#   - Timeouts maiores (a t2.micro é lenta para subir pods Besu)
#   - Espera maior entre checagens de bloco (mineração demora mais)
#   - Texto de log identifica como "AWS Cloud Network"
#
# Como funciona o acesso remoto?
#   O workflow configura um kubeconfig que aponta para a EC2 (via SSH tunnel
#   ou via IP público se 6443 estiver aberto). Aqui, o kubectl funciona
#   exatamente como no local — a diferença está no kubeconfig.
# =============================================================================

NAMESPACE="default"
VALIDATOR_SVC="besu-validator01"
LOCAL_RPC_PORT="18545"
RPC_TIMEOUT=10           # Aumentado: t2.micro responde mais lentamente
PEER_COUNT_MIN=1
BLOCK_WAIT_SECONDS=45     # Aumentado: blocos demoram mais para serem produzidos
KUBECTL_TIMEOUT="600s"  # 10 minutos: t2.micro demora para pull de imagens
LABEL_SELECTOR="app in (besu-boot01, besu-validator01, besu-validator02, besu-validator03, besu-write01)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

fail() { echo -e "${RED}FAIL: $1${NC}" >&2; exit 1; }
ok()   { echo -e "${GREEN}OK: $1${NC}"; }
info() { echo -e "${YELLOW}INFO: $1${NC}"; }

cleanup() {
    if [[ -n "${PF_PID:-}" ]] && kill -0 "${PF_PID}" 2>/dev/null; then
        info "Cleaning up port-forward (PID: ${PF_PID})..."
        kill "${PF_PID}" 2>/dev/null || true
        wait "${PF_PID}" 2>/dev/null || true
    fi
}
trap cleanup EXIT

rpc_call() {
    local method=$1
    curl -s -m "${RPC_TIMEOUT}" -X POST "http://localhost:${LOCAL_RPC_PORT}" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"${method}\",\"params\":[],\"id\":1}"
}

hex_to_dec() {
    printf "%d" "$1" 2>/dev/null || echo "0"
}

# =============================================================================
# MAIN
# =============================================================================
echo "=================================="
echo " Smoke Test: Besu AWS Cloud Network"
echo "=================================="

# =============================================================================
# STEP 1: CHECK IF PODS ARE READY
# =============================================================================
echo ""
echo "[1/3] Verifying pods readiness..."
echo "  Label selector: ${LABEL_SELECTOR}"
echo "  Timeout: ${KUBECTL_TIMEOUT}"

if ! kubectl wait --for=condition=ready pod \
    -l "${LABEL_SELECTOR}" \
    -n "${NAMESPACE}" \
    --timeout="${KUBECTL_TIMEOUT}"; then
    fail "Not all Besu pods became ready within ${KUBECTL_TIMEOUT}."
fi

ok "All Besu pods are Ready."

# =============================================================================
# STEP 2: START PORT-FORWARD
# =============================================================================
echo ""
echo "[PORT-FORWARD] Starting port-forward for ${VALIDATOR_SVC}..."

kubectl port-forward "svc/${VALIDATOR_SVC}" "${LOCAL_RPC_PORT}:8545" \
    -n "${NAMESPACE}" > /dev/null 2>&1 &

PF_PID=$!

# Espera o tunnel estabilizar
for i in {1..15}; do
    if nc -z localhost "${LOCAL_RPC_PORT}" 2>/dev/null; then
        break
    fi
    sleep 1
done

if ! nc -z localhost "${LOCAL_RPC_PORT}" 2>/dev/null; then
    fail "Port-forward did not establish on port ${LOCAL_RPC_PORT}."
fi

ok "Port-forward active on localhost:${LOCAL_RPC_PORT} (PID: ${PF_PID})"

# =============================================================================
# STEP 3: CHECK PEER COUNT
# =============================================================================
echo ""
echo "[2/3] Checking peer count via RPC..."

RESPONSE=$(rpc_call "net_peerCount")

if [[ -z "${RESPONSE}" ]] || [[ "${RESPONSE}" != *"\"result\""* ]]; then
    fail "Invalid RPC response: ${RESPONSE:-empty}"
fi

PEER_HEX=$(echo "${RESPONSE}" | grep -o '"result"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
PEER_DEC=$(hex_to_dec "${PEER_HEX}")

info "Peer count: ${PEER_DEC} (hex: ${PEER_HEX})"

if [[ "${PEER_DEC}" -lt "${PEER_COUNT_MIN}" ]]; then
    fail "Peer count (${PEER_DEC}) below minimum (${PEER_COUNT_MIN})."
fi

ok "Peer count is adequate (${PEER_DEC})."

# =============================================================================
# STEP 4: CHECK BLOCK PRODUCTION
# =============================================================================
echo ""
echo "[3/3] Checking block production..."

BLOCK1_HEX=$(rpc_call "eth_blockNumber" | grep -o '"result"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
BLOCK1_DEC=$(hex_to_dec "${BLOCK1_HEX}")

info "Initial blockNumber: ${BLOCK1_DEC} (hex: ${BLOCK1_HEX})"
info "Waiting ${BLOCK_WAIT_SECONDS} seconds..."

sleep "${BLOCK_WAIT_SECONDS}"

BLOCK2_HEX=$(rpc_call "eth_blockNumber" | grep -o '"result"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
BLOCK2_DEC=$(hex_to_dec "${BLOCK2_HEX}")

info "Current blockNumber: ${BLOCK2_DEC} (hex: ${BLOCK2_HEX})"

if [[ "${BLOCK2_DEC}" -le "${BLOCK1_DEC}" ]]; then
    fail "BlockNumber did not increase (${BLOCK1_DEC} -> ${BLOCK2_DEC})."
fi

ok "Blocks are being produced (${BLOCK1_DEC} -> ${BLOCK2_DEC})."

# =============================================================================
# SUCCESS
# =============================================================================
echo ""
echo "=================================="
echo -e "${GREEN}SMOKE TEST PASSED (AWS Cloud)${NC}"
echo "=================================="
