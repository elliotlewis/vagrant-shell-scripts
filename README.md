Vagrant Provision scripts using VirtualBox and Shell (Bash)
===========================================================

Suggested file structure

- Project/
  - Vagrant
  - bootstrap.sh
  - vagrant-shell-scripts/

Usage
-----

1. Set-up Vagrant

    $ vagrant init

2. Submodule vagrant-shell-scripts into same directory as Vagrant

3. Copy vagrant-shell-scripts/_Vagrant to Vagrant and amend as necessary for host

4. Copy vagrant-shell-scripts/_bootstrap to same location as Vagrant and amend as necessary for provissioning