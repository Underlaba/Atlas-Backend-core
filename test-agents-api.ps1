# Test Agent Registration Endpoint
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  TESTING AGENT ENDPOINTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:3000/api/v1"

# Test 1: Register new agent
Write-Host "1. Testing Agent Registration..." -ForegroundColor Yellow
$agentData = @{
    deviceId = "test-device-$(Get-Random -Maximum 10000)"
    walletAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/agents/register" -Method Post -Body $agentData -ContentType "application/json"
    Write-Host "   SUCCESS" -ForegroundColor Green
    Write-Host "   Agent ID: $($response.data.id)" -ForegroundColor White
    Write-Host "   Device ID: $($response.data.deviceId)" -ForegroundColor White
    Write-Host "   Wallet: $($response.data.walletAddress)" -ForegroundColor White
    Write-Host "   Status: $($response.data.status)" -ForegroundColor White
    $agentId = $response.data.id
} catch {
    Write-Host "   FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $agentId = $null
}

# Test 2: Try to register duplicate device
Write-Host "`n2. Testing Duplicate Device ID..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/agents/register" -Method Post -Body $agentData -ContentType "application/json"
    Write-Host "   FAILED: Should have rejected duplicate" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "   SUCCESS: Duplicate rejected correctly" -ForegroundColor Green
    } else {
        Write-Host "   FAILED: Wrong error code" -ForegroundColor Red
    }
}

# Test 3: Invalid wallet format
Write-Host "`n3. Testing Invalid Wallet Format..." -ForegroundColor Yellow
$invalidData = @{
    deviceId = "test-device-invalid"
    walletAddress = "invalid-wallet"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/agents/register" -Method Post -Body $invalidData -ContentType "application/json"
    Write-Host "   FAILED: Should have rejected invalid wallet" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "   SUCCESS: Invalid wallet rejected" -ForegroundColor Green
    } else {
        Write-Host "   FAILED: Wrong error code" -ForegroundColor Red
    }
}

# Test 4: Get all agents (requires authentication)
Write-Host "`n4. Testing Get All Agents (without auth)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/agents" -Method Get
    Write-Host "   FAILED: Should require authentication" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "   SUCCESS: Authentication required" -ForegroundColor Green
    } else {
        Write-Host "   FAILED: Wrong error code" -ForegroundColor Red
    }
}

# Test 5: Login and get agents
Write-Host "`n5. Testing Authenticated Endpoints..." -ForegroundColor Yellow
$loginData = @{
    email = "admin@atlas.com"
    password = "Admin123!"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.accessToken
    
    if ($token) {
        Write-Host "   Login successful" -ForegroundColor Green
        
        # Get all agents with token
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        
        $agentsResponse = Invoke-RestMethod -Uri "$baseUrl/agents" -Method Get -Headers $headers
        Write-Host "   Total agents: $($agentsResponse.pagination.total)" -ForegroundColor White
        Write-Host "   Retrieved: $($agentsResponse.data.Count) agents" -ForegroundColor White
        
        if ($agentId) {
            # Get specific agent
            $agentResponse = Invoke-RestMethod -Uri "$baseUrl/agents/$agentId" -Method Get -Headers $headers
            Write-Host "   Single agent retrieved: $($agentResponse.data.deviceId)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "   FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  TESTS COMPLETED" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
