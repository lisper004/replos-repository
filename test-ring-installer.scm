;; JUST FOR TEST

(use-modules (ice-9 rdelim)
             (ice-9 regex)
             (srfi srfi-1))

(define (get-user-input prompt)
  (display prompt)
  (flush-all-ports)
  (string-trim-both (read-line)))

(define (yes-no? prompt)
  (let ((answer (get-user-input (string-append prompt " (y/n): "))))
    (or (string=? answer "y")
        (string=? answer "yes")
        (string=? answer "Y"))))

(define (run-cmd cmd)
  (format #t "  → ~a\n" cmd)
  (system cmd))

(define (run-cmd-check cmd)
  (let ((status (run-cmd cmd)))
    (unless (zero? status)
      (error (string-append "Command failed: " cmd)))
    status))

(define (list-disks)
  (display "\nAvailable disks:\n")
  (run-cmd "lsblk -o NAME,SIZE,TYPE,MODEL | grep disk")
  (display "\n"))

(define (select-disk)
  (list-disks)
  (let ((disk (get-user-input "Enter disk (e.g., /dev/sda): ")))
    (if (file-exists? disk)
        disk
        (begin
          (display "Disk not found.\n")
          (select-disk)))))

(define (partition-disk disk)
  (display "\n--- Partitioning ---\n")
  
  (when (yes-no? "This will ERASE ALL DATA on disk. Continue?")
    (run-cmd-check (string-append "sudo parted -s " disk " mklabel gpt"))
    
    (run-cmd-check (string-append "sudo parted -s " disk " mkpart primary fat32 1MiB 513MiB"))
    (run-cmd-check (string-append "sudo parted -s " disk " set 1 esp on"))
    
    (run-cmd-check (string-append "sudo parted -s " disk " mkpart primary ext4 513MiB 100%"))
    
    (display "Partitioning complete.\n")
    #t))

(define (format-partitions disk)
  (display "\n--- Formatting ---\n")
  
  (let* ((disk-name (string-trim disk (string->list "/dev/")))
         (efi-part (string-append disk "1"))
         (root-part (string-append disk "2")))
    
    (format #t "Formatting EFI (fat32): ~a\n" efi-part)
    (run-cmd-check (string-append "sudo mkfs.fat -F32 " efi-part))
    
    (format #t "Formatting root (ext4): ~a\n" root-part)
    (run-cmd-check (string-append "sudo mkfs.ext4 -F " root-part))
    
    (cons efi-part root-part)))

(define (mount-partitions parts)
  (display "\n--- Mounting ---\n")
  
  (let ((root (cdr parts))
        (boot (car parts)))
    
    (run-cmd-check "sudo mount /dev/disk/by-label/RING /mnt")
    (run-cmd-check (string-append "sudo mount " boot " /mnt/boot"))
    
    (display "Mounted.\n")))

(define (install-base-system)
  (display "\n--- Installing base system ---\n")
  
  (let ((packages "base base-devel linux linux-firmware grub efibootmgr"))
    (format #t "Installing: ~a\n" packages)
    (run-cmd-check (string-append "sudo pacstrap -K /mnt " packages)))
  
  (display "Base system installed.\n"))

(define (configure-system)
  (display "\n--- Configuring system ---\n")
  
  (run-cmd-check "sudo genfstab -U /mnt >> /mnt/etc/fstab")
  
  (call-with-output-file "/tmp/chroot-setup.sh"
    (lambda (port)
      (format port "#!/bin/bash
set -e

echo '--- Chroot configuration ---'

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo 'ring' > /etc/hostname

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=RING
grub-mkconfig -o /boot/grub/grub.cfg

git clone https://github.com/lisper004/replos.git /root/.replos
cp -r /root/.replos/.guile /root/
              
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF

echo 'Configuration complete.'
")))
  
  (run-cmd-check "chmod +x /tmp/chroot-setup.sh")
  (run-cmd-check "sudo arch-chroot /mnt /bin/bash /tmp/chroot-setup.sh")
  (run-cmd-check "rm /tmp/chroot-setup.sh")
  
  (display "System configured.\n"))

(define (finish-installation parts)
  (display "\n--- Finishing ---\n")
  
  (run-cmd "sync")
  
  (when (yes-no? "Unmount partitions?")
    (run-cmd "sudo umount -R /mnt")
    (display "Unmounted.\n"))
  
  (display "\n RING installation complete!\n")
  (display "You can now reboot.\n"))

(define (ring-install)
  (display "
╔═══════════════════════════════════════════╗
║   RING Installer (UNSTABLE TEST VER.)     ║
║   (Replos Is Not Guix)                    ║
╚═══════════════════════════════════════════╝
")
  
  (let ((disk (select-disk)))
    (when (yes-no? (string-append "Install RING to " disk "?"))
      (partition-disk disk)
      (let ((parts (format-partitions disk)))
        (mount-partitions parts)
        (install-base-system)
        (configure-system)
        (finish-installation parts))
      (display "Installation finished.\n"))))
