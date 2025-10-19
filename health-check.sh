#!/bin/bash

# Atlas Backend Health Check Script
# This script monitors the health of the backend application

# Configuration
API_URL="http://localhost:3000"
HEALTH_ENDPOINT="$API_URL/api/v1/health"
PM2_APP_NAME="atlas-backend"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "=========================================="
echo "Atlas Backend Health Check"
echo "=========================================="

# Check 1: PM2 Process Status
log_info "Checking PM2 process status..."
PM2_STATUS=$(pm2 jlist | jq -r ".[] | select(.name==\"$PM2_APP_NAME\") | .pm2_env.status" 2>/dev/null)

if [ "$PM2_STATUS" = "online" ]; then
    log_info "PM2 Status: Online"
else
    log_error "PM2 Status: $PM2_STATUS"
    log_error "Application is not running properly"
    exit 1
fi

# Check 2: Process Memory Usage
MEMORY_USAGE=$(pm2 jlist | jq -r ".[] | select(.name==\"$PM2_APP_NAME\") | .monit.memory" 2>/dev/null)
MEMORY_MB=$((MEMORY_USAGE / 1024 / 1024))
log_info "Memory Usage: ${MEMORY_MB}MB"

if [ "$MEMORY_MB" -gt 450 ]; then
    log_warn "High memory usage detected (${MEMORY_MB}MB / 500MB limit)"
fi

# Check 3: Process CPU Usage
CPU_USAGE=$(pm2 jlist | jq -r ".[] | select(.name==\"$PM2_APP_NAME\") | .monit.cpu" 2>/dev/null)
log_info "CPU Usage: ${CPU_USAGE}%"

# Check 4: Process Restart Count
RESTART_COUNT=$(pm2 jlist | jq -r ".[] | select(.name==\"$PM2_APP_NAME\") | .pm2_env.restart_time" 2>/dev/null)
log_info "Restart Count: $RESTART_COUNT"

if [ "$RESTART_COUNT" -gt 5 ]; then
    log_warn "High restart count detected ($RESTART_COUNT times)"
fi

# Check 5: Process Uptime
UPTIME_MS=$(pm2 jlist | jq -r ".[] | select(.name==\"$PM2_APP_NAME\") | (.pm2_env.pm_uptime // 0)" 2>/dev/null)
CURRENT_TIME=$(date +%s)000
UPTIME_SEC=$(( (CURRENT_TIME - UPTIME_MS) / 1000 ))
UPTIME_MIN=$((UPTIME_SEC / 60))
log_info "Uptime: ${UPTIME_MIN} minutes"

# Check 6: HTTP Health Endpoint
log_info "Checking HTTP health endpoint..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_ENDPOINT" 2>/dev/null || echo "000")

if [ "$HTTP_RESPONSE" = "200" ]; then
    log_info "HTTP Health Check: PASSED (200 OK)"
else
    log_error "HTTP Health Check: FAILED (HTTP $HTTP_RESPONSE)"
    exit 1
fi

# Check 7: Response Time
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" "$HEALTH_ENDPOINT" 2>/dev/null || echo "0")
RESPONSE_MS=$(echo "$RESPONSE_TIME * 1000" | bc)
log_info "Response Time: ${RESPONSE_MS}ms"

if (( $(echo "$RESPONSE_TIME > 1.0" | bc -l) )); then
    log_warn "Slow response time detected (${RESPONSE_MS}ms)"
fi

# Check 8: Database Connection
log_info "Checking database connection..."
DB_CHECK=$(curl -s "$HEALTH_ENDPOINT" | jq -r '.database' 2>/dev/null || echo "unknown")

if [ "$DB_CHECK" = "connected" ]; then
    log_info "Database: Connected"
else
    log_error "Database: $DB_CHECK"
    exit 1
fi

# Check 9: Disk Space
log_info "Checking disk space..."
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -gt 80 ]; then
    log_warn "Low disk space: ${DISK_USAGE}% used"
else
    log_info "Disk Usage: ${DISK_USAGE}%"
fi

# Check 10: Log File Sizes
log_info "Checking log file sizes..."
if [ -d "logs" ]; then
    ERROR_LOG_SIZE=$(du -h logs/err.log 2>/dev/null | cut -f1 || echo "0K")
    OUT_LOG_SIZE=$(du -h logs/out.log 2>/dev/null | cut -f1 || echo "0K")
    log_info "Error Log: $ERROR_LOG_SIZE"
    log_info "Output Log: $OUT_LOG_SIZE"
fi

# Summary
echo "=========================================="
log_info "Health Check Summary: ALL CHECKS PASSED"
echo "=========================================="
echo "Application Status: Healthy"
echo "PM2 Status: $PM2_STATUS"
echo "Memory: ${MEMORY_MB}MB"
echo "CPU: ${CPU_USAGE}%"
echo "Uptime: ${UPTIME_MIN} minutes"
echo "HTTP Response: $HTTP_RESPONSE"
echo "Response Time: ${RESPONSE_MS}ms"
echo "Database: $DB_CHECK"
echo "Disk Usage: ${DISK_USAGE}%"
echo "=========================================="

exit 0
