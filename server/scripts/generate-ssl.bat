@echo off

REM Create SSL directory if it doesn't exist
if not exist nginx\ssl mkdir nginx\ssl

REM Generate SSL certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 ^
  -keyout nginx\ssl\key.pem ^
  -out nginx\ssl\cert.pem ^
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

echo SSL certificates generated successfully! 