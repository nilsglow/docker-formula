# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import data as d with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

{%- if 'repo' in d.pkg.docker and d.pkg.docker.repo %}
  {%- from tplroot ~ "/files/macros.jinja" import format_kwargs with context %}

  {% if grains.os_family == 'Debian' %}
docker-software-package-repo-keyring-managed:
  file.managed:
    - name: {{ d.pkg.docker.repo_keyring }}
    - source: {{ files_switch(['docker-archive-keyring.gpg'],
                              lookup='docker-software-package-repo-keyring-managed'
                 )
              }}
    - require_in:
      - file: docker-software-package-repo-managed

docker-software-package-repo-managed:
  file.managed:
    - name: {{ d.pkg.docker.repo.file }}
    - contents: {{ d.pkg.docker.repo.name }}

# Docker's key, formerly added via apt-key to the legacy /etc/apt/trusted.gpg,
# is trusted there for every repository. The list above references the
# keyring instead, so remove it.
docker-software-package-repo-legacy-apt-key-absent:
  cmd.run:
    - name: apt-key --keyring /etc/apt/trusted.gpg del 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
    - onlyif:
      - test -f /etc/apt/trusted.gpg
      - gpg --no-default-keyring --keyring /etc/apt/trusted.gpg --list-keys 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
    - require:
      - file: docker-software-package-repo-managed
      - file: docker-software-package-repo-keyring-managed

  {%- else %}

docker-software-package-repo-managed:
  pkgrepo.managed:
    {{- format_kwargs(d.pkg.docker.repo) }}
    - humanname: {{ grains["os"] }} {{ grains["oscodename"]|capitalize }} Docker Package Repository
    - refresh: {{ d.misc.refresh }}

  {%- endif %}
{%- endif %}
