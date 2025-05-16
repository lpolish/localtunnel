#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_message "Docker is not running. Please start Docker first." "$RED"
        exit 1
    fi
}

# Function to generate SSL certificates
generate_ssl() {
    print_message "Generating SSL certificates..." "$YELLOW"
    ./scripts/generate-ssl.sh
    if [ $? -eq 0 ]; then
        print_message "SSL certificates generated successfully!" "$GREEN"
    else
        print_message "Failed to generate SSL certificates." "$RED"
        exit 1
    fi
}

# Function to start services
start_services() {
    print_message "Starting services..." "$YELLOW"
    if [ "$1" == "dev" ]; then
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    else
        docker-compose up -d
    fi
    if [ $? -eq 0 ]; then
        print_message "Services started successfully!" "$GREEN"
    else
        print_message "Failed to start services." "$RED"
        exit 1
    fi
}

# Function to stop services
stop_services() {
    print_message "Stopping services..." "$YELLOW"
    docker-compose down
    if [ $? -eq 0 ]; then
        print_message "Services stopped successfully!" "$GREEN"
    else
        print_message "Failed to stop services." "$RED"
        exit 1
    fi
}

# Function to restart services
restart_services() {
    print_message "Restarting services..." "$YELLOW"
    docker-compose restart
    if [ $? -eq 0 ]; then
        print_message "Services restarted successfully!" "$GREEN"
    else
        print_message "Failed to restart services." "$RED"
        exit 1
    fi
}

# Function to show logs
show_logs() {
    print_message "Showing logs..." "$YELLOW"
    if [ -z "$1" ]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$1"
    fi
}

# Function to show status
show_status() {
    print_message "Service Status:" "$YELLOW"
    docker-compose ps
}

# Function to clean up
cleanup() {
    print_message "Cleaning up..." "$YELLOW"
    docker-compose down -v
    if [ $? -eq 0 ]; then
        print_message "Cleanup completed successfully!" "$GREEN"
    else
        print_message "Failed to cleanup." "$RED"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: ./manage.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  start [dev]    Start services (add 'dev' for development mode)"
    echo "  stop           Stop services"
    echo "  restart        Restart services"
    echo "  logs [service] Show logs (optional: service name)"
    echo "  status         Show service status"
    echo "  ssl            Generate SSL certificates"
    echo "  cleanup        Remove all containers and volumes"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./manage.sh start     # Start services in production mode"
    echo "  ./manage.sh start dev # Start services in development mode"
    echo "  ./manage.sh logs api  # Show logs for API service"
}

# Main script
check_docker

case "$1" in
    "start")
        if [ "$2" == "dev" ]; then
            start_services "dev"
        else
            start_services
        fi
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "logs")
        show_logs "$2"
        ;;
    "status")
        show_status
        ;;
    "ssl")
        generate_ssl
        ;;
    "cleanup")
        cleanup
        ;;
    "help"|"")
        show_help
        ;;
    *)
        print_message "Unknown command: $1" "$RED"
        show_help
        exit 1
        ;;
esac 