---
title: Example Post
date: 2022-07-08 00:00 +0200
categories: [documentation,linux,jekyll]
tags: [hosting,code,docs]
author: barend
---

# Welcome!

This is an example site. So please be patient.

## Show scripting

Here we will show some scripting languages

### Bash

```bash
sudo apt update
```

### YAML

```yaml
version: '3.5'

services:
  traefik:
    image: traefik:latest
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
```

### JSON
```json
{
    "name":"John", 
    "age":30, 
    "car":null
}
```

## Lists

### Unordered

* One thing
* Another thing
* Some other thing

### Ordered

1. First thing
2. Second thing
    1. Seconds' first thing
    2. Seconds'second thing
3. Third thing

## Photos

![Cyber](https://static-cdn.jtvnw.net/jtv_user_pictures/fe2a71e2-99d8-4299-86be-16f1932530e7-profile_banner-480.png){: w="700" h="400" }

## Prompt Boxes

> An example showing the tip type prompt. 
{: .prompt-tip}

> An example showing the info type prompt. 
{: .prompt-info}

> An example showing the warning type prompt. 
{: .prompt-warning}

> An example showing the danger type prompt. 
{: .prompt-danger}

## More

Refer to https://chirpy.cotes.page/posts/write-a-new-post/