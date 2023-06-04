---
title: "Bruteforcing a fully encrypted LVM drive"
date: 2023-06-04T16:16:39-03:00
categories: [ "Cryptography", "Cybersecurity", "Infosec", "Bruteforcing", "posts"]
---

One of the most crucial lessons that security professionals and enthusiasts must grasp is that security policies should be tailored to a business's needs, and realistic goals should be set for their implementation. 
I learned this lesson many years ago by forgetting the last 4 chars of my 45-character-long password.

Back in 2014, "No Place to Hide" by Glenn Greenwald had just come out, and the side effect of reading it in a couple of days is a bit of paranoia. That's when I decided to start fully encrypting my drives using LUKS.
I used GRC's "Perfect Passwords" to generate my password, and after memorizing it I destroyed every copy I had of it.
A few months later my PSU suddenly broke down. Unfortunately, the shop took 1 month to honor the warranty, and when I tried decrypting my disk I was uncertain about four different characters.

For this occasion, I would use a random password that I just generated:

> .BbV.$D]8ftauy~$(OgA<BM63!ft@O46hj8yJ.9{en**s%F**

Using upper and lower case letters, numbers, and special characters, I had 830584 possible combinations.


### LUKS1 overview
LUKS (Linux Unified Key Setup) is a specification for block device encryption. It establishes an on-disk format for the data, as well as a passphrase/key management policy.
There is an unencrypted header at the beginning of an encrypted volume, which allows up to 8 (LUKS1) or 32 (LUKS2) encryption keys to be stored along with encryption parameters such as cipher type and key size.

The basic on-disk structure of a LUKS1 header is depicted below:

![luks1 header](/disklayout.jpg)

A LUKS1 partition is composed of the partition header (phdr), followed by key material and then the bulk data.

**The header (phdr):** Contains information about the cipher, cipher mode, key length, hash function, master key checksum, salt, and iteration counts.

**Key Material:** Where an encrypted copy of the master key is stored.

The password you create when encrypting a volume it's not used to encrypt the bulk data itself but rather to lock an encrypted copy of the master key. 
Supplying the user password unlocks the decryption for the key material, which stores the master key. The master key in turn unlocks the bulk data

Although you don't need to have a backup of your LUKS header to brute force your disk, I highly recommend that you create one while you still have access to the drive. If the header of a LUKS volume gets corrupted, you won't be able to access or decrypt your data unless you have a backup of your header. Keep in mind that you cannot backup the header of an encrypted LUKS drive without the passphrase because the contents of the header are encrypted using the passphrase and cannot be accessed without it. If you don't have a backup of your header, create one now! 
You can use cryptsetup to make a backup of your LUKS header:

```
sudo cryptsetup luksHeaderBackup /dev/sdb1 --header-backup-file luks_backup_sdb1
```


### Bruteforcing a LUKS1 header

To access the bulk data we need the master key, and to recover it the user must supply a password. Then the password is processed for every active key slot. The recovery is successful when a master key candidate correctly checksums against the master key checksum stored in the phdr.

First, I wrote a simple Python script to create a dictionary with all of the possible combinations.

{{< highlight python3 >}}
import itertools
import string

def passwordGenerator():
    characters = string.ascii_letters + string.digits + string.punctuation
    incompletePassword = r".BbV.$D]8ftauy~$(OgA<BM63!ft@O46hj8yJ.9{en" #Create a raw string so we can include the backslash character (\) as a literal character

    with open("dictionary.txt", "w") as dictionaryFile:
        for i in itertools.product(characters, repeat=3):
            combination = ''.join(i) #Convert the output of itertools to a string
            dictionaryFile.write(incompletePassword + combination + '\n')

passwordGenerator()

{{< /highlight >}}

To bruteforce the header we can use a tool like bruteforce-luks.
```
bruteforce-luks -t 8 -v 60 -f dictionary.txt /dev/sdd1
```
-t CPU threads to be used
-v Print progress information every x seconds
-f  path to the diccionary
/dev/sdxx path to the encrypted drive partition

