#!/bin/env python3
# add additional alias tags if one is found from the set
tag_alias_map = [
        {"salt", "saltstack"},
        {"verify", "überprüfen"},
        {"life", "private", "leben"},
        {"cleanup", "aufräumen"},
        {"skill", "fähigkeit"},
        {"contacts", "kontakte"},
        {"read", "lesen"},
        {"review", "überprüfen"},
        {"examine", "untersuchen", "kontrollieren"},
        {"plan", "planen", "entwerfen"},
        {"geschenk", "present"},
        {"research", "recherche"},
        {"install", "setup", "installieren", "einrichten"},
        {"log", "logging"},
        {"sell", "verkaufen"},
        {"goal", "ziel"},
        {"lifegoal", "lebensziel"},
        {"data", "daten"},
        {"accounting", "buchhaltung"},
        {"health", "gesundheit"},
        {"kopieren", "copy"},
        {"domäne", "domain"},
        {"mail", "e-mail"},
        {"story", "userstory"},
        {"virt", "virtualization", "virtual"},
        {"lib", "library"},
        {"fw", "firewall"},
        {"tanzen", "dance"},
        {"kickboxen", "kickboxing", "kb"},
        {"nachricht", "message"},
        {"phone", "telefon"},
        {"bedarf", "anforderung"},
        {"robot", "roboter"},
        {"event", "veranstaltung"},
        {"fit", "fitness"},
        {"secret", "geheim"},
        {"machine", "host"},
        {"cli", "commandline"},
        {"kvm", "virtualization"},
        {"tw", "taskwarrior"},
        {"document", "documents", "dokumente", "dokument"},
        {"buy", "kaufen"},
        {"repo", "repository"},
        {"config", "configuration"},
        {"doc", "documentation", "dokumentation"},
        {"milestone", "target"},
        {"cs", "compsci"},
        {"math", "mathematics", "mathe"},
        {"phy", "physics", "physik"},
        {"graph", "graphtheory", "graphentheorie"},
        {"stats", "statistic", "statistik"},
        {"dev", "development"},
        {"ops", "operations", "admin", "administration"},
        {"ci", "continuous_integration"},
        {"cd", "continuous_deployment"},
        {"compsci", "informatik", "cs"},
        {"calculus", "calc", "analysis"},
        {"exam", "prüfung", "klausur"},
        {"uni", "university", "fachhochschule"},
        {"cert", "certificate"},
        {"geld", "money"},
        {"ap", "accesspoint"},
        {"net", "network"},
        {"rpi", "raspberrypi"},
        {"lan", "intranet"},
        {"phone", "call", "anrufen"},
        {"icinga", "icinga2"},
        {"sudo", "sudoers"},
        {"www", "web"},
        {"ids", "intrusion_detection_system"},
        {"flex", "flexibility", "stretch", "stretching"},
        {"js", "javascript"},
        {"maybe", "someday"},
        {"privilege", "privileges", "berechtigung", "berechtigungen"},
        ]
# add related tags if one is found by key
tag_relations = {
        # items land first in intray # fast add, only default attributes set
        # decide what to do about the task, next action
        "intray": {},
        #
        # projects
        "professional": {},
        "personal": {},
        #
        "philosophy": {"life"},
        "ghm": {"git", "manager", "hooks", "project", "repository"},
        "iptables": {"firewall", "admin", "linux", "security"},
        "python": {"programming", "dev"},
        "python3": {"python", "dev", "programming"},
        "slapd": {
            "ldap",
            "admin",
            "linux",
            "identity",
            "storage",
            },
        "kubernetes": {
            "cluster",
            "docker",
            "admin",
            "linux",
            "orchestration",
            "container",
            },
        "ldap": {
            "directory",
            "data",
            "admin",
            "authentication", "authorization", "network"
            },
        "kerberos": {"admin", "security", "authentication", "network", },
        "2fa": {"security", "network", "authentication", "token", },
        "tripwire": {
            "ids",
            "security",
            "audit", "integrity", "linux", "monitor", },
        "radius": {
            "admin", "security", "authentication",
            "network", "access", "audit", "2fa", },
        "vim": {
            "editor",
            },
        "vimwiki": {
            "wiki",
            "vim",
            },
        "openvas": {
            "scanner",
            "audit",
            "vulnerability",
            "security",
            "admin",
            "network",
            },
        "freeradius": {"radius", },
        "c": {"programming", "dev"},
        "fitness": {"life", "body", "sport", "health"},
        "sport": {"life", "health"},
        "calisthenics": {"sport", },
        "stretch": {"life", "health", "fitness", "body", "workout"},
        "body": {"life"},
        "arzt": {"health"},
        "health": {"life"},
        "muscle": {"life", "health", "workout", "training"},
        "training": {"life", "health"},
        "workout": {"life", "health"},
        "box": {"life", "sport", "training", "health"},
        "kickboxing": {"life", "sport", "training", "health"},
        "loadbalance": {"admin", },
        "flask": {"web", "python", "framework", "dev", "backend"},
        "css": {"web", "dev", "frontent"},
        "javascript": {"web", "dev", "frontent"},
        "movie": {"watch", "cinematic", },
        "bro": {"ids", "network", "security", "monitor", },
        "snort": {"ids", "network", "security", "monitor", },
        "terraform": {"ci", "devops", "admin", "dev", },
        "rust": {"programming", "dev"},
        "bash": {"programming", "script", "admin", "dev"},
        "programming": {"dev", },
        "dns": {"domain", "admin", },
        "bind": {"domain", "admin", "linux", "service", },
        "devops": {"ops", "dev"},
        "refactor": {"dev", "programming", },
        "linux": {"os", "admin"},
        "workstation": {"ws", "pc"},
        "windows": {"os", "admin"},
        "cron": {"linux", "admin", },
        "docker": {"linux", "admin", "devops", "dev"},
        "nginx": {"http", "admin", "web", "proxy", },
        "squid": {"proxy", "http", "access", "control", },
        "ubuntu": {"distribution", "admin", "linux"},
        "arch": {"distribution", "admin", "linux"},
        "archarm": {"distribution", "admin", "linux"},
        "centos": {"distribution", "admin", "linux"},
        "package": {"pkg", "admin"},
        "mutt": {
            "mail",
            "e-mail",
            "smtp", "imap", "client", "software", "cli"},
        "libvirt": {"virt", "admin"},
        "xen": {"virt", "admin"},
        "ha": {"cluster", "admin", "network", },
        "vm": {"virt", "admin"},
        "tablet": {"art", "drawing"},
        "lxd": {"virt", "container", "admin", "devops", "service", "lxc", },
        "lxc": {"virt", "container", "admin", "devops", },
        "git": {"vcs", "devops", "admin", "dev", "repository"},
        "gitolite": {"vcs", "devops", "admin", "dev", "repository"},
        "router": {"node", "admin"},
        "repository": {"vcs", "dev", },
        "host": {"node", "admin", },
        "node": {"network", },
        "terminal": {"cli", "shell", "console", "admin", "linux"},
        "wiki": {"doc"},
        "rsnapshot": {"rsync", "backup", "admin", "linux"},
        "borg": {
            "ssh",
            "admin",
            "backup",
            "repo",
            "linux"},
        "formula": {"salt", "state", "devops"},
        "pillar": {"salt", "devops"},
        "reactor": {"salt", "devops"},
        "grains": {"salt", "devops"},
        "salt": {"devops", "admin", "dev", "linux"},
        "ansible": {"devops", "admin", "dev", "linux"},
        "bug": {"error", "dev", "programming", },
        "postgres": {"database", "linux", "admin"},
        "database": {"data", "storage", "admin"},
        "backup": {"admin"},
        "samba": {"linux", "admin", },
        "vault": {"secret", "storage", "admin", "linux", "service", },
        "token": {"secret"},
        "jinja": {"template"},
        "habit": {"life"},
        "key": {"secret"},
        "postfix": {"mail", "smtp", "admin", "linux", "e-mail"},
        "dovecot": {"mail", "imap", "admin", "linux"},
        "pki": {"secret", "certificate", "admin"},
        "analysis": {"math"},
        "algebra": {"math"},
        "book": {"read"},
        "work": {},
        "qemu": {"kvm", "linux", "admin"},
        "bahamut": {"admin", "server", "minion", "node", "host", "intranet", },
        "rhea": {"admin", "server", "minion", "node", "host", "intranet", },
        "icinga": {"monitoring", "admin"},
        "network": {"admin", },
        "intranet": {"network", "lan", },
        "lan": {"network", },
        "buildbot": {
            "ci",
            "cd",
            "build",
            "integration", "devops", "deployment", },
        "concourse": {
            "ci",
            "cd",
            "build",
            "integration", "devops", "deployment", },
        "wlan": {"network", "wireless", "admin", },
        "ap": {"network", "wlan", "admin", },
        "sniffer": {"security", "network"},
        "goal": {"life", },
        "dhcp": {"client", "admin", "network", },
        "dhcpd": {"service", "admin", "network", },
        "firewall": {"admin", },
        "shorewall": {"firewall", "linux", "admin", "iptables"},
        "rsyslog": {"syslog", "log", "linux", "admin"},
        "spardabank": {"bank", "finance"},
        "bank": {"finance", "money", },
        "accounting": {"finance", "money", },
        "ckteam": {"boxing", "kickboxing", "club", },
        "ledger": {
            "accounting",
            "transaction",
            "app",
            "cli",
            "balance",
            "finance", },
        "money": {"life", "finance"},
        "hdd": {"storage", "disk", "admin"},
        "disk": {"storage", "admin"},
        "isci": {"storage", "admin"},
        "lvm": {"storage", "admin"},
        "grafana": {"linux", "admin", "dashboard", "monitoring", "webapp"},
        "collectd": {"linux", "admin", "monitoring", "service", "metrics"},
        "weechat": {"linux", "chat", "irc", "userapp"},
        "sudoers": {
            "linux",
            "admin",
            "authorization",
            "policy", "security", "privileges"},
        "ssh": {"linux", "admin", "authentication", "security"},
        "x509": {"linux", "admin", "certificate"},
        "kernel": {"admin"},
        "fail2ban": {
            "linux",
            "admin",
            "security", "iptables", "service", "tool"},
        }


def get_tag_mapping(tag_map, mapping_set):
    for tag in tag_map:
        for relation in mapping_set:
            if tag in relation:
                tag_map = tag_map.union(relation)
    return tag_map


def test_mapping():
    tags = ["nope"]
    aliases = [{"nope", "n"}]
    result = {"nope", "n"}
    stags = set(tags)
    stags = get_tag_mapping(stags, aliases)
    assert stags == result


def test_get_all_relations():
    tags = {"nope", "gear", "home"}
    relations = {
            "n": {"home", "h", },
            }
    aliases = [{"nope", "n"}]
    tags_check = tags.copy()
    while tags_check:
        tag = tags_check.pop()
        relation = relations.get(tag, "")
        stags = get_tag_mapping({tag, }, aliases)
        print(tag)
        print(relation, stags)
        print(tags_check)
        print("--")
        if not tags.issuperset(stags):
            tags_check = tags_check.union(stags)
            tags = tags.union(stags)
        if relation and not tags.issuperset(relation):
            tags_check = tags_check.union(relation)
            tags = tags.union(relation)

    result = {"nope", "n", "gear", "home", "h"}
    assert tags == result
