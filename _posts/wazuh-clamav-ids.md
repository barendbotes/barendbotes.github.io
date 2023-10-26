---
title: Wazuh ClamAV HIPS
date: 2023-02-19 13:30 +0200
categories: [docker,docker-compose,wazuh,siem]
tags: [clamav,hids,hips]
author: barend
---

![Zammad](https://wazuh.com/uploads/2022/05/wazuh-logo.png)

# Wazuh HIPS with ClamAV

## Requirements

- [**Wazuh** - *Wazuh installation guide.*](https://documentation.wazuh.com/current/installation-guide/index.html)
- [**Wazuh Agent** - *Wazuh agent installation guide*](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/index.html)

## ClamAV Installation and Configuration

Install ClamAV

```bash
sudo apt update && sudo apt install clamav clamav-daemon -y
```

Configure `OnAccessScanning`

```bash
sudo nano /etc/clamav/clamd.conf
```
Append the below to the `clamd.conf` file.

```bash
OnAccessIncludePath /root
OnAccessIncludePath /home
OnAccessPrevention yes
OnAccessExcludeUname clamav
OnAccessExtraScanning yes
```
{: file="/etc/clamav/clamd.conf" }

Create ClamAV OnAccessScanning Service

```bash
sudo nano /etc/systemd/system/clamonacc.service
```

```bash
# /etc/systemd/system/clamonacc.service
[Unit]
Description=ClamAV On Access Scanner
Requires=clamav-daemon.service
After=clamav-daemon.service
After=syslog.target
After=network-online.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/bash -c "while [ ! -S /var/run/clamav/clamd.ctl ]; do sleep 1; done"
ExecStart=/usr/sbin/clamonacc -F --fdpass --config-file=/etc/clamav/clamd.conf

[Install]
WantedBy=multi-user.target
```
{: file="/etc/systemd/system/clamonacc.service" }

```bash
sudo chmod 644 /etc/systemd/system/clamonacc.service
sudo systemctl enable clamonacc
```
```bash
sudo systemctl start clamonacc
```

```bash
sudo systemctl status clamonacc
```

Confirm that it is `watching` your folders specified in the `clam.conf` and that `extra scanning on inotify events enabled` is showing

## Setup Wazuh Agent

Install jq

```bash
sudo apt update
sudo apt -y install jq
```

Create Wazuh command on Wazuh Agent

```bash
sudo nano /var/ossec/active-response/bin/clamav-remove-threat.sh
```

```bash
#!/bin/bash

LOCAL=`dirname $0`;
cd $LOCAL
cd ../

PWD=`pwd`

read INPUT_JSON
FILENAME=$(echo $INPUT_JSON | jq -r .parameters.alert.data.url)
COMMAND=$(echo $INPUT_JSON | jq -r .command)
LOG_FILE="${PWD}/../logs/active-responses.log"

#------------------------ Analyze command -------------------------#
if [ ${COMMAND} = "add" ]
then
 # Send control message to execd
 printf '{"version":1,"origin":{"name":"remove-threat","module":"active-response"},"command":"check_keys", "parameters":{"keys":[]}}\n'

 read RESPONSE
 COMMAND2=$(echo $RESPONSE | jq -r .command)
 if [ ${COMMAND2} != "continue" ]
 then
  echo "`date '+%Y/%m/%d %H:%M:%S'` $0: $INPUT_JSON Remove threat active response aborted" >> ${LOG_FILE}
  exit 0;
 fi
fi

# Removing file
rm -f $FILENAME
if [ $? -eq 0 ]; then
 echo "`date '+%Y/%m/%d %H:%M:%S'` $0: $INPUT_JSON Successfully removed threat" >> ${LOG_FILE}
else
 echo "`date '+%Y/%m/%d %H:%M:%S'` $0: $INPUT_JSON Error removing threat" >> ${LOG_FILE}
fi

exit 0;
```
{: file="/var/ossec/active-response/bin/clamav-remove-threat.sh" }


Modify permissions

```bash
sudo chmod 750 /var/ossec/active-response/bin/clamav-remove-threat.sh
sudo chown root:wazuh /var/ossec/active-response/bin/clamav-remove-threat.sh
```

Restart Agent

```bash
sudo systemctl restart wazuh-agent
```

## Wazuh Manager

Add the `clamav-remove-threat.sh` script as a command and the `active-response` that uses that command for ClamAV. You have to add it within `<ossec_config> ... </ossec_config>` 

```bash
sudo nano /var/ossec/etc/ossec.conf
```

```xml
  <command>
    <name>clamav-remove-threat</name>
    <executable>clamav-remove-threat.sh</executable>
    <timeout_allowed>no</timeout_allowed>
  </command>

  <active-response>
    <disabled>no</disabled>
    <command>clamav-remove-threat</command>
    <location>local</location>
    <rules_id>52502</rules_id>
  </active-response>
```
{: file="/var/ossec/etc/ossec.conf" }

Rules to alert in Wazuh dashboard

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```
Append the below to the `local_rules.xml` file

```xml
<group name="clam,">
  <rule id="100092" level="12">
    <if_sid>657</if_sid>
    <match>Successfully removed threat</match>
    <description>$(parameters.program) removed threat located at $(parameters.alert.data.virustotal.source.file)</description>
  </rule>

  <rule id="100093" level="12">
    <if_sid>657</if_sid>
    <match>Error removing threat</match>
    <description>Error removing threat located at $(parameters.alert.data.virustotal.source.file)</description>
  </rule>
</group>
```
{: file="/var/ossec/etc/rules/local_rules.xml" }


Restart Wazuh Manager

```bash
sudo systemctl restart wazuh-manager
```

## Test

On the Wazuh Agent, test ClamAV by running the below in the home directory of your user account.

```bash
sudo curl -LO https://secure.eicar.org/eicar.com && ls -lah eicar.com
```

Check syslog.

```bash
sudo cat /var/log/syslog | grep FOUND
```

You should see something like `... Win.Test.EICAR_HDB-1 FOUND`, once you see it in there, navigate to your Wazuh dashboard, select `Modules` > `Security Events`, select `Explore Agents` on the right and select your Wazuh agent.
Once selected, click on `Events` > `Add filter` > `Edit as Query DSL` and paste in the following:

```json
{
  "query": {
    "bool": {
      "should": [
        {
          "match_phrase": {
            "rule.id": "52502"
          }
        },
        {
          "match_phrase": {
            "rule.id": "100092"
          }
        }
      ],
      "minimum_should_match": 1
    }
  }
}
```

You should see a `Virus detected` and an `active-response/bin/clamav-remove-threat.sh` event.