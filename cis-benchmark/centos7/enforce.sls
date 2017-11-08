# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "cis-benchmark/map.jinja" import cis_benchmark with context %}

# Services disabled (from all benchmark sections)
{% for service in cis_benchmark.disable_services %}
{{ service }}:
  service.dead:
    - enable: False
{% endfor %}

# Packages removed (from all benchmark sections)
{% for pkg in cis_benchmark.remove_pkgs %}
{{ pkg }}:
  pkg.removed
{% endfor %}

# Sysctl variables enabled (value = 1)
{% for sysctlv in cis_benchmark.sysctl_enable %}
{{ sysctlv }}:
  sysctl.present:
    - value: 1
{% endfor %}

# Sysctl variables disabled (value = 0)
{% for sysctlv in cis_benchmark.sysctl_disable %}
{{ sysctlv }}:
  sysctl.present:
    - value: 0
{% endfor %}

# 1.1.1
# Filesystem mounts disabled
{% for filesystem in cis_benchmark.disable_filesystem_types %}
no-{{ filesystem }}:
  file.managed:
    - name: /etc/modprobe.d/disable_{{ filesystem }}.conf
    - contents: 
      - "install {{ filesystem }} /bin/true\n"
    - user: root
    - group: root
    - file_mode: 640
{% endfor %}

# 1.2.2
{% if cis_benchmark.gpgcheck %}
/etc/yum.conf:
  file.line:
    - content: 'gpgcheck=1'
    - match: /^gpgcheck=0$/
    - mode: Replace
{% endif %}

# 1.2.3
{% if cis_benchmark.update %}
yum-update:
  cmd.run:
    - name: /usr/bin/yum -y update
    - unless:
      - /usr/bin/yum check-update
{% endif %}

# 1.3.1
{% if cis_benchmark.aide %}
aide:
  pkg.installed

init_aide:
  cmd.run:
    - name: "/usr/sbin/aide --init -B 'database_out=file:/var/lib/aide/aide.db.gz'"
    - creates: /var/lib/aide/aide.db.gz
    - require:
      - pkg: aide

# 1.3.2
/usr/sbin/aide --check:
  cron.present:
    - user: root
    - special: '@daily'
{% endif %}

# 1.4.1
{% if cis_benchmark.selinux %}
enforcing:
  selinux.mode
{% endif %}

# 1.5.1
{% if cis_benchmark.core_dump_hard_limit %}
/etc/security/limits.d/core_dump_hard_limit:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - contents: |
        * hard core 0

fs.suid_dumpable:
  sysctl.present:
    - value: 0
{% endif %}

# 1.5.1 - 1.5.2
/boot/grub2/grub.cfg:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - replace: False

# 1.6.2
kernel.randomize_va_space:
  sysctl.present:
    - value: 2

# 4.5.1
{% if cis_benchmark.tcpwrappers %}
tcp_wrappers:
  pkg.installed

# FIXME Incomplete: need to generate hosts.allow
{% endif %}

# 5.1
{% if cis_benchmark.rsyslog %}
rsyslog_pkg:
  pkg.installed:
    - name: rsyslog

rsyslog_service:
  service.running:
    - name: rsyslog
    - enable: True
    - require:
      - pkg: rsyslog

# Omitted: 5.1.3, 5.1.4, 5.1.5
{% endif %}

# 5.1.8
{% if cis_benchmark.at_deny_absent %}
/etc/at.deny:
  file.absent
{% endif %}

{% if cis_benchmark.at_allow %}
/etc/at.allow:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - replace: False
{% endif %}

{% if cis_benchmark.cron_deny_absent %}
/etc/cron.deny:
  file.absent
{% endif %}

{% if cis_benchmark.cron_allow %}
/etc/cron.allow:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - replace: False
{% endif %}
  
# 5.2.1
/etc/ssh/sshd_config:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - replace: False

# 5.3
{% if cis_benchmark.password_creation_requirements %}
/etc/security/pwquality.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
        minlen=14
        dcredit=-1
        ucredit=-1
        ocredit=-1
        lcredit=-1
{% endif %}

{% if cis_benchmark.pam_password_files %}
/etc/pam.d/password-auth-ac:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
        auth        required      pam_env.so
        auth        sufficient    pam_unix.so nullok try_first_pass
        auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
        auth        required      pam_deny.so
        
        auth required pam_faillock.so preauth audit silent deny=5 unlock_time=900
        auth [success=1 default=bad] pam_unix.so
        auth [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900
        auth sufficient pam_faillock.so authsucc audit deny=5 unlock_time=900

        account     required      pam_unix.so
        account     sufficient    pam_localuser.so
        account     sufficient    pam_succeed_if.so uid < 1000 quiet
        account     required      pam_permit.so
        
        password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
        password    sufficient    pam_unix.so remember=5 sha512 shadow nullok try_first_pass use_authtok
        password    required      pam_deny.so
        
        session     optional      pam_keyinit.so revoke
        session     required      pam_limits.so
        -session     optional      pam_systemd.so
        session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
        session     required      pam_unix.so

/etc/pam.d/system-auth-ac:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
        auth        required      pam_env.so
        auth        sufficient    pam_unix.so nullok try_first_pass
        auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
        auth        required      pam_deny.so
        
        auth required pam_faillock.so preauth audit silent deny=5 unlock_time=900
        auth [success=1 default=bad] pam_unix.so
        auth [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900
        auth sufficient pam_faillock.so authsucc audit deny=5 unlock_time=900

        account     required      pam_unix.so
        account     sufficient    pam_localuser.so
        account     sufficient    pam_succeed_if.so uid < 1000 quiet
        account     required      pam_permit.so
        
        password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
        password    sufficient    pam_unix.so remember=5 sha512 shadow nullok try_first_pass use_authtok
        password    required      pam_deny.so
        
        session     optional      pam_keyinit.so revoke
        session     required      pam_limits.so
        -session     optional      pam_systemd.so
        session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
        session     required      pam_unix.so

{% endif %}


{% if cis_benchmark.login_defs_password %}
# 5.4.1.1 - 5.4.1.3
login_defs_password:
  file.blockreplace:
    - name: /etc/login.defs
    - append_if_not_found: True
    - marker_start: '#-- salt managed login defs zone --'
    - marker_end: '#-- end salt managed login defs --'
    - content: |
        PASS_MAX_DAYS 90
        PASS_MAX_DAYS 7
        PASS_WARN_AGE 7
{% endif %}

# 5.4.1.4
{% if cis_benchmark.inactive_lock %}
useradd_inactive_lock:
  file.line:
    - name: /etc/default/useradd
    - match: INACTIVE=-1
    - content: |
        INACTIVE=30
    - mode: replace
{% endif %}

# 5.6
{% if cis_benchmark.pam_su %}
/etc/pam.d/su:
  file.blockreplace:
    - append_if_not_found: True
    - marker_start: '#-- salt managed su zone --'
    - marker_end: '#-- end salt managed su defs --'
    - content: |
        auth required pam_wheel.so use_uid
{% endif %}

# 6.1.4
/etc/crontab:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - replace: False

# 6.1.5
/etc/cron.hourly:
  file.directory:
    - user: root
    - group: root
    - mode: 700

# 6.1.6
/etc/cron.daily:
  file.directory:
    - user: root
    - group: root
    - mode: 700

# 6.1.7
/etc/cron.weekly:
  file.directory:
    - user: root
    - group: root
    - mode: 700

# 6.1.8
/etc/cron.monthly:
  file.directory:
    - user: root
    - group: root
    - mode: 700

# 6.1.6
/etc/passwd-:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - replace: False

# 6.1.8
/etc/group-:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - replace: False

# 6.1.9
/etc/cron.d:
  file.directory:
    - user: root
    - group: root
    - mode: 700

# 6.1.10
/etc/at.deny:
  file.absent

/etc/at.allow:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - replace: False

# Omitted: 6.1.11


