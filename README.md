# Plugins
wget --show-progress https://github.com/ilyasM6/Plugins/raw/main/STB_UNION%20E2.tar.gz -O /tmp/p.tar.gz && tar -xzvf /tmp/p.tar.gz -C /usr/lib/enigma2/python/Plugins/Extensions/ && rm /tmp/p.tar.gz && init 4 && sleep 2 && init 3

https://github.com/ilyasM6/Plugins/blob/main/STB_UNION_servers.json


# Plugins & Servers
wget -qO /tmp/p.tar.gz https://github.com/ilyasM6/Plugins/raw/main/STB_UNION%20E2.tar.gz && tar -xzf /tmp/p.tar.gz -C /usr/lib/enigma2/python/Plugins/Extensions/ && mkdir -p /etc/enigma2 && wget -qO /etc/enigma2/STB_UNION_servers.json https://github.com/ilyasM6/Plugins/raw/main/STB_UNION_servers.json && rm /tmp/p.tar.gz && init 4 && sleep 2 && init 3
