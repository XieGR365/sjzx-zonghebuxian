#!/bin/bash

REMOTE_HOST="192.168.19.58"
REMOTE_USER="yroot"

COLOR_INFO='\033[0;36m'
COLOR_SUCCESS='\033[0;32m'
COLOR_ERROR='\033[0;31m'
COLOR_WARNING='\033[0;33m'
COLOR_RESET='\033[0m'

function write_info() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"
}

function write_success() {
    echo -e "${COLOR_SUCCESS}[OK]${COLOR_RESET} $1"
}

function write_error() {
    echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $1"
}

function write_warning() {
    echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} $1"
}

function write_separator() {
    echo "================================================================================"
}

function check_ssh_connection() {
    write_separator
    write_info "Step 1: Check SSH connection"
    write_separator
    
    write_info "Testing SSH connection to ${REMOTE_USER}@${REMOTE_HOST}..."
    result=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "echo 'Connection successful'" 2>&1)
    
    if [ $? -eq 0 ] && [[ "$result" == *"Connection successful"* ]]; then
        write_success "SSH connection OK"
        return 0
    else
        write_error "SSH connection failed"
        write_info "Please check:"
        write_info "  1. Remote server IP: $REMOTE_HOST"
        write_info "  2. SSH service running"
        write_info "  3. Network connection"
        write_info "  4. SSH key or password"
        return 1
    fi
}

function get_os_info() {
    write_separator
    write_info "Step 2: Check OS information"
    write_separator
    
    write_info "Getting OS information..."
    os_info=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "cat /etc/os-release" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "$os_info"
        
        os_name=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '\"'" 2>&1)
        os_version=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"'" 2>&1)
        
        write_info "OS: $os_name"
        write_info "Version: $os_version"
        
        echo "$os_name"
    else
        write_error "Cannot get OS information"
        echo ""
    fi
}

function check_nodejs() {
    write_separator
    write_info "Step 3: Check Node.js environment"
    write_separator
    
    write_info "Checking if Node.js is installed..."
    node_version=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "node --version" 2>&1)
    node_version=$(echo "$node_version" | tr -d '\n' | tr -d '\r')
    
    if [ -z "$node_version" ] || [[ "$node_version" == *"command not found"* ]]; then
        write_warning "Node.js not installed"
        write_info "Need to install Node.js 18 or higher"
        return 1
    else
        write_success "Node.js installed: $node_version"
        
        major_version=$(echo "$node_version" | sed 's/v\([0-9]\+\).*/\1/')
        if [ "$major_version" -lt 18 ]; then
            write_warning "Node.js version too low: $node_version (recommend 18 or higher)"
            return 1
        fi
        
        return 0
    fi
}

function install_nodejs() {
    local os_name=$1
    
    write_separator
    write_info "Step 4: Install Node.js"
    write_separator
    
    write_warning "Starting Node.js 18 installation..."
    write_warning "This may take several minutes, please wait..."
    
    if [ "$os_name" == "ubuntu" ]; then
        write_info "Detected Ubuntu system, using apt..."
        
        write_info "Updating package list..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "apt-get update" 2>&1
        if [ $? -ne 0 ]; then
            write_error "Failed to update package list"
            write_info "Please check network and apt source"
            return 1
        fi
        write_success "Package list updated"
        
        write_info "Installing required tools..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "apt-get install -y curl gnupg" 2>&1
        if [ $? -ne 0 ]; then
            write_error "Failed to install tools"
            return 1
        fi
        write_success "Tools installed"
        
        write_info "Adding Node.js 18.x repository..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -" 2>&1
        if [ $? -ne 0 ]; then
            write_error "Failed to add Node.js repository"
            write_info "Please check network connection"
            return 1
        fi
        write_success "Node.js repository added"
        
        write_info "Installing Node.js..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "apt-get install -y nodejs" 2>&1
        if [ $? -ne 0 ]; then
            write_error "Failed to install Node.js"
            return 1
        fi
        write_success "Node.js installed"
    elif [ "$os_name" == "centos" ]; then
        write_info "Detected CentOS system, using yum..."
        
        write_info "Installing required tools..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "yum install -y curl" 2>&1
        if [ $? -ne 0 ]; then
            write_error "Failed to install tools"
            return 1
        fi
        write_success "Tools installed"
        
        write_info "Adding Node.js 18.x repository..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -" 2>&1
        if [ $? -ne 0 ]; then
            write_error "Failed to add Node.js repository"
            write_info "Please check network connection"
            return 1
        fi
        write_success "Node.js repository added"
        
        write_info "Installing Node.js..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "yum install -y nodejs" 2>&1
        if [ $? -ne 0 ]; then
            write_error "Failed to install Node.js"
            return 1
        fi
        write_success "Node.js installed"
    else
        write_error "Unsupported OS: $os_name"
        write_info "Please manually install Node.js 18 or higher"
        write_info "Download: https://nodejs.org/"
        return 1
    fi
    
    write_info "Verifying Node.js installation..."
    node_version=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "node --version" 2>&1)
    node_version=$(echo "$node_version" | tr -d '\n' | tr -d '\r')
    
    if [ -z "$node_version" ] || [[ "$node_version" == *"command not found"* ]]; then
        write_error "Node.js installation verification failed"
        return 1
    else
        write_success "Node.js installed successfully: $node_version"
        return 0
    fi
}

function check_npm() {
    write_separator
    write_info "Step 5: Check NPM environment"
    write_separator
    
    write_info "Checking if NPM is installed..."
    npm_version=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "npm --version" 2>&1)
    npm_version=$(echo "$npm_version" | tr -d '\n' | tr -d '\r')
    
    if [ -z "$npm_version" ] || [[ "$npm_version" == *"command not found"* ]]; then
        write_warning "NPM not installed"
        write_info "NPM usually comes with Node.js"
        return 1
    else
        write_success "NPM installed: $npm_version"
        return 0
    fi
}

function install_npm() {
    write_separator
    write_info "Step 6: Install NPM"
    write_separator
    
    write_warning "Starting NPM installation..."
    
    write_info "Installing npm using npm..."
    ssh ${REMOTE_USER}@${REMOTE_HOST} "npm install -g npm" 2>&1
    if [ $? -ne 0 ]; then
        write_error "Failed to install NPM"
        write_info "Trying to install using package manager..."
        
        os_name=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '\"'" 2>&1)
        
        if [ "$os_name" == "ubuntu" ]; then
            ssh ${REMOTE_USER}@${REMOTE_HOST} "apt-get install -y npm" 2>&1
        elif [ "$os_name" == "centos" ]; then
            ssh ${REMOTE_USER}@${REMOTE_HOST} "yum install -y npm" 2>&1
        else
            write_error "Unsupported OS"
            return 1
        fi
        
        if [ $? -ne 0 ]; then
            write_error "Failed to install NPM"
            return 1
        fi
    fi
    
    write_success "NPM installation completed"
    
    write_info "Verifying NPM installation..."
    npm_version=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "npm --version" 2>&1)
    npm_version=$(echo "$npm_version" | tr -d '\n' | tr -d '\r')
    
    if [ -z "$npm_version" ] || [[ "$npm_version" == *"command not found"* ]]; then
        write_error "NPM installation verification failed"
        return 1
    else
        write_success "NPM installed successfully: $npm_version"
        return 0
    fi
}

function check_disk_space() {
    write_separator
    write_info "Step 7: Check disk space"
    write_separator
    
    write_info "Checking disk space..."
    disk_info=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "df -h /" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "$disk_info"
        
        available_space=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "df -h / | tail -1 | awk '{print \$4}'" 2>&1)
        
        write_info "Available disk space: $available_space"
        
        available_gb=$(echo "$available_space" | sed 's/G//')
        if (( $(echo "$available_gb < 2" | bc -l) )); then
            write_warning "Disk space insufficient: $available_space (recommend at least 2GB)"
            write_info "Please clean up disk space"
            return 1
        else
            write_success "Disk space sufficient"
            return 0
        fi
    else
        write_error "Cannot get disk information"
        return 1
    fi
}

function check_ports() {
    write_separator
    write_info "Step 8: Check port usage"
    write_separator
    
    BACKEND_PORT=3001
    FRONTEND_PORT=80
    
    write_info "Checking port usage..."
    
    backend_result=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "netstat -tuln 2>/dev/null | grep ':3001 '" 2>&1)
    backend_result=$(echo "$backend_result" | tr -d '\n' | tr -d '\r')
    
    if [ -z "$backend_result" ]; then
        write_success "Backend port $BACKEND_PORT available"
    else
        write_warning "Backend port $BACKEND_PORT is in use"
        write_info "Process using port:"
        echo "$backend_result"
    fi
    
    frontend_result=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "netstat -tuln 2>/dev/null | grep ':80 '" 2>&1)
    frontend_result=$(echo "$frontend_result" | tr -d '\n' | tr -d '\r')
    
    if [ -z "$frontend_result" ]; then
        write_success "Frontend port $FRONTEND_PORT available"
    else
        write_warning "Frontend port $FRONTEND_PORT is in use"
        write_info "Process using port:"
        echo "$frontend_result"
    fi
    
    return 0
}

function show_summary() {
    write_separator
    write_info "Environment check summary"
    write_separator
    
    write_info "Remote server: ${REMOTE_USER}@${REMOTE_HOST}"
    
    node_version=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "node --version" 2>&1)
    node_version=$(echo "$node_version" | tr -d '\n' | tr -d '\r')
    if [ -z "$node_version" ] || [[ "$node_version" == *"command not found"* ]]; then
        write_error "Node.js: Not installed"
    else
        write_success "Node.js: $node_version"
    fi
    
    npm_version=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "npm --version" 2>&1)
    npm_version=$(echo "$npm_version" | tr -d '\n' | tr -d '\r')
    if [ -z "$npm_version" ] || [[ "$npm_version" == *"command not found"* ]]; then
        write_error "NPM: Not installed"
    else
        write_success "NPM: $npm_version"
    fi
    
    available_space=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "df -h / | tail -1 | awk '{print \$4}'" 2>&1)
    write_info "Disk space: $available_space available"
    
    write_separator
}

function main() {
    write_separator
    echo -e "${COLOR_SUCCESS}Cable Management System - Server Installation Script${COLOR_RESET}"
    write_separator
    echo ""
    
    start_time=$(date)
    write_info "Start time: $start_time"
    echo ""
    
    if ! check_ssh_connection; then
        write_error "SSH connection failed, stopping execution"
        exit 1
    fi
    echo ""
    
    os_name=$(get_os_info)
    if [ -z "$os_name" ]; then
        write_error "Cannot get OS information, stopping execution"
        exit 1
    fi
    echo ""
    
    if ! check_nodejs; then
        write_warning "Node.js not installed or version too low, need to install"
        read -p "Continue to install Node.js? (y/n): " install
        if [ "$install" != "y" ] && [ "$install" != "Y" ]; then
            write_error "User cancelled installation, stopping execution"
            exit 1
        fi
        
        if ! install_nodejs "$os_name"; then
            write_error "Node.js installation failed, stopping execution"
            exit 1
        fi
        echo ""
    fi
    
    if ! check_npm; then
        write_warning "NPM not installed, need to install"
        read -p "Continue to install NPM? (y/n): " install
        if [ "$install" != "y" ] && [ "$install" != "Y" ]; then
            write_error "User cancelled installation, stopping execution"
            exit 1
        fi
        
        if ! install_npm; then
            write_error "NPM installation failed, stopping execution"
            exit 1
        fi
        echo ""
    fi
    
    if ! check_disk_space; then
        write_error "Disk space insufficient, stopping execution"
        exit 1
    fi
    echo ""
    
    check_ports
    echo ""
    
    show_summary
    
    write_separator
    write_success "Environment check and installation completed!"
    write_separator
    echo ""
    
    end_time=$(date)
    write_info "End time: $end_time"
    echo ""
    write_info "Next steps:"
    write_info "  1. Run 1_拷贝文件到远程服务器.ps1 to copy project files"
    write_info "  2. Run 服务器启动.sh to start services"
    echo ""
}

main
