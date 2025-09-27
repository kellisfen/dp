# Скрипт установки Kibana 7.17.0 через SSH алиасы (ssh_config)
$ErrorActionPreference = "Stop"

$sshConfig = "ansible\ssh_config"

Write-Host "Checking SSH access to alias 'kibana'..."
ssh -F $sshConfig kibana "hostname" | Out-Null

Write-Host "Stopping and removing Kibana Docker container (if any)..."
ssh -F $sshConfig kibana "docker stop kibana 2>/dev/null || true; docker rm kibana 2>/dev/null || true" | Out-Null

Write-Host "Adding Elasticsearch GPG key..."
ssh -F $sshConfig kibana "wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -" | Out-Null

Write-Host "Adding Elasticsearch 7.x APT repository..."
ssh -F $sshConfig kibana "echo 'deb https://artifacts.elastic.co/packages/7.x/apt stable main' | sudo tee /etc/apt/sources.list.d/elastic-7.x.list" | Out-Null

Write-Host "Updating APT cache..."
ssh -F $sshConfig kibana "sudo apt-get update" | Out-Null

Write-Host "Installing Kibana 7.17.0..."
ssh -F $sshConfig kibana "sudo apt-get install -y kibana=7.17.0" | Out-Null

Write-Host "Preparing Kibana configuration..."
$kibanaConfig = @"
server.port: 5601
server.host: ""0.0.0.0""
server.name: ""kibana.ru-central1.internal""

elasticsearch.hosts: [""http://10.0.4.17:9200""]

logging.appenders.file.type: file
logging.appenders.file.fileName: /var/log/kibana/kibana.log
logging.appenders.file.layout.type: json

logging.root.level: info
logging.root.appenders: [default, file]

pid.file: /run/kibana/kibana.pid

ops.interval: 5000

i18n.locale: ""ru""
"@

Write-Host "Writing Kibana configuration to /etc/kibana/kibana.yml..."
$kibanaConfig | ssh -F $sshConfig kibana "sudo tee /etc/kibana/kibana.yml > /dev/null" | Out-Null

Write-Host "Enabling and restarting Kibana service..."
ssh -F $sshConfig kibana "sudo systemctl enable kibana && sudo systemctl restart kibana" | Out-Null

Write-Host "Waiting for Kibana to start..."
Start-Sleep -Seconds 30

Write-Host "Checking Kibana service status..."
ssh -F $sshConfig kibana "sudo systemctl status kibana --no-pager"

Write-Host "Checking Kibana HTTP availability on localhost:5601..."
ssh -F $sshConfig kibana "curl -s -o /dev/null -w '%{http_code}' http://localhost:5601"

Write-Host "Done: Kibana installed and started."