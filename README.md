# deploy-dev-digitalocean


## Description
Deploy a custom configured droplet into Digital Ocean, provision it via the shell & ansible, and configure your local ssh client to use the droplet without the hassle of adding DNS.  This was created to quickly create a development environment to use and then throw it away.

### Disclaimer
_This is very much a work in progress. Please be patient while I add more code and playbooks. If you find this useful, [drop me a note](https://chadmayfield.com/contact/)._

## Requirements
* A Digital Ocean account. ([Use my referral link](https://m.do.co/c/4bea333bc82a) to give you $50 over 30 days.)
* A Digital Ocean personal [API](https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key) key saved in an environment variable as $DO_KEY
* Additional command-line utilities required;
  * [vagrant](https://www.vagrantup.com):
  * [curl](https://curl.haxx.se):
  * [jq](https://stedolan.github.io/jq/):
* A ssh config file that is [configured](http://man7.org/linux/man-pages/man5/ssh_config.5.html) to 'Include config.d' so we can add custom options to connect to the deployed droplet.

## Invocation



# Sample output
There are currently two options available with the main script, `droplet.sh`.  Get and create.

## 'get'
This option will query the Digital Ocean API and get one of three things; available regions, droplet sizes, and main distros.

### droplet regions
```
(0) [chad@laptop:~] $ ./droplet.sh get regions
==========================
ACTIVE LOCATION  ||  SLUG
==========================
    Amsterdam 3  =>  ams3
    Bangalore 1  =>  blr1
    Frankfurt 1  =>  fra1
       London 1  =>  lon1
     New York 1  =>  nyc1
     New York 3  =>  nyc3
San Francisco 2  =>  sfo2
    Singapore 1  =>  sgp1
      Toronto 1  =>  tor1
```

#### droplet sizes
```
(0) [chad@laptop:~] $ ./droplet.sh get sizes
=======================================================================
   DROPLET SLUG :   CPU       MEM     STORAGE  BANDWIDTH          PRICE
=======================================================================
          512mb :  1cpu     512MB    20GB SSD   1TB Xfer     $5/monthly
    s-1vcpu-1gb :  1cpu    1024MB    25GB SSD   1TB Xfer     $5/monthly
            1gb :  1cpu    1024MB    30GB SSD   2TB Xfer    $10/monthly
    s-1vcpu-2gb :  1cpu    2048MB    50GB SSD   2TB Xfer    $10/monthly
    s-1vcpu-3gb :  1cpu    3072MB    60GB SSD   3TB Xfer    $15/monthly
    s-2vcpu-2gb :  2cpu    2048MB    60GB SSD   3TB Xfer    $15/monthly
    s-3vcpu-1gb :  3cpu    1024MB    60GB SSD   3TB Xfer    $15/monthly
            2gb :  2cpu    2048MB    40GB SSD   3TB Xfer    $20/monthly
    s-2vcpu-4gb :  2cpu    4096MB    80GB SSD   4TB Xfer    $20/monthly
            4gb :  2cpu    4096MB    60GB SSD   4TB Xfer    $40/monthly
            c-2 :  2cpu    4096MB    25GB SSD   4TB Xfer    $40/monthly
    m-1vcpu-8gb :  1cpu    8192MB    40GB SSD   5TB Xfer    $40/monthly
    s-4vcpu-8gb :  4cpu    8192MB   160GB SSD   5TB Xfer    $40/monthly
    g-2vcpu-8gb :  2cpu    8192MB    25GB SSD   4TB Xfer    $60/monthly
   gd-2vcpu-8gb :  2cpu    8192MB    50GB SSD   4TB Xfer    $65/monthly
         m-16gb :  2cpu   16384MB    60GB SSD   5TB Xfer    $75/monthly
            8gb :  4cpu    8192MB    80GB SSD   5TB Xfer    $80/monthly
            c-4 :  4cpu    8192MB    50GB SSD   5TB Xfer    $80/monthly
   s-6vcpu-16gb :  6cpu   16384MB   320GB SSD   6TB Xfer    $80/monthly
   g-4vcpu-16gb :  4cpu   16384MB    50GB SSD   5TB Xfer   $120/monthly
  gd-4vcpu-16gb :  4cpu   16384MB   100GB SSD   5TB Xfer   $130/monthly
         m-32gb :  4cpu   32768MB    90GB SSD   5TB Xfer   $150/monthly
           16gb :  8cpu   16384MB   160GB SSD   6TB Xfer   $160/monthly
            c-8 :  8cpu   16384MB   100GB SSD   6TB Xfer   $160/monthly
   s-8vcpu-32gb :  8cpu   32768MB   640GB SSD   7TB Xfer   $160/monthly
  s-12vcpu-48gb : 12cpu   49152MB   960GB SSD   8TB Xfer   $240/monthly
   g-8vcpu-32gb :  8cpu   32768MB   100GB SSD   6TB Xfer   $240/monthly
  gd-8vcpu-32gb :  8cpu   32768MB   200GB SSD   6TB Xfer   $260/monthly
         m-64gb :  8cpu   65536MB   200GB SSD   5TB Xfer   $300/monthly
           32gb : 12cpu   32768MB   320GB SSD   7TB Xfer   $320/monthly
           c-16 : 16cpu   32768MB   200GB SSD   7TB Xfer   $320/monthly
  s-16vcpu-64gb : 16cpu   65536MB  1280GB SSD   9TB Xfer   $320/monthly
           48gb : 16cpu   49152MB   480GB SSD   8TB Xfer   $480/monthly
  s-20vcpu-96gb : 20cpu   98304MB  1920GB SSD  10TB Xfer   $480/monthly
  g-16vcpu-64gb : 16cpu   65536MB   200GB SSD   7TB Xfer   $480/monthly
 gd-16vcpu-64gb : 16cpu   65536MB   400GB SSD   7TB Xfer   $520/monthly
        m-128gb : 16cpu  131072MB   340GB SSD   5TB Xfer   $600/monthly
           64gb : 20cpu   65536MB   640GB SSD   9TB Xfer   $640/monthly
           c-32 : 32cpu   65536MB   400GB SSD   9TB Xfer   $640/monthly
 s-24vcpu-128gb : 24cpu  131072MB  2560GB SSD  11TB Xfer   $640/monthly
 s-32vcpu-192gb : 32cpu  196608MB  3840GB SSD  12TB Xfer   $960/monthly
 g-32vcpu-128gb : 32cpu  131072MB   400GB SSD   8TB Xfer   $960/monthly
gd-32vcpu-128gb : 32cpu  131072MB   800GB SSD   8TB Xfer  $1040/monthly
        m-224gb : 32cpu  229376MB   500GB SSD   5TB Xfer  $1100/monthly
 g-40vcpu-160gb : 40cpu  163840MB   500GB SSD   9TB Xfer  $1200/monthly
gd-40vcpu-160gb : 40cpu  163840MB  1000GB SSD   9TB Xfer  $1300/monthly
```

### droplet distros
```
(0) [chad@laptop:~] $ ./droplet.sh get distros
==============================================
  DISTRIBUTION NAME/VERSION  ||  SLUG
==============================================
             CentOS 6.9 x32  =>  centos-6-x32
             CentOS 6.9 x64  =>  centos-6-x64
             CentOS 7.6 x64  =>  centos-7-x64
   CoreOS 2191.5.0 (stable)  =>  coreos-stable
     CoreOS 2219.2.1 (beta)  =>  coreos-beta
    CoreOS 2247.0.0 (alpha)  =>  coreos-alpha
              Debian 10 x64  =>  debian-10-x64
             Debian 9.7 x64  =>  debian-9-x64
              Fedora 28 x64  =>  fedora-28-x64
              Fedora 29 x64  =>  fedora-29-x64
              Fedora 30 x64  =>  fedora-30-x64
Fedora Atomic 28 x64 Atomic  =>  fedora-28-x64-atomic
       FreeBSD 11.3 x64 ufs  =>  freebsd-11-x64-ufs
       FreeBSD 11.3 x64 zfs  =>  freebsd-11-x64-zfs
       FreeBSD 12.0 x64 ufs  =>  freebsd-12-x64
       FreeBSD 12.0 x64 zfs  =>  freebsd-12-x64-zfs
           RancherOS v1.4.3  =>  rancheros-1.4
           RancherOS v1.5.4  =>  rancheros
   Ubuntu 16.04.6 (LTS) x32  =>  ubuntu-16-04-x32
   Ubuntu 16.04.6 (LTS) x64  =>  ubuntu-16-04-x64
   Ubuntu 18.04.3 (LTS) x64  =>  ubuntu-18-04-x64
           Ubuntu 19.04 x64  =>  ubuntu-19-04-x64
```

### 'create'

```
(0) [chad@laptop:~] $ ./droplet.sh create sfo2 s-1vcpu-1gb ubuntu-18-04-x64 test1
Deploying machine: sfo2-s-1vcpu-1gb-20190904-1209
Bringing machine 'test1' up with 'digital_ocean' provider...
==> test1: Using existing SSH key: Vagrant
==> test1: Creating a new droplet...
==> test1: Assigned IP address: 167.71.147.218
==> test1: Creating user account: chad...
==> test1: Rsyncing folder: /Users/chad/digitalocean/deployments/sfo2-s-1vcpu-1gb-20190904-1209/ => /vagrant
==> test1:   - Exclude: [".vagrant/", ".git/.gitignore.vscode"]
==> test1: Running provisioner: shell...
    test1: Running: /var/folders/mh/zj515z4x1xx162j7s5yh42cr0000gn/T/vagrant-shell20190904-77322-1awd6vj.sh
    test1: Beginning provisioning on root@test1
    test1: Get:1 http://mirrors.digitalocean.com/ubuntu bionic InRelease [242 kB]
    test1: Get:2 http://mirrors.digitalocean.com/ubuntu bionic-updates InRelease [88.7 kB]
    test1: Get:3 http://mirrors.digitalocean.com/ubuntu bionic-backports InRelease [74.6 kB]
    test1: Get:4 http://mirrors.digitalocean.com/ubuntu bionic/universe amd64 Packages [8570 kB]
    test1: Get:5 http://security.ubuntu.com/ubuntu bionic-security InRelease [88.7 kB]
    test1: Get:6 http://mirrors.digitalocean.com/ubuntu bionic/universe Translation-en [4941 kB]
...
...
...
...
...
...
    test1: (Reading database ...
    test1: 59707 files and directories currently installed.)
    test1: Preparing to unpack .../do-agent_3.5.6_amd64.deb ...
    test1: Unpacking do-agent (3.5.6) ...
    test1: Setting up do-agent (3.5.6) ...
    test1: Detecting SELinux
    test1: SELinux not enforced
    test1: userdel: user 'do-agent' does not exist
    test1: enable systemd service
    test1: Created symlink /etc/systemd/system/multi-user.target.wants/do-agent.service → /etc/systemd/system/do-agent.service.
    test1: Processing triggers for ureadahead (0.100.0-21) ...
==> test1: Running provisioner: ansible_local...
    test1: Installing Ansible...
Vagrant has automatically selected the compatibility mode '2.0'
according to the Ansible version installed (2.8.4).

Alternatively, the compatibility mode can be specified in your Vagrantfile:
https://www.vagrantup.com/docs/provisioning/ansible_common.html#compatibility_mode

    test1: Running ansible-playbook...

PLAY [all] *********************************************************************

TASK [shell] *******************************************************************
changed: [test1]

TASK [debug] *******************************************************************
ok: [test1] => {
    "ls_result.stdout_lines": [
        "ansible.cfg",
        "group_vars",
        "playbook.yaml",
        "roles"
    ]
}

TASK [shell] *******************************************************************
changed: [test1]

TASK [debug] *******************************************************************
ok: [test1] => {
    "who.stdout_lines": [
        "root"
    ]
}

PLAY RECAP *********************************************************************
test1                      : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

==> test1: Running action triggers after up ...
==> test1: Running trigger: Finished Message...
==> test1: Machine is up!
```