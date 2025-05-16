# Function to print colored messages
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if Docker is running
function Test-DockerRunning {
    try {
        $null = docker info
        return $true
    }
    catch {
        Write-ColorMessage "Docker is not running. Please start Docker first." "Red"
        exit 1
    }
}

# Function to generate SSL certificates
function Start-GenerateSSL {
    Write-ColorMessage "Generating SSL certificates..." "Yellow"
    try {
        & .\scripts\generate-ssl.bat
        Write-ColorMessage "SSL certificates generated successfully!" "Green"
    }
    catch {
        Write-ColorMessage "Failed to generate SSL certificates." "Red"
        exit 1
    }
}

# Function to start services
function Start-Services {
    param(
        [string]$Mode
    )
    Write-ColorMessage "Starting services..." "Yellow"
    try {
        if ($Mode -eq "dev") {
            docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
        }
        else {
            docker-compose up -d
        }
        Write-ColorMessage "Services started successfully!" "Green"
    }
    catch {
        Write-ColorMessage "Failed to start services." "Red"
        exit 1
    }
}

# Function to stop services
function Stop-Services {
    Write-ColorMessage "Stopping services..." "Yellow"
    try {
        docker-compose down
        Write-ColorMessage "Services stopped successfully!" "Green"
    }
    catch {
        Write-ColorMessage "Failed to stop services." "Red"
        exit 1
    }
}

# Function to restart services
function Restart-Services {
    Write-ColorMessage "Restarting services..." "Yellow"
    try {
        docker-compose restart
        Write-ColorMessage "Services restarted successfully!" "Green"
    }
    catch {
        Write-ColorMessage "Failed to restart services." "Red"
        exit 1
    }
}

# Function to show logs
function Show-Logs {
    param(
        [string]$Service
    )
    Write-ColorMessage "Showing logs..." "Yellow"
    if ([string]::IsNullOrEmpty($Service)) {
        docker-compose logs -f
    }
    else {
        docker-compose logs -f $Service
    }
}

# Function to show status
function Show-Status {
    Write-ColorMessage "Service Status:" "Yellow"
    docker-compose ps
}

# Function to clean up
function Start-Cleanup {
    Write-ColorMessage "Cleaning up..." "Yellow"
    try {
        docker-compose down -v
        Write-ColorMessage "Cleanup completed successfully!" "Green"
    }
    catch {
        Write-ColorMessage "Failed to cleanup." "Red"
        exit 1
    }
}

# Function to show help
function Show-Help {
    Write-Host "Usage: .\manage.ps1 [command] [options]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  start [dev]    Start services (add 'dev' for development mode)"
    Write-Host "  stop           Stop services"
    Write-Host "  restart        Restart services"
    Write-Host "  logs [service] Show logs (optional: service name)"
    Write-Host "  status         Show service status"
    Write-Host "  ssl            Generate SSL certificates"
    Write-Host "  cleanup        Remove all containers and volumes"
    Write-Host "  help           Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\manage.ps1 start     # Start services in production mode"
    Write-Host "  .\manage.ps1 start dev # Start services in development mode"
    Write-Host "  .\manage.ps1 logs api  # Show logs for API service"
}

# Main script
Test-DockerRunning

$command = $args[0]
$option = $args[1]

switch ($command) {
    "start" {
        Start-Services -Mode $option
    }
    "stop" {
        Stop-Services
    }
    "restart" {
        Restart-Services
    }
    "logs" {
        Show-Logs -Service $option
    }
    "status" {
        Show-Status
    }
    "ssl" {
        Start-GenerateSSL
    }
    "cleanup" {
        Start-Cleanup
    }
    "help" {
        Show-Help
    }
    default {
        if ([string]::IsNullOrEmpty($command)) {
            Show-Help
        }
        else {
            Write-ColorMessage "Unknown command: $command" "Red"
            Show-Help
            exit 1
        }
    }
} 