#! /bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
ip=$(hostname -I)
echo "<h1>Azure Virtual Machine with Load Balancer<br>$ip<br>Vladislav Semenenko<br>2021</h1>" | sudo tee /var/www/html/index.html
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDqZAI7rjihjiihggfgffgfvvbhjbbjbjjeF..." | sudo tee /home/azureuser/.ssh/authorized_keys