---
title: "Encrypting External Storage for Enhanced Security"
date: 2023-07-06T14:55:04-03:00
categories: ["Cryptography", "Cybersecurity"]
---
Protecting sensitive information from unauthorized access and potential breaches is crucial, especially when it comes to external storage devices like USB drives, which are susceptible to loss or theft.

After [setting up an encrypted Proxmox instance on my server](https://pablodip.me/post/encrypted-proxmox), I needed to protect my external storage. It wouldnt be very usefull to run my hypervisor over an encrypted LVM volume if I store all my backups and data on a open HDD.

Today I will show you the very simple process of encrypting a drive to ensure the confidentiality and integrity of your data. 

To begin, let's find the drive we want to encrypt
{{< highlight bash >}}
lsblk
{{< /highlight >}}
```
NAME                  MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda                     8:0    0   1.8T  0 disk
└─sda1                  8:1    0   1.8T  0 part
sdb                     8:16   0 232.9G  0 disk
├─sdb1                  8:17   0   512M  0 part  /boot/efi
├─sdb2                  8:18   0   732M  0 part  /boot
└─sdb3                  8:19   0 231.7G  0 part
  └─sda3_crypt        254:0    0 231.7G  0 crypt
    └─parrot--vg-root 254:1    0 231.6G  0 lvm  
sdc                     8:32   0   9.1T  0 disk
└─sdc1                  8:33   0   9.1T  0 part
sdd                     8:48   0 931.5G  0 disk
└─sdd1                  8:49   0 931.5G  0 part
```


For this example, let's assume we will use ```sdd```.
Before encrypting the drive, I highly recommend performing a secure erase to overwrite the entire disk with random data. This step helps protect against potential file recovery. 
Ensure you have identified the correct drive on the previous step, as the following command will delete all of its contents.

{{< highlight bash >}}
sudo dd if=/dev/zero of=/dev/sdd count=4096
{{< /highlight >}}

### Encrypt the Device

The command ```cryptsetup``` is ussed to setup cryptographic volumes and the subcommand ```luksFormat``` initializes a LUKS partition and sets the initial key.
The example below uses these commands to encrypt the ```/dev/sdd``` partition. Keep in mind that by executing this command you will lose all data on the partition that you are encrypting.

{{< highlight bash >}}
sudo cryptsetup luksFormat /dev/sdd
{{< /highlight >}}


You will be prompted with a warning message. Type "YES" in uppercase to confirm and proceed. Then, enter and verify your passphrase.
```
WARNING!
========
This will overwrite data on /dev/sdd irrevocably.

Are you sure? (Type uppercase yes): YES
Enter passphrase: 
Verify passphrase:
```
Create a logical device-mapper device, mounted to the LUKS-encrypted partition. In the example below, encryptedDrive is the given name of the mapping name for the opened LUKS partition.
{{< highlight bash >}}
sudo cryptsetup open /dev/sdd encryptedDrive
{{< /highlight >}}

LUKS volumes are opened in ```/dev/mapper```. We can see that our encrypted drive is listed:
{{< highlight bash >}}
ls /dev/mapper
{{< /highlight >}}
```
control parrot--vg-root sda3_crypt encryptedDrive
```

Now, let's format the encrypted partition with the ext4 filesystem and assign the label encryptedDrive to it.

{{< highlight bash >}}
sudo mkfs.ext4 -L encryptedDrive /dev/mapper/encryptedDrive
{{< /highlight >}}

Finally, we can mount the encrypted drive to directory. I will mount it to ```/mnt/vaultDrive```

{{< highlight bash >}}
sudo mount /dev/mapper/encryptedDrive /mnt/vaultDrive
{{< /highlight >}}

