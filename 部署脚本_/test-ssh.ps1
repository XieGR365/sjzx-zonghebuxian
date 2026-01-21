$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "root"

Write-Host "Testing SSH connection to ${REMOTE_USER}@${REMOTE_HOST}..."
ssh ${REMOTE_USER}@${REMOTE_HOST} "echo 'Connection successful'"
