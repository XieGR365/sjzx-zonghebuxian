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

function test_remote_files() {
    write_info "Checking remote server files..."
    
    all_ok=true
    
    ssh ${REMOTE_USER}@${REMOTE_HOST} '[ -d ~/sjzx-zonghebuxian/backend ]' 2>&1
    if [ $? -ne 0 ]; then
        write_error "Backend directory does not exist"
        all_ok=false
    else
        write_success "Backend directory exists"
    fi
    
    ssh ${REMOTE_USER}@${REMOTE_HOST} '[ -d ~/sjzx-zonghebuxian/frontend ]' 2>&1
    if [ $? -ne 0 ]; then
        write_error "Frontend directory does not exist"
        all_ok=false
    else
        write_success "Frontend directory exists"
    fi
    
    if [ "$all_ok" = false ]; then
        return 1
    fi
    
    return 0
}

function test_nodejs() {
    write_info "Checking Node.js environment..."
    
    node_version=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "node --version" 2>&1)
    node_version=$(echo "$node_version" | tr -d '\n' | tr -d '\r')
    
    if [ -z "$node_version" ]; then
        write_error "Node.js not installed"
        return 1
    else
        write_success "Node.js installed: $node_version"
        return 0
    fi
}

function test_npm() {
    write_info "Checking NPM environment..."
    
    npm_version=$(ssh ${REMOTE_USER}@${REMOTE_HOST} "npm --version" 2>&1)
    npm_version=$(echo "$npm_version" | tr -d '\n' | tr -d '\r')
    
    if [ -z "$npm_version" ]; then
        write_error "NPM not installed"
        return 1
    else
        write_success "NPM installed: $npm_version"
        return 0
    fi
}

function test_ports() {
    write_info "Checking port usage..."
    
    backend_check=$(ssh ${REMOTE_USER}@${REMOTE_HOST} 'netstat -tuln 2>/dev/null | grep -q ":3001 "; if [ $? -eq 0 ]; then echo "in_use"; else echo "free"; fi' 2>&1)
    backend_check=$(echo "$backend_check" | tr -d '\n' | tr -d '\r')
    
    if [ "$backend_check" = "in_use" ]; then
        write_warning "Backend port 3001 is in use"
    else
        write_success "Backend port 3001 is available"
    fi
    
    frontend_check=$(ssh ${REMOTE_USER}@${REMOTE_HOST} 'netstat -tuln 2>/dev/null | grep -q ":80 "; if [ $? -eq 0 ]; then echo "in_use"; else echo "free"; fi' 2>&1)
    frontend_check=$(echo "$frontend_check" | tr -d '\n' | tr -d '\r')
    
    if [ "$frontend_check" = "in_use" ]; then
        write_warning "Frontend port 80 is in use"
    else
        write_success "Frontend port 80 is available"
    fi
    
    return 0
}

function install_backend_dependencies() {
    write_info "Installing backend dependencies..."
    
    write_info "Entering backend directory..."
    ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/backend; if [ $? -ne 0 ]; then exit 1; fi' 2>&1
    if [ $? -ne 0 ]; then
        write_error "Cannot enter backend directory"
        return 1
    fi
    
    write_info "Running npm install..."
    write_warning "This may take several minutes, please wait..."
    
    ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/backend && npm install --production' 2>&1
    
    if [ $? -eq 0 ]; then
        write_success "Backend dependencies installed"
        return 0
    else
        write_error "Backend dependencies installation failed"
        return 1
    fi
}

function install_frontend_dependencies() {
    write_info "Installing frontend dependencies..."
    
    write_info "Entering frontend directory..."
    ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/frontend; if [ $? -ne 0 ]; then exit 1; fi' 2>&1
    if [ $? -ne 0 ]; then
        write_error "Cannot enter frontend directory"
        return 1
    fi
    
    write_info "Running npm install..."
    write_warning "This may take several minutes, please wait..."
    
    ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/frontend && npm install' 2>&1
    
    if [ $? -eq 0 ]; then
        write_success "Frontend dependencies installed"
        return 0
    else
        write_error "Frontend dependencies installation failed"
        return 1
    fi
}

function start_backend_service() {
    write_info "Starting backend service..."
    
    write_info "Checking backend environment configuration..."
    ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/backend; if [ ! -f .env ]; then cp .env.example .env; fi' 2>&1
    
    write_info "Starting backend service..."
    ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/backend && nohup npm start > backend.log 2>&1 &' 2>&1
    
    if [ $? -eq 0 ]; then
        write_success "Backend service started"
        return 0
    else
        write_error "Backend service startup failed"
        return 1
    fi
}

function start_frontend_service() {
    write_info "Starting frontend service..."
    
    write_info "Building frontend..."
    write_warning "This may take several minutes, please wait..."
    
    ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/frontend && npm run build' 2>&1
    
    if [ $? -ne 0 ]; then
        write_error "Frontend build failed"
        return 1
    fi
    
    write_success "Frontend build completed"
    
    write_info "Starting frontend service..."
    ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/frontend && nohup npm run preview > frontend.log 2>&1 &' 2>&1
    
    if [ $? -eq 0 ]; then
        write_success "Frontend service started"
        return 0
    else
        write_error "Frontend service startup failed"
        return 1
    fi
}

function test_backend_service() {
    write_info "Testing backend service..."
    
    sleep 3
    
    backend_process=$(ssh ${REMOTE_USER}@${REMOTE_HOST} 'ps aux | grep "npm start" | grep -v grep; if [ $? -ne 0 ]; then echo "not running"; fi' 2>&1)
    echo "$backend_process"
    
    if [[ "$backend_process" == *"not running"* ]]; then
        write_error "Backend service not running"
        return 1
    else
        write_success "Backend service is running"
        return 0
    fi
}

function test_frontend_service() {
    write_info "Testing frontend service..."
    
    sleep 3
    
    frontend_process=$(ssh ${REMOTE_USER}@${REMOTE_HOST} 'ps aux | grep "npm run preview" | grep -v grep; if [ $? -ne 0 ]; then echo "not running"; fi' 2>&1)
    echo "$frontend_process"
    
    if [[ "$frontend_process" == *"not running"* ]]; then
        write_error "Frontend service not running"
        return 1
    else
        write_success "Frontend service is running"
        return 0
    fi
}

function show_service_status() {
    write_separator
    write_info "Service status"
    write_separator
    
    write_info "Backend process:"
    backend_process=$(ssh ${REMOTE_USER}@${REMOTE_HOST} 'ps aux | grep "npm start" | grep -v grep; if [ $? -ne 0 ]; then echo "not running"; fi' 2>&1)
    echo "$backend_process"
    
    write_info "Frontend process:"
    frontend_process=$(ssh ${REMOTE_USER}@${REMOTE_HOST} 'ps aux | grep "npm run preview" | grep -v grep; if [ $? -ne 0 ]; then echo "not running"; fi' 2>&1)
    echo "$frontend_process"
    
    write_info "Port listening:"
    port_listen=$(ssh ${REMOTE_USER}@${REMOTE_HOST} 'netstat -tuln 2>/dev/null | grep -E ":3001|:80"; if [ $? -ne 0 ]; then echo "none"; fi' 2>&1)
    echo "$port_listen"
    
    write_separator
}

function main() {
    write_separator
    echo -e "${COLOR_SUCCESS}Cable Management System - Server Startup Script${COLOR_RESET}"
    write_separator
    echo ""
    
    start_time=$(date)
    write_info "Start time: $start_time"
    echo ""
    
    if ! test_remote_files; then
        write_error "Remote file check failed, stopping execution"
        write_info "Please run 1_拷贝文件到远程服务器.ps1 first"
        exit 1
    fi
    echo ""
    
    if ! test_nodejs; then
        write_error "Node.js environment check failed, stopping execution"
        write_info "Please install Node.js on the remote server"
        exit 1
    fi
    echo ""
    
    if ! test_npm; then
        write_error "NPM environment check failed, stopping execution"
        write_info "Please install NPM on the remote server"
        exit 1
    fi
    echo ""
    
    test_ports
    echo ""
    
    if ! install_backend_dependencies; then
        write_error "Backend dependencies installation failed, stopping execution"
        exit 1
    fi
    echo ""
    
    if ! install_frontend_dependencies; then
        write_error "Frontend dependencies installation failed, stopping execution"
        exit 1
    fi
    echo ""
    
    if ! start_backend_service; then
        write_error "Backend service startup failed, stopping execution"
        exit 1
    fi
    echo ""
    
    if ! start_frontend_service; then
        write_error "Frontend service startup failed, stopping execution"
        exit 1
    fi
    echo ""
    
    sleep 5
    
    test_backend_service
    echo ""
    
    test_frontend_service
    echo ""
    
    show_service_status
    
    write_separator
    write_success "Service startup completed!"
    write_separator
    echo ""
    
    end_time=$(date)
    write_info "End time: $end_time"
    echo ""
    write_info "Access URLs:"
    write_info "  Frontend: http://${REMOTE_HOST}:80"
    write_info "  Backend: http://${REMOTE_HOST}:3001"
    echo ""
    write_info "View logs:"
    write_info "  Backend: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f ~/sjzx-zonghebuxian/backend/backend.log'"
    write_info "  Frontend: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f ~/sjzx-zonghebuxian/frontend/frontend.log'"
    echo ""
}

main
