# SSH Key Setup Guide

## Step 1: SSH to Remote Server

Open PowerShell and run:
```
ssh yroot@192.168.19.58
```

Enter password: **Yovole@2026**

## Step 2: Add Public Key to Authorized Keys

Once connected, run these commands:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHPJOi+Lh65JknLGmD45yRQRrWxEe56ekLWH8c0qYlk9lE6hermsg2bKk0x4ck5NRSmkR9q3FLTbVyYu9XZCh9N+qUqgg5sqc1EMYHd6MhIBiey3gzVX7wKeiKAHaRL5rpksq/RkD9G3AS1LT9QHD9P3XuHKv0evb7BpV3pEYOhYXPbzjHtnwcc7e7Cz9NodvjBDIgld0dxi6L8UYFylMQRGwLzhEV5ZbH/q1R+NK3JrBoakDd7kQJbqEnxfYAvi2GAvOkMSnkwMKmB6mY63b0qnVHHM9kza4baqJg2iBPO0jLQEgf3o/0eefQqktmE3g4GhHokJYhXUT8jtiinUc+jt+lYFH8e80Hi0pISl1UlJh/9wHut28pHknpWN4TAxYhAlUL1TY30DyA7KwijYpiEartEGIjh2RHKYKZku0nYPp2wMK2GkMHoHhIbBIR/qS8zWPxt+DWNzuaVlVguISNd807V5RUnwGVLMin33T4TLo+GMepfK+lg6qM/WjAb0A0QIwOZZHC8w7UHcjo642H5ufCziIOdaqNGh+B1Am7KaOBRwu64IObWWJQh70hbgdIZxX35k7ls7ctS7JjC70cNiqCLVnxJbD/Yf7t0Fio9JXcTna4f/Dg75e2o7QBhHF3FQQISlARTFCuAsaiVSdiQqFVec7N5uCdl8b+3693Qw== admin@DESKTOP-N628603" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## Step 3: Test SSH Connection

Exit from the server and test SSH connection without password:

```
ssh yroot@192.168.19.58 "echo 'SSH connection successful'"
```

If successful, you should see "SSH connection successful" without being prompted for a password.

## Step 4: Run Deployment Script

Once SSH key authentication is working, run:

```
.\deploy_with_ssh_key.bat
```

This will copy all files to the remote server without requiring password input.
